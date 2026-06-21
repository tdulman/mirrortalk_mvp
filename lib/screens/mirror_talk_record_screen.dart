import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:video_player/video_player.dart';

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
  CameraController? _cameraController;
  VideoPlayerController? _reviewController;
  Timer? _timer;

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

  bool get _isReviewing => _recordedFile != null;

  @override
  void initState() {
    super.initState();
    _prepareCamera();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _cameraController?.dispose();
    _reviewController?.dispose();
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
        ResolutionPreset.high,
        enableAudio: true,
      );
      await controller.initialize();

      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _cameraController = controller;
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
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) return;

    if (_recording) {
      final file = await controller.stopVideoRecording();
      _timer?.cancel();
      final started = _startedAt;
      final duration =
          started == null ? Duration.zero : DateTime.now().difference(started);
      setState(() {
        _recording = false;
        _recordedFile = file;
        _duration = duration;
      });
      await _prepareReview(file);
      HapticFeedback.lightImpact();
      return;
    }

    await _reviewController?.dispose();
    _reviewController = null;
    await controller.startVideoRecording();
    setState(() {
      _recording = true;
      _recordedFile = null;
      _startedAt = DateTime.now();
      _duration = Duration.zero;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final started = _startedAt;
      if (!mounted || started == null) return;
      setState(() => _duration = DateTime.now().difference(started));
    });
    HapticFeedback.mediumImpact();
  }

  Future<void> _prepareReview(XFile file) async {
    final controller = VideoPlayerController.file(File(file.path));
    await controller.initialize();
    await controller.setLooping(true);
    if (!mounted) {
      await controller.dispose();
      return;
    }
    setState(() => _reviewController = controller);
  }

  Future<void> _togglePlayback() async {
    final controller = _reviewController;
    if (controller == null || !controller.value.isInitialized) return;
    if (controller.value.isPlaying) {
      await controller.pause();
    } else {
      await controller.play();
    }
    if (mounted) setState(() {});
  }

  Future<void> _retake() async {
    await _reviewController?.dispose();
    _reviewController = null;
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
      _noteCtrl.clear();
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

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final controller = _cameraController;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.mirrorTalkTitle),
        actions: [
          if (_isReviewing)
            TextButton(
              onPressed: _saving ? null : _retake,
              child: Text(l10n.mirrorTalkRetake),
            ),
        ],
      ),
      body: SafeArea(
        child: _loading
            ? _LoadingState(text: l10n.mirrorTalkPreparingCamera)
            : _error != null || controller == null
                ? _ErrorState(message: _error ?? l10n.mirrorTalkNoCamera)
                : _isReviewing
                    ? _ReviewView(
                        controller: _reviewController,
                        duration: _formatDuration(_duration),
                        noteController: _noteCtrl,
                        saving: _saving,
                        onTogglePlayback: _togglePlayback,
                        onRetake: _retake,
                        onSave: _save,
                      )
                    : _RecordingView(
                        controller: controller,
                        recording: _recording,
                        duration: _formatDuration(_duration),
                        onToggleRecording: _toggleRecording,
                      ),
      ),
    );
  }
}

class _RecordingView extends StatelessWidget {
  final CameraController controller;
  final bool recording;
  final String duration;
  final Future<void> Function() onToggleRecording;

