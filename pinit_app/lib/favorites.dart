import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

// 찜한 디자인 목록 - 바뀌면 화면들에 알려주고 기기에 저장
class FavoritesStore extends ChangeNotifier {
  static const _key = 'favorites';

  List<Map<String, String>> _items = [];

  List<Map<String, String>> get items => List.unmodifiable(_items);
  int get count => _items.length;

  // 디자인 데이터에 id가 없어서 '샵 + 디자인명'으로 구분
  static String _idOf(Map<String, String> item) => '${item['shop']}|${item['title']}';

  bool isFavorite(Map<String, String> item) => _items.any((e) => _idOf(e) == _idOf(item));

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return;
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      _items = list.map((e) => Map<String, String>.from(e as Map)).toList();
      notifyListeners();
    } catch (_) {
      // 저장 형식이 깨졌으면 빈 목록으로 시작
    }
  }

  void toggle(Map<String, String> item) {
    if (isFavorite(item)) {
      _items = _items.where((e) => _idOf(e) != _idOf(item)).toList();
    } else {
      _items = [Map.of(item), ..._items]; // 최근에 찜한 것이 앞으로
    }
    notifyListeners();
    _save();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(_items));
  }
}
