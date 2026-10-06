import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import 'nail_shop.dart';
import 'shop.dart';

// ---------------------------------------------------------------------------
// 📍 지도 탐색 화면 - OpenStreetMap 지도 + 샵 핀 + 예약 채널(네이버/카톡/인스타) 연결
// 처음엔 지도만 보이고, 핀을 누르면 하단에 샵 카드가 뜸 (빈 곳을 누르면 닫힘)
// ---------------------------------------------------------------------------
class MultiChannelMapExplorerScreen extends StatefulWidget {
  final List<Shop> shops;

  const MultiChannelMapExplorerScreen({super.key, this.shops = pinitShops});

  @override
  State<MultiChannelMapExplorerScreen> createState() => _MultiChannelMapExplorerScreenState();
}

class _MultiChannelMapExplorerScreenState extends State<MultiChannelMapExplorerScreen> {
  final MapController _mapController = MapController();
  String _selectedCategory = '전체';
  List<NailShop> _nailShops = []; // 공공데이터(소상공인 상가정보) 강남구 네일샵

  // 지금 카드로 보고 있는 샵 (둘 중 하나만 선택됨, 둘 다 null이면 카드 없음)
  Shop? _selectedShop;
  NailShop? _selectedNail;

  // 공공데이터 핀은 '전체'와 '네일' 카테고리에서만 표시
  bool get _showNailShops => _selectedCategory == '전체' || _selectedCategory == '💅 네일';

  @override
  void initState() {
    super.initState();
    _loadNailShops();
  }

  Future<void> _loadNailShops() async {
    try {
      final shops = await loadNailShops();
      if (mounted) setState(() => _nailShops = shops);
    } catch (_) {
      // 데이터를 못 읽어도 직접 등록한 샵은 그대로 보여줌
    }
  }

  List<Shop> get _filteredShops => _selectedCategory == '전체'
      ? widget.shops
      : widget.shops.where((shop) => shop.category == _selectedCategory).toList();

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  void _selectCategory(String category) {
    setState(() {
      _selectedCategory = category;
      _selectedShop = null;
      _selectedNail = null;
    });
  }

  void _onShopTap(Shop shop) {
    setState(() {
      _selectedShop = shop;
      _selectedNail = null;
    });
    _mapController.move(shop.location, _mapController.camera.zoom);
  }

  void _onNailTap(NailShop nail) {
    setState(() {
      _selectedShop = null;
      _selectedNail = nail;
    });
    _mapController.move(LatLng(nail.lat, nail.lng), _mapController.camera.zoom);
  }

  void _closeCard() {
    setState(() {
      _selectedShop = null;
      _selectedNail = null;
    });
  }

