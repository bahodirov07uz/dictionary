import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../services/word_provider.dart';
import '../models/api_word.dart';
import '../models/word.dart';
import '../widgets/add_word_dialog.dart';

class WordDetailScreen extends StatefulWidget {
  final int id;
  final String word;
  const WordDetailScreen({Key? key, required this.id, required this.word}) : super(key: key);

  @override
  State<WordDetailScreen> createState() => _WordDetailScreenState();
}

class _WordDetailScreenState extends State<WordDetailScreen> {
  final _api = ApiService();
  ApiWordDetail? _detail;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final d = await _api.getDetail(widget.id);
    if (!mounted) return;
    setState(() { _detail = d; _loading = false; });
    if (d != null) {
      context.read<WordProvider>().addToHistory(HistoryItem(
        wordId: d.id,
        word: d.word,
        translations: d.translations,
        viewedAt: DateTime.now(),
      ));
    }
  }

  // Custom lug'atga qo'shish
  void _addToMyDictionary(BuildContext context, {String? uzbek, String? english}) {
    final provider = context.read<WordProvider>();
    final eng = english ?? widget.word;
    final uz = uzbek ?? (_detail?.translations.isNotEmpty == true ? _detail!.translations.first : '');

    showDialog(
      context: context,
      builder: (_) => _AddToMyDictDialog(
        initialEnglish: eng,
        initialUzbek: uz,
        onSave: (uz2, en2, learned) async {
          await provider.addWord(uz2, en2, isLearned: learned);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('"$en2" lug\'atga qo\'shildi'),
                backgroundColor: const Color(0xFF43A047),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F3F7),
      appBar: AppBar(
        title: Text(widget.word,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1A1A2E),
        elevation: 0,
        actions: [
          if (_detail != null)
            IconButton(
              tooltip: "Lug'atimga qo'shish",
              icon: const Icon(Icons.playlist_add),
              onPressed: () => _addToMyDictionary(context),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF1A1A2E)))
          : _detail == null
              ? const Center(child: Text("Ma'lumot topilmadi"))
              : _buildBody(),
    );
  }

  Widget _buildBody() {
    final d = _detail!;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Main card
        _card(children: [
          // So'z + word class (rasmga o'xshash)
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(d.word,
                  style: const TextStyle(
                      fontSize: 26, fontWeight: FontWeight.w900, color: Color(0xFF1A1A2E))),
              if (d.wordClass != null) ...[
                const SizedBox(width: 10),
                Text(d.wordClass!,
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: _classColor(d.wordClass),
                        fontStyle: FontStyle.italic)),
              ],
            ],
          ),
          if (d.wordClassBody != null) ...[
            const SizedBox(height: 4),
            Text(d.wordClassBody!,
                style: const TextStyle(fontSize: 13, color: Color(0xFF888888))),
          ],

          if (d.translations.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            // Tarjimalar
            ...d.translations.map((t) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Container(width: 4, height: 4, decoration: const BoxDecoration(
                    color: Color(0xFF43A047), shape: BoxShape.circle)),
                  const SizedBox(width: 8),
                  Text(t, style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF222222))),
                ],
              ),
            )),
          ],

          // "Lug'atimga qo'shish" tugmasi
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _addToMyDictionary(context),
              icon: const Icon(Icons.add, size: 18),
              label: const Text("Lug'atimga qo'shish"),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF1A1A2E),
                side: const BorderSide(color: Color(0xFF1A1A2E)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
        ]),

        // Example
        if (d.example != null) ...[
          const SizedBox(height: 12),
          _sectionTitle("Misol"),
          _card(children: [
            Text(d.example!,
                style: const TextStyle(fontStyle: FontStyle.italic, color: Color(0xFF444444), height: 1.5)),
          ]),
        ],

        // More examples
        if (d.examples != null) ...[
          const SizedBox(height: 12),
          _sectionTitle("Ko'proq misollar"),
          _card(children: [
            Text(_stripHtml(d.examples!),
                style: const TextStyle(color: Color(0xFF444444), height: 1.7)),
          ]),
        ],

        // Synonyms
        if (d.synonyms != null) ...[
          const SizedBox(height: 12),
          _sectionTitle("Sinonimlar"),
          _card(children: [
            Text(_stripHtml(d.synonyms!), style: const TextStyle(color: Color(0xFF444444))),
          ]),
        ],

        // Children — har biri alohida card + "qo'shish" tugmasi
        for (final child in d.children) ...[
          const SizedBox(height: 12),
          _childCard(child),
        ],

        const SizedBox(height: 40),
      ],
    );
  }

  Widget _childCard(ApiWordChild child) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8EAF6)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(child.word,
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E))),
            if (child.wordClass != null) ...[
              const SizedBox(width: 8),
              Text(child.wordClass!,
                  style: TextStyle(
                      fontSize: 13, color: _classColor(child.wordClass), fontStyle: FontStyle.italic)),
            ],
          ],
        ),
        if (child.translations.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8, runSpacing: 4,
            children: child.translations.map((t) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(t, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF2E7D32))),
            )).toList(),
          ),
        ],
        if (child.example != null) ...[
          const SizedBox(height: 8),
          Text(child.example!,
              style: const TextStyle(fontStyle: FontStyle.italic, color: Color(0xFF555555), fontSize: 13)),
        ],
        if (child.synonyms != null) ...[
          const SizedBox(height: 6),
          Text("Syn: ${_stripHtml(child.synonyms!)}",
              style: const TextStyle(fontSize: 12, color: Color(0xFF888888))),
        ],
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _addToMyDictionary(context,
                english: child.word,
                uzbek: child.translations.isNotEmpty ? child.translations.first : ''),
            icon: const Icon(Icons.add, size: 16),
            label: const Text("Lug'atimga qo'shish", style: TextStyle(fontSize: 13)),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF1565C0),
              side: const BorderSide(color: Color(0xFF1565C0)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(vertical: 8),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _card({required List<Widget> children}) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
      );

  Widget _sectionTitle(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 6, left: 4),
        child: Text(t,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                color: Color(0xFF888888), letterSpacing: 0.5)),
      );

  Color _classColor(String? cls) {
    if (cls == null) return const Color(0xFF888888);
    if (cls.contains('noun')) return const Color(0xFF1565C0);
    if (cls.contains('verb')) return const Color(0xFF2E7D32);
    if (cls.contains('adj')) return const Color(0xFF6A1B9A);
    if (cls.contains('adv')) return const Color(0xFFE65100);
    if (cls.contains('excl')) return const Color(0xFFC62828);
    return const Color(0xFF888888);
  }

  String _stripHtml(String html) => html
      .replaceAll(RegExp(r'<[^>]*>'), '')
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .trim();
}

