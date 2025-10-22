enum QuizStatus { draft, active, completed }

class Quiz {
  final String id;
  final String classId;
  final String title;
  final String? sourceFileUrl;
  final QuizStatus status;
  final DateTime createdAt;

  Quiz({
    required this.id,
    required this.classId,
    required this.title,
    this.sourceFileUrl,
    required this.status,
    required this.createdAt,
  });

  factory Quiz.fromJson(Map<String, dynamic> json) {
    return Quiz(
      id: json['id'] as String,
      classId: json['class_id'] as String,
      title: json['title'] as String,
      sourceFileUrl: json['source_file_url'] as String?,
      status: QuizStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => QuizStatus.draft,
      ),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'class_id': classId,
      'title': title,
      'source_file_url': sourceFileUrl,
      'status': status.name,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Quiz copyWith({
    String? id,
    String? classId,
    String? title,
    String? sourceFileUrl,
    QuizStatus? status,
    DateTime? createdAt,
  }) {
    return Quiz(
      id: id ?? this.id,
      classId: classId ?? this.classId,
      title: title ?? this.title,
      sourceFileUrl: sourceFileUrl ?? this.sourceFileUrl,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}