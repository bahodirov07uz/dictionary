import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_provider.dart';
import '../models/wisdom_models.dart';

class MyWordsScreen extends StatefulWidget {
  const MyWordsScreen({Key? key}) : super(key: key);
  @override
  State<MyWordsScreen> createState() => _MyWordsScreenState();
}

class _MyWordsScreenState extends State<MyWordsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  final _searchCtrl = TextEditingController();
  bool _showSearch = false;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _tabs.addListener(() {
      final p = context.read<AppProvider>();
      switch (_tabs.index) {
        case 0: p.setFilter(FilterType.all); break;
        case 1: p.setFilter(FilterType.unlearned); break;
        case 2: p.setFilter(FilterType.learned); break;
      }
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<AppProvider>();
    return Scaffold(
      backgroundColor: const Color(0xFFF2F3F7),
      body: SafeArea(child: Column(children: [
        _header(p),
        _statsBar(p),
        _tabBar(),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          child: _showSearch ? _searchBar(p) : const SizedBox.shrink(),
        ),
        Expanded(child: _list(p)),
      ])),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Export
          FloatingActionButton.small(
            heroTag: 'export',
            onPressed: () => _export(context, p),
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFF1A1A2E),
            tooltip: 'Export JSON',
            child: const Icon(Icons.upload),
          ),
          const SizedBox(width: 8),
          // Import
          FloatingActionButton.small(
            heroTag: 'import',
            onPressed: () => _showImportDialog(context, p),
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFF1A1A2E),
            tooltip: 'Import JSON',
            child: const Icon(Icons.download),
          ),
        ],
      ),
    );
  }

  Widget _header(AppProvider p) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 20, 16, 8),
    child: Row(children: [
      Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E), borderRadius: BorderRadius.circular(14)),
        child: const Text("📚", style: TextStyle(fontSize: 22)),
      ),
      const SizedBox(width: 12),
      const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text("Lug'atim", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF1A1A2E))),
        Text("O'zbek • English", style: TextStyle(fontSize: 12, color: Color(0xFF888888))),
      ]),
      const Spacer(),
      IconButton(
        icon: Icon(_showSearch ? Icons.search_off : Icons.search, color: const Color(0xFF1A1A2E)),
        onPressed: () {
          setState(() => _showSearch = !_showSearch);
          if (!_showSearch) { _searchCtrl.clear(); p.setLocalSearch(''); }
        },
      ),
    ]),
  );

  Widget _statsBar(AppProvider p) => Container(
    margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    decoration: BoxDecoration(
      color: Colors.white, borderRadius: BorderRadius.circular(16),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
    ),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
      _stat("Jami", p.totalCount, const Color(0xFF1A1A2E)),
      _vDivider(),
      _stat("Yodlanmadi", p.unlearnedCount, const Color(0xFFE53935)),
      _vDivider(),
      _stat("Yodlandi", p.learnedCount, const Color(0xFF43A047)),
    ]),
  );

  Widget _stat(String label, int count, Color color) => Column(children: [
    Text('$count', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: color)),
    Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF888888))),
  ]);

  Widget _vDivider() => Container(width: 1, height: 34, color: const Color(0xFFEEEEEE));

  Widget _tabBar() => Container(
    margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
    child: TabBar(
      controller: _tabs,
      labelColor: Colors.white,
      unselectedLabelColor: const Color(0xFF888888),
      labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
      indicator: BoxDecoration(color: const Color(0xFF1A1A2E), borderRadius: BorderRadius.circular(12)),
      indicatorSize: TabBarIndicatorSize.tab,
      dividerColor: Colors.transparent,
      padding: const EdgeInsets.all(4),
      tabs: const [Tab(text: "Barchasi"), Tab(text: "Yodlanmadi"), Tab(text: "Yodlandi")],
    ),
  );

  Widget _searchBar(AppProvider p) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
    child: TextField(
      controller: _searchCtrl,
      autofocus: true,
      onChanged: p.setLocalSearch,
      decoration: InputDecoration(
        hintText: "So'z qidiring...",
        prefixIcon: const Icon(Icons.search, color: Color(0xFF888888)),
        filled: true, fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
      ),
    ),
  );

  Widget _list(AppProvider p) {
    final words = p.words;
    if (words.isEmpty) return _empty(p);
    return ListView.builder(
      padding: const EdgeInsets.only(top: 4, bottom: 120),
      itemCount: words.length,
      itemBuilder: (ctx, i) => _WordTile(word: words[i]),
    );
  }

  Widget _empty(AppProvider p) => Center(child: Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Text(p.filter != FilterType.all ? "📋" : "📖", style: const TextStyle(fontSize: 60)),
      const SizedBox(height: 14),
      Text(p.filter != FilterType.all ? "Bu bo'limda so'z yo'q" : "Hali so'z qo'shilmagan",
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E))),
      const SizedBox(height: 6),
      Text(p.filter != FilterType.all ? "Boshqa bo'limni tekshiring" : 'Qidiruv orqali so\'z qo\'shing',
          style: const TextStyle(color: Color(0xFF888888))),
    ],
  ));

  // ─── Export ──────────────────────────────────────────────
  Future<void> _export(BuildContext context, AppProvider p) async {
    try {
      final path = await p.exportToFile();
      if (!context.mounted) return;
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text("Export tayyor ✅"),
          content: SelectableText(path, style: const TextStyle(fontSize: 12)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK")),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Xato: $e'), backgroundColor: Colors.red));
    }
  }

  // ─── Import ──────────────────────────────────────────────
  void _showImportDialog(BuildContext context, AppProvider p) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text("Import JSON", style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              maxLines: 6,
              decoration: InputDecoration(
                hintText: 'JSON matnini shu yerga paste qiling...',
                filled: true, fillColor: const Color(0xFFF5F5F5),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Bekor"),
              )),
              const SizedBox(width: 8),
              Expanded(child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A1A2E),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () async {
                  Navigator.pop(context);
                  try {
                    final (imp, skip) = await p.importFromJson(ctrl.text);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text('✅ $imp ta qo\'shildi, $skip ta o\'tkazib yuborildi'),
                        backgroundColor: const Color(0xFF43A047),
                      ));
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text('Xato: $e'), backgroundColor: Colors.red));
                    }
                  }
                },
                child: const Text("Import", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
              )),
            ]),
          ]),
        ),
      ),
    );
  }
}