// ---- Dialog: lug'atga qo'shish ----
class _AddToMyDictDialog extends StatefulWidget {
  final String initialEnglish;
  final String initialUzbek;
  final Future<void> Function(String uz, String en, bool learned) onSave;

  const _AddToMyDictDialog({
    required this.initialEnglish,
    required this.initialUzbek,
    required this.onSave,
  });

  @override
  State<_AddToMyDictDialog> createState() => _AddToMyDictDialogState();
}

class _AddToMyDictDialogState extends State<_AddToMyDictDialog> {
  late final TextEditingController _enCtrl;
  late final TextEditingController _uzCtrl;
  bool _learned = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _enCtrl = TextEditingController(text: widget.initialEnglish);
    _uzCtrl = TextEditingController(text: widget.initialUzbek);
  }

  @override
  void dispose() {
    _enCtrl.dispose();
    _uzCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Lug'atimga qo'shish",
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF1A1A2E))),
            const SizedBox(height: 16),

            _field("🇬🇧 Inglizcha", _enCtrl),
            const SizedBox(height: 12),
            _field("🇺🇿 O'zbekcha", _uzCtrl),
            const SizedBox(height: 12),

            // Yodlandi toggle
            InkWell(
              onTap: () => setState(() => _learned = !_learned),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: _learned ? const Color(0xFFE8F5E9) : const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _learned ? const Color(0xFF43A047) : const Color(0xFFDDDDDD),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(_learned ? Icons.check_circle : Icons.radio_button_unchecked,
                        color: _learned ? const Color(0xFF43A047) : const Color(0xFFBBBBBB),
                        size: 20),
                    const SizedBox(width: 10),
                    Text(
                      _learned ? "Yodlandi deb belgilash" : "Yodlanmadi (standart)",
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: _learned ? const Color(0xFF43A047) : const Color(0xFF666666)),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Bekor"),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _saving ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A1A2E),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: _saving
                        ? const SizedBox(width: 18, height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text("Qo'shish", style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController ctrl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF888888))),
        const SizedBox(height: 4),
        TextField(
          controller: ctrl,
          style: const TextStyle(fontSize: 15),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFF7F7F7),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
      ],
    );
  }

  Future<void> _save() async {
    final uz = _uzCtrl.text.trim();
    final en = _enCtrl.text.trim();
    if (uz.isEmpty || en.isEmpty) return;
    setState(() => _saving = true);
    await widget.onSave(uz, en, _learned);
    if (mounted) Navigator.pop(context);
  }
}
