class ClassModel {
  final String id;
  final String teacherId;
  final String name;
  final String accessCode;
  final DateTime createdAt;

  ClassModel({
    required this.id,
    required this.teacherId,
    required this.name,
    required this.accessCode,
    required this.createdAt,
  });

  factory ClassModel.fromJson(Map<String, dynamic> json) {
    return ClassModel(
      id: json['id'] as String,
      teacherId: json['teacher_id'] as String,
      name: json['name'] as String,
      accessCode: json['access_code'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'teacher_id': teacherId,
      'name': name,
      'access_code': accessCode,
      'created_at': createdAt.toIso8601String(),
    };
  }

  ClassModel copyWith({
    String? id,
    String? teacherId,
    String? name,
    String? accessCode,
    DateTime? createdAt,
  }) {
    return ClassModel(
      id: id ?? this.id,
      teacherId: teacherId ?? this.teacherId,
      name: name ?? this.name,
      accessCode: accessCode ?? this.accessCode,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class ClassStudent {
  final String id;
  final String classId;
  final String studentId;
  final DateTime joinedAt;

  ClassStudent({
    required this.id,
    required this.classId,
    required this.studentId,
    required this.joinedAt,
  });

  factory ClassStudent.fromJson(Map<String, dynamic> json) {
    return ClassStudent(
      id: json['id'] as String,
      classId: json['class_id'] as String,
      studentId: json['student_id'] as String,
      joinedAt: DateTime.parse(json['joined_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'class_id': classId,
      'student_id': studentId,
      'joined_at': joinedAt.toIso8601String(),
    };
  }
}