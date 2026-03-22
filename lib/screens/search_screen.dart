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
  List<ApiSearchResult> _results = [];
  bool _loading = false;
  String _error = '';
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String val) {
    _debounce?.cancel();
    if (val.trim().isEmpty) {
      setState(() { _results = []; _error = ''; });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 400), () => _search(val));
  }

  Future<void> _search(String q) async {
    setState(() { _loading = true; _error = ''; });
    try {
      final res = await _api.search(q);
      setState(() { _results = res; _loading = false; });
    } catch (e) {
      setState(() { _error = 'Xato: $e'; _loading = false; });
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
            // Header + Search bar
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "🔍 Qidiruv",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF1A1A2E)),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _controller,
                    onChanged: _onChanged,
                    autofocus: false,
                    style: const TextStyle(fontSize: 16),
                    decoration: InputDecoration(
                      hintText: "Inglizcha so'z kiriting...",
                      prefixIcon: const Icon(Icons.search, color: Color(0xFF888888)),
                      suffixIcon: _controller.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                _controller.clear();
                                setState(() { _results = []; });
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: const Color(0xFFF5F5F5),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFF1A1A2E), width: 2),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF1A1A2E)))
                  : _error.isNotEmpty
                      ? Center(child: Text(_error, style: const TextStyle(color: Colors.red)))
                      : _results.isNotEmpty
                          ? _buildResults()
                          : _controller.text.isEmpty
                              ? _buildHistory(history)
                              : _buildEmpty(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResults() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _results.length,
      itemBuilder: (ctx, i) {
        final item = _results[i];
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          title: Text(item.word, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          subtitle: item.translations.isNotEmpty
              ? Text(item.translations.join(', '), style: const TextStyle(color: Color(0xFF43A047)))
              : null,
          trailing: const Icon(Icons.chevron_right, color: Color(0xFFBBBBBB)),
          onTap: () => _openDetail(item),
        );
      },
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
            Text("So'z qidiring", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E))),
            SizedBox(height: 6),
            Text("Ko'rilgan so'zlar bu yerda chiqadi", style: TextStyle(color: Color(0xFF888888))),
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
              const Text("Tarix", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Color(0xFF1A1A2E))),
              const Spacer(),
              TextButton(
                onPressed: () => _confirmClearHistory(),
                child: const Text("Hammasini tozalash", style: TextStyle(color: Colors.red, fontSize: 12)),
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
                key: Key('history_${h.wordId}'),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  color: Colors.red.shade100,
                  child: const Icon(Icons.delete_outline, color: Colors.red),
                ),
                onDismissed: (_) => context.read<WordProvider>().deleteHistoryItem(h.wordId),
                child: ListTile(
                  leading: const Icon(Icons.history, color: Color(0xFFBBBBBB)),
                  title: Text(h.word, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(h.translations.join(', '), style: const TextStyle(color: Color(0xFF43A047), fontSize: 12)),
                  trailing: const Icon(Icons.chevron_right, color: Color(0xFFBBBBBB)),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => WordDetailScreen(id: h.wordId, word: h.word)),
                  ),
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
            onPressed: () {
              Navigator.pop(ctx);
              context.read<WordProvider>().clearHistory();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("O'chirish"),
          ),
        ],
      ),
    );
  }
}
