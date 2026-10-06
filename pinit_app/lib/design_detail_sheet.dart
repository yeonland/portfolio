import 'package:flutter/material.dart';

import 'favorites.dart';

// 이미지를 불러오지 못했을 때 보여줄 회색 자리표시
Widget imagePlaceholder() {
  return Container(
    color: Colors.grey[300],
    child: const Icon(Icons.image_not_supported_outlined, color: Colors.grey),
  );
}

// 디자인 상세 바텀시트 (핀잇 픽 · 레퍼런스 보드 공용)
void showDesignDetailSheet(
  BuildContext context, {
  required Map<String, String> item,
  required FavoritesStore favorites,
  required ValueChanged<Map<String, String>> onReserve,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (sheetContext) {
      return Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: double.infinity,
                height: 200,
                child: Image.network(
                  item['img']!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => imagePlaceholder(),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${item['shop']} · ${item['keyword']}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                // 북마크를 누르면 보관함(레퍼런스 보드)에 저장/해제
                ListenableBuilder(
                  listenable: favorites,
                  builder: (context, _) {
                    final isFavorite = favorites.isFavorite(item);
                    return TextButton.icon(
                      style: TextButton.styleFrom(foregroundColor: const Color(0xFFD63F7A)),
                      icon: Icon(isFavorite ? Icons.bookmark : Icons.bookmark_border),
                      label: Text(isFavorite ? '보관함에 있음' : '보관함에 저장'),
                      onPressed: () => favorites.toggle(item),
                    );
                  },
                ),
              ],
            ),
            Text(
              item['title']!,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              item['price']!,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () {
                  Navigator.pop(sheetContext);
                  onReserve(item);
                },
                child: const Text(
                  '이 디자인으로 예약 문의하기',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}