  Future<void> _openLink(Uri uri, String channelName) async {
    final messenger = ScaffoldMessenger.of(context);
    var opened = false;
    try {
      opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      opened = false;
    }
    if (!opened) {
      messenger.showSnackBar(SnackBar(content: Text('$channelName 링크를 열 수 없어요.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredShops = _filteredShops;
    final hasNothing = filteredShops.isEmpty && !_showNailShops;

    return Stack(
      children: [
        // 1. 실제 지도 (OpenStreetMap)
        FlutterMap(
          mapController: _mapController,
          // 처음 열 때 강남역과 등록된 샵이 한 화면에 보이도록 (필터 영역만큼 여백)
          options: MapOptions(
            initialCameraFit: CameraFit.coordinates(
              coordinates: [gangnamStation, for (final shop in widget.shops) shop.location],
              padding: const EdgeInsets.fromLTRB(60, 80, 60, 60),
              maxZoom: 16,
            ),
            onTap: (_, _) => _closeCard(),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.pinit_app',
            ),
            // 공공데이터 네일샵: 작은 점 (직접 등록한 샵 핀보다 아래에 깔림)
            if (_showNailShops)
              MarkerLayer(
                markers: [
                  for (final nail in _nailShops)
                    Marker(
                      point: LatLng(nail.lat, nail.lng),
                      width: 22,
                      height: 22,
                      child: GestureDetector(
                        onTap: () => _onNailTap(nail),
                        child: Center(child: _buildNailDot(nail == _selectedNail)),
                      ),
                    ),
                ],
              ),
            MarkerLayer(
              markers: [
                for (final shop in filteredShops)
                  Marker(
                    point: shop.location,
                    width: 140,
                    height: 36,
                    child: GestureDetector(
                      onTap: () => _onShopTap(shop),
                      child: Center(child: _buildMapPin(shop, shop == _selectedShop)),
                    ),
                  ),
              ],
            ),
            const RichAttributionWidget(
              alignment: AttributionAlignment.bottomLeft,
              attributions: [TextSourceAttribution('OpenStreetMap contributors')],
            ),
          ],
        ),

        // 2. 카테고리 필터
        Positioned(
          top: 12,
          left: 0,
          right: 0,
          child: SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                for (final category in ['전체', ...shopCategories])
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: FilterChip(
                      label: Text(
                        category,
                        style: TextStyle(
                          color: _selectedCategory == category ? Colors.white : Colors.black,
                          fontWeight: _selectedCategory == category ? FontWeight.bold : FontWeight.normal,
                          fontSize: 12,
                        ),
                      ),
                      selected: _selectedCategory == category,
                      onSelected: (_) => _selectCategory(category),
                      selectedColor: Colors.black,
                      backgroundColor: Colors.white,
                      elevation: 3,
                      shadowColor: Colors.black26,
                      showCheckmark: false,
                    ),
                  ),
              ],
            ),
          ),
        ),

        // 3. 하단: 핀을 눌렀을 때만 샵 카드 표시
        if (_selectedShop != null || _selectedNail != null || hasNothing)
          Positioned(
            bottom: 28,
            left: 16,
            right: 16,
            child: hasNothing
                ? Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text('이 카테고리에는 아직 등록된 샵이 없어요.'),
                    ),
                  )
                : _selectedShop != null
                    ? _buildShopCard(_selectedShop!)
                    : _buildNailCard(_selectedNail!),
          ),
      ],
    );
  }

  // 카드 공통 틀: 이름 줄 + 내용 + 닫기 버튼
  Widget _buildCardFrame({required String title, List<Widget> badges = const [], required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
              ...badges,
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                tooltip: '닫기',
                visualDensity: VisualDensity.compact,
                onPressed: _closeCard,
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String text, {bool outlined = false}) {
    return Container(
      margin: const EdgeInsets.only(left: 6),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: outlined ? null : Colors.grey.withValues(alpha: 0.2),
        border: outlined ? Border.all(color: Colors.grey) : null,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: outlined ? 10 : 11,
          color: outlined ? Colors.grey : null,
          fontWeight: outlined ? null : FontWeight.bold,
        ),
      ),
    );
  }

  // 직접 등록한 샵 카드: 등록된 채널만 버튼으로 표시
  Widget _buildShopCard(Shop shop) {
    final instagramUri = shop.instagramUri;
    final kakaoUri = shop.kakaoUri;

    return _buildCardFrame(
      title: shop.name,
      badges: [
        if (shop.isSample) _buildBadge('예시', outlined: true),
        _buildBadge('강남역 ${shop.distanceLabel}'),
      ],
      children: [
        Text(
          '${shop.category} · ${shop.address}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        if (shop.price != null) ...[
          const SizedBox(height: 4),
          Text(
            shop.price!,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
        const SizedBox(height: 12),
        // 네이버는 링크가 없으면 지도 검색으로 연결
        Row(
          children: [
            _buildChannelButton(
              label: 'N 네이버',
              color: const Color(0xFF03C75A),
              textColor: Colors.white,
              onPressed: () => _openLink(shop.naverUri, '네이버'),
            ),
            if (kakaoUri != null)
              _buildChannelButton(
                label: '💬 카톡문의',
                color: const Color(0xFFFEE500),
                textColor: Colors.black87,
                onPressed: () => _openLink(kakaoUri, '카카오톡'),
              ),
            if (instagramUri != null)
              _buildChannelButton(
                label: '📸 인스타',
                color: const Color(0xFFE1306C),
                textColor: Colors.white,
                onPressed: () => _openLink(instagramUri, '인스타그램'),
              ),
          ],
        ),
      ],
    );
  }

  // 공공데이터 샵 카드: 예약 채널이 없어서 네이버 지도 검색으로 연결
  Widget _buildNailCard(NailShop nail) {
    final distance = const Distance().as(LengthUnit.Meter, gangnamStation, LatLng(nail.lat, nail.lng));
    final distanceLabel = distance < 1000 ? '${distance.round()}m' : '${(distance / 1000).toStringAsFixed(1)}km';

    return _buildCardFrame(
      title: nail.name,
      badges: [_buildBadge('강남역 $distanceLabel')],
      children: [
        Text(
          '💅 네일 · ${nail.fullAddress}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 4),
        const Text(
          '출처: 소상공인시장진흥공단 상가(상권)정보 · 예약 채널 미등록',
          style: TextStyle(fontSize: 11, color: Colors.grey),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildChannelButton(
              label: 'N 네이버 지도에서 보기',
              color: const Color(0xFF03C75A),
              textColor: Colors.white,
              onPressed: () => _openLink(Uri.https('map.naver.com', '/p/search/${nail.name}'), '네이버'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildChannelButton({
    required String label,
    required Color color,
    required Color textColor,
    required VoidCallback onPressed,
  }) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            padding: EdgeInsets.zero,
            minimumSize: const Size(0, 36),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            elevation: 0,
          ),
          onPressed: onPressed,
          child: Text(
            label,
            style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 11),
          ),
        ),
      ),
    );
  }

  Widget _buildNailDot(bool isSelected) {
    final size = isSelected ? 18.0 : 12.0;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: isSelected ? Colors.black : const Color(0xFFFF6FA5),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 2, offset: Offset(0, 1)),
        ],
      ),
    );
  }

  Widget _buildMapPin(Shop shop, bool isSelected) {
    final emoji = shop.category.split(' ').first;
    final shortName = shop.name.split(' ').first;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isSelected ? Colors.black : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black, width: 1.5),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Text(
        '$emoji $shortName',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.black,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
