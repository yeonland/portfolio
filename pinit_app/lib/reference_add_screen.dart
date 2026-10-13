import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';

import 'favorites.dart';
import 'my_reference.dart';
import 'pinit_colors.dart';

// 보관함 탭의 '+ 레퍼런스 추가'에서 여는 화면
void openReferenceAddScreen(BuildContext context, FavoritesStore favorites) {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => Scaffold(
        appBar: AppBar(
          title: const Text('레퍼런스 추가', style: TextStyle(fontWeight: FontWeight.w800)),
        ),
        body: ReferenceAddScreen(favorites: favorites),
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// 📎 레퍼런스 추가 - 인스타 링크 · 캡처 사진 · 출처 · 시술한 샵 · 키워드 · 메모
// 사진은 이 기기에만 저장 (나만 보는 보관함)
// ---------------------------------------------------------------------------
class ReferenceAddScreen extends StatefulWidget {
  final FavoritesStore favorites;

  const ReferenceAddScreen({super.key, required this.favorites});

  @override
  State<ReferenceAddScreen> createState() => _ReferenceAddScreenState();
}

class _ReferenceAddScreenState extends State<ReferenceAddScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _linkController = TextEditingController();
  final TextEditingController _accountController = TextEditingController();
  final TextEditingController _shopController = TextEditingController();
  final TextEditingController _shopAccountController = TextEditingController();
  final TextEditingController _keywordController = TextEditingController();
  final TextEditingController _memoController = TextEditingController();

  Uint8List? _photo; // 줄여서 JPEG로 바꾼 캡처 사진
  bool _isProcessingPhoto = false;
  bool _isSaving = false;

  // 보관함에 이미 있는 키워드 (빠르게 고르기용)
  late final List<String> _keywordSuggestions = {
    for (final item in widget.favorites.items)
      if (item['keyword'] != null) item['keyword']!,
  }.take(8).toList();

  @override
  void dispose() {
    _linkController.dispose();
    _accountController.dispose();
    _shopController.dispose();
    _shopAccountController.dispose();
    _keywordController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  // 링크를 붙여넣으면 출처 계정 자동 입력 (계정 칸이 비어 있을 때만)
  void _onLinkChanged(String link) {
    final account = instagramAccountFromLink(link);
    if (account != null && _accountController.text.trim().isEmpty) {
      _accountController.text = '@$account';
    }
  }

  Future<void> _pickPhoto() async {
    final messenger = ScaffoldMessenger.of(context);
    final file = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1440);
    if (file == null) return;

    setState(() => _isProcessingPhoto = true);
    final bytes = await file.readAsBytes();
    final photo = _shrinkPhoto(bytes);
    if (!mounted) return;
    setState(() {
      _isProcessingPhoto = false;
      _photo = photo ?? _photo;
    });
    if (photo == null) {
      messenger.showSnackBar(const SnackBar(content: Text('이 사진은 불러올 수 없어요. 다른 사진을 골라주세요.')));
    }
  }

  // 기기(브라우저) 저장 공간이 작아서 가로 720px JPEG로 줄여서 저장 (보통 100KB 안팎)
  Uint8List? _shrinkPhoto(Uint8List bytes) {
    final decoded = img.decodeImage(bytes);
    if (decoded == null) return null;
    final resized = decoded.width > 720 ? img.copyResize(decoded, width: 720) : decoded;
    return img.encodeJpg(resized, quality: 75);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final link = _linkController.text.trim();
    if (link.isEmpty && _photo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('링크나 사진 중 하나는 넣어주세요.')),
      );
      return;
    }

    var keyword = _keywordController.text.trim().replaceAll(' ', '');
    if (keyword.isNotEmpty && !keyword.startsWith('#')) keyword = '#$keyword';

    String? textOrNull(TextEditingController controller) {
      final text = controller.text.trim();
      return text.isEmpty ? null : text;
    }

    final item = <String, String>{
      'id': 'mine_${DateTime.now().microsecondsSinceEpoch}',
      'source': 'mine',
      'keyword': keyword.isEmpty ? '#내 레퍼런스' : keyword,
      if (link.isNotEmpty) 'link': link,
      'account': ?cleanAccount(_accountController.text),
      'shop': ?textOrNull(_shopController),
      'shopAccount': ?cleanAccount(_shopAccountController.text),
      'memo': ?textOrNull(_memoController),
      if (_photo != null) 'photo': base64Encode(_photo!),
    };

    setState(() => _isSaving = true);
    final saved = await widget.favorites.add(item);
    if (!mounted) return;
    setState(() => _isSaving = false);

    final messenger = ScaffoldMessenger.of(context);
    if (saved) {
      Navigator.of(context).pop();
      messenger.showSnackBar(SnackBar(content: Text('${item['keyword']}에 저장했어요.')));
    } else {
      messenger.showSnackBar(
        const SnackBar(content: Text('기기 저장 공간이 부족해요. 사진이 있는 레퍼런스를 몇 개 지운 뒤 다시 저장해주세요.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          _sectionTitle('캡처 사진'),
          _buildPhotoPicker(),
          const SizedBox(height: 4),
          const Text(
            '나만 보는 보관함에만 저장돼요. 다른 사람에게 공개되지 않아요.',
            style: TextStyle(fontSize: 11, color: Colors.grey),
          ),

          _sectionTitle('출처'),
          TextFormField(
            controller: _linkController,
            keyboardType: TextInputType.url,
            decoration: _decoration('게시물 링크', 'https://www.instagram.com/p/...'),
            onChanged: _onLinkChanged,
            validator: (value) {
              final text = value?.trim() ?? '';
              if (text.isEmpty) return null;
              final uri = Uri.tryParse(text);
              final isWebLink = uri != null && (uri.scheme == 'http' || uri.scheme == 'https') && uri.host.isNotEmpty;
              return isWebLink ? null : 'https://로 시작하는 링크를 넣어주세요.';
            },
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _accountController,
            decoration: _decoration('출처 계정', '@게시한 사람 계정'),
          ),

          _sectionTitle('시술한 샵 (선택)'),
          const Text(
            '손님 후기 게시물이면 시술한 샵을 적어주세요. 비워두면 출처 계정으로 문의해요.',
            style: TextStyle(fontSize: 11, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _shopController,
            decoration: _decoration('샵 이름', '예: 루나네일'),
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _shopAccountController,
            decoration: _decoration('샵 인스타 계정', '@샵 계정'),
          ),

          _sectionTitle('키워드 · 메모'),
          TextFormField(
            controller: _keywordController,
            decoration: _decoration('키워드', '#시럽네일'),
          ),
          if (_keywordSuggestions.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final keyword in _keywordSuggestions)
                  ActionChip(
                    label: Text(keyword, style: const TextStyle(fontSize: 12)),
                    onPressed: () => setState(() => _keywordController.text = keyword),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 10),
          TextFormField(
            controller: _memoController,
            maxLines: 2,
            decoration: _decoration('메모', '예: 이 색감 그대로, 길이는 짧게'),
          ),
          const SizedBox(height: 24),

          SizedBox(
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: pinitAccent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: _isSaving || _isProcessingPhoto ? null : _save,
              child: const Text(
                '보관함에 저장',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoPicker() {
    if (_isProcessingPhoto) {
      return const SizedBox(height: 160, child: Center(child: CircularProgressIndicator()));
    }
    if (_photo != null) {
      return Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.memory(_photo!, height: 220, width: double.infinity, fit: BoxFit.cover),
          ),
          Positioned(
            top: 6,
            right: 6,
            child: IconButton(
              tooltip: '사진 빼기',
              style: IconButton.styleFrom(backgroundColor: Colors.white.withValues(alpha: 0.85)),
              icon: const Icon(Icons.close, size: 18),
              onPressed: () => setState(() => _photo = null),
            ),
          ),
        ],
      );
    }
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: _pickPhoto,
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.35)),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_photo_alternate_outlined, color: pinitAccent, size: 32),
            SizedBox(height: 6),
            Text('갤러리에서 사진 고르기', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 8),
      child: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
    );
  }

  InputDecoration _decoration(String label, String hint) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      isDense: true,
    );
  }
}