  const _RecordingView({
    required this.controller,
    required this.recording,
    required this.duration,
    required this.onToggleRecording,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final prompt = DateTime.now().hour < 15
        ? l10n.mirrorTalkPromptMorning
        : l10n.mirrorTalkPromptEvening;

    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.xs,
              AppSpacing.lg,
              AppSpacing.md,
            ),
            child: _CameraFrame(
              controller: controller,
              recording: recording,
              duration: duration,
              prompt: prompt,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: Column(
            children: [
              Text(
                l10n.mirrorTalkRecordingHint,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.inkMuted,
                    ),
              ),
              const SizedBox(height: AppSpacing.md),
              _RecordButton(
                recording: recording,
                onPressed: onToggleRecording,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CameraFrame extends StatelessWidget {
  final CameraController controller;
  final bool recording;
  final String duration;
  final String prompt;

  const _CameraFrame({
    required this.controller,
    required this.recording,
    required this.duration,
    required this.prompt,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ColoredBox(
            color: Colors.black,
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: controller.value.previewSize?.height ?? 1,
                height: controller.value.previewSize?.width ?? 1,
                child: CameraPreview(controller),
              ),
            ),
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black54,
                  Colors.transparent,
                  Colors.black54,
                ],
              ),
            ),
          ),
          Positioned(
            left: AppSpacing.md,
            right: AppSpacing.md,
            top: AppSpacing.md,
            child: Row(
              children: [
                if (recording) const _RecordingPill(),
                const Spacer(),
                _TimePill(text: duration),
              ],
            ),
          ),
          Positioned(
            left: AppSpacing.md,
            right: AppSpacing.md,
            bottom: AppSpacing.md,
            child: Text(
              prompt,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    height: 1.1,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecordButton extends StatelessWidget {
  final bool recording;
  final Future<void> Function() onPressed;

  const _RecordButton({
    required this.recording,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Semantics(
      button: true,
      label: recording
          ? l10n.mirrorTalkStopRecording
          : l10n.mirrorTalkStartRecording,
      child: GestureDetector(
        onTap: onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 76,
          height: 76,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: recording ? AppColors.danger : Colors.white,
            border: Border.all(
              color: recording ? AppColors.danger : AppColors.primary,
              width: 4,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Icon(
            recording ? Icons.stop_rounded : Icons.fiber_manual_record,
            color: recording ? Colors.white : AppColors.danger,
            size: recording ? 34 : 30,
          ),
        ),
      ),
    );
  }
}

class _ReviewView extends StatelessWidget {
  final VideoPlayerController? controller;
  final String duration;
  final TextEditingController noteController;
  final bool saving;
  final Future<void> Function() onTogglePlayback;
  final Future<void> Function() onRetake;
  final Future<void> Function() onSave;

  const _ReviewView({
    required this.controller,
    required this.duration,
    required this.noteController,
    required this.saving,
    required this.onTogglePlayback,
    required this.onRetake,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.xs,
        AppSpacing.lg,
        AppSpacing.xl,
      ),
      children: [
        Text(
          l10n.mirrorTalkReviewTitle,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          l10n.mirrorTalkReviewPrompt,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.inkMuted,
                height: 1.3,
              ),
        ),
        const SizedBox(height: AppSpacing.md),
        _VideoReviewPanel(
          controller: controller,
          duration: duration,
          onTogglePlayback: onTogglePlayback,
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: noteController,
          minLines: 4,
          maxLines: 7,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            labelText: l10n.mirrorTalkTranscriptLabel,
            hintText: l10n.mirrorTalkTranscriptHint,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: [
            const Icon(
              Icons.lock_outline,
              size: 16,
              color: AppColors.inkMuted,
            ),
            const SizedBox(width: AppSpacing.xxs),
            Expanded(
              child: Text(
                l10n.mirrorTalkVideoKeptSevenDays,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.inkMuted,
                    ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: saving ? null : onRetake,
                child: Text(l10n.mirrorTalkRetake),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: FilledButton(
                onPressed: saving ? null : onSave,
                child: saving
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(l10n.mirrorTalkSaveReflection),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _VideoReviewPanel extends StatelessWidget {
  final VideoPlayerController? controller;
  final String duration;
  final Future<void> Function() onTogglePlayback;

  const _VideoReviewPanel({
    required this.controller,
    required this.duration,
    required this.onTogglePlayback,
  });

  @override
  Widget build(BuildContext context) {
    final videoController = controller;
    final ready =
        videoController != null && videoController.value.isInitialized;
    final playing = ready && videoController.value.isPlaying;
    final l10n = AppLocalizations.of(context);

    return AspectRatio(
      aspectRatio: 3 / 4,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(
              color: Colors.black,
              child: ready
                  ? FittedBox(
                      fit: BoxFit.cover,
                      child: SizedBox(
                        width: videoController.value.size.width,
                        height: videoController.value.size.height,
                        child: VideoPlayer(videoController),
                      ),
                    )
                  : const Center(child: CircularProgressIndicator()),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.24),
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.45),
                  ],
                ),
              ),
            ),
            Positioned(
              top: AppSpacing.md,
              right: AppSpacing.md,
              child: _TimePill(text: duration),
            ),
            Center(
              child: IconButton.filled(
                onPressed: ready ? onTogglePlayback : null,
                iconSize: 34,
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.9),
                  foregroundColor: AppColors.ink,
                ),
                icon: Icon(
                  playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                ),
              ),
            ),
            Positioned(
              left: AppSpacing.md,
              right: AppSpacing.md,
              bottom: AppSpacing.md,
              child: Text(
                l10n.mirrorTalkTapToPlay,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimePill extends StatelessWidget {
  final String text;
  const _TimePill({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.48),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w700,
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
