import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/word_provider.dart';
import '../widgets/word_card.dart';
import '../widgets/add_word_dialog.dart';
import '../models/word.dart';
import 'search_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentTab = 0; // 0 = My words, 1 = Search
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WordProvider>().loadWords();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F3F7),
      body: PageView(
        controller: _pageController,
        onPageChanged: (i) => setState(() => _currentTab = i),
        children: const [
          _MyWordsTab(),
          SearchScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentTab,
        onDestinationSelected: (i) {
          setState(() => _currentTab = i);
          _pageController.animateToPage(i, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
        },
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFF1A1A2E).withOpacity(0.1),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.book_outlined), selectedIcon: Icon(Icons.book), label: "Lug'atim"),
          NavigationDestination(icon: Icon(Icons.search), selectedIcon: Icon(Icons.search), label: "Qidiruv"),
        ],
      ),
    );
  }
}

class _MyWordsTab extends StatefulWidget {
  const _MyWordsTab({Key? key}) : super(key: key);

  @override
  State<_MyWordsTab> createState() => _MyWordsTabState();
}

class _MyWordsTabState extends State<_MyWordsTab> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  bool _showSearch = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);
  }

  void _onTabChanged() {
    final provider = context.read<WordProvider>();
    switch (_tabController.index) {
      case 0: provider.setFilter(FilterType.all); break;
      case 1: provider.setFilter(FilterType.unlearned); break;
      case 2: provider.setFilter(FilterType.learned); break;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _showAddDialog([Word? editWord]) {
    showDialog(context: context, builder: (_) => AddWordDialog(editWord: editWord));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F3F7),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Consumer<WordProvider>(builder: (ctx, p, _) => _buildStatsBar(p)),
            _buildTabBar(),
            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              child: _showSearch ? _buildSearchBar() : const SizedBox.shrink(),
            ),
            Expanded(
              child: Consumer<WordProvider>(
                builder: (ctx, provider, _) {
                  if (provider.isLoading) return const Center(child: CircularProgressIndicator(color: Color(0xFF1A1A2E)));
                  if (provider.words.isEmpty) return _buildEmptyState(provider);
                  return ListView.builder(
                    padding: const EdgeInsets.only(top: 8, bottom: 100),
                    itemCount: provider.words.length,
                    itemBuilder: (ctx, i) => WordCard(
                      word: provider.words[i],
                      onTap: () => _showAddDialog(provider.words[i]),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddDialog(),
        backgroundColor: const Color(0xFF1A1A2E),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text("Yangi so'z", style: TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 16, 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: const Color(0xFF1A1A2E), borderRadius: BorderRadius.circular(14)),
            child: const Text("📚", style: TextStyle(fontSize: 22)),
          ),
          const SizedBox(width: 12),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Lug'atim", style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF1A1A2E))),
              Text("O'zbek • English", style: TextStyle(fontSize: 12, color: Color(0xFF888888), fontWeight: FontWeight.w500)),
            ],
          ),
          const Spacer(),
          IconButton(
            onPressed: () {
              setState(() => _showSearch = !_showSearch);
              if (!_showSearch) {
                _searchController.clear();
                context.read<WordProvider>().setSearch('');
              }
            },
            icon: Icon(_showSearch ? Icons.search_off : Icons.search, color: const Color(0xFF1A1A2E)),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsBar(WordProvider p) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _statItem("Jami", p.totalCount, const Color(0xFF1A1A2E)),
          _divider(),
          _statItem("Yodlanmadi", p.unlearnedCount, const Color(0xFFE53935)),
          _divider(),
          _statItem("Yodlandi", p.learnedCount, const Color(0xFF43A047)),
        ],
      ),
    );
  }

  Widget _statItem(String label, int count, Color color) => Column(children: [
    Text(count.toString(), style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: color)),
    Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF888888), fontWeight: FontWeight.w500)),
  ]);

  Widget _divider() => Container(width: 1, height: 36, color: const Color(0xFFEEEEEE));

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
      child: TabBar(
        controller: _tabController,
        labelColor: Colors.white,
        unselectedLabelColor: const Color(0xFF888888),
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        unselectedLabelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        indicator: BoxDecoration(color: const Color(0xFF1A1A2E), borderRadius: BorderRadius.circular(12)),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        padding: const EdgeInsets.all(4),
        tabs: const [Tab(text: "Barchasi"), Tab(text: "Yodlanmadi"), Tab(text: "Yodlandi")],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: TextField(
        controller: _searchController,
        autofocus: true,
        onChanged: (v) => context.read<WordProvider>().setSearch(v),
        decoration: InputDecoration(
          hintText: "So'z qidiring...",
          prefixIcon: const Icon(Icons.search, color: Color(0xFF888888)),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(icon: const Icon(Icons.clear, size: 18), onPressed: () {
                  _searchController.clear();
                  context.read<WordProvider>().setSearch('');
                })
              : null,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _buildEmptyState(WordProvider provider) {
    final isFiltered = provider.filterType != FilterType.all;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(isFiltered ? "📋" : "📖", style: const TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          Text(isFiltered ? "Bu bo'limda so'z yo'q" : "Hali so'z qo'shilmagan",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E))),
          const SizedBox(height: 8),
          Text(isFiltered ? "Boshqa bo'limni tekshiring" : '"Yangi so\'z" tugmasini bosing',
              style: const TextStyle(fontSize: 14, color: Color(0xFF888888))),
        ],
      ),
    );
  }
}
