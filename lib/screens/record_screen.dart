import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uuid/uuid.dart';

import '../models/entry.dart';
import '../services/storage_service.dart';

enum RecordType { morning, evening }

class RecordScreen extends StatefulWidget {
  final RecordType type;
  const RecordScreen({Key? key, required this.type}) : super(key: key);

  @override
  State<RecordScreen> createState() => _RecordScreenState();
}

class _RecordScreenState extends State<RecordScreen> {
  CameraController? _controller;
  bool _isRecording = false;
  bool _noCamera = false;   // simulator/izin yoksa fallback
  int _remaining = 120;     // 2 dakika

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final cam = await Permission.camera.request();
    final mic = await Permission.microphone.request();
    if (!cam.isGranted || !mic.isGranted) {
      setState(() => _noCamera = true);
      return;
    }

    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() => _noCamera = true);
        return;
      }
      final front = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );
      _controller = CameraController(
        front,
        ResolutionPreset.medium,
        enableAudio: true,
      );
      await _controller!.initialize();
      if (mounted) setState(() {});
    } catch (_) {
      setState(() => _noCamera = true);
    }
  }

  Future<void> _start() async {
    setState(() {
      _isRecording = true;
      _remaining = 120;
    });

    if (!_noCamera && _controller?.value.isInitialized == true) {
      await _controller!.startVideoRecording();
    }

    Timer.periodic(const Duration(seconds: 1), (t) async {
      if (!mounted) { t.cancel(); return; }
      if (_remaining <= 0) {
        t.cancel();
        await _stop();
      } else {
        setState(() => _remaining--);
      }
    });
  }

  Future<void> _stop() async {
    File? savedFile;

    if (_noCamera || _controller == null || !_controller!.value.isRecordingVideo) {
      final dir = await getApplicationDocumentsDirectory();
      final f = File('${dir.path}/${DateTime.now().millisecondsSinceEpoch}_SIMULATED.txt');
      await f.writeAsString('Simulated recording on simulator.');
      savedFile = f;
    } else {
      final xfile = await _controller!.stopVideoRecording();
      final dir = await getApplicationDocumentsDirectory();
      final out = File('${dir.path}/${DateTime.now().millisecondsSinceEpoch}.mp4');
      await File(xfile.path).copy(out.path);
      savedFile = out;
    }

    final entry = Entry(
      id: const Uuid().v4(),
      createdAt: DateTime.now(),
      type: widget.type == RecordType.morning ? 'morning' : 'evening',
      durationSec: 120 - _remaining,
      videoPath: savedFile.path,
    );
    await StorageService.upsert(entry);

    if (!mounted) return;
    setState(() => _isRecording = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Saved: ${savedFile.path.split('/').last}')),
    );
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.type == RecordType.morning ? 'Morning Talk' : 'Evening Talk';
    final mm = (_remaining ~/ 60).toString().padLeft(2, '0');
    final ss = (_remaining % 60).toString().padLeft(2, '0');

    final timerChip = Positioned(
      top: 24, right: 24,
      child: Chip(label: Text('$mm:$ss')),
    );

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: _noCamera
          ? Stack(children: [
              const Center(
                child: Text(
                  'Simulator mode: no camera.\nTimer will run and a simulated file will be saved.',
                  textAlign: TextAlign.center,
                ),
              ),
              timerChip,
            ])
          : (_controller?.value.isInitialized == true
              ? Stack(children: [
                  Center(
                    child: Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.rotationY(3.1415926),
                      child: CameraPreview(_controller!),
                    ),
                  ),
                  timerChip,
                ])
              : const Center(child: CircularProgressIndicator())),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton.icon(
            onPressed: _isRecording ? _stop : _start,
            icon: Icon(_isRecording ? Icons.stop : Icons.fiber_manual_record),
            label: Text(_isRecording ? 'Stop & Save' : 'Start Recording'),
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(54)),
          ),
        ),
      ),
    );
  }
}


