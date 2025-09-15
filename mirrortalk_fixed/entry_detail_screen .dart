// lib/screens/entry_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/entry.dart';

class EntryDetailScreen extends StatefulWidget {
  final Entry entry;
  const EntryDetailScreen({super.key, required this.entry});

  @override
  State<EntryDetailScreen> createState() => _EntryDetailScreenState();
}

class _EntryDetailScreenState extends State<EntryDetailScreen> {
  late TextEditingController _txt;
  late TextEditingController _tagCtrl;
  late List<String> _tags;

  @override
  void initState() {
    super.initState();
    _txt = TextEditingController(text: widget.entry.transcript ?? '');
    _tagCtrl = TextEditingController();
    _tags = List<String>.from(widget.entry.tags);
  }

  @override
  void dispose() {
    _txt.dispose();
    _tagCtrl.dispose();
    super.dispose();
  }

  void _addTagFromInput() {
    final t = _tagCtrl.text.trim();
    if (t.isEmpty) return;
    setState(() => _tags.add(t));
    _tagCtrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    final when = DateFormat('EEE, MMM d • HH:mm').format(widget.entry.createdAt);
    return Scaffold(
      appBar: AppBar(title: const Text('Entry Detail')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Text('Type: ${widget.entry.type.name.toUpperCase()}'),
            Text('When: $when'),
            const SizedBox(height: 12),
            TextField(
              controller: _txt,
              minLines: 4,
              maxLines: 10,
              decoration: const InputDecoration(
                labelText: 'Transcript',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _tags.map((t) => Chip(label: Text(t))).toList(),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _tagCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Add tag',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _addTagFromInput(),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(onPressed: _addTagFromInput, child: const Text('Add'))
              ],
            ),
          ],
        ),
      ),
    );
  }
}
