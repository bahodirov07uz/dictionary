import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/word_provider.dart';
import '../widgets/word_card.dart';
import '../widgets/add_word_dialog.dart';
import '../models/word.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  bool _showSearch = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WordProvider>().loadWords();
    });
  }

  void _onTabChanged() {
    final provider = context.read<WordProvider>();
    switch (_tabController.index) {
      case 0:
        provider.setFilter(FilterType.all);
        break;
      case 1:
        provider.setFilter(FilterType.unlearned);
        break;
      case 2:
        provider.setFilter(FilterType.learned);
        break;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _showAddDialog([Word? editWord]) {
    showDialog(
      context: context,
      builder: (_) => AddWordDialog(editWord: editWord),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F3F7),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(),

            // Stats bar
            Consumer<WordProvider>(
              builder: (ctx, provider, _) => _buildStatsBar(provider),
            ),

            // Tab bar
            _buildTabBar(),

            // Search bar (animated)
            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              child: _showSearch ? _buildSearchBar() : const SizedBox.shrink(),
            ),

            // Word list
            Expanded(
              child: Consumer<WordProvider>(
                builder: (ctx, provider, _) {
                  if (provider.isLoading) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF1A1A2E),
                      ),
                    );
                  }
                  if (provider.words.isEmpty) {
                    return _buildEmptyState(provider);
                  }
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
        label: const Text(
          "Yangi so'z",
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        elevation: 4,
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
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A2E),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Text("📚", style: TextStyle(fontSize: 22)),
          ),
          const SizedBox(width: 12),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Lug'atim",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1A1A2E),
                  letterSpacing: -0.5,
                ),
              ),
              Text(
                "O'zbek • English",
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF888888),
                  fontWeight: FontWeight.w500,
                ),
              ),
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
            icon: Icon(
              _showSearch ? Icons.search_off : Icons.search,
              color: const Color(0xFF1A1A2E),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsBar(WordProvider provider) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _statItem("Jami", provider.totalCount, const Color(0xFF1A1A2E)),
          _divider(),
          _statItem("Yodlanmadi", provider.unlearnedCount, const Color(0xFFE53935)),
          _divider(),
          _statItem("Yodlandi", provider.learnedCount, const Color(0xFF43A047)),
        ],
      ),
    );
  }

  Widget _statItem(String label, int count, Color color) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Color(0xFF888888),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _divider() {
    return Container(
      width: 1,
      height: 36,
      color: const Color(0xFFEEEEEE),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: Colors.white,
        unselectedLabelColor: const Color(0xFF888888),
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        unselectedLabelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        indicator: BoxDecoration(
          color: const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(12),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        padding: const EdgeInsets.all(4),
        tabs: const [
          Tab(text: "Barchasi"),
          Tab(text: "Yodlanmadi"),
          Tab(text: "Yodlandi"),
        ],
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
        style: const TextStyle(fontSize: 15),
        decoration: InputDecoration(
          hintText: "So'z qidiring...",
          prefixIcon: const Icon(Icons.search, color: Color(0xFF888888)),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: () {
                    _searchController.clear();
                    context.read<WordProvider>().setSearch('');
                  },
                )
              : null,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
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
          Text(
            isFiltered ? "📋" : "📖",
            style: const TextStyle(fontSize: 64),
          ),
          const SizedBox(height: 16),
          Text(
            isFiltered
                ? "Bu bo'limda so'z yo'q"
                : "Hali so'z qo'shilmagan",
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isFiltered
                ? "Boshqa bo'limni tekshiring"
                : "\"Yangi so'z\" tugmasini bosing",
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF888888),
            ),
          ),
        ],
      ),
    );
  }
}
