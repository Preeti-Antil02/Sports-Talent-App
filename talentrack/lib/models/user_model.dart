class UserModel {
  final String id;
  final String phoneNumber;
  final String name;
  final String email;
  final UserType userType;
  final DateTime createdAt;
  final List<String> badges;
  final int totalScore;
  final Map<String, int> skillScores;

  const UserModel({
    required this.id,
    required this.phoneNumber,
    required this.name,
    required this.email,
    required this.userType,
    required this.createdAt,
    this.badges = const [],
    this.totalScore = 0,
    this.skillScores = const {},
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'phoneNumber': phoneNumber,
    'name': name,
    'email': email,
    'userType': userType.name,
    'createdAt': createdAt.millisecondsSinceEpoch,
    'badges': badges,
    'totalScore': totalScore,
    'skillScores': skillScores,
  };

  factory UserModel.fromMap(Map<String, dynamic> map) => UserModel(
    id: map['id'],
    phoneNumber: map['phoneNumber'],
    name: map['name'],
    email: map['email'],
    userType: UserType.values.byName(map['userType']),
    createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
    badges: List<String>.from(map['badges'] ?? []),
    totalScore: map['totalScore'] ?? 0,
    skillScores: Map<String, int>.from(map['skillScores'] ?? {}),
  );

  UserModel copyWith({
    String? id,
    String? phoneNumber,
    String? name,
    String? email,
    UserType? userType,
    DateTime? createdAt,
    List<String>? badges,
    int? totalScore,
    Map<String, int>? skillScores,
  }) => UserModel(
    id: id ?? this.id,
    phoneNumber: phoneNumber ?? this.phoneNumber,
    name: name ?? this.name,
    email: email ?? this.email,
    userType: userType ?? this.userType,
    createdAt: createdAt ?? this.createdAt,
    badges: badges ?? this.badges,
    totalScore: totalScore ?? this.totalScore,
    skillScores: skillScores ?? this.skillScores,
  );
}

enum UserType { athlete, authority }