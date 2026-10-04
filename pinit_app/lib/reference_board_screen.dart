import 'package:flutter/material.dart';

import 'design_detail_sheet.dart';
import 'favorites.dart';

// ---------------------------------------------------------------------------
// 💖 레퍼런스 보드 - 찜한 디자인을 카테고리(키워드)별로 모아보기
// ---------------------------------------------------------------------------
class ReferenceBoardScreen extends StatelessWidget {
  final FavoritesStore favorites;
  final ValueChanged<Map<String, String>> onReserve;

  const ReferenceBoardScreen({
    super.key,
    required this.favorites,
    required this.onReserve,
  });

  // 보드에서 예약 문의하면 보드를 닫고 예약 양식으로 이동
  void _reserveFromBoard(BuildContext context, Map<String, String> item) {
    Navigator.pop(context);
    onReserve(item);
  }

  void _remove(BuildContext context, Map<String, String> item) {
    favorites.toggle(item);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('\'${item['title']}\'을(를) 보드에서 뺐어요.'),
          action: SnackBarAction(label: '되돌리기', onPressed: () => favorites.toggle(item)),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('레퍼런스 보드', style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: ListenableBuilder(
        listenable: favorites,
        builder: (context, _) {
          final items = favorites.items;
          if (items.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.favorite_border, size: 56, color: Colors.grey),
                    SizedBox(height: 12),
                    Text(
                      '아직 찜한 디자인이 없어요',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '핀잇 픽에서 마음에 드는 디자인의 ♡를 눌러보세요.',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            );
          }

          // 키워드(#시럽네일, #생일케이크 …)별로 묶기 - 처음 등장한 순서 유지
          final groups = <String, List<Map<String, String>>>{};
          for (final item in items) {
            groups.putIfAbsent(item['keyword'] ?? '기타', () => []).add(item);
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              Text(
                '찜한 디자인 ${items.length}개',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              for (final entry in groups.entries) ...[
                Padding(
                  padding: const EdgeInsets.only(top: 16, bottom: 10),
                  child: Text(
                    '${entry.key} ${entry.value.length}',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                  ),
                ),
                GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 0.78,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    for (final item in entry.value) _buildCard(context, item),
                  ],
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildCard(BuildContext context, Map<String, String> item) {
    return GestureDetector(
      onTap: () => showDesignDetailSheet(
        context,
        item: item,
        favorites: favorites,
        onReserve: (design) => _reserveFromBoard(context, design),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    item['img']!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => imagePlaceholder(),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: IconButton(
                      tooltip: '보드에서 빼기',
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.85),
                      ),
                      icon: const Icon(Icons.favorite, color: Colors.red, size: 20),
                      onPressed: () => _remove(context, item),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            item['shop']!,
            style: const TextStyle(fontSize: 11, color: Colors.grey),
          ),
          Text(
            item['title']!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
          ),
          Text(
            item['price']!,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
