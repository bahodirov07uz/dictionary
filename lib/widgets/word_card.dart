import 'package:flutter/material.dart';
import '../models/word.dart';
import '../services/word_provider.dart';
import 'package:provider/provider.dart';

class WordCard extends StatelessWidget {
  final Word word;
  final VoidCallback? onTap;

  const WordCard({Key? key, required this.word, this.onTap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final provider = context.read<WordProvider>();

    return Dismissible(
      key: Key('word_${word.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
      ),
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text("O'chirishni tasdiqlang"),
            content: Text('"${word.uzbek}" so\'zini o\'chirasizmi?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text("Bekor qilish"),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text("O'chirish"),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) => provider.deleteWord(word),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: word.isLearned
                ? const Color(0xFFE8F5E9)
                : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: word.isLearned
                  ? const Color(0xFF66BB6A)
                  : const Color(0xFFE0E0E0),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Status indicator
                Container(
                  width: 8,
                  height: 50,
                  decoration: BoxDecoration(
                    color: word.isLearned
                        ? const Color(0xFF43A047)
                        : const Color(0xFFBDBDBD),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 14),
                // Words
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        word.uzbek,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A1A2E),
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        word.english,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
                // Toggle button
                GestureDetector(
                  onTap: () => provider.toggleLearned(word),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: word.isLearned
                          ? const Color(0xFF43A047)
                          : const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: word.isLearned
                            ? const Color(0xFF43A047)
                            : const Color(0xFFBDBDBD),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          word.isLearned ? Icons.check_circle : Icons.radio_button_unchecked,
                          size: 16,
                          color: word.isLearned ? Colors.white : Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          word.isLearned ? "Yodlandi" : "Yodlanmadi",
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: word.isLearned ? Colors.white : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
