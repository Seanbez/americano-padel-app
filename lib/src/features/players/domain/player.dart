import 'package:uuid/uuid.dart';

import '../../../core/enums.dart';

/// Represents a player in a tournament
class Player {
  Player({
    String? id,
    required this.name,
    this.gender = Gender.unspecified,
    this.skillRating = 0,
    this.isActive = true,
    DateTime? createdAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  final String id;
  final String name;
  final Gender gender;
  final int skillRating; // 0-5, optional
  final bool isActive;
  final DateTime createdAt;

  Player copyWith({
    String? id,
    String? name,
    Gender? gender,
    int? skillRating,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return Player(
      id: id ?? this.id,
      name: name ?? this.name,
      gender: gender ?? this.gender,
      skillRating: skillRating ?? this.skillRating,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'gender': gender.name,
      'skillRating': skillRating,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Player.fromJson(Map<String, dynamic> json) {
    return Player(
      id: json['id'] as String,
      name: json['name'] as String,
      gender: Gender.values.firstWhere(
        (e) => e.name == json['gender'],
        orElse: () => Gender.unspecified,
      ),
      skillRating: json['skillRating'] as int? ?? 0,
      isActive: json['isActive'] as bool? ?? true,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Player && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Player(id: $id, name: $name, gender: ${gender.shortName})';
}