// ─── Word tile ────────────────────────────────────────────
class _WordTile extends StatelessWidget {
  final LearnWord word;
  const _WordTile({required this.word});

  @override
  Widget build(BuildContext context) {
    final p = context.read<AppProvider>();
    return Dismissible(
      key: Key('lw_${word.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red.shade400, borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 26),
      ),
      confirmDismiss: (_) => showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text("O'chirishni tasdiqlang"),
          content: Text('"${word.english}" ni o\'chirasizmi?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Bekor")),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text("O'chirish"),
            ),
          ],
        ),
      ),
      onDismissed: (_) => p.deleteWord(word),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        decoration: BoxDecoration(
          color: word.isLearned ? const Color(0xFFE8F5E9) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: word.isLearned ? const Color(0xFF66BB6A) : const Color(0xFFE0E0E0),
          ),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            Container(
              width: 5, height: 48,
              decoration: BoxDecoration(
                color: word.isLearned ? const Color(0xFF43A047) : const Color(0xFFBDBDBD),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text(word.english,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E))),
                if (word.wordClass != null) ...[
                  const SizedBox(width: 6),
                  Text(word.wordClass!,
                      style: const TextStyle(fontSize: 12, color: Color(0xFF1565C0), fontStyle: FontStyle.italic)),
                ],
              ]),
              const SizedBox(height: 3),
              Text(word.uzbek, style: const TextStyle(fontSize: 13, color: Color(0xFF555555))),
            ])),
            GestureDetector(
              onTap: () => p.toggleLearned(word),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: word.isLearned ? const Color(0xFF43A047) : const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: word.isLearned ? const Color(0xFF43A047) : const Color(0xFFBDBDBD),
                  ),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(
                    word.isLearned ? Icons.check_circle : Icons.radio_button_unchecked,
                    size: 14,
                    color: word.isLearned ? Colors.white : Colors.grey,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    word.isLearned ? "Yodlandi" : "Yodlanmadi",
                    style: TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w600,
                      color: word.isLearned ? Colors.white : Colors.grey.shade600,
                    ),
                  ),
                ]),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
