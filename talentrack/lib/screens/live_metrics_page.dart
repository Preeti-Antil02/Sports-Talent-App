import 'dart:async';
import 'package:flutter/material.dart';
import '../services/backend_service.dart';

class LiveMetricsPage extends StatefulWidget {
  @override
  _LiveMetricsPageState createState() => _LiveMetricsPageState();
}

class _LiveMetricsPageState extends State<LiveMetricsPage> {
  final backendService = BackendService(baseUrl: 'http://10.0.2.2:8000'); // Use emulator IP
  Map<String, dynamic> metrics = {};
  Timer? timer;

  @override
  void initState() {
    super.initState();
    fetchMetrics();
    timer = Timer.periodic(Duration(seconds: 1), (_) => fetchMetrics());
  }

  void fetchMetrics() async {
    try {
      final data = await backendService.getMetrics();
      setState(() {
        metrics = data;
      });
    } catch (e) {
      print('Error fetching metrics: $e');
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Live Metrics')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Sit-up Count: ${metrics['situp_count'] ?? 0}', style: TextStyle(fontSize: 24)),
            SizedBox(height: 16),
            Text('Jump Height: ${metrics['jump_height_cm']?.toStringAsFixed(2) ?? 0} cm', style: TextStyle(fontSize: 24)),
            SizedBox(height: 16),
            Text('Anomaly Detected: ${metrics['anomaly_detected'] ?? false}', style: TextStyle(fontSize: 24)),
          ],
        ),
      ),
    );
  }
}
