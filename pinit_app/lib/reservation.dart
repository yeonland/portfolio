import 'dart:convert';

import 'package:flutter/material.dart' show DateUtils;
import 'package:shared_preferences/shared_preferences.dart';

// 예약 진행 단계: 문의 보냄 → 예약 확정 → 방문 완료
const List<String> reservationSteps = ['문의 보냄', '예약 확정', '방문 완료'];

class Reservation {
  final String id;
  final String shop;
  final String design;
  final String? price;
  final String? img;
  final DateTime date;
  final String time;
  final String channel;
  final int step; // reservationSteps의 인덱스

  const Reservation({
    required this.id,
    required this.shop,
    required this.design,
    this.price,
    this.img,
    required this.date,
    required this.time,
    required this.channel,
    this.step = 0,
  });

  bool get isDone => step == reservationSteps.length - 1;

  // 오늘 기준 남은 날짜 (0이면 당일, 음수면 지난 날짜)
  int daysLeft([DateTime? now]) {
    final today = DateUtils.dateOnly(now ?? DateTime.now());
    return DateUtils.dateOnly(date).difference(today).inDays;
  }

  String dDayLabel([DateTime? now]) {
    final days = daysLeft(now);
    if (days == 0) return 'D-day';
    return days > 0 ? 'D-$days' : 'D+${-days}';
  }

  Reservation copyWith({int? step}) {
    return Reservation(
      id: id,
      shop: shop,
      design: design,
      price: price,
      img: img,
      date: date,
      time: time,
      channel: channel,
      step: step ?? this.step,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'shop': shop,
        'design': design,
        'price': price,
        'img': img,
        'date': date.toIso8601String(),
        'time': time,
        'channel': channel,
        'step': step,
      };

  factory Reservation.fromJson(Map<String, dynamic> json) {
    return Reservation(
      id: json['id'] as String,
      shop: json['shop'] as String,
      design: json['design'] as String,
      price: json['price'] as String?,
      img: json['img'] as String?,
      date: DateTime.parse(json['date'] as String),
      time: json['time'] as String,
      channel: json['channel'] as String,
      step: json['step'] as int? ?? 0,
    );
  }
}

// 기기에 예약 목록 저장/불러오기 (웹에서는 브라우저 저장소 사용)
class ReservationStorage {
  static const _key = 'reservations';

  static Future<List<Reservation>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list.map((e) => Reservation.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return []; // 저장 형식이 깨졌으면 빈 목록으로 시작
    }
  }

  static Future<void> save(List<Reservation> reservations) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(reservations.map((r) => r.toJson()).toList()));
  }
}
