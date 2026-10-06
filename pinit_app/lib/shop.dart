import 'package:latlong2/latlong.dart';

// 지도 기준점: 강남역
const LatLng gangnamStation = LatLng(37.497952, 127.027619);

class Shop {
  final String name;
  final String category; // shopCategories 중 하나
  final String address;
  final LatLng location;
  final String? price;
  final String? naverUrl; // 네이버 예약/플레이스 링크 (없으면 네이버 지도 검색으로 연결)
  final String? kakaoUrl; // 카카오톡 채널 링크 (pf.kakao.com/...)
  final String? instagram; // 인스타그램 아이디 (@ 없어도 됨)
  final bool isSample; // 실제 샵이 아닌 예시 데이터

  const Shop({
    required this.name,
    required this.category,
    required this.address,
    required this.location,
    this.price,
    this.naverUrl,
    this.kakaoUrl,
    this.instagram,
    this.isSample = false,
  });

  Uri get naverUri =>
      naverUrl != null ? Uri.parse(naverUrl!) : Uri.https('map.naver.com', '/p/search/$name');

  Uri? get kakaoUri => kakaoUrl != null ? Uri.parse(kakaoUrl!) : null;

  Uri? get instagramUri {
    final id = instagram?.replaceFirst('@', '').trim();
    return (id == null || id.isEmpty) ? null : Uri.https('www.instagram.com', '/$id/');
  }

  // 강남역에서의 직선 거리 (예: 350m, 1.2km)
  String get distanceLabel {
    final meters = const Distance().as(LengthUnit.Meter, gangnamStation, location);
    return meters < 1000 ? '${meters.round()}m' : '${(meters / 1000).toStringAsFixed(1)}km';
  }
}

// 앞 3개: 뷰티(몸에 직접 받는 시술) / 뒤 3개: 주문 제작
const List<String> shopCategories = ['💅 네일', '👁️ 속눈썹', '💄 메이크업', '🎂 케이크', '💐 꽃집', '🎨 타투'];

// 샵 목록
// 좌표는 OpenStreetMap 도로 데이터 기준 추정값 (실제 건물과 최대 100m 정도 차이 가능)
const List<Shop> pinitShops = [
  Shop(
    name: '크라스니네일',
    category: '💅 네일',
    address: '서울 강남구 선릉로89길 11 1층',
    location: LatLng(37.503462, 127.048487),
    instagram: '@krasnyspace',
  ),
];
