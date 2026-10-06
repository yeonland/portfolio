import 'package:flutter/material.dart';

import 'designs.dart';
import 'shop.dart';

// ---------------------------------------------------------------------------
// 🏠 홈 - "무엇을 예약하시겠어요?" 카테고리를 고르면 해당 디자인으로 이동
// ---------------------------------------------------------------------------
class HomeScreen extends StatelessWidget {
  final ValueChanged<String> onCategorySelected;

  const HomeScreen({super.key, required this.onCategorySelected});

  // 몸에 직접 받는 시술 / 주문해서 받는 제작물
  static const Map<String, List<String>> _groups = {
    '뷰티': ['💅 네일', '👁️ 속눈썹', '💄 메이크업'],
    '주문 제작': ['🎂 케이크', '💐 꽃집', '🎨 타투'],
  };

  @override
  Widget build(BuildContext context) {
    // 지도에 샵이 등록된 카테고리 (지금은 네일만)
    final categoriesWithShops = pinitShops.map((shop) => shop.category).toSet();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
      children: [
        const Text(
          '무엇을 예약하시겠어요?',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          '디자인을 고르고, 샵을 찾고, 예약 문의까지 한 번에.',
          style: TextStyle(fontSize: 13, color: Colors.grey),
        ),
        for (final group in _groups.entries) ...[
          Padding(
            padding: const EdgeInsets.only(top: 28, bottom: 10),
            child: Text(
              group.key,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Row(
            children: [
              for (var i = 0; i < group.value.length; i++) ...[
                if (i > 0) const SizedBox(width: 10),
                Expanded(
                  child: _buildCategoryCard(
                    context,
                    group.value[i],
                    hasShops: categoriesWithShops.contains(group.value[i]),
                  ),
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildCategoryCard(
    BuildContext context,
    String category, {
    required bool hasShops,
  }) {
    final emoji = category.split(' ').first;
    final name = category.substring(emoji.length).trim();
    final designCount = pinitDesigns
        .where((design) => design['category'] == category)
        .length;

    return Material(
      color: Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(16),
      elevation: 1,
      shadowColor: Colors.black26,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => onCategorySelected(category),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
          child: Column(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 34)),
              const SizedBox(height: 8),
              Text(
                name,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '디자인 $designCount',
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: hasShops
                      ? const Color(0xFFFF6FA5).withValues(alpha: 0.15)
                      : Colors.grey.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  hasShops ? '샵 지도 ✓' : '샵 준비 중',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: hasShops ? const Color(0xFFD63F7A) : Colors.grey,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
