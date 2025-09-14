// lib/screens/entry_detail_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

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
  late TextEditingController _tagCtrl;
  late List<String> _tags;

  VideoPlayerController? _video;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _txt = TextEditingController(text: widget.entry.transcript ?? '');
    _tagCtrl = TextEditingController();
    _tags = List<String>.from(widget.entry.tags);

    _initVideoIfAny();
  }

  Future<void> _initVideoIfAny() async {
    final path = widget.entry.videoPath;
    if (path == null || path.isEmpty) return;
    final f = File(path);
    if (!await f.exists()) return;

    final c = VideoPlayerController.file(f);
    await c.initialize();
    setState(() => _video = c);
  }

  @override
  void dispose() {
    _video?.dispose();
    _txt.dispose();
    _tagCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
  setState(() => _saving = true);

  final updated = widget.entry.copyWith(
    transcript: _txt.text.trim().isEmpty ? null : _txt.text.trim(),
    tags: _tags,
  );

  await StorageService.upsert(updated);

  if (!mounted) return;
  setState(() => _saving = false);

  Navigator.pop(context, true); // sadece 1 kez, true ile dön
}


  void _addTagFromInput() {
    final t = _tagCtrl.text.trim();
    if (t.isEmpty) return;
    if (_tags.contains(t)) {
      _tagCtrl.clear();
      return;
    }
    setState(() => _tags.add(t));
    _tagCtrl.clear();
  }

  void _removeTag(String t) {
    setState(() => _tags.remove(t));
  }

  Widget _tagEditor() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SizedBox(height: 16),
      Text('Tags', style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 8),

      // Giriş + Ekle butonu / Klavyeden enter ile de ekler
      Row(
        children: [
          Expanded(
            child: TextField(
              controller: _tagCtrl,
              decoration: const InputDecoration(
                hintText: 'Add a tag and press Enter',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onSubmitted: (_) => _addTagFromInput(),
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: _addTagFromInput,
            child: const Text('Add'),
          ),
        ],
      ),

      const SizedBox(height: 12),
      _tagChips(),
    ],
  );
}

Widget _tagChips() {
  if (_tags.isEmpty) {
    return const Text(
      'No tags yet.',
      style: TextStyle(color: Colors.black54),
    );
  }

  return Wrap(
    spacing: 8,
    runSpacing: 8,
    children: _tags.map((t) {
      return Chip(
        label: Text(t),
        deleteIcon: const Icon(Icons.close),
        onDeleted: () => _removeTag(t),
      );
    }).toList(),
  );
}


  Widget _videoPlayer() {
    final c = _video;
    if (c == null || !c.value.isInitialized) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AspectRatio(
          aspectRatio: c.value.aspectRatio == 0 ? 16 / 9 : c.value.aspectRatio,
          child: VideoPlayer(c),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            FilledButton.icon(
              onPressed: () {
                if (c.value.isPlaying) {
                  c.pause();
                } else {
                  c.play();
                }
                setState(() {});
              },
              icon: Icon(c.value.isPlaying ? Icons.pause : Icons.play_arrow),
              label: Text(c.value.isPlaying ? 'Pause' : 'Play'),
            ),
            const SizedBox(width: 12),
            Text(
              '${widget.entry.type.name.toUpperCase()}'
              ' · ${widget.entry.durationSec}s',
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final created = widget.entry.createdAt;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Entry'),
      ),
      body: SafeArea(
        child: _saving
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                children: [
                  // Üst bilgi
                  Text(
                    '${widget.entry.type.name.toUpperCase()} '
                    '• ${created.year}-${created.month.toString().padLeft(2, '0')}-${created.day.toString().padLeft(2, '0')} '
                    '${created.hour.toString().padLeft(2, '0')}:${created.minute.toString().padLeft(2, '0')}',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(color: Colors.black54),
                  ),
                  const SizedBox(height: 12),

                  // Video (varsa)
                  _videoPlayer(),
                  if (_video != null) const SizedBox(height: 16),

                  // Transcript
                  Text('Transcript', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  TextField(
                    
                    controller: _txt,
                    maxLines: 6,
                    decoration: const InputDecoration(
                      hintText: 'What did you talk about?',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  _tagEditor(),

                  // Tags
                  Text('Tags', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: -6,
                    children: [
                      for (final t in _tags)
                        Chip(
                          label: Text(t),
                          onDeleted: () => _removeTag(t),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _tagCtrl,
                          decoration: const InputDecoration(
                            hintText: 'Add tag',
                            border: OutlineInputBorder(),
                          ),
                          onSubmitted: (_) => _addTagFromInput(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: _addTagFromInput,
                        child: const Text('Add'),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: _save,
                    icon: const Icon(Icons.save_outlined),
                    label: const Text('Save'),
                  ),
                ],
              ),
      ),
    );
  }
}

