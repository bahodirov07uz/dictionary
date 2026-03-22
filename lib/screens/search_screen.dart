import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../services/word_provider.dart';
import '../models/api_word.dart';
import 'word_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _api = ApiService();
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  List<ApiSearchResult> _results = [];
  bool _loading = false;
  Timer? _debounce;
  String _lastQuery = '';

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    _api.dispose();
    super.dispose();
  }

  void _onChanged(String val) {
    final q = val.trim();
    if (q == _lastQuery) return;
    _lastQuery = q;

    _debounce?.cancel();
    if (q.isEmpty) {
      setState(() { _results = []; _loading = false; });
      return;
    }

    // Show loading immediately
    setState(() => _loading = true);

    _debounce = Timer(const Duration(milliseconds: 150), () => _search(q));
  }

  Future<void> _search(String q) async {
    final res = await _api.search(q);
    if (!mounted) return;
    if (_lastQuery == q) {
      setState(() { _results = res; _loading = false; });
    }
  }

  void _openDetail(ApiSearchResult item) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => WordDetailScreen(id: item.id, word: item.word)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final history = context.watch<WordProvider>().history;

    return Scaffold(
      backgroundColor: const Color(0xFFF2F3F7),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Qidiruv",
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF1A1A2E))),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    onChanged: _onChanged,
                    style: const TextStyle(fontSize: 16),
                    decoration: InputDecoration(
                      hintText: "So'z kiriting...",
                      prefixIcon: _loading
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: SizedBox(
                                width: 20, height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF1A1A2E)),
                              ))
                          : const Icon(Icons.search, color: Color(0xFF888888)),
                      suffixIcon: _controller.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                _controller.clear();
                                _onChanged('');
                                _focusNode.requestFocus();
                              })
                          : null,
                      filled: true,
                      fillColor: const Color(0xFFF5F5F5),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Color(0xFF1A1A2E), width: 2)),
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: _results.isNotEmpty
                  ? _buildResults()
                  : _controller.text.isEmpty
                      ? _buildHistory(history)
                      : _loading
                          ? const SizedBox.shrink()
                          : _buildEmpty(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResults() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 6),
      itemCount: _results.length,
      itemBuilder: (ctx, i) => _SearchResultTile(item: _results[i], onTap: () => _openDetail(_results[i])),
    );
  }

  Widget _buildHistory(List<HistoryItem> history) {
    if (history.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Text("🔎", style: TextStyle(fontSize: 52)),
            SizedBox(height: 12),
            Text("So'z qidiring",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E))),
            SizedBox(height: 6),
            Text("Ko'rilgan so'zlar bu yerda chiqadi",
                style: TextStyle(color: Color(0xFF888888))),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(
            children: [
              const Text("Tarix",
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Color(0xFF1A1A2E))),
              const Spacer(),
              TextButton(
                onPressed: _confirmClearHistory,
                child: const Text("Tozalash", style: TextStyle(color: Colors.red, fontSize: 12)),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: history.length,
            itemBuilder: (ctx, i) {
              final h = history[i];
              return Dismissible(
                key: Key('h_${h.wordId}'),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  color: Colors.red.shade50,
                  child: const Icon(Icons.delete_outline, color: Colors.red),
                ),
                onDismissed: (_) => context.read<WordProvider>().deleteHistoryItem(h.wordId),
                child: ListTile(
                  leading: const Icon(Icons.history, color: Color(0xFFBBBBBB), size: 20),
                  title: Text(h.word,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                  subtitle: h.translations.isNotEmpty
                      ? Text(h.translations.join(', '),
                          style: const TextStyle(color: Color(0xFF43A047), fontSize: 12))
                      : null,
                  trailing: const Icon(Icons.chevron_right, color: Color(0xFFBBBBBB)),
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => WordDetailScreen(id: h.wordId, word: h.word))),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEmpty() {
    return const Center(
      child: Text("Hech narsa topilmadi", style: TextStyle(color: Color(0xFF888888))),
    );
  }

  void _confirmClearHistory() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Tarixni tozalash"),
        content: const Text("Barcha tarixni o'chirasizmi?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Bekor")),
          TextButton(
            onPressed: () { Navigator.pop(ctx); context.read<WordProvider>().clearHistory(); },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("O'chirish"),
          ),
        ],
      ),
    );
  }
}

// ---- Tile (rasmga o'xshash layout) ----
class _SearchResultTile extends StatelessWidget {
  final ApiSearchResult item;
  final VoidCallback onTap;
  const _SearchResultTile({required this.item, required this.onTap});

  static const _classColors = {
    'noun': Color(0xFF1565C0),
    'verb': Color(0xFF2E7D32),
    'adjective': Color(0xFF6A1B9A),
    'adverb': Color(0xFFE65100),
    'exclamation': Color(0xFFC62828),
    'preposition': Color(0xFF00695C),
  };

  Color _classColor(String? cls) {
    if (cls == null) return const Color(0xFF888888);
    for (final k in _classColors.keys) {
      if (cls.toLowerCase().contains(k)) return _classColors[k]!;
    }
    return const Color(0xFF888888);
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(bottom: BorderSide(color: Color(0xFFF0F0F0))),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // So'z + word class bir qatorda (rasmga o'xshash)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(item.word,
                          style: const TextStyle(
                              fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E))),
                      if (item.wordClass != null) ...[
                        const SizedBox(width: 8),
                        Text(item.wordClass!,
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: _classColor(item.wordClass),
                                fontStyle: FontStyle.italic)),
                      ],
                    ],
                  ),
                  if (item.translations.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(item.translations.join(', '),
                        style: const TextStyle(fontSize: 13, color: Color(0xFF555555))),
                  ],
                ],
              ),
            ),
            // Star indicator
            if (item.isStar)
              const Icon(Icons.star, color: Color(0xFFE53935), size: 20)
            else
              const Icon(Icons.star_border, color: Color(0xFFCCCCCC), size: 20),
          ],
        ),
      ),
    );
  }
}
