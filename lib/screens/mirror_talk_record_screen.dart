import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/entry.dart';
import '../services/goal_suggester.dart';
import '../services/storage_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

class MirrorTalkRecordScreen extends StatefulWidget {
  const MirrorTalkRecordScreen({super.key});

  @override
  State<MirrorTalkRecordScreen> createState() => _MirrorTalkRecordScreenState();
}

class _MirrorTalkRecordScreenState extends State<MirrorTalkRecordScreen> {
  CameraController? _controller;
  bool _loading = true;
  bool _recording = false;
  bool _saving = false;
  String? _error;
  XFile? _recordedFile;
  DateTime? _startedAt;
  Duration _duration = Duration.zero;
  final _noteCtrl = TextEditingController();

  RecordType get _type {
    final hour = DateTime.now().hour;
    return hour < 15 ? RecordType.morning : RecordType.evening;
  }

  @override
  void initState() {
    super.initState();
    _prepareCamera();
  }

  @override
  void dispose() {
    _controller?.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _prepareCamera() async {
    final l10n = AppLocalizations.of(context);
    setState(() {
      _loading = true;
      _error = null;
    });

    final camera = await Permission.camera.request();
    final microphone = await Permission.microphone.request();
    if (!camera.isGranted || !microphone.isGranted) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = l10n.mirrorTalkPermissionBody;
      });
      _showPermissionDialog();
      return;
    }

    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (!mounted) return;
        setState(() {
          _loading = false;
          _error = l10n.mirrorTalkNoCamera;
        });
        return;
      }

      final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      final controller = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: true,
      );
      await controller.initialize();

      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _controller = controller;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = l10n.mirrorTalkNoCamera;
      });
    }
  }

  Future<void> _showPermissionDialog() async {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context);
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.mirrorTalkPermissionTitle),
        content: Text(l10n.mirrorTalkPermissionBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.mirrorTalkCancel),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await openAppSettings();
            },
            child: Text(l10n.mirrorTalkOpenSettings),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleRecording() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;

    if (_recording) {
      final file = await controller.stopVideoRecording();
      final started = _startedAt;
      setState(() {
        _recording = false;
        _recordedFile = file;
        _duration = started == null
            ? Duration.zero
            : DateTime.now().difference(started);
      });
      HapticFeedback.lightImpact();
      return;
    }

    await controller.startVideoRecording();
    setState(() {
      _recording = true;
      _recordedFile = null;
      _startedAt = DateTime.now();
      _duration = Duration.zero;
    });
    HapticFeedback.mediumImpact();
  }

  Future<void> _retake() async {
    final file = _recordedFile;
    if (file != null) {
      try {
        await File(file.path).delete();
      } catch (_) {
        // Temporary camera files may already be gone.
      }
    }
    setState(() {
      _recordedFile = null;
      _duration = Duration.zero;
    });
  }

  Future<void> _save() async {
    final file = _recordedFile;
    if (file == null || _saving) return;

    setState(() => _saving = true);
    final now = DateTime.now();
    final videoPath = await _persistVideo(file, now);
    final note = _noteCtrl.text.trim();
    final entry = Entry(
      id: now.microsecondsSinceEpoch.toString(),
      type: _type,
      createdAt: now,
      durationSec: _duration.inSeconds,
      transcript: note.isEmpty ? null : note,
      tags: const [],
      videoPath: videoPath,
    );
    await StorageService.appendEntry(entry);

    final suggestions = GoalSuggester.suggest(note, maxGoals: 3);
    if (!mounted) return;
    if (suggestions.isNotEmpty) {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (ctx) => _SuggestionSheet(suggestions: suggestions),
      );
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context).mirrorTalkSaved)),
    );
    Navigator.of(context).pop(true);
  }

  Future<String> _persistVideo(XFile file, DateTime now) async {
    final dir = await getApplicationDocumentsDirectory();
    final videoDir = Directory('${dir.path}/mirror_talk_videos');
    if (!await videoDir.exists()) {
      await videoDir.create(recursive: true);
    }
    final path = '${videoDir.path}/${now.microsecondsSinceEpoch}.mp4';
    await file.saveTo(path);
    return path;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final controller = _controller;
    final prompt = _type == RecordType.morning
        ? l10n.mirrorTalkPromptMorning
        : l10n.mirrorTalkPromptEvening;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.mirrorTalkTitle)),
      body: SafeArea(
        child: _loading
            ? _LoadingState(text: l10n.mirrorTalkPreparingCamera)
            : _error != null || controller == null
                ? _ErrorState(message: _error ?? l10n.mirrorTalkNoCamera)
                : ListView(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    children: [
                      Text(
                        prompt,
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _CameraPanel(
                        controller: controller,
                        recording: _recording,
                        hasRecording: _recordedFile != null,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      if (_recordedFile == null)
                        FilledButton.icon(
                          onPressed: _toggleRecording,
                          icon: Icon(_recording
                              ? Icons.stop
                              : Icons.fiber_manual_record),
                          label: Text(
                            _recording
                                ? l10n.mirrorTalkStopRecording
                                : l10n.mirrorTalkStartRecording,
                          ),
                        )
                      else ...[
                        TextField(
                          controller: _noteCtrl,
                          minLines: 3,
                          maxLines: 6,
                          decoration: InputDecoration(
                            labelText: l10n.mirrorTalkTranscriptLabel,
                            hintText: l10n.mirrorTalkTranscriptHint,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _saving ? null : _retake,
                                child: Text(l10n.mirrorTalkRetake),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: FilledButton(
                                onPressed: _saving ? null : _save,
                                child: Text(l10n.mirrorTalkSaveReflection),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
      ),
    );
  }
}

class _CameraPanel extends StatelessWidget {
  final CameraController controller;
  final bool recording;
  final bool hasRecording;

  const _CameraPanel({
    required this.controller,
    required this.recording,
    required this.hasRecording,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 3 / 4,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          fit: StackFit.expand,
          children: [
            CameraPreview(controller),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.14),
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.18),
                  ],
                ),
              ),
            ),
            if (recording)
              const Positioned(
                top: AppSpacing.md,
                right: AppSpacing.md,
                child: _RecordingPill(),
              ),
            if (hasRecording)
              const Center(
                child: Icon(
                  Icons.check_circle,
                  color: Colors.white,
                  size: 56,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _RecordingPill extends StatelessWidget {
  const _RecordingPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.danger,
        borderRadius: BorderRadius.circular(999),
      ),
      child: const Text(
        'REC',
        style: TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  final String text;
  const _LoadingState({required this.text});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: AppSpacing.md),
          Text(text),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  const _ErrorState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ),
    );
  }
}

class _SuggestionSheet extends StatefulWidget {
  final List<String> suggestions;
  const _SuggestionSheet({required this.suggestions});

  @override
  State<_SuggestionSheet> createState() => _SuggestionSheetState();
}

class _SuggestionSheetState extends State<_SuggestionSheet> {
  late final List<TextEditingController> _controllers;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      3,
      (index) => TextEditingController(
        text:
            widget.suggestions.length > index ? widget.suggestions[index] : '',
      ),
    );
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _apply() async {
    final today = await StorageService.getDaySummary(DateTime.now());
    final goals =
        _controllers.map((controller) => controller.text.trim()).toList();
    await StorageService.upsertDaySummary(today.copyWith(goals: goals));
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.md,
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.goalSuggestionsTitle,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: AppSpacing.sm),
          for (var i = 0; i < _controllers.length; i++) ...[
            TextField(
              controller: _controllers[i],
              decoration:
                  InputDecoration(labelText: l10n.goalSuggestionLabel(i + 1)),
            ),
            const SizedBox(height: AppSpacing.xs),
          ],
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _apply,
              child: Text(l10n.goalSuggestionsApply),
            ),
          ),
        ],
      ),
    );
  }
}
