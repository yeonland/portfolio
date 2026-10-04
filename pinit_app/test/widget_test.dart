import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pinit_app/main.dart';

void main() {
  testWidgets('PinItApp builds', (WidgetTester tester) async {
    await tester.pumpWidget(const PinItApp());
    expect(find.byType(PinItApp), findsOneWidget);
  });

  testWidgets('핀잇 픽에서 예약 문의하면 예약 양식이 자동으로 채워진다', (WidgetTester tester) async {
    await tester.pumpWidget(const PinItApp());

    // 첫 번째 디자인(루나네일 - 시럽 마블 글리터 아트) 선택
    await tester.tap(find.text('55,000원'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('이 디자인으로 예약 문의하기'));
    await tester.pumpAndSettle();

    // 예약 양식 탭으로 이동 + 샵/디자인 자동 입력 확인
    expect(find.byType(ReservationFormScreen), findsOneWidget);
    expect(find.widgetWithText(TextFormField, '루나네일'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, '시럽 마블 글리터 아트'), findsOneWidget);
  });

  testWidgets('날짜와 시간을 고르지 않으면 안내 메시지가 뜬다', (WidgetTester tester) async {
    await tester.pumpWidget(const PinItApp());

    await tester.tap(find.text('예약 양식'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('✨ 주문서 완성하기'),
      200,
      scrollable: find
          .descendant(of: find.byType(ReservationFormScreen), matching: find.byType(Scrollable))
          .first,
    );
    await tester.tap(find.text('✨ 주문서 완성하기'));
    await tester.pump();

    expect(find.text('희망 날짜와 시간을 선택해주세요.'), findsOneWidget);
  });
}
