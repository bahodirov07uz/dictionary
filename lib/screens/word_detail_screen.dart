import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../services/word_provider.dart';
import '../models/api_word.dart';

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
  String _error = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final d = await _api.getDetail(widget.id);
      if (mounted) setState(() { _detail = d; _loading = false; });
      // Save to history
      if (d != null && mounted) {
        context.read<WordProvider>().addToHistory(HistoryItem(
          wordId: d.id,
          word: d.word,
          translations: d.translations,
          viewedAt: DateTime.now(),
        ));
      }
    } catch (e) {
      if (mounted) setState(() { _error = 'Xato: $e'; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F3F7),
      appBar: AppBar(
        title: Text(widget.word, style: const TextStyle(fontWeight: FontWeight.w800)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1A1A2E),
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF1A1A2E)))
          : _error.isNotEmpty
              ? Center(child: Text(_error))
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(d.word,
                        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFF1A1A2E))),
                    if (d.wordClass != null)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1A2E).withOpacity(0.08),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(d.wordClass!,
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF1A1A2E))),
                      ),
                    if (d.wordClassBody != null) ...[
                      const SizedBox(height: 4),
                      Text(d.wordClassBody!, style: const TextStyle(fontSize: 13, color: Color(0xFF888888))),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (d.translations.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: d.translations.map((t) => Chip(
                label: Text(t, style: const TextStyle(fontWeight: FontWeight.w600)),
                backgroundColor: const Color(0xFFE8F5E9),
                side: BorderSide.none,
              )).toList(),
            ),
          ],
        ]),

        // Example
        if (d.example != null) ...[
          const SizedBox(height: 12),
          _sectionTitle("Misol"),
          _card(children: [
            Text(d.example!, style: const TextStyle(fontStyle: FontStyle.italic, color: Color(0xFF444444))),
          ]),
        ],

        // Examples (HTML stripped)
        if (d.examples != null) ...[
          const SizedBox(height: 12),
          _sectionTitle("Ko'proq misollar"),
          _card(children: [
            Text(_stripHtml(d.examples!), style: const TextStyle(color: Color(0xFF444444), height: 1.6)),
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

        // Children (verb forms etc)
        for (final child in d.children) ...[
          const SizedBox(height: 12),
          _sectionTitle("${child.word} (boshqa ma'no)"),
          _card(children: [
            if (child.translations.isNotEmpty)
              Wrap(
                spacing: 8,
                children: child.translations.map((t) => Chip(
                  label: Text(t, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                  backgroundColor: const Color(0xFFE3F2FD),
                  side: BorderSide.none,
                )).toList(),
              ),
            if (child.example != null) ...[
              const SizedBox(height: 8),
              Text(child.example!, style: const TextStyle(fontStyle: FontStyle.italic, color: Color(0xFF555555))),
            ],
            if (child.synonyms != null) ...[
              const SizedBox(height: 8),
              Text("Sinonimlar: ${_stripHtml(child.synonyms!)}",
                  style: const TextStyle(fontSize: 12, color: Color(0xFF888888))),
            ],
          ]),
        ],

        const SizedBox(height: 32),
      ],
    );
  }

  Widget _card({required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, left: 4),
      child: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF888888))),
    );
  }

  String _stripHtml(String html) {
    return html
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .trim();
  }
}
