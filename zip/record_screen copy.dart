// lib/screens/record_screen.dart
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/entry.dart';
import '../services/storage_service.dart';

class RecordScreen extends StatefulWidget {
  const RecordScreen({super.key, required this.type});

  final RecordType type; // morning / evening

  @override
  State<RecordScreen> createState() => _RecordScreenState();
}

class _RecordScreenState extends State<RecordScreen> with WidgetsBindingObserver {
  CameraController? _controller;
  bool _initializing = true;
  bool _noCamera = false;
  bool _isRecording = false;

  static const int _maxSeconds = 120;
  int _elapsed = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _init();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Kamera hayat döngüsü koruması
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;

    if (state == AppLifecycleState.inactive) {
      controller.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _reinitCamera();
    }
  }

  Future<void> _init() async {
    try {
      // İzinler
      final statuses = await [
        Permission.camera,
        Permission.microphone,
      ].request();

      if (statuses[Permission.camera] != PermissionStatus.granted ||
          statuses[Permission.microphone] != PermissionStatus.granted) {
        setState(() {
          _noCamera = true;
          _initializing = false;
        });
        return;
      }

      await _reinitCamera();
    } catch (_) {
      setState(() {
        _noCamera = true;
        _initializing = false;
      });
    }
  }

  Future<void> _reinitCamera() async {
    try {
      final cams = await availableCameras();
      if (cams.isEmpty) {
        setState(() {
          _noCamera = true;
          _initializing = false;
        });
        return;
      }

      // Ön kamera tercih
      CameraDescription cam =
          cams.firstWhere((c) => c.lensDirection == CameraLensDirection.front,
              orElse: () => cams.first);

      final controller = CameraController(
        cam,
        ResolutionPreset.medium,
        enableAudio: true,
      );
      await controller.initialize();

      if (mounted) {
        setState(() {
          _controller?.dispose();
          _controller = controller;
          _initializing = false;
          _noCamera = false;
        });
      } else {
        // init bitmeden ekran kapandıysa temizle
        controller.dispose();
      }
    } catch (_) {
      setState(() {
        _noCamera = true;
        _initializing = false;
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;

    try {
      await controller.prepareForVideoRecording();
    } catch (_) {
      // iOS dışı platformlarda yok, yoksay.
    }

    await controller.startVideoRecording();

    setState(() {
      _isRecording = true;
      _elapsed = 0;
    });

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) async {
      if (!mounted) return;
      if (_elapsed + 1 >= _maxSeconds) {
        await _stopAndSave(); // otomatik bitir
      } else {
        setState(() => _elapsed++);
      }
    });
  }

  Future<void> _stopAndSave() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;

    _timer?.cancel();

    late final XFile file;
    try {
      file = await controller.stopVideoRecording();
    } catch (_) {
      if (mounted) {
        setState(() {
          _isRecording = false;
        });
      }
      return;
    }

    // Dosyayı uygulama klasörüne taşı
    final dir = await getApplicationDocumentsDirectory();
    final videosDir = Directory(p.join(dir.path, 'videos'));
    if (!await videosDir.exists()) {
      await videosDir.create(recursive: true);
    }
    final ts = DateTime.now().millisecondsSinceEpoch;
    final name =
        '${widget.type.name}_${ts.toString()}${p.extension(file.path).isEmpty ? '.mp4' : p.extension(file.path)}';
    final savedPath = p.join(videosDir.path, name);

    try {
      await file.saveTo(savedPath);
    } catch (_) {
      // Bazı Android/iOS’ta saveTo çalışmazsa elle taşı
      await File(file.path).copy(savedPath);
      try {
        await File(file.path).delete();
      } catch (_) {}
    }

    // Entry oluşturup kaydet
    final entry = Entry(
      id: ts.toString(),
      type: widget.type,
      createdAt: DateTime.now(),
      durationSec: _elapsed,
      transcript: '',
      tags: const [],
      videoPath: savedPath,
    );
    await StorageService.upsert(entry);

    if (!mounted) return;
    setState(() => _isRecording = false);

    // Journal’a “değişti” sinyali gönder
    Navigator.pop(context, true);
  }

  Future<void> _cancelRecording() async {
    final controller = _controller;
    if (controller == null) {
      if (mounted) Navigator.pop(context, false);
      return;
    }
    if (_isRecording) {
      try {
        final tmp = await controller.stopVideoRecording();
        // kaydı at
        try {
          await File(tmp.path).delete();
        } catch (_) {}
      } catch (_) {}
    }
    _timer?.cancel();
    if (mounted) {
      setState(() => _isRecording = false);
      Navigator.pop(context, false);
    }
  }

  String _mmss(int s) {
    final m = (s ~/ 60).toString().padLeft(2, '0');
    final ss = (s % 60).toString().padLeft(2, '0');
    return '$m:$ss';
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.type == RecordType.morning ? 'Morning Talk' : 'Evening Talk';

    return Scaffold(
      appBar: AppBar(
        title: Text(_isRecording ? '$title  •  ${_mmss(_elapsed)}' : title),
        actions: [
          IconButton(
            tooltip: 'Cancel',
            icon: const Icon(Icons.close),
            onPressed: _cancelRecording,
          ),
        ],
      ),
      body: _initializing
          ? const Center(child: CircularProgressIndicator())
          : _noCamera
              ? _NoCamera(onRetry: _init)
              : _controller == null
                  ? const Center(child: Text('Camera not available'))
                  : SafeArea(
                      child: Column(
                        children: [
                          AspectRatio(
                            aspectRatio: _controller!.value.aspectRatio,
                            child: CameraPreview(_controller!),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _isRecording
                                ? 'Recording… ${_mmss(_elapsed)} / ${_mmss(_maxSeconds)}'
                                : 'Max ${_mmss(_maxSeconds)}',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const Spacer(),
                        ],
                      ),
                    ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: _isRecording ? _stopAndSave : _start,
                  icon: Icon(_isRecording ? Icons.stop : Icons.fiber_manual_record),
                  label: Text(_isRecording ? 'Stop & Save' : 'Start Recording'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _cancelRecording,
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Discard'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NoCamera extends StatelessWidget {
  const _NoCamera({required this.onRetry});
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.videocam_off, size: 72, color: Colors.grey),
            const SizedBox(height: 12),
            const Text(
              'Camera or microphone permission is missing.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: onRetry,
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}



