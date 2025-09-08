import 'dart:io';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../models/entry.dart';
import '../services/storage_service.dart';

class EntryDetailScreen extends StatefulWidget {
  final Entry entry;
  const EntryDetailScreen({super.key, required this.entry});

  @override
  State<EntryDetailScreen> createState() => _EntryDetailScreenState();
}

class _EntryDetailScreenState extends State<EntryDetailScreen> {
  late TextEditingController _txt;
  late List<String> _tags;
  final _tagCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _txt = TextEditingController(text: widget.entry.transcript);
    _tags = List<String>.from(widget.entry.tags);
  }

  Future<void> _save() async {
    final updated =
        widget.entry.copyWith(transcript: _txt.text, tags: _tags);
    await StorageService.upsert(updated);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Saved')));
  }

  void _addTag() {
    final t = _tagCtrl.text.trim();
    if (t.isEmpty) return;
    if (!_tags.contains(t)) {
      setState(() => _tags.add(t));
    }
    _tagCtrl.clear();
  }

  void _removeTag(String t) {
    setState(() => _tags.remove(t));
  }

  Future<void> _shareTranscript() async {
    final text = _txt.text.isEmpty ? '(empty transcript)' : _txt.text;
    await Share.share(text, subject: 'MirrorTalk transcript');
  }

  Future<void> _shareVideo() async {
    final path = widget.entry.videoPath;
    if (path == null || !await File(path).exists()) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No video file found')),
      );
      return;
    }
    await Share.shareXFiles([XFile(path)], text: 'MirrorTalk video');
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.entry;

    return Scaffold(
      appBar: AppBar(
        title: Text('${e.type.toUpperCase()} • ${e.durationSec}s'),
        actions: [
          IconButton(
            tooltip: 'Share transcript',
            icon: const Icon(Icons.ios_share),
            onPressed: _shareTranscript,
          ),
          IconButton(
            tooltip: 'Share video',
            icon: const Icon(Icons.video_file_outlined),
            onPressed: _shareVideo,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Transcript',
              style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          TextField(
            controller: _txt,
            maxLines: 8,
            decoration: const InputDecoration(
              hintText: 'Your transcribed text…',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Tags', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _tags
                .map((t) => Chip(
                      label: Text(t),
                      onDeleted: () => _removeTag(t),
                    ))
                .toList(),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _tagCtrl,
                  decoration: const InputDecoration(
                    hintText: 'Add a tag',
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => _addTag(),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(onPressed: _addTag, child: const Text('Add')),
            ],
          ),
          const SizedBox(height: 16),
          FilledButton(onPressed: _save, child: const Text('Save')),
        ],
      ),
    );
  }
}
