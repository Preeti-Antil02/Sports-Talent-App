import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talenttrack/models/performance_model.dart';
import 'package:talenttrack/models/user_model.dart';

class StorageService {
  static const String _performancesKey = 'performances';
  static const String _badgesKey = 'badges';

  static String jsonEncode(Map<String, dynamic> data) => json.encode(data);
  static Map<String, dynamic> jsonDecode(String data) => json.decode(data);

  // Video storage
  static Future<String> getVideoStoragePath() async {
    final directory = await getApplicationDocumentsDirectory();
    final videosDir = Directory('${directory.path}/videos');
    if (!await videosDir.exists()) {
      await videosDir.create(recursive: true);
    }
    return videosDir.path;
  }

  static Future<File> saveVideoFile(String sourcePath, String fileName) async {
    final videoDir = await getVideoStoragePath();
    final targetPath = '$videoDir/$fileName';
    final sourceFile = File(sourcePath);
    return await sourceFile.copy(targetPath);
  }

  // Performance data
  static Future<List<PerformanceModel>> getPerformances(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final performancesJson = prefs.getStringList('${_performancesKey}_$userId') ?? [];
    return performancesJson.map((json) => PerformanceModel.fromMap(jsonDecode(json))).toList();
  }

  static Future<void> savePerformance(PerformanceModel performance) async {
    final prefs = await SharedPreferences.getInstance();
    final performances = await getPerformances(performance.userId);
    performances.add(performance);
    final performancesJson = performances.map((p) => jsonEncode(p.toMap())).toList();
    await prefs.setStringList('${_performancesKey}_${performance.userId}', performancesJson);
  }

  static Future<void> updatePerformance(PerformanceModel performance) async {
    final prefs = await SharedPreferences.getInstance();
    final performances = await getPerformances(performance.userId);
    final index = performances.indexWhere((p) => p.id == performance.id);
    if (index != -1) {
      performances[index] = performance;
      final performancesJson = performances.map((p) => jsonEncode(p.toMap())).toList();
      await prefs.setStringList('${_performancesKey}_${performance.userId}', performancesJson);
    }
  }

  // Badge management
  static Future<void> addBadge(String userId, String badge) async {
    final prefs = await SharedPreferences.getInstance();
    final badges = prefs.getStringList('${_badgesKey}_$userId') ?? [];
    if (!badges.contains(badge)) {
      badges.add(badge);
      await prefs.setStringList('${_badgesKey}_$userId', badges);
    }
  }

  static Future<List<String>> getBadges(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList('${_badgesKey}_$userId') ?? [];
  }

  // Sample performance data
  static List<PerformanceModel> getSamplePerformances(String userId) => [
    PerformanceModel(
      id: 'perf_1',
      userId: userId,
      skillId: 'speed',
      videoPath: '/sample/speed_run.mp4',
      timestamp: DateTime.now().subtract(const Duration(days: 2)),
      metrics: {'Sprint Time': 12.5, 'Max Speed': 28.3, 'Acceleration': 8.7},
      score: 85,
      feedback: 'Excellent speed! Work on your starting position for better acceleration.',
      status: PerformanceStatus.reviewed,
    ),
    PerformanceModel(
      id: 'perf_2',
      userId: userId,
      skillId: 'strength',
      videoPath: '/sample/strength_training.mp4',
      timestamp: DateTime.now().subtract(const Duration(days: 5)),
      metrics: {'Max Weight': 120.0, 'Reps': 8.0, 'Endurance': 7.5},
      score: 78,
      feedback: 'Good form! Try to increase the rep count for better endurance.',
      status: PerformanceStatus.reviewed,
    ),
    PerformanceModel(
      id: 'perf_3',
      userId: userId,
      skillId: 'agility',
      videoPath: '/sample/agility_drill.mp4',
      timestamp: DateTime.now().subtract(const Duration(days: 1)),
      metrics: {'Cone Drill Time': 15.8, 'Direction Changes': 12.0, 'Balance': 9.2},
      score: 92,
      feedback: 'Outstanding agility! Your direction changes are very smooth.',
      status: PerformanceStatus.approved,
    ),
  ];
}