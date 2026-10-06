import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

/// 네일샵 한 곳의 정보 (assets/data/nail_shops.json 한 줄)
class NailShop {
  final String id;
  final String name;
  final String address;
  final String floor;
  final double lat;
  final double lng;

  const NailShop({
    required this.id,
    required this.name,
    required this.address,
    required this.floor,
    required this.lat,
    required this.lng,
  });

  /// 화면에 보여줄 전체 주소 (층 포함)
  String get fullAddress => floor.isEmpty ? address : '$address $floor';

  factory NailShop.fromJson(Map<String, dynamic> json) {
    return NailShop(
      id: json['id'] as String,
      name: json['name'] as String,
      address: json['address'] as String,
      floor: (json['floor'] as String?) ?? '',
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
    );
  }
}

/// assets 폴더의 JSON을 읽어서 네일샵 목록으로 바꿔줌
Future<List<NailShop>> loadNailShops() async {
  final text = await rootBundle.loadString('assets/data/nail_shops.json');
  final list = jsonDecode(text) as List<dynamic>;
  return list
      .map((item) => NailShop.fromJson(item as Map<String, dynamic>))
      .toList();
}
