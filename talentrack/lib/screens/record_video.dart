import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';

class LiveMetricsPage extends StatefulWidget {
  const LiveMetricsPage({Key? key}) : super(key: key);

  @override
  State<LiveMetricsPage> createState() => _LiveMetricsPageState();
}

class _LiveMetricsPageState extends State<LiveMetricsPage> {
  CameraController? _controller;
  bool _isRecording = false;
  String? _savedVideoPath;
  Map<String, dynamic>? _mlResults;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    final camera = cameras.first; // Use first camera (usually back)
    _controller = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: true,
    );
    await _controller!.initialize();
    if (mounted) setState(() {});
  }

  Future<String> _getAppVideoPath() async {
    final directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/${DateTime.now().millisecondsSinceEpoch}.mp4';
  }

  Future<void> _startRecording() async {
    if (_controller == null || _controller!.value.isRecordingVideo) return;
    await _controller!.startVideoRecording();
    setState(() => _isRecording = true);
  }

  Future<void> _stopRecording() async {
    if (_controller == null || !_controller!.value.isRecordingVideo) return;

    final XFile videoFile = await _controller!.stopVideoRecording();
    final savedPath = await _getAppVideoPath();
    await videoFile.saveTo(savedPath);

    setState(() {
      _isRecording = false;
      _savedVideoPath = savedPath;
    });

    // Upload to backend
    await _uploadVideo(savedPath);
  }

  Future<void> _uploadVideo(String filePath) async {
    var request = http.MultipartRequest(
      'POST',
      Uri.parse("http://10.0.2.2:8000/upload"), // Emulator IP
    );
    request.files.add(await http.MultipartFile.fromPath('file', filePath));

    var response = await request.send();
    if (response.statusCode == 200) {
      String respStr = await response.stream.bytesToString();
      setState(() {
        _mlResults = jsonDecode(respStr);
      });
      print("✅ Backend response: $_mlResults");
    } else {
      print("❌ Upload failed: ${response.statusCode}");
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Live Metrics")),
      body: Column(
        children: [
          AspectRatio(
            aspectRatio: _controller!.value.aspectRatio,
            child: CameraPreview(_controller!),
          ),
          const SizedBox(height: 20),
          if (_isRecording)
            const Text("Recording...", style: TextStyle(color: Colors.red))
          else
            const Text("Ready to record"),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: _isRecording ? _stopRecording : _startRecording,
                child: Text(_isRecording ? "Stop" : "Record"),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (_mlResults != null)
            Column(
              children: [
                Text("Sit-ups: ${_mlResults!['situp_count']}"),
                Text("Jump height: ${_mlResults!['jump_height_cm']} cm"),
                Text("Anomaly detected: ${_mlResults!['anomaly_detected']}"),
              ],
            ),
          if (_savedVideoPath != null)
            Text("Video stored at: $_savedVideoPath"),
        ],
      ),
    );
  }
}
