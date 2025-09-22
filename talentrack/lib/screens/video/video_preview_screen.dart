import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:talenttrack/models/skill_model.dart';
import 'package:talenttrack/models/performance_model.dart';
import 'package:talenttrack/services/auth_service.dart';
import 'package:talenttrack/services/storage_service.dart';

class VideoPreviewScreen extends StatefulWidget {
  final String videoPath;
  final SkillModel skill;

  const VideoPreviewScreen({
    super.key,
    required this.videoPath,
    required this.skill,
  });

  @override
  State<VideoPreviewScreen> createState() => _VideoPreviewScreenState();
}

class _VideoPreviewScreenState extends State<VideoPreviewScreen> {
  VideoPlayerController? _videoController;
  bool _isInitialized = false;
  bool _isSubmitting = false;
  final TextEditingController _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeVideoPlayer();
  }

  Future<void> _initializeVideoPlayer() async {
    _videoController = VideoPlayerController.file(File(widget.videoPath));

    try {
      await _videoController!.initialize();
      await _videoController!.setLooping(true);
      setState(() => _isInitialized = true);
    } catch (e) {
      debugPrint('Error initializing video player: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back_rounded),
                    style: IconButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.surface,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Review Recording',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          widget.skill.name,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Video Player
            Expanded(
              flex: 3,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: _isInitialized && _videoController != null
                      ? Stack(
                    alignment: Alignment.center,
                    children: [
                      AspectRatio(
                        aspectRatio: _videoController!.value.aspectRatio,
                        child: VideoPlayer(_videoController!),
                      ),

                      // Play/Pause Button
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            if (_videoController!.value.isPlaying) {
                              _videoController!.pause();
                            } else {
                              _videoController!.play();
                            }
                          });
                        },
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.7),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _videoController!.value.isPlaying
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 40,
                          ),
                        ),
                      ),
                    ],
                  ).animate().scale(duration: 600.ms, curve: Curves.elasticOut)
                      : const Center(child: CircularProgressIndicator()),
                ),
              ),
            ),

            // Notes Section
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Add Notes (Optional)',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 16),

                    Expanded(
                      child: TextField(
                        controller: _notesController,
                        maxLines: null,
                        expands: true,
                        textAlignVertical: TextAlignVertical.top,
                        decoration: InputDecoration(
                          hintText: 'Describe your performance, goals, or any observations...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Theme.of(context).colorScheme.primary,
                              width: 2,
                            ),
                          ),
                          contentPadding: const EdgeInsets.all(16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Action Buttons
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Retake'),
                    ),
                  ),

                  const SizedBox(width: 16),

                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitPerformance,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                          : const Text(
                        'Submit for Review',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitPerformance() async {
    setState(() => _isSubmitting = true);

    try {
      final user = await AuthService.getCurrentUser();
      if (user == null) return;

      // Save video file
      final fileName = 'performance_${DateTime.now().millisecondsSinceEpoch}.mp4';
      final savedFile = await StorageService.saveVideoFile(widget.videoPath, fileName);

      // Generate sample metrics and score for demo
      final metrics = _generateSampleMetrics();
      final score = _calculateScore(metrics);

      // Create performance record
      final performance = PerformanceModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: user.id,
        skillId: widget.skill.id,
        videoPath: savedFile.path,
        timestamp: DateTime.now(),
        metrics: metrics,
        score: score,
        feedback: 'Performance submitted for review. Results will be available soon.',
      );

      await StorageService.savePerformance(performance);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Performance submitted successfully!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );

        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting performance: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  Map<String, double> _generateSampleMetrics() {
    // Generate realistic sample metrics based on skill type
    switch (widget.skill.id) {
      case 'speed':
        return {
          'Sprint Time': 12.5 + (DateTime.now().millisecond % 100) / 100,
          'Max Speed': 28.0 + (DateTime.now().millisecond % 50) / 10,
          'Acceleration': 8.0 + (DateTime.now().millisecond % 30) / 10,
        };
      case 'strength':
        return {
          'Max Weight': 100.0 + (DateTime.now().millisecond % 500) / 10,
          'Reps': (8 + DateTime.now().millisecond % 5).toDouble(),
          'Endurance': 7.0 + (DateTime.now().millisecond % 30) / 10,
        };
      case 'agility':
        return {
          'Cone Drill Time': 15.0 + (DateTime.now().millisecond % 100) / 100,
          'Direction Changes': (10 + DateTime.now().millisecond % 5).toDouble(),
          'Balance': 8.0 + (DateTime.now().millisecond % 30) / 10,
        };
      default:
        return {
          'Performance': 75.0 + (DateTime.now().millisecond % 250) / 10,
        };
    }
  }

  int _calculateScore(Map<String, double> metrics) {
    // Simple scoring algorithm - in a real app this would be more sophisticated
    final avgMetric = metrics.values.reduce((a, b) => a + b) / metrics.length;
    return (avgMetric * 0.8 + 20).round().clamp(0, 100);
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _notesController.dispose();
    super.dispose();
  }
}