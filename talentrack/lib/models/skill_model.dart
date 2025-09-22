class SkillModel {
  final String id;
  final String name;
  final String description;
  final String iconUrl;
  final SkillCategory category;
  final List<String> metrics;

  const SkillModel({
    required this.id,
    required this.name,
    required this.description,
    required this.iconUrl,
    required this.category,
    required this.metrics,
  });

  static List<SkillModel> defaultSkills = [
    SkillModel(
      id: 'speed',
      name: 'Speed',
      description: 'Track your running speed and acceleration',
      iconUrl: 'https://pixabay.com/get/g4d1f9d5044febd6d7a971699a1cd5260d232c9bcef1c96669796d941e55ba80f88bbda6a8fc85e8527fdda9eab742fc81d1ebcc362c442766c482047244a2dd5_1280.jpg',
      category: SkillCategory.physical,
      metrics: ['Sprint Time', 'Max Speed', 'Acceleration'],
    ),
    SkillModel(
      id: 'strength',
      name: 'Strength',
      description: 'Build and track your physical strength',
      iconUrl: 'https://pixabay.com/get/g996158f90bcff60bb9e87b0e7f3183d470ec434d9f09167515bf200f7bb7f8cd8dc1e7df2e57c46d25d34de6d0e70ad46cf07fbfc2f56cf2906a14f42f301c43_1280.jpg',
      category: SkillCategory.physical,
      metrics: ['Max Weight', 'Reps', 'Endurance'],
    ),
    SkillModel(
      id: 'agility',
      name: 'Agility',
      description: 'Improve your movement and coordination',
      iconUrl: 'https://pixabay.com/get/gb451c3177d03d148fc3deb018ad4701b6bf0157b417c9b1e4fad3e20748070c86b38baddc57c319294a5c97b327a78a1d82c920ae898c3ea3c630563b518f02d_1280.jpg',
      category: SkillCategory.coordination,
      metrics: ['Cone Drill Time', 'Direction Changes', 'Balance'],
    ),
    SkillModel(
      id: 'stamina',
      name: 'Stamina',
      description: 'Build cardiovascular endurance',
      iconUrl: 'https://pixabay.com/get/g188ae257785861e53192ce0366f2a81e8ca5b7b1ed0ea2e786f127d9565dd9d8bad23bda2d121f3623da2dc52596de8798c2c5af3aab5961be4d4976e95d1a25_1280.jpg',
      category: SkillCategory.endurance,
      metrics: ['Distance', 'Time', 'Heart Rate'],
    ),
    SkillModel(
      id: 'flexibility',
      name: 'Flexibility',
      description: 'Enhance your range of motion',
      iconUrl: 'https://pixabay.com/get/g4b9e0b3d43e08fe511d27b2adc70d6b6410dbac8fdbfb3bb0d8a96e9725aa11fe9366274431a633a5ac47cd07328051bd6f56af749c06b1e6b444c5dae1d3b22_1280.jpg',
      category: SkillCategory.mobility,
      metrics: ['Range of Motion', 'Hold Time', 'Comfort Level'],
    ),
    SkillModel(
      id: 'coordination',
      name: 'Coordination',
      description: 'Master complex movement patterns',
      iconUrl: 'https://pixabay.com/get/gb451c3177d03d148fc3deb018ad4701b6bf0157b417c9b1e4fad3e20748070c86b38baddc57c319294a5c97b327a78a1d82c920ae898c3ea3c630563b518f02d_1280.jpg',
      category: SkillCategory.coordination,
      metrics: ['Precision', 'Timing', 'Multi-limb Control'],
    ),
  ];

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'description': description,
    'iconUrl': iconUrl,
    'category': category.name,
    'metrics': metrics,
  };

  factory SkillModel.fromMap(Map<String, dynamic> map) => SkillModel(
    id: map['id'],
    name: map['name'],
    description: map['description'],
    iconUrl: map['iconUrl'],
    category: SkillCategory.values.byName(map['category']),
    metrics: List<String>.from(map['metrics']),
  );
}

enum SkillCategory { physical, endurance, coordination, mobility }