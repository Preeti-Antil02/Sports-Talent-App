class PerformanceModel {
  final String id;
  final String userId;
  final String skillId;
  final String videoPath;
  final DateTime timestamp;
  final Map<String, double> metrics;
  final int score;
  final String feedback;
  final PerformanceStatus status;

  const PerformanceModel({
    required this.id,
    required this.userId,
    required this.skillId,
    required this.videoPath,
    required this.timestamp,
    required this.metrics,
    required this.score,
    required this.feedback,
    this.status = PerformanceStatus.pending,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'userId': userId,
    'skillId': skillId,
    'videoPath': videoPath,
    'timestamp': timestamp.millisecondsSinceEpoch,
    'metrics': metrics,
    'score': score,
    'feedback': feedback,
    'status': status.name,
  };

  factory PerformanceModel.fromMap(Map<String, dynamic> map) => PerformanceModel(
    id: map['id'],
    userId: map['userId'],
    skillId: map['skillId'],
    videoPath: map['videoPath'],
    timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
    metrics: Map<String, double>.from(map['metrics']),
    score: map['score'],
    feedback: map['feedback'],
    status: PerformanceStatus.values.byName(map['status']),
  );

  PerformanceModel copyWith({
    String? id,
    String? userId,
    String? skillId,
    String? videoPath,
    DateTime? timestamp,
    Map<String, double>? metrics,
    int? score,
    String? feedback,
    PerformanceStatus? status,
  }) => PerformanceModel(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    skillId: skillId ?? this.skillId,
    videoPath: videoPath ?? this.videoPath,
    timestamp: timestamp ?? this.timestamp,
    metrics: metrics ?? this.metrics,
    score: score ?? this.score,
    feedback: feedback ?? this.feedback,
    status: status ?? this.status,
  );
}

enum PerformanceStatus { pending, reviewed, approved }