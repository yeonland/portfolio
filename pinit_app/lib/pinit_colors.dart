import 'package:flutter/material.dart';

// 핀잇 포인트 색 (코랄 핑크 한 가지만 쓰고 나머지는 무채색)
const Color pinitAccent = Color(0xFFFF6B81);
const Color pinitAccentDark = Color(0xFFE0485F); // 글자·테두리용 진한 톤

// 예약 채널 브랜드 색
const Color kakaoYellow = Color(0xFFFEE500);
const Color naverGreen = Color(0xFF03C75A);
const Color instagramPink = Color(0xFFE1306C);

// 가격 문자열(예: '55,000원')을 숫자로
int priceValue(String? price) => int.tryParse((price ?? '').replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
