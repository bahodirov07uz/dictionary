import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_provider.dart';
import '../models/wisdom_models.dart';

class WordDetailScreen extends StatefulWidget {
  final WisdomSearchResult result;
  const WordDetailScreen({Key? key, required this.result}) : super(key: key);
  @override
  State<WordDetailScreen> createState() => _WordDetailScreenState();
}

class _WordDetailScreenState extends State<WordDetailScreen> {
  WisdomWord? _detail;
  bool _loading = true;
  bool _inMyDict = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = context.read<AppProvider>();
    final d = await p.getDetail(widget.result.wordenId);
    final exists = await p.wordExists(widget.result.wordenId);
    if (!mounted) return;
    setState(() { _detail = d; _loading = false; _inMyDict = exists; });

    // Tarixga qo'shish
    final translations = d?.translations ?? widget.result.translations;
    await p.addHistory(HistoryItem(
      wordEntityId: widget.result.wordenId,
      word: widget.result.word,
      translations: translations,
      viewedAt: DateTime.now(),
    ));
  }

  Future<void> _addToMyDict({WisdomWord? child}) async {
    final p = context.read<AppProvider>();
    final source = child ?? _detail;
    if (source == null) return;

    final uz = source.translations.isNotEmpty ? source.translations.first : '';
    final engCtrl = TextEditingController(text: source.word);
    final uzCtrl = TextEditingController(text: uz);
    bool learned = false;

    await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSt) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text(child != null ? "So'zni qo'shish" : "Lug'atimga qo'shish",
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
              const SizedBox(height: 14),
              _inputField("🇬🇧 Inglizcha", engCtrl),
              const SizedBox(height: 10),
              _inputField("🇺🇿 O'zbekcha", uzCtrl),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () => setSt(() => learned = !learned),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: learned ? const Color(0xFFE8F5E9) : const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: learned ? const Color(0xFF43A047) : const Color(0xFFDDDDDD)),
                  ),
                  child: Row(children: [
                    Icon(learned ? Icons.check_circle : Icons.radio_button_unchecked,
                        color: learned ? const Color(0xFF43A047) : const Color(0xFFBBBBBB), size: 20),
                    const SizedBox(width: 10),
                    Text(learned ? "Yodlandi" : "Yodlanmadi",
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: learned ? const Color(0xFF43A047) : const Color(0xFF666666),
                        )),
                  ]),
                ),
              ),
              const SizedBox(height: 14),
              Row(children: [
                Expanded(child: TextButton(
                    onPressed: () => Navigator.pop(ctx), child: const Text("Bekor"))),
                const SizedBox(width: 8),
                Expanded(child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A1A2E),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () async {
                    Navigator.pop(ctx);
                    final w = LearnWord(
                      english: engCtrl.text.trim(),
                      uzbek: uzCtrl.text.trim(),
                      wordClass: source.wordClass,
                      example: source.example,
                      wordEntityId: source.id,
                      isLearned: learned,
                    );
                    final added = await p.addWord(w);
                    if (context.mounted) {
                      if (child == null) setState(() => _inMyDict = added || _inMyDict);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(added ? '✅ Lug\'atga qo\'shildi' : '⚠️ Allaqachon mavjud'),
                        backgroundColor: added ? const Color(0xFF43A047) : Colors.orange,
                        behavior: SnackBarBehavior.floating,
                      ));
                    }
                  },
                  child: const Text("Qo'shish", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                )),
              ]),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _inputField(String label, TextEditingController ctrl) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF888888))),
      const SizedBox(height: 4),
      TextField(
        controller: ctrl,
        style: const TextStyle(fontSize: 15),
        decoration: InputDecoration(
          filled: true, fillColor: const Color(0xFFF7F7F7),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F3F7),
      appBar: AppBar(
        title: Text(widget.result.word,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1A1A2E),
        elevation: 0,
        actions: [
          if (!_loading && _detail != null)
            IconButton(
              tooltip: _inMyDict ? "Lug'atimda bor" : "Lug'atimga qo'shish",
              icon: Icon(_inMyDict ? Icons.bookmark : Icons.bookmark_border,
                  color: _inMyDict ? const Color(0xFF1A1A2E) : null),
              onPressed: () => _addToMyDict(),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF1A1A2E)))
          : _detail == null
              ? const Center(child: Text("Ma'lumot topilmadi"))
              : _buildBody(_detail!),
    );
  }

  Widget _buildBody(WisdomWord d) => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      // Main card
      _card([
        Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
          Text(d.word,
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Color(0xFF1A1A2E))),
          if (d.wordClass != null) ...[
            const SizedBox(width: 10),
            Text(d.wordClass!,
                style: TextStyle(fontSize: 15, color: _clsColor(d.wordClass), fontStyle: FontStyle.italic)),
          ],
        ]),
        if (d.wordClassBody != null) ...[
          const SizedBox(height: 4),
          Text(d.wordClassBody!, style: const TextStyle(fontSize: 13, color: Color(0xFF888888))),
        ],
        if (d.translations.isNotEmpty) ...[
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 10),
          ...d.translations.map((t) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(children: [
              Container(width: 4, height: 4,
                  decoration: const BoxDecoration(color: Color(0xFF43A047), shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Text(t, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF222222))),
            ]),
          )),
        ],
        const SizedBox(height: 12),
        SizedBox(width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _addToMyDict(),
            icon: Icon(_inMyDict ? Icons.bookmark : Icons.bookmark_border, size: 18),
            label: Text(_inMyDict ? "Lug'atimda bor" : "Lug'atimga qo'shish"),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF1A1A2E),
              side: const BorderSide(color: Color(0xFF1A1A2E)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),
      ]),

      if (d.example != null) ...[
        const SizedBox(height: 12),
        _label("MISOL"),
        _card([Text(d.example!,
            style: const TextStyle(fontStyle: FontStyle.italic, color: Color(0xFF444444), height: 1.5))]),
      ],

      if (d.examples != null) ...[
        const SizedBox(height: 12),
        _label("KO'PROQ MISOLLAR"),
        _card([Text(_strip(d.examples!),
            style: const TextStyle(color: Color(0xFF444444), height: 1.7))]),
      ],

      if (d.synonyms != null) ...[
        const SizedBox(height: 12),
        _label("SINONIMLAR"),
        _card([Text(_strip(d.synonyms!), style: const TextStyle(color: Color(0xFF444444)))]),
      ],

      // Children
      for (final child in d.children) ...[
        const SizedBox(height: 12),
        _childCard(child),
      ],

      const SizedBox(height: 40),
    ],
  );

  Widget _card(List<Widget> children) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white, borderRadius: BorderRadius.circular(16),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
  );

  Widget _label(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 5, left: 4),
    child: Text(t, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
        color: Color(0xFF888888), letterSpacing: 0.8)),
  );

  Widget _childCard(WisdomWord child) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white, borderRadius: BorderRadius.circular(14),
      border: Border.all(color: const Color(0xFFE8EAF6)),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6)],
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
        Text(child.word,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E))),
        if (child.wordClass != null) ...[
          const SizedBox(width: 6),
          Text(child.wordClass!,
              style: TextStyle(fontSize: 12, color: _clsColor(child.wordClass), fontStyle: FontStyle.italic)),
        ],
      ]),
      if (child.translations.isNotEmpty) ...[
        const SizedBox(height: 6),
        Wrap(spacing: 6, runSpacing: 4,
          children: child.translations.map((t) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(20)),
            child: Text(t, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF2E7D32))),
          )).toList(),
        ),
      ],
      if (child.example != null) ...[
        const SizedBox(height: 6),
        Text(child.example!, style: const TextStyle(fontStyle: FontStyle.italic, color: Color(0xFF555555), fontSize: 13)),
      ],
      const SizedBox(height: 8),
      SizedBox(width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: () => _addToMyDict(child: child),
          icon: const Icon(Icons.add, size: 15),
          label: const Text("Qo'shish", style: TextStyle(fontSize: 13)),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF1565C0),
            side: const BorderSide(color: Color(0xFF1565C0)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            padding: const EdgeInsets.symmetric(vertical: 7),
          ),
        ),
      ),
    ]),
  );

  Color _clsColor(String? cls) {
    if (cls == null) return const Color(0xFF888888);
    if (cls.contains('noun')) return const Color(0xFF1565C0);
    if (cls.contains('verb')) return const Color(0xFF2E7D32);
    if (cls.contains('adj')) return const Color(0xFF6A1B9A);
    if (cls.contains('adv')) return const Color(0xFFE65100);
    if (cls.contains('excl')) return const Color(0xFFC62828);
    return const Color(0xFF888888);
  }

  String _strip(String html) => html
      .replaceAll(RegExp(r'<[^>]*>'), '').replaceAll('&nbsp;', ' ')
      .replaceAll('&amp;', '&').replaceAll('&lt;', '<').replaceAll('&gt;', '>').trim();
}
