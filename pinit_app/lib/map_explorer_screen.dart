import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:url_launcher/url_launcher.dart';

import 'shop.dart';

// ---------------------------------------------------------------------------
// 📍 지도 탐색 화면 - OpenStreetMap 지도 + 샵 핀 + 예약 채널(네이버/카톡/인스타) 연결
// ---------------------------------------------------------------------------
class MultiChannelMapExplorerScreen extends StatefulWidget {
  final List<Shop> shops;

  const MultiChannelMapExplorerScreen({super.key, this.shops = pinitShops});

  @override
  State<MultiChannelMapExplorerScreen> createState() => _MultiChannelMapExplorerScreenState();
}

class _MultiChannelMapExplorerScreenState extends State<MultiChannelMapExplorerScreen> {
  final MapController _mapController = MapController();
  final PageController _pageController = PageController(viewportFraction: 0.86);
  String _selectedCategory = '전체';
  int _selectedIndex = 0;

  List<Shop> get _filteredShops => _selectedCategory == '전체'
      ? widget.shops
      : widget.shops.where((shop) => shop.category == _selectedCategory).toList();

  @override
  void dispose() {
    _pageController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  void _selectCategory(String category) {
    setState(() {
      _selectedCategory = category;
      _selectedIndex = 0;
    });
    if (_pageController.hasClients) _pageController.jumpToPage(0);
    final filtered = _filteredShops;
    if (filtered.isNotEmpty) _mapController.move(filtered.first.location, _mapController.camera.zoom);
  }

  // 핀을 누르면 해당 카드로, 카드를 넘기면 해당 핀으로 지도 이동
  void _onPinTap(int index) {
    _pageController.animateToPage(index, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
  }

  void _onCardChanged(int index) {
    setState(() {
      _selectedIndex = index;
    });
    _mapController.move(_filteredShops[index].location, _mapController.camera.zoom);
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

    return Stack(
      children: [
        // 1. 실제 지도 (OpenStreetMap)
        FlutterMap(
          mapController: _mapController,
          // 처음 열 때 모든 샵이 한 화면에 보이도록 (카드·필터 영역만큼 여백)
          options: MapOptions(
            initialCenter: gangnamStation,
            initialZoom: 15.5,
            initialCameraFit: widget.shops.length < 2
                ? null
                : CameraFit.coordinates(
                    coordinates: [for (final shop in widget.shops) shop.location],
                    padding: const EdgeInsets.fromLTRB(60, 80, 60, 230),
                  ),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.pinit_app',
            ),
            MarkerLayer(
              markers: [
                for (var i = 0; i < filteredShops.length; i++)
                  Marker(
                    point: filteredShops[i].location,
                    width: 140,
                    height: 36,
                    child: GestureDetector(
                      onTap: () => _onPinTap(i),
                      child: Center(child: _buildMapPin(filteredShops[i], i == _selectedIndex)),
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

        // 3. 하단 샵 카드 (좌우로 넘기기)
        Positioned(
          bottom: 28,
          left: 0,
          right: 0,
          child: SizedBox(
            height: 170,
            child: filteredShops.isEmpty
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
                : PageView.builder(
                    controller: _pageController,
                    itemCount: filteredShops.length,
                    onPageChanged: _onCardChanged,
                    itemBuilder: (context, index) => _buildShopCard(filteredShops[index]),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildShopCard(Shop shop) {
    final instagramUri = shop.instagramUri;
    final kakaoUri = shop.kakaoUri;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  shop.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
              if (shop.isSample)
                Container(
                  margin: const EdgeInsets.only(right: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text('예시', style: TextStyle(fontSize: 10, color: Colors.grey)),
                ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '강남역 ${shop.distanceLabel}',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          Text(
            '${shop.category} · ${shop.address}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          if (shop.price != null)
            Text(
              shop.price!,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          // 등록된 채널만 버튼으로 표시 (네이버는 링크가 없으면 지도 검색으로 연결)
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
      ),
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
