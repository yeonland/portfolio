import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'design_detail_sheet.dart';
import 'designs.dart';
import 'favorites.dart';
import 'home_screen.dart';
import 'map_explorer_screen.dart';
import 'pinit_colors.dart';
import 'reference_board_screen.dart';
import 'reservation.dart';
import 'reservation_timeline_screen.dart';

void main() {
  runApp(const PinItApp());
}

class PinItApp extends StatefulWidget {
  const PinItApp({super.key});

  @override
  State<PinItApp> createState() => _PinItAppState();
}

class _PinItAppState extends State<PinItApp> {
  bool _isDarkMode = false;

  void _toggleDarkMode(bool value) {
    setState(() {
      _isDarkMode = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PinIt',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        colorSchemeSeed: pinitAccent,
        scaffoldBackgroundColor: const Color(0xFFF9F9F9),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
          selectedItemColor: pinitAccentDark,
          unselectedItemColor: Colors.grey,
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        colorSchemeSeed: pinitAccent,
        scaffoldBackgroundColor: const Color(0xFF121212),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E1E1E),
          foregroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Color(0xFF1E1E1E),
          selectedItemColor: pinitAccent,
          unselectedItemColor: Colors.grey,
        ),
      ),
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: MainNavigationScreen(
        isDarkMode: _isDarkMode,
        onDarkModeChanged: _toggleDarkMode,
      ),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  final bool isDarkMode;
  final ValueChanged<bool> onDarkModeChanged;

  const MainNavigationScreen({
    super.key,
    required this.isDarkMode,
    required this.onDarkModeChanged,
  });

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  // 하단 탭 순서
  static const int _homeTab = 0;
  static const int _designTab = 1;
  static const int _boardTab = 3;
  static const int _timelineTab = 4;

  int _selectedIndex = _homeTab;
  String? _designCategory; // 홈에서 고른 카테고리 (null이면 전체 디자인)

  List<Reservation> _reservations = []; // 내 예약 타임라인
  final FavoritesStore _favorites = FavoritesStore(); // 찜한 디자인 (레퍼런스 보드)

  @override
  void initState() {
    super.initState();
    _loadReservations();
    _favorites.load();
  }

  @override
  void dispose() {
    _favorites.dispose();
    super.dispose();
  }

  Future<void> _loadReservations() async {
    final saved = await ReservationStorage.load();
    if (!mounted) return;
    setState(() {
      _reservations = saved;
    });
  }

  void _updateReservations(List<Reservation> reservations) {
    setState(() {
      _reservations = reservations;
    });
    ReservationStorage.save(reservations);
  }

  // '예약 문의하기'를 누르면 예약 양식 화면을 띄움 (design이 없으면 빈 양식)
  void _openReservationForm([Map<String, String>? design]) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (routeContext) => Scaffold(
          appBar: AppBar(
            title: Text(
              design?['shop'] == null ? '예약 양식 작성' : '${design!['shop']} 예약 양식',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          body: ReservationFormScreen(
            design: design,
            onSaved: _addReservation,
            onViewTimeline: () {
              Navigator.of(routeContext).popUntil((route) => route.isFirst);
              _goToTimeline();
            },
          ),
        ),
      ),
    );
  }

  // 홈에서 카테고리를 고르면 그 카테고리의 디자인 탭으로 이동
  void _openCategory(String category) {
    setState(() {
      _designCategory = category;
      _selectedIndex = _designTab;
    });
  }

  // 주문서를 완성하면 타임라인에 추가
  void _addReservation(Reservation reservation) {
    _updateReservations([..._reservations, reservation]);
  }

  void _goToTimeline() {
    setState(() {
      _selectedIndex = _timelineTab;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      // 1. 홈 - 무엇을 예약하시겠어요?
      HomeScreen(onCategorySelected: _openCategory),

      // 2. 디자인 (핀잇 픽) - 카테고리별 디자인 피드
      PinItPickScreen(
        key: ValueKey(_designCategory),
        category: _designCategory,
        onClearCategory: () => setState(() => _designCategory = null),
        favorites: _favorites,
        onReserve: _openReservationForm,
      ),

      // 3. 지도 탭 (네이버/카톡/인스타 다중 채널)
      MultiChannelMapExplorerScreen(onReserve: _openReservationForm),

      // 4. 보관함 (레퍼런스 보드)
      ReferenceBoardScreen(favorites: _favorites, onReserve: _openReservationForm),

      // 5. 내 예약 타임라인 (D-day + 진행 단계)
      ReservationTimelineScreen(
        reservations: _reservations,
        onStepChanged: (reservation, step) => _updateReservations([
          for (final r in _reservations) r.id == reservation.id ? r.copyWith(step: step) : r,
        ]),
        onDelete: (reservation) => _updateReservations(
          _reservations.where((r) => r.id != reservation.id).toList(),
        ),
        onBrowse: () => setState(() => _selectedIndex = _designTab),
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'PinIt',
          style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.5),
        ),
        actions: [
          Row(
            children: [
              Icon(
                widget.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                size: 20,
              ),
              Switch(
                value: widget.isDarkMode,
                onChanged: widget.onDarkModeChanged,
                activeThumbColor: Colors.white,
              ),
            ],
          ),
        ],
      ),
      body: pages[_selectedIndex],
      // 내 예약 탭: 디자인 없이 바로 예약 문의 쓰기 (보관함 탭의 레퍼런스 추가는 화면 상단 버튼)
      floatingActionButton: _selectedIndex == _timelineTab
          ? FloatingActionButton.extended(
              onPressed: _openReservationForm,
              backgroundColor: pinitAccent,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.edit_note),
              label: const Text('예약 문의 쓰기', style: TextStyle(fontWeight: FontWeight.bold)),
            )
          : null,
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed, // 탭 4개 이상이면 고정형으로
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: '홈',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.auto_awesome), // 반짝이는 픽 아이콘
            label: '디자인',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.map_outlined),
            activeIcon: Icon(Icons.map),
            label: '지도',
          ),
          // 보관함: 저장한 디자인 개수 배지
          BottomNavigationBarItem(
            icon: ListenableBuilder(
              listenable: _favorites,
              builder: (context, _) => Badge(
                isLabelVisible: _favorites.count > 0,
                label: Text('${_favorites.count}'),
                child: Icon(_selectedIndex == _boardTab ? Icons.bookmark : Icons.bookmark_border),
              ),
            ),
            label: '보관함',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.event_note),
            label: '내 예약',
          ),
        ],
      ),
    );
  }
}


// ---------------------------------------------------------------------------
// ✨ 핀잇 픽 (PinIt Pick) - 검색 + 키워드 + 가격대 + 2열 디자인 카드
// ---------------------------------------------------------------------------
class PinItPickScreen extends StatefulWidget {
  final String? category; // 홈에서 고른 카테고리 (null이면 전체)
  final VoidCallback? onClearCategory;
  final FavoritesStore favorites;
  final ValueChanged<Map<String, String>> onReserve;

  const PinItPickScreen({
    super.key,
    this.category,
    this.onClearCategory,
    required this.favorites,
    required this.onReserve,
  });

  @override
  State<PinItPickScreen> createState() => _PinItPickScreenState();
}

