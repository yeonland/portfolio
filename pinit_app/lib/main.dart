import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
        scaffoldBackgroundColor: const Color(0xFFF9F9F9),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
          selectedItemColor: Colors.black,
          unselectedItemColor: Colors.grey,
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF121212),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E1E1E),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Color(0xFF1E1E1E),
          selectedItemColor: Colors.white,
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
  int _selectedIndex = 1; // '핀잇 픽' 탭 기본 선택
  Map<String, String>? _selectedDesign; // 핀잇 픽에서 고른 디자인 (예약 양식 자동 입력용)

  // 핀잇 픽에서 '예약 문의하기'를 누르면 예약 양식 탭으로 이동
  void _goToReservation(Map<String, String> design) {
    setState(() {
      _selectedDesign = design;
      _selectedIndex = 2;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      // 1. 지도 탭 (네이버/카톡/인스타 다중 채널)
      const MultiChannelMapExplorerScreen(),

      // 2. 핀잇 픽 (PinIt Pick) - 센스있는 디자인 피드 탭
      PinItPickScreen(onReserve: _goToReservation),

      // 3. 스마트 예약 주문서 탭 (디자인이 바뀌면 양식을 새로 채움)
      ReservationFormScreen(
        key: ValueKey(_selectedDesign?['title']),
        design: _selectedDesign,
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
                activeColor: Colors.white,
              ),
            ],
          ),
        ],
      ),
      body: pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.map),
            label: '지도 탐색',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.auto_awesome), // 반짝이는 픽 아이콘
            label: '핀잇 픽',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.edit_note),
            label: '예약 양식',
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 📍 지도 탐색 화면 (네이버 / 카톡 / 인스타 다중 예약)
// ---------------------------------------------------------------------------
class MultiChannelMapExplorerScreen extends StatefulWidget {
  const MultiChannelMapExplorerScreen({super.key});

  @override
  State<MultiChannelMapExplorerScreen> createState() => _MultiChannelMapExplorerScreenState();
}

class _MultiChannelMapExplorerScreenState extends State<MultiChannelMapExplorerScreen> {
  String _selectedCategory = '전체';

  final List<String> _categories = ['전체', '💅 네일', '🎂 케이크', '🎨 타투', '👁️ 속눈썹', '💐 꽃집'];

