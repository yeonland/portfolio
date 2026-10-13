import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'design_detail_sheet.dart';
import 'favorites.dart';
import 'pinit_colors.dart';

// ---------------------------------------------------------------------------
// 📎 내가 직접 추가한 레퍼런스 (인스타 링크 · 캡처 사진)
// 보관함에 핀잇 디자인과 같은 Map으로 저장하고 'source': 'mine'으로 구분
//   id · link(출처 링크) · account(출처 계정) · shop(시술한 샵) · shopAccount(샵 인스타)
//   keyword · memo · photo(캡처 사진, base64 JPEG)
// ---------------------------------------------------------------------------
bool isMyReference(Map<String, String> item) => item['source'] == 'mine';

// instagram.com/계정명/... 에서 첫 칸이 계정명이 아닌 경우
const Set<String> _notAccounts = {'p', 'reel', 'reels', 'tv', 'stories', 'explore', 'share', 's'};

// 인스타 링크에서 계정명 뽑기 (게시물 링크는 계정명이 없을 수도 있어서 null)
String? instagramAccountFromLink(String link) {
  final uri = Uri.tryParse(link.trim());
  if (uri == null || !uri.host.endsWith('instagram.com')) return null;
  final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
  if (segments.isEmpty || _notAccounts.contains(segments.first)) return null;
  return segments.first;
}

// '@luna_nail ' → 'luna_nail' (비어 있으면 null)
String? cleanAccount(String? text) {
  final id = text?.trim().replaceFirst('@', '');
  return (id == null || id.isEmpty) ? null : id;
}

// 문의할 계정: 시술한 샵이 있으면 샵, 없으면 출처 계정
String? inquiryAccountOf(Map<String, String> item) => item['shopAccount'] ?? item['account'];

// 카드·상세에 보여줄 이름 (샵 이름 → @샵 → @출처)
String referenceShopLabel(Map<String, String> item) {
  if (item['shop'] != null) return item['shop']!;
  final account = inquiryAccountOf(item);
  return account != null ? '@$account' : '내 레퍼런스';
}

// 같은 사진을 화면마다 다시 디코딩하지 않도록 id별로 기억
final Map<String, Uint8List> _photoCache = {};

Uint8List? referencePhotoOf(Map<String, String> item) {
  final photo = item['photo'];
  if (photo == null) return null;
  return _photoCache.putIfAbsent(item['id'] ?? photo, () => base64Decode(photo));
}

// 보관함 카드·상세 공용 이미지 (캡처 사진 → 핀잇 디자인 사진 → 링크만 있는 카드)
Widget referenceImage(Map<String, String> item) {
  final photo = referencePhotoOf(item);
  if (photo != null) return Image.memory(photo, fit: BoxFit.cover);
  if (item['img'] != null) {
    return Image.network(
      item['img']!,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => imagePlaceholder(),
    );
  }
  return Container(
    color: instagramPink.withValues(alpha: 0.08),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.link, color: instagramPink, size: 32),
        const SizedBox(height: 6),
        Text(
          item['account'] != null ? '@${item['account']}' : '링크 레퍼런스',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: instagramPink),
        ),
      ],
    ),
  );
}

Future<void> _openLink(BuildContext context, Uri uri, String name) async {
  final messenger = ScaffoldMessenger.of(context);
  var opened = false;
  try {
    opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    opened = false;
  }
  if (!opened) {
    messenger.showSnackBar(SnackBar(content: Text('$name 링크를 열 수 없어요.')));
  }
}

// 내 레퍼런스 상세 바텀시트 - 원본 보기 · DM 문의 · 예약 문의 · 삭제
void showMyReferenceSheet(
  BuildContext context, {
  required Map<String, String> item,
  required FavoritesStore favorites,
  required ValueChanged<Map<String, String>> onReserve,
}) {
  final link = item['link'] != null ? Uri.tryParse(item['link']!) : null;
  final inquiryAccount = inquiryAccountOf(item);

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (sheetContext) {
      return SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: double.infinity,
                  height: referencePhotoOf(item) != null ? 280 : 140,
                  child: referenceImage(item),
                ),
              ),
              const SizedBox(height: 12),

              // 출처 - 사진 저작권은 원작자에게 있으니 원본으로 갈 수 있게
              Row(
                children: [
                  Expanded(
                    child: Text(
                      item['account'] != null ? '출처 @${item['account']}' : '출처 계정 없음',
                      style: const TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w600),
                    ),
                  ),
                  if (link != null)
                    TextButton.icon(
                      style: TextButton.styleFrom(foregroundColor: pinitAccentDark),
                      icon: const Icon(Icons.open_in_new, size: 16),
                      label: const Text('원본 보기'),
                      onPressed: () => _openLink(sheetContext, link, '원본'),
                    ),
                ],
              ),
              Text(
                item['keyword'] ?? '#내 레퍼런스',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: pinitAccentDark),
              ),
              if (item['memo'] != null) ...[
                const SizedBox(height: 4),
                Text(item['memo']!, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
              const SizedBox(height: 8),
              Text(
                '시술한 샵 · ${referenceShopLabel(item)}',
                style: const TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: instagramPink,
                          side: const BorderSide(color: instagramPink),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        icon: const Icon(Icons.send, size: 18),
                        label: const Text('DM 문의', style: TextStyle(fontWeight: FontWeight.bold)),
                        // ig.me/m/계정명 → 인스타 DM 창
                        onPressed: inquiryAccount == null
                            ? null
                            : () => _openLink(sheetContext, Uri.https('ig.me', '/m/$inquiryAccount'), '인스타 DM'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: pinitAccent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () {
                          Navigator.pop(sheetContext);
                          onReserve({
                            'shop': item['shop'] ?? (inquiryAccount != null ? '@$inquiryAccount' : ''),
                            'title': item['memo'] ?? item['keyword'] ?? '',
                          });
                        },
                        child: const Text(
                          '예약 문의하기',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              if (inquiryAccount == null)
                const Padding(
                  padding: EdgeInsets.only(top: 6),
                  child: Text(
                    '인스타 계정을 입력하면 DM으로 바로 문의할 수 있어요.',
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ),
              const SizedBox(height: 8),
              Center(
                child: TextButton.icon(
                  style: TextButton.styleFrom(foregroundColor: Colors.grey),
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text('보관함에서 삭제'),
                  onPressed: () {
                    Navigator.pop(sheetContext);
                    favorites.toggle(item);
                  },
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
