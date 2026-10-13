import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

// 찜한 디자인 목록 - 바뀌면 화면들에 알려주고 기기에 저장
class FavoritesStore extends ChangeNotifier {
  static const _key = 'favorites';

  List<Map<String, String>> _items = [];

  List<Map<String, String>> get items => List.unmodifiable(_items);
  int get count => _items.length;

  // 직접 추가한 레퍼런스는 id로, 핀잇 디자인은 id가 없어서 '샵 + 디자인명'으로 구분
  static String _idOf(Map<String, String> item) => item['id'] ?? '${item['shop']}|${item['title']}';

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

  // 직접 추가한 레퍼런스 저장 - 기기 저장 공간이 부족하면 되돌리고 false
  Future<bool> add(Map<String, String> item) async {
    _items = [Map.of(item), ..._items];
    notifyListeners();
    if (await _save()) return true;
    _items = _items.where((e) => _idOf(e) != _idOf(item)).toList();
    notifyListeners();
    return false;
  }

  Future<bool> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, jsonEncode(_items));
      return true;
    } catch (_) {
      return false; // 웹은 브라우저 저장 공간이 몇 MB라 사진이 많으면 실패할 수 있음
    }
  }
}