  final List<Map<String, dynamic>> _shops = [
    {
      'name': '루나네일 강남점',
      'category': '💅 네일',
      'rating': '4.9 (128)',
      'distance': '250m',
      'address': '서울 강남구 테헤란로 123',
      'price': '이달의아트 55,000원~',
      'hasNaver': true,
      'hasKakao': true,
      'hasInsta': true,
    },
    {
      'name': '달콤스튜디오 케이크',
      'category': '🎂 케이크',
      'rating': '4.8 (95)',
      'distance': '410m',
      'address': '서울 강남구 역삼로 45',
      'price': '레터링 케이크 38,000원~',
      'hasNaver': false,
      'hasKakao': true,
      'hasInsta': true,
    },
    {
      'name': '블룸아뜰리에 꽃집',
      'category': '💐 꽃집',
      'rating': '5.0 (64)',
      'distance': '600m',
      'address': '서울 강남구 강남대로 88',
      'price': '커스텀 꽃다발 35,000원~',
      'hasNaver': true,
      'hasKakao': true,
      'hasInsta': false,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final filteredShops = _selectedCategory == '전체'
        ? _shops
        : _shops.where((shop) => shop['category'] == _selectedCategory).toList();

    return Stack(
      children: [
        Container(
          width: double.infinity,
          height: double.infinity,
          color: const Color(0xFFE5E9EC),
          child: Stack(
            children: [
              const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.location_on, size: 70, color: Colors.black87),
                    SizedBox(height: 12),
                    Text(
                      '🗺️ PinIt 지도 탐색',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '네이버 · 카톡 · 인스타그램 원하는 채널로 자유롭게 예약',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 180,
                left: 110,
                child: _buildMapPin('💅 루나네일', true),
              ),
              Positioned(
                top: 260,
                right: 80,
                child: _buildMapPin('🎂 달콤케이크', false),
              ),
            ],
          ),
        ),
        Positioned(
          top: 12,
          left: 0,
          right: 0,
          child: SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final cat = _categories[index];
                final isSelected = _selectedCategory == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: FilterChip(
                    label: Text(
                      cat,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.black,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 12,
                      ),
                    ),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategory = cat;
                      });
                    },
                    selectedColor: Colors.black,
                    backgroundColor: Colors.white,
                    elevation: 3,
                    shadowColor: Colors.black26,
                    showCheckmark: false,
                  ),
                );
              },
            ),
          ),
        ),
        Positioned(
          bottom: 12,
          left: 12,
          right: 12,
          child: SizedBox(
            height: 165,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: filteredShops.length,
              itemBuilder: (context, index) {
                final shop = filteredShops[index];
                return Container(
                  width: 300,
                  margin: const EdgeInsets.only(right: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            shop['name']!,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.black12,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              shop['distance']!,
                              style: const TextStyle(
                                color: Colors.black87,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '⭐ ${shop['rating']} · ${shop['address']}',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      Text(
                        shop['price']!,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          if (shop['hasNaver'] == true)
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(right: 4.0),
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF03C75A),
                                    padding: EdgeInsets.zero,
                                    minimumSize: const Size(0, 36),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    elevation: 0,
                                  ),
                                  onPressed: () {
                                    _showToast(context, '${shop['name']} 네이버 예약으로 연결합니다.');
                                  },
                                  child: const Text(
                                    'N 네이버',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          if (shop['hasKakao'] == true)
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(right: 4.0),
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFFEE500),
                                    padding: EdgeInsets.zero,
                                    minimumSize: const Size(0, 36),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    elevation: 0,
                                  ),
                                  onPressed: () {
                                    _showToast(context, '${shop['name']} 카카오톡 오픈채팅으로 연결합니다.');
                                  },
                                  child: const Text(
                                    '💬 카톡문의',
                                    style: TextStyle(
                                      color: Colors.black87,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          if (shop['hasInsta'] == true)
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFE1306C),
                                  padding: EdgeInsets.zero,
                                  minimumSize: const Size(0, 36),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  elevation: 0,
                                ),
                                onPressed: () {
                                  _showToast(context, '${shop['name']} 인스타그램 DM으로 연결합니다.');
                                },
                                child: const Text(
                                  '📸 인스타',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  void _showToast(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildMapPin(String label, bool isSelected) {
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
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.black,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// ✨ 핀잇 픽 (PinIt Pick) - 검색 + 키워드 + 3열 피드 + 가격표 복원!
// ---------------------------------------------------------------------------
class PinItPickScreen extends StatefulWidget {
  final ValueChanged<Map<String, String>> onReserve;

  const PinItPickScreen({super.key, required this.onReserve});

  @override
  State<PinItPickScreen> createState() => _PinItPickScreenState();
}

class _PinItPickScreenState extends State<PinItPickScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedTag = '전체';

  final List<String> _trendingKeywords = [
    '전체',
    '#이달의아트',
    '#시럽네일',
    '#생일케이크',
    '#레터링',
    '#미니타투',
    '#속눈썹펌',
    '#꽃다발',
  ];

  final List<Map<String, String>> _allArtList = [
    {'shop': '루나네일', 'title': '시럽 마블 글리터 아트', 'price': '55,000원', 'keyword': '#시럽네일', 'tag': '#이달의아트', 'img': 'https://picsum.photos/300/300?random=1'},
    {'shop': '달콤케이크', 'title': '빈티지 레터링 커스텀', 'price': '38,000원', 'keyword': '#생일케이크', 'tag': '#레터링', 'img': 'https://picsum.photos/300/300?random=2'},
    {'shop': '잉크타투', 'title': '미니멀 라인 플라워', 'price': '80,000원', 'keyword': '#미니타투', 'tag': '#레터링', 'img': 'https://picsum.photos/300/300?random=3'},
    {'shop': '글램래쉬', 'title': '플랫모 뷰러 펌 세트', 'price': '45,000원', 'keyword': '#속눈썹펌', 'tag': '#이달의아트', 'img': 'https://picsum.photos/300/300?random=4'},
    {'shop': '블룸아뜰리에', 'title': '파스텔 튤립 꽃다발', 'price': '35,000원', 'keyword': '#꽃다발', 'tag': '#생일케이크', 'img': 'https://picsum.photos/300/300?random=5'},
    {'shop': '모모네일', 'title': '자개 영롱 인스타 아트', 'price': '60,000원', 'keyword': '#시럽네일', 'tag': '#이달의아트', 'img': 'https://picsum.photos/300/300?random=6'},
    {'shop': '베이크미', 'title': '캐릭터 입체 레터링 케이크', 'price': '42,000원', 'keyword': '#생일케이크', 'tag': '#레터링', 'img': 'https://picsum.photos/300/300?random=7'},
    {'shop': '네일디자인', 'title': '치크 시럽 블러셔 아트', 'price': '50,000원', 'keyword': '#시럽네일', 'tag': '#이달의아트', 'img': 'https://picsum.photos/300/300?random=8'},
    {'shop': '타투스튜디오', 'title': '감성 드로잉 미니타투', 'price': '70,000원', 'keyword': '#미니타투', 'tag': '#레터링', 'img': 'https://picsum.photos/300/300?random=9'},
  ];

  @override
  Widget build(BuildContext context) {
    final filteredList = _allArtList.where((item) {
      final matchesSearch = _searchQuery.isEmpty ||
          item['title']!.contains(_searchQuery) ||
          item['shop']!.contains(_searchQuery) ||
          item['keyword']!.contains(_searchQuery);

      final matchesTag = _selectedTag == '전체' ||
          item['keyword'] == _selectedTag ||
          item['tag'] == _selectedTag;

      return matchesSearch && matchesTag;
    }).toList();

    return Column(
      children: [
        // 1. 검색 바
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          child: Container(
            height: 42,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(10),
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
            itemCount: _trendingKeywords.length,
            itemBuilder: (context, index) {
              final keyword = _trendingKeywords[index];
              final isSelected = _selectedTag == keyword;

              return Padding(
                padding: const EdgeInsets.only(right: 6.0),
                child: ChoiceChip(
                  label: Text(
                    keyword,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 12,
                    ),
                  ),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _selectedTag = keyword;
                    });
                  },
                  selectedColor: Colors.black,
                  backgroundColor: Colors.grey[100],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  showCheckmark: false,
                ),
              );
            },
          ),
        ),

        const Divider(height: 1, thickness: 0.5),

        // 3. 3열 정사각형 피드 + 💰 가격표 완벽 복원!
        Expanded(
          child: filteredList.isEmpty
              ? const Center(
                  child: Text(
                    '검색 결과가 없습니다 😅',
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(2.0),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 2.0,
                    mainAxisSpacing: 2.0,
                    childAspectRatio: 1.0,
                  ),
                  itemCount: filteredList.length,
                  itemBuilder: (context, index) {
                    final item = filteredList[index];
                    return GestureDetector(
                      onTap: () => _showArtDetailDialog(context, item),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.network(
                            item['img']!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => _imagePlaceholder(),
                          ),
                          // 🏷️ 가격표 태그 복원 (좌측 하단)
                          Positioned(
                            bottom: 4,
                            left: 4,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.65),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                item['price']!,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // 팝업 상세 모달 (샵 이름, 가격, 예약 문의 버튼 복원)
  void _showArtDetailDialog(BuildContext context, Map<String, String> item) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                  const Icon(Icons.favorite_border, color: Colors.red),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                item['title']!,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                item['price']!,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Colors.black,
                ),
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
                    Navigator.pop(context);
                    widget.onReserve(item);
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
}

// 이미지를 불러오지 못했을 때 보여줄 회색 자리표시
Widget _imagePlaceholder() {
  return Container(
    color: Colors.grey[300],
    child: const Icon(Icons.image_not_supported_outlined, color: Colors.grey),
  );
}

// ---------------------------------------------------------------------------
// ✍️ 스마트 예약 주문서 - 양식을 채우면 예약 문의 메시지를 자동으로 만들어줌
// ---------------------------------------------------------------------------
class ReservationFormScreen extends StatefulWidget {
  final Map<String, String>? design; // 핀잇 픽에서 넘어온 디자인 (없으면 직접 입력)

  const ReservationFormScreen({super.key, this.design});

  @override
  State<ReservationFormScreen> createState() => _ReservationFormScreenState();
}

class _ReservationFormScreenState extends State<ReservationFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _shopController;
  late final TextEditingController _designController;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _memoController = TextEditingController();

  DateTime? _selectedDate;
  String? _selectedTime;
  String _selectedChannel = '💬 카톡';

  final List<String> _times = ['11:00', '13:00', '15:00', '17:00', '19:00'];
  final List<String> _channels = ['💬 카톡', '📸 인스타 DM', 'N 네이버'];

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
    buffer
      ..writeln('📅 희망 일시: ${_formatDate(_selectedDate!)} $_selectedTime')
      ..writeln('🙋 이름: ${_nameController.text}')
      ..writeln('📞 연락처: ${_phoneController.text}');
    if (_memoController.text.trim().isNotEmpty) {
      buffer.writeln('📝 요청사항: ${_memoController.text.trim()}');
    }
    buffer
      ..writeln()
      ..write('예약 가능 여부 확인 부탁드립니다!');
    return buffer.toString();
  }

  void _submit() {
    final isValid = _formKey.currentState!.validate();
    if (_selectedDate == null || _selectedTime == null) {
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
              Text(
                '✨ 주문서 완성! ($_selectedChannel)',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              const Text(
                '아래 메시지를 복사해서 샵에 바로 보내보세요.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
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
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: const Icon(Icons.copy, color: Colors.white, size: 18),
                  label: const Text(
                    '메시지 복사하기',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  onPressed: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    final navigator = Navigator.of(sheetContext);
                    await Clipboard.setData(ClipboardData(text: message));
                    navigator.pop();
                    messenger.showSnackBar(
                      SnackBar(content: Text('복사 완료! $_selectedChannel에 붙여넣기 해주세요.')),
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

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 핀잇 픽에서 넘어온 디자인 카드
          if (design != null) ...[
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2)),
                ],
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      design['img']!,
                      width: 64,
                      height: 64,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          SizedBox(width: 64, height: 64, child: _imagePlaceholder()),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${design['shop']} · ${design['keyword']}',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          design['title']!,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
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
            const SizedBox(height: 20),
          ] else ...[
            const Text(
              '💡 핀잇 픽에서 디자인을 고르면 자동으로 채워져요.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 12),
          ],

          _sectionTitle('샵 / 디자인'),
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

          _sectionTitle('희망 날짜'),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
              alignment: Alignment.centerLeft,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            icon: const Icon(Icons.calendar_today, size: 18),
            label: Text(_selectedDate == null ? '날짜 선택하기' : _formatDate(_selectedDate!)),
            onPressed: _pickDate,
          ),

          _sectionTitle('희망 시간'),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _times.map((time) => _buildChoiceChip(
                  label: time,
                  isSelected: _selectedTime == time,
                  onSelected: () => setState(() => _selectedTime = time),
                )).toList(),
          ),

          _sectionTitle('예약자 정보'),
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

          _sectionTitle('요청사항 (선택)'),
          TextFormField(
            controller: _memoController,
            decoration: _inputDecoration('예: 손톱이 짧아요 / 레터링 문구는 "생일 축하해"'),
            maxLines: 3,
          ),

          _sectionTitle('문의 채널'),
          Wrap(
            spacing: 6,
            children: _channels.map((channel) => _buildChoiceChip(
                  label: channel,
                  isSelected: _selectedChannel == channel,
                  onSelected: () => setState(() => _selectedChannel = channel),
                )).toList(),
          ),

          const SizedBox(height: 28),
          SizedBox(
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: _submit,
              child: const Text(
                '✨ 주문서 완성하기',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildChoiceChip({
    required String label,
    required bool isSelected,
    required VoidCallback onSelected,
  }) {
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : null,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      selectedColor: Colors.black,
      showCheckmark: false,
      onSelected: (_) => onSelected(),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
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
    );
  }
}