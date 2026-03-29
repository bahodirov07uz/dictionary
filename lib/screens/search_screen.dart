import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_provider.dart';
import '../models/wisdom_models.dart';
import 'word_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);
  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _ctrl = TextEditingController();
  final _focus = FocusNode();
  List<WisdomSearchResult> _results = [];
  bool _loading = false;
  Timer? _debounce;
  String _lastQ = '';

  @override
  void dispose() { _debounce?.cancel(); _ctrl.dispose(); _focus.dispose(); super.dispose(); }

  void _onChanged(String val) {
    final q = val.trim();
    if (q == _lastQ) return;
    _lastQ = q;
    _debounce?.cancel();
    if (q.isEmpty) { setState(() { _results = []; _loading = false; }); return; }
    setState(() => _loading = true);
    _debounce = Timer(const Duration(milliseconds: 150), () => _search(q));
  }

  Future<void> _search(String q) async {
    final res = await context.read<AppProvider>().search(q);
    if (!mounted || _lastQ != q) return;
    setState(() { _results = res; _loading = false; });
  }

  void _open(WisdomSearchResult item) {
    Navigator.push(context,
        MaterialPageRoute(builder: (_) => WordDetailScreen(result: item)));
  }

  @override
  Widget build(BuildContext context) {
    final history = context.watch<AppProvider>().history;
    final wisdomReady = context.watch<AppProvider>().wisdomReady;

    return Scaffold(
      backgroundColor: const Color(0xFFF2F3F7),
      body: SafeArea(child: Column(children: [
        // Search bar header
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text("Qidiruv",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF1A1A2E))),
            const SizedBox(height: 10),
            if (!wisdomReady)
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0), borderRadius: BorderRadius.circular(10)),
                child: const Row(children: [
                  Icon(Icons.info_outline, color: Color(0xFFE65100), size: 18),
                  SizedBox(width: 8),
                  Expanded(child: Text(
                    'wisdom.db topilmadi. assets/ papkasiga qo\'yib reinstall qiling.',
                    style: TextStyle(fontSize: 12, color: Color(0xFFE65100)),
                  )),
                ]),
              ),
            const SizedBox(height: 8),
            TextField(
              controller: _ctrl,
              focusNode: _focus,
              onChanged: _onChanged,
              enabled: wisdomReady,
              style: const TextStyle(fontSize: 16),
              decoration: InputDecoration(
                hintText: wisdomReady ? "So'z kiriting..." : "DB tayyorlanmoqda...",
                prefixIcon: _loading
                    ? const Padding(padding: EdgeInsets.all(12),
                        child: SizedBox(width: 18, height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF1A1A2E))))
                    : const Icon(Icons.search, color: Color(0xFF888888)),
                suffixIcon: _ctrl.text.isNotEmpty
                    ? IconButton(icon: const Icon(Icons.clear, size: 18),
                        onPressed: () { _ctrl.clear(); _onChanged(''); _focus.requestFocus(); })
                    : null,
                filled: true, fillColor: const Color(0xFFF5F5F5),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFF1A1A2E), width: 2)),
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ]),
        ),

        Expanded(child: _results.isNotEmpty
            ? _buildResults()
            : _ctrl.text.isEmpty
                ? _buildHistory(history)
                : _loading ? const SizedBox.shrink() : _buildEmpty()),
      ])),
    );
  }

  Widget _buildResults() => ListView.builder(
    padding: const EdgeInsets.symmetric(vertical: 4),
    itemCount: _results.length,
    itemBuilder: (ctx, i) => _ResultTile(item: _results[i], onTap: () => _open(_results[i])),
  );

  Widget _buildHistory(List<HistoryItem> history) {
    if (history.isEmpty) return Center(child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: const [
        Text("🔎", style: TextStyle(fontSize: 52)),
        SizedBox(height: 12),
        Text("So'z qidiring", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E))),
        SizedBox(height: 6),
        Text("Ko'rilgan so'zlar bu yerda chiqadi", style: TextStyle(color: Color(0xFF888888))),
      ],
    ));

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        child: Row(children: [
          const Text("Tarix", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Color(0xFF1A1A2E))),
          const Spacer(),
          TextButton(
            onPressed: () => context.read<AppProvider>().clearHistory(),
            child: const Text("Tozalash", style: TextStyle(color: Colors.red, fontSize: 12)),
          ),
        ]),
      ),
      Expanded(child: ListView.builder(
        itemCount: history.length,
        itemBuilder: (ctx, i) {
          final h = history[i];
          return Dismissible(
            key: Key('hist_${h.wordEntityId}'),
            direction: DismissDirection.endToStart,
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              color: Colors.red.shade50,
              child: const Icon(Icons.delete_outline, color: Colors.red),
            ),
            onDismissed: (_) => context.read<AppProvider>().deleteHistory(h.wordEntityId),
            child: ListTile(
              leading: const Icon(Icons.history, color: Color(0xFFBBBBBB), size: 20),
              title: Text(h.word, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
              subtitle: h.translations.isNotEmpty
                  ? Text(h.translations.join(', '), style: const TextStyle(color: Color(0xFF43A047), fontSize: 12))
                  : null,
              trailing: const Icon(Icons.chevron_right, color: Color(0xFFBBBBBB)),
              onTap: () => Navigator.push(context, MaterialPageRoute(
                  builder: (_) => WordDetailScreen(
                    result: WisdomSearchResult(
                      id: 0, wordenId: h.wordEntityId, word: h.word,
                      translations: h.translations,
                    ),
                  ))),
            ),
          );
        },
      )),
    ]);
  }

  Widget _buildEmpty() => const Center(
    child: Text("Hech narsa topilmadi", style: TextStyle(color: Color(0xFF888888))),
  );
}

// Rasmga o'xshash tile
class _ResultTile extends StatelessWidget {
  final WisdomSearchResult item;
  final VoidCallback onTap;
  const _ResultTile({required this.item, required this.onTap});

  static const _colors = {
    'noun': Color(0xFF1565C0),
    'verb': Color(0xFF2E7D32),
    'adjective': Color(0xFF6A1B9A),
    'adverb': Color(0xFFE65100),
    'exclamation': Color(0xFFC62828),
    'preposition': Color(0xFF00695C),
  };

  Color _color(String? cls) {
    if (cls == null) return const Color(0xFF888888);
    for (final k in _colors.keys) {
      if (cls.toLowerCase().contains(k)) return _colors[k]!;
    }
    return const Color(0xFF888888);
  }

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFF0F0F0))),
      ),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
            Text(item.word,
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E))),
            if (item.wordClass != null) ...[
              const SizedBox(width: 8),
              Text(item.wordClass!,
                  style: TextStyle(fontSize: 13, color: _color(item.wordClass), fontStyle: FontStyle.italic)),
            ],
          ]),
          if (item.translations.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(item.translations.join(', '),
                style: const TextStyle(fontSize: 13, color: Color(0xFF555555))),
          ],
        ])),
        Icon(item.isStar ? Icons.star : Icons.star_border,
            color: item.isStar ? const Color(0xFFE53935) : const Color(0xFFCCCCCC), size: 20),
      ]),
    ),
  );
}
