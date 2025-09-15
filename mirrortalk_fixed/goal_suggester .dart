// lib/services/goal_suggester.dart
// Lightweight EN-first goal extractor from a free-form transcript.
// Simple heuristic for MVP; we can swap to LLM later without UI changes.

class GoalSuggester {
  static List<String> suggest(String text, {int maxGoals = 3}) {
    if (text.trim().isEmpty) return [];
    final cleaned = text
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'\.+'), '.')
        .trim();

    // Split by sentences.
    final sentences = cleaned
        .split(RegExp(r'[.!?]+\s*'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    final List<String> candidates = [];

    for (var s in sentences) {
      final lower = s.toLowerCase();

      // Common intent markers / verbs
      final patterns = <String>[
        'do ',
        'finish',
        'start',
        'complete',
        'walk',
        'run',
        'call',
        'write',
        'read',
        'meditate',
        'work out',
        'gym',
        'buy',
        'shop',
        'plan',
        'clean',
        'wash',
        'prepare',
        'email',
        'study',
        'research',
        'today ',
        'tomorrow ',
        'now ',
      ];

      final looksLikeGoal = patterns.any((p) => lower.contains(p));
      if (looksLikeGoal) {
        var g = s;

        // Strip leading time adverbs
        g = g.replaceAll(
            RegExp(r'^(today|tomorrow|now)[:,]?\s*', caseSensitive: false), '');

        if (g.length > 80) g = g.substring(0, 80).trim() + '…';
        candidates.add(_toImperative(g));
      }
    }

    // Fallback: take first sentences if nothing matched
    if (candidates.isEmpty) {
      candidates.addAll(sentences.take(maxGoals));
    }

    // Dedup & clamp
    final seen = <String>{};
    final unique = <String>[];
    for (final c in candidates) {
      final key = c.toLowerCase();
      if (seen.add(key)) unique.add(c);
      if (unique.length >= maxGoals) break;
    }
    return unique;
  }

  static String _toImperative(String s) {
    // Rough imperative normalization for EN
    s = s.replaceAll(
        RegExp(r'^(i|i will|i should|i need to)\s+', caseSensitive: false), '');
    s = s
        .replaceAll(
            RegExp(r'\b(quickly|maybe|probably|i guess)\b',
                caseSensitive: false),
            '')
        .trim();
    return s;
  }
}