class _PinItPickScreenState extends State<PinItPickScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedTag = '전체';
  String _priceRange = _priceAll;

  final List<String> _trendingKeywords = [
    '전체',
    '#이달의아트',
    '#시럽네일',
    '#생일케이크',
    '#레터링',
    '#미니타투',
    '#속눈썹펌',
    '#꽃다발',
    '#촬영메이크업',
  ];

  // 가격대: 이름 → (최소, 최대) 원
  static const String _priceAll = '가격 전체';
  static const Map<String, (int, int)> _priceRanges = {
    _priceAll: (0, 1 << 31),
    '3~4만원대': (30000, 49999),
    '5~6만원대': (50000, 69999),
    '7만원 이상': (70000, 1 << 31),
  };

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // 홈에서 카테고리를 골랐으면 그 카테고리 디자인만
  List<Map<String, String>> get _categoryDesigns => widget.category == null
      ? pinitDesigns
      : pinitDesigns.where((design) => design['category'] == widget.category).toList();

  @override
  Widget build(BuildContext context) {
    final designs = _categoryDesigns;
    // 지금 카테고리에 있는 키워드만 칩으로 표시
    final keywords = [
      for (final keyword in _trendingKeywords)
        if (keyword == '전체' || designs.any((item) => item['keyword'] == keyword || item['tag'] == keyword))
          keyword,
    ];
    final selectedTag = keywords.contains(_selectedTag) ? _selectedTag : '전체';
    final (minPrice, maxPrice) = _priceRanges[_priceRange]!;

    final filteredList = designs.where((item) {
      final matchesSearch = _searchQuery.isEmpty ||
          item['title']!.contains(_searchQuery) ||
          item['shop']!.contains(_searchQuery) ||
          item['keyword']!.contains(_searchQuery);

      final matchesTag = selectedTag == '전체' ||
          item['keyword'] == selectedTag ||
          item['tag'] == selectedTag;

      final price = priceValue(item['price']);
      final matchesPrice = price >= minPrice && price <= maxPrice;

      return matchesSearch && matchesTag && matchesPrice;
    }).toList();

    return Column(
      children: [
        // 0. 홈에서 고른 카테고리 (전체 보기로 해제)
        if (widget.category != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 8, 0),
            child: Row(
              children: [
                Text(
                  '${widget.category} 디자인',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
                const Spacer(),
                TextButton(
                  onPressed: widget.onClearCategory,
                  child: const Text('전체 보기'),
                ),
              ],
            ),
          ),

        // 1. 검색 바
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          child: Container(
            height: 42,
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: '디자인, 키워드, 샵 이름 검색 (예: #시럽네일)',
                hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
                prefixIcon: const Icon(Icons.search, size: 20, color: Colors.grey),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18, color: Colors.grey),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
        ),

        // 2. 키워드 해시태그 칩
        SizedBox(
          height: 46,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            itemCount: keywords.length,
            itemBuilder: (context, index) {
              final keyword = keywords[index];
              return Padding(
                padding: const EdgeInsets.only(right: 6.0),
                child: pinitChip(
                  label: keyword,
                  isSelected: selectedTag == keyword,
                  onSelected: () => setState(() => _selectedTag = keyword),
                ),
              );
            },
          ),
        ),

        // 3. 결과 개수 + 가격대 선택
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 4, 0),
          child: Row(
            children: [
              Text(
                '디자인 ${filteredList.length}개',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const Spacer(),
              PopupMenuButton<String>(
                tooltip: '가격대',
                initialValue: _priceRange,
                onSelected: (range) => setState(() => _priceRange = range),
                itemBuilder: (context) => [
                  for (final range in _priceRanges.keys) PopupMenuItem(value: range, child: Text(range)),
                ],
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      Text(
                        _priceRange,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: _priceRange == _priceAll ? null : pinitAccentDark,
                        ),
                      ),
                      const Icon(Icons.expand_more, size: 18),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // 4. 2열 디자인 카드 (사진 · 샵 · 가격 · 양식 쓰기)
        Expanded(
          child: filteredList.isEmpty
              ? Center(
                  child: Text(
                    designs.isEmpty ? '아직 등록된 디자인이 없어요 🙏' : '조건에 맞는 디자인이 없어요',
                    style: const TextStyle(color: Colors.grey),
                  ),
                )
              : ListenableBuilder(
                  listenable: widget.favorites,
                  builder: (context, _) => GridView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 240,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.62,
                    ),
                    itemCount: filteredList.length,
                    itemBuilder: (context, index) => _buildDesignCard(filteredList[index]),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildDesignCard(Map<String, String> item) {
    return Material(
      color: Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => showDesignDetailSheet(
          context,
          item: item,
          favorites: widget.favorites,
          onReserve: widget.onReserve,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    item['img']!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => imagePlaceholder(),
                  ),
                  // 🔖 보관한 디자인 표시 (우측 상단)
                  if (widget.favorites.isFavorite(item))
                    const Positioned(
                      top: 6,
                      right: 6,
                      child: Icon(
                        Icons.bookmark,
                        color: pinitAccent,
                        size: 22,
                        shadows: [Shadow(color: Colors.black45, blurRadius: 3)],
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['shop']!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                  Text(
                    item['title']!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item['price']!,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
            // 보관함 저장 · 양식 쓰기
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
              child: SizedBox(
                height: 32,
                child: Row(
                  children: [
                    Expanded(child: _buildSaveButton(item)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: pinitAccentDark,
                          side: const BorderSide(color: pinitAccent),
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        icon: const Icon(Icons.edit_note, size: 16),
                        label: const Text('양식 쓰기', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        onPressed: () => widget.onReserve(item),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 보관함 저장 버튼 (저장되면 채워진 코랄 버튼으로 바뀜)
  Widget _buildSaveButton(Map<String, String> item) {
    final isSaved = widget.favorites.isFavorite(item);
    return FilledButton.icon(
      style: FilledButton.styleFrom(
        backgroundColor: isSaved ? pinitAccent : pinitAccent.withValues(alpha: 0.12),
        foregroundColor: isSaved ? Colors.white : pinitAccentDark,
        padding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      icon: Icon(isSaved ? Icons.bookmark : Icons.bookmark_border, size: 16),
      label: Text(isSaved ? '저장됨' : '저장', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
      onPressed: () {
        widget.favorites.toggle(item);
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(
            duration: const Duration(seconds: 2),
            content: Text(isSaved ? '보관함에서 뺐어요.' : '보관함에 저장했어요. 하단 「보관함」 탭에서 볼 수 있어요.'),
          ));
      },
    );
  }
}

// 선택형 칩 (선택되면 연한 코랄 배경 + 진한 코랄 글씨)
Widget pinitChip({
  required String label,
  required bool isSelected,
  required VoidCallback onSelected,
}) {
  return ChoiceChip(
    label: Text(
      label,
      style: TextStyle(
        color: isSelected ? pinitAccentDark : null,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 12,
      ),
    ),
    selected: isSelected,
    onSelected: (_) => onSelected(),
    selectedColor: pinitAccent.withValues(alpha: 0.14),
    side: BorderSide(color: isSelected ? pinitAccent : Colors.grey.withValues(alpha: 0.3)),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    showCheckmark: false,
  );
}

// ---------------------------------------------------------------------------
// ✍️ 예약 양식 - 단계별로 채우면 샵에 보낼 예약 문의 메시지를 만들어줌
// ---------------------------------------------------------------------------
class ReservationFormScreen extends StatefulWidget {
  // 디자인 탭에서 오면 디자인 전체, 지도에서 오면 shop·category만 (없으면 빈 양식)
  final Map<String, String>? design;
  final ValueChanged<Reservation> onSaved; // 메시지 복사 시 타임라인에 저장
  final VoidCallback onViewTimeline;

  const ReservationFormScreen({
    super.key,
    this.design,
    required this.onSaved,
    required this.onViewTimeline,
  });

  @override
  State<ReservationFormScreen> createState() => _ReservationFormScreenState();
}

// 문의 채널: 저장용 이름 · 버튼 문구 · 아이콘 글자 · 색
class _Channel {
  final String name;
  final String label;
  final String mark;
  final Color color;
  final Color markColor;

  const _Channel(this.name, this.label, this.mark, this.color, this.markColor);
}

class _ReservationFormScreenState extends State<ReservationFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _shopController;
  late final TextEditingController _designController;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _memoController = TextEditingController();
  final TextEditingController _customTimeController = TextEditingController();

  DateTime? _selectedDate;
  String? _selectedTime;
  bool _isCustomTime = false; // '직접 입력'을 고르면 칸에 자유롭게 입력

  // 네일 옵션
  String? _removal; // 기존 젤 제거
  bool _extension = false; // 연장

  static const List<String> _removalOptions = ['없음', '자사 제거', '타사 제거'];

  static const List<_Channel> _channels = [
    _Channel('💬 카톡', '카카오톡으로 보내기', 'TALK', kakaoYellow, Colors.black87),
    _Channel('📸 인스타 DM', '인스타 DM으로 보내기', 'IG', instagramPink, Colors.white),
    _Channel('N 네이버', '네이버 예약으로 보내기', 'N', naverGreen, Colors.white),
  ];

  // 오전 9:00 ~ 오후 9:00, 30분 간격
  static final List<String> _times = [
    for (var minutes = 9 * 60; minutes <= 21 * 60; minutes += 30)
      '${minutes ~/ 60}:${(minutes % 60).toString().padLeft(2, '0')}',
  ];
  List<String> get _morningTimes => _times.where((time) => int.parse(time.split(':').first) < 12).toList();
  List<String> get _afternoonTimes => _times.where((time) => int.parse(time.split(':').first) >= 12).toList();

  // 메시지·예약에 들어갈 희망 시간 (직접 입력이면 입력한 글자 그대로)
  String? get _timeText {
    if (!_isCustomTime) return _selectedTime;
    final text = _customTimeController.text.trim();
    return text.isEmpty ? null : text;
  }

  // 사진이 있는 디자인에서 왔는지 (지도에서 오면 샵 이름만 있음)
  bool get _hasDesignPhoto => widget.design?['img'] != null;
  bool get _isNail => widget.design?['category'] == '💅 네일';

  @override
  void initState() {
    super.initState();
    _shopController = TextEditingController(text: widget.design?['shop'] ?? '');
    _designController = TextEditingController(text: widget.design?['title'] ?? '');
  }

  @override
  void dispose() {
    _shopController.dispose();
    _designController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _memoController.dispose();
    _customTimeController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    const weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    return '${date.month}월 ${date.day}일 (${weekdays[date.weekday - 1]})';
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 90)),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  // 샵에 그대로 보낼 수 있는 예약 문의 메시지
  String _buildMessage() {
    final buffer = StringBuffer()
      ..writeln('안녕하세요, ${_shopController.text}님! PinIt 보고 예약 문의드려요 😊')
      ..writeln()
      ..writeln('📌 디자인: ${_designController.text}');
    if (widget.design?['price'] != null) {
      buffer.writeln('💰 가격: ${widget.design!['price']}');
    }
    buffer.writeln('📅 희망 일시: ${_formatDate(_selectedDate!)} $_timeText');
    if (_removal != null) buffer.writeln('🧴 제거: $_removal');
    if (_extension) buffer.writeln('💅 연장: 필요해요');
    buffer
      ..writeln('🙋 이름: ${_nameController.text}')
      ..writeln('📞 연락처: ${_phoneController.text}');
    if (_memoController.text.trim().isNotEmpty) {
      buffer.writeln('📝 요청사항: ${_memoController.text.trim()}');
    }
    if (_hasDesignPhoto) {
      buffer.writeln('🖼️ 레퍼런스 사진은 이어서 보내드릴게요!');
    }
    buffer
      ..writeln()
      ..write('예약 가능 여부 확인 부탁드립니다!');
    return buffer.toString();
  }

  Reservation _buildReservation(_Channel channel) {
    return Reservation(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      shop: _shopController.text.trim(),
      design: _designController.text.trim(),
      price: widget.design?['price'],
      img: widget.design?['img'],
      date: _selectedDate!,
      time: _timeText!,
      channel: channel.name,
    );
  }

  void _submit(_Channel channel) {
    final isValid = _formKey.currentState!.validate();
    if (_selectedDate == null || _timeText == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('희망 날짜와 시간을 선택해주세요.')),
      );
      return;
    }
    if (!isValid) return;

    final message = _buildMessage();
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
              const Text(
                '예약 문의 메시지가 완성됐어요',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                '복사해서 ${channel.name}에 붙여넣어 보내세요.',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: SelectableText(
                  message,
                  style: const TextStyle(fontSize: 13, height: 1.6),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: pinitAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.copy, size: 18),
                  label: const Text('메시지 복사하기', style: TextStyle(fontWeight: FontWeight.bold)),
                  onPressed: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    final navigator = Navigator.of(sheetContext);
                    // 복사가 실패해도 예약은 타임라인에 남도록 먼저 저장
                    widget.onSaved(_buildReservation(channel));
                    var copied = true;
                    try {
                      await Clipboard.setData(ClipboardData(text: message));
                    } catch (_) {
                      copied = false;
                    }
                    navigator.pop();
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(copied
                            ? '복사 완료! ${channel.name}에 붙여넣고, 내 예약에서 일정을 확인하세요.'
                            : '복사에 실패했어요. 메시지를 길게 눌러 직접 복사해주세요.'),
                        action: SnackBarAction(label: '내 예약', onPressed: widget.onViewTimeline),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final design = widget.design;
    var step = 0; // 섹션 번호 (네일 옵션이 없으면 번호가 당겨짐)
    String numbered(String title) => '${++step}. $title';

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          _sectionTitle(numbered('샵 · 디자인')),
          TextFormField(
            controller: _shopController,
            decoration: _inputDecoration('샵 이름'),
            validator: (value) => (value == null || value.trim().isEmpty) ? '샵 이름을 입력해주세요.' : null,
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _designController,
            decoration: _inputDecoration('원하는 디자인'),
            validator: (value) => (value == null || value.trim().isEmpty) ? '디자인을 입력해주세요.' : null,
          ),
          if (design == null)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                '💡 디자인 탭에서 고른 디자인으로 문의하면 자동으로 채워져요.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),

          _sectionTitle(numbered('방문 희망 날짜 & 시간')),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
              alignment: Alignment.centerLeft,
              foregroundColor: _selectedDate == null ? null : pinitAccentDark,
              side: BorderSide(color: _selectedDate == null ? Colors.grey.withValues(alpha: 0.4) : pinitAccent),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            icon: const Icon(Icons.calendar_today, size: 18),
            label: Text(_selectedDate == null ? '날짜 선택하기' : _formatDate(_selectedDate!)),
            onPressed: _pickDate,
          ),
          const SizedBox(height: 12),
          _buildTimeGroup('오전', _morningTimes),
          const SizedBox(height: 10),
          _buildTimeGroup('오후', _afternoonTimes),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.only(left: 36), // 시간 칩과 왼쪽 줄 맞추기
            child: Align(
              alignment: Alignment.centerLeft,
              child: pinitChip(
                label: '✏️ 직접 입력',
                isSelected: _isCustomTime,
                onSelected: () => setState(() {
                  _isCustomTime = true;
                  _selectedTime = null;
                }),
              ),
            ),
          ),
          if (_isCustomTime) ...[
            const SizedBox(height: 8),
            TextField(
              controller: _customTimeController,
              autofocus: true,
              decoration: _inputDecoration('예: 오후 2시 이후 아무 때나 / 퇴근 후 7시 반'),
            ),
          ],

          // 네일일 때만: 제거 · 연장 옵션
          if (_isNail) ...[
            _sectionTitle(numbered('옵션 선택')),
            _buildOptionRow('제거', [
              for (final option in _removalOptions)
                pinitChip(
                  label: option,
                  isSelected: _removal == option,
                  onSelected: () => setState(() => _removal = _removal == option ? null : option),
                ),
            ]),
            const SizedBox(height: 6),
            _buildOptionRow('연장', [
              pinitChip(
                label: '연장 필요해요',
                isSelected: _extension,
                onSelected: () => setState(() => _extension = !_extension),
              ),
            ]),
          ],

          _sectionTitle(numbered('레퍼런스 & 요청사항')),
          if (_hasDesignPhoto) ...[
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      design!['img']!,
                      width: 72,
                      height: 72,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          SizedBox(width: 72, height: 72, child: imagePlaceholder()),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('레퍼런스 사진', style: TextStyle(fontSize: 11, color: Colors.grey)),
                        const SizedBox(height: 2),
                        Text(
                          design['title'] ?? '',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                        if (design['price'] != null)
                          Text(
                            design['price']!,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
          TextFormField(
            controller: _memoController,
            decoration: _inputDecoration('예: 약지만 파츠를 분홍색으로 바꾸고 싶어요 / 손톱이 짧아요'),
            maxLines: 3,
          ),

          _sectionTitle(numbered('예약자 정보')),
          TextFormField(
            controller: _nameController,
            decoration: _inputDecoration('이름'),
            validator: (value) => (value == null || value.trim().isEmpty) ? '이름을 입력해주세요.' : null,
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _phoneController,
            decoration: _inputDecoration('연락처 (예: 010-1234-5678)'),
            keyboardType: TextInputType.phone,
            validator: (value) {
              final digits = (value ?? '').replaceAll(RegExp(r'[^0-9]'), '');
              return digits.length < 10 ? '연락처를 정확히 입력해주세요.' : null;
            },
          ),

          _sectionTitle(numbered('예약 문의 보내기')),
          for (final channel in _channels) ...[
            _buildChannelButton(channel),
            const SizedBox(height: 8),
          ],
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // 옵션 한 줄: 왼쪽 이름표 + 오른쪽 칩
  Widget _buildOptionRow(String label, List<Widget> chips) {
    return Row(
      children: [
        SizedBox(
          width: 48,
          child: Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
        ),
        Expanded(child: Wrap(spacing: 6, runSpacing: 6, children: chips)),
      ],
    );
  }

  // 채널 버튼: 왼쪽 브랜드 색 아이콘 + 문구 + 화살표
  Widget _buildChannelButton(_Channel channel) {
    return Material(
      color: Colors.grey.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _submit(channel),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: channel.color, borderRadius: BorderRadius.circular(9)),
                child: Text(
                  channel.mark,
                  style: TextStyle(
                    color: channel.markColor,
                    fontSize: channel.mark.length > 2 ? 9 : 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  channel.label,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  // 오전/오후 묶음: 왼쪽에 이름표, 오른쪽에 30분 간격 시간 칩
  Widget _buildTimeGroup(String label, List<String> times) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 36,
          child: Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ),
        ),
        Expanded(
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            children: times.map((time) => pinitChip(
                  label: time,
                  isSelected: !_isCustomTime && _selectedTime == time,
                  onSelected: () => setState(() {
                    _selectedTime = time;
                    _isCustomTime = false;
                  }),
                )).toList(),
          ),
        ),
      ],
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 10),
      child: Text(
        title,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: pinitAccent, width: 1.5),
      ),
    );
  }
}
