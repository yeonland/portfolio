import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:latlong2/latlong.dart';

import 'package:pinit_app/main.dart';
import 'package:pinit_app/map_explorer_screen.dart';
import 'package:pinit_app/reservation.dart';
import 'package:pinit_app/shop.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

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
    await _scrollToSubmit(tester);
    await tester.tap(find.text('✨ 주문서 완성하기'));
    await tester.pump();

    expect(find.text('희망 날짜와 시간을 선택해주세요.'), findsOneWidget);
  });

  testWidgets('주문서를 완성하고 복사하면 내 예약 타임라인에 저장된다', (WidgetTester tester) async {
    // 테스트 환경용 가짜 클립보드
    String? clipboardText;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') {
        clipboardText = (call.arguments as Map)['text'] as String?;
      }
      return null;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));

    await tester.pumpWidget(const PinItApp());

    // 디자인 선택 → 예약 양식
    await tester.tap(find.text('55,000원'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('이 디자인으로 예약 문의하기'));
    await tester.pumpAndSettle();

    // 날짜(기본값: 내일) · 시간 · 예약자 정보 입력
    await tester.tap(find.text('날짜 선택하기'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('15:00'));
    final nameField = find.widgetWithText(TextFormField, '이름');
    final phoneField = find.widgetWithText(TextFormField, '연락처 (예: 010-1234-5678)');
    await _scrollTo(tester, phoneField);
    await tester.enterText(nameField, '김핀잇');
    await tester.enterText(phoneField, '010-1234-5678');
    await _scrollToSubmit(tester);
    await tester.tap(find.text('✨ 주문서 완성하기'));
    await tester.pumpAndSettle();

    // 메시지 복사 → 타임라인 저장
    await tester.tap(find.text('메시지 복사하기'));
    await tester.pumpAndSettle();
    expect(clipboardText, contains('📅 희망 일시:'));
    await tester.tap(find.descendant(of: find.byType(BottomNavigationBar), matching: find.text('내 예약')));
    await tester.pumpAndSettle();

    expect(find.text('다가오는 예약 1'), findsOneWidget);
    expect(find.text('D-1'), findsOneWidget);
    expect(find.text('시럽 마블 글리터 아트'), findsOneWidget);

    // 기기 저장소에도 저장됐는지 확인
    final saved = await ReservationStorage.load();
    expect(saved.single.shop, '루나네일');
    expect(saved.single.time, '15:00');
  });

  testWidgets('타임라인에서 단계를 누르면 진행 상황이 바뀐다', (WidgetTester tester) async {
    final reservation = Reservation(
      id: '1',
      shop: '달콤케이크',
      design: '빈티지 레터링 커스텀',
      date: DateTime.now().add(const Duration(days: 3)),
      time: '13:00',
      channel: '💬 카톡',
    );
    SharedPreferences.setMockInitialValues({
      'reservations': jsonEncode([reservation.toJson()]),
    });

    await tester.pumpWidget(const PinItApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('내 예약'));
    await tester.pumpAndSettle();

    expect(find.text('D-3'), findsOneWidget);

    // 방문 완료로 바꾸면 지난 예약으로 이동
    await tester.tap(find.text('방문 완료'));
    await tester.pumpAndSettle();
    expect(find.text('지난 예약 1'), findsOneWidget);
    expect(find.text('완료'), findsOneWidget);
    expect((await ReservationStorage.load()).single.step, 2);
  });

  testWidgets('예약이 없으면 안내 화면이 보인다', (WidgetTester tester) async {
    await tester.pumpWidget(const PinItApp());
    await tester.tap(find.text('내 예약'));
    await tester.pumpAndSettle();

    expect(find.text('아직 예약이 없어요'), findsOneWidget);
  });

  testWidgets('하트를 누르면 레퍼런스 보드에 저장되고 피드에 찜 표시가 생긴다', (WidgetTester tester) async {
    await tester.pumpWidget(const PinItApp());
    expect(find.byIcon(Icons.favorite), findsNothing);

    // 상세 화면에서 찜하기
    await tester.tap(find.text('55,000원'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('찜하기'));
    await tester.pump();
    expect(find.byTooltip('찜 해제'), findsOneWidget);

    // 상세 화면 닫기 → 피드에 ♥ 표시 + 상단 배지 1
    await tester.tapAt(const Offset(20, 20));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.favorite), findsOneWidget);
    expect(find.descendant(of: find.byType(Badge), matching: find.text('1')), findsOneWidget);

    // 레퍼런스 보드에서 카테고리별로 확인
    await tester.tap(find.byTooltip('레퍼런스 보드'));
    await tester.pumpAndSettle();
    expect(find.text('#시럽네일 1'), findsOneWidget);
    expect(find.text('시럽 마블 글리터 아트'), findsOneWidget);

    // 기기 저장 확인
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('favorites'), contains('시럽 마블 글리터 아트'));
  });

  testWidgets('보드에서 빼면 사라지고 되돌리기로 복구된다', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({
      'favorites': jsonEncode([
        {'shop': '달콤케이크', 'title': '빈티지 레터링 커스텀', 'price': '38,000원', 'keyword': '#생일케이크', 'tag': '#레터링', 'img': 'https://example.com/a.jpg'},
      ]),
    });
    await tester.pumpWidget(const PinItApp());
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('레퍼런스 보드'));
    await tester.pumpAndSettle();
    expect(find.text('#생일케이크 1'), findsOneWidget);

    await tester.tap(find.byTooltip('보드에서 빼기'));
    await tester.pumpAndSettle();
    expect(find.text('아직 찜한 디자인이 없어요'), findsOneWidget);

    await tester.tap(find.text('되돌리기'));
    await tester.pumpAndSettle();
    expect(find.text('#생일케이크 1'), findsOneWidget);
  });

  testWidgets('보드에서 예약 문의하면 예약 양식으로 이동한다', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({
      'favorites': jsonEncode([
        {'shop': '달콤케이크', 'title': '빈티지 레터링 커스텀', 'price': '38,000원', 'keyword': '#생일케이크', 'tag': '#레터링', 'img': 'https://example.com/a.jpg'},
      ]),
    });
    await tester.pumpWidget(const PinItApp());
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('레퍼런스 보드'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('빈티지 레터링 커스텀'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('이 디자인으로 예약 문의하기'));
    await tester.pumpAndSettle();

    expect(find.byType(ReservationFormScreen), findsOneWidget);
    expect(find.widgetWithText(TextFormField, '달콤케이크'), findsOneWidget);
  });

  testWidgets('지도 탭: 등록된 채널만 버튼이 보이고 카테고리로 거를 수 있다', (WidgetTester tester) async {
    const testShops = [
      Shop(
        name: '테스트네일',
        category: '💅 네일',
        address: '서울 강남구',
        location: LatLng(37.4990, 127.0290),
        instagram: '@test_nail',
        kakaoUrl: 'https://pf.kakao.com/_test',
      ),
      Shop(
        name: '테스트케이크',
        category: '🎂 케이크',
        address: '서울 강남구',
        location: LatLng(37.5005, 127.0335),
      ),
    ];
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: MultiChannelMapExplorerScreen(shops: testShops)),
    ));
    await tester.pump();

    // 첫 번째 샵: 네이버 + 카톡 + 인스타 모두 표시
    expect(find.text('테스트네일'), findsOneWidget);
    expect(find.text('💬 카톡문의'), findsOneWidget);
    expect(find.text('📸 인스타'), findsOneWidget);

    // 케이크만 보기: 링크가 없는 카톡·인스타 버튼은 숨김
    await tester.tap(find.text('🎂 케이크'));
    await tester.pumpAndSettle();
    expect(find.text('테스트케이크'), findsOneWidget);
    expect(find.text('테스트네일'), findsNothing);
    expect(find.text('N 네이버'), findsOneWidget);
    expect(find.text('💬 카톡문의'), findsNothing);

    // 등록된 샵이 없는 카테고리
    await tester.tap(find.text('🎨 타투'));
    await tester.pumpAndSettle();
    expect(find.text('이 카테고리에는 아직 등록된 샵이 없어요.'), findsOneWidget);
  });

  test('샵 예약 채널 링크 만들기', () {
    const shop = Shop(
      name: '루나네일 강남점',
      category: '💅 네일',
      address: '서울 강남구',
      location: LatLng(37.4990, 127.0290),
      instagram: '@luna_nail',
    );
    // 네이버 링크가 없으면 네이버 지도 검색으로 연결
    expect(shop.naverUri.toString(), 'https://map.naver.com/p/search/${Uri.encodeComponent('루나네일 강남점')}');
    expect(shop.instagramUri.toString(), 'https://www.instagram.com/luna_nail/');
    expect(shop.kakaoUri, isNull);
    expect(shop.distanceLabel, endsWith('m'));
  });

  test('D-day 표시 계산', () {
    final now = DateTime(2026, 10, 4, 21, 30);
    Reservation at(DateTime date) =>
        Reservation(id: 'x', shop: 's', design: 'd', date: date, time: '11:00', channel: 'c');

    expect(at(DateTime(2026, 10, 4)).dDayLabel(now), 'D-day');
    expect(at(DateTime(2026, 10, 7)).dDayLabel(now), 'D-3');
    expect(at(DateTime(2026, 10, 2)).dDayLabel(now), 'D+2');
  });
}

Future<void> _scrollToSubmit(WidgetTester tester) => _scrollTo(tester, find.text('✨ 주문서 완성하기'));

// 예약 양식 안에서 원하는 위젯이 보일 때까지 스크롤
Future<void> _scrollTo(WidgetTester tester, Finder finder) {
  return tester.scrollUntilVisible(
    finder,
    200,
    scrollable: find
        .descendant(of: find.byType(ReservationFormScreen), matching: find.byType(Scrollable))
        .first,
  );
}
