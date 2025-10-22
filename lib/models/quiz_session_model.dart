class QuizSession {
  final String id;
  final String quizId;
  final String studentId;
  final DateTime startedAt;
  final DateTime? completedAt;
  final int? score;
  final int? totalPoints;

  QuizSession({
    required this.id,
    required this.quizId,
    required this.studentId,
    required this.startedAt,
    this.completedAt,
    this.score,
    this.totalPoints,
  });

  factory QuizSession.fromJson(Map<String, dynamic> json) {
    return QuizSession(
      id: json['id'] as String,
      quizId: json['quiz_id'] as String,
      studentId: json['student_id'] as String,
      startedAt: DateTime.parse(json['started_at'] as String),
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
      score: json['score'] as int?,
      totalPoints: json['total_points'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'quiz_id': quizId,
      'student_id': studentId,
      'started_at': startedAt.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'score': score,
      'total_points': totalPoints,
    };
  }

  bool get isCompleted => completedAt != null;

  double get percentage {
    if (totalPoints == null || score == null || totalPoints == 0) return 0.0;
    return (score! / totalPoints!) * 100;
  }

  QuizSession copyWith({
    String? id,
    String? quizId,
    String? studentId,
    DateTime? startedAt,
    DateTime? completedAt,
    int? score,
    int? totalPoints,
  }) {
    return QuizSession(
      id: id ?? this.id,
      quizId: quizId ?? this.quizId,
      studentId: studentId ?? this.studentId,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      score: score ?? this.score,
      totalPoints: totalPoints ?? this.totalPoints,
    );
  }
}

class StudentAnswer {
  final String id;
  final String sessionId;
  final String questionId;
  final String? selectedOptionId;
  final String? textAnswer;
  final bool? isCorrect;
  final int? pointsEarned;

  StudentAnswer({
    required this.id,
    required this.sessionId,
    required this.questionId,
    this.selectedOptionId,
    this.textAnswer,
    this.isCorrect,
    this.pointsEarned,
  });

  factory StudentAnswer.fromJson(Map<String, dynamic> json) {
    return StudentAnswer(
      id: json['id'] as String,
      sessionId: json['session_id'] as String,
      questionId: json['question_id'] as String,
      selectedOptionId: json['selected_option_id'] as String?,
      textAnswer: json['text_answer'] as String?,
      isCorrect: json['is_correct'] as bool?,
      pointsEarned: json['points_earned'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'session_id': sessionId,
      'question_id': questionId,
      'selected_option_id': selectedOptionId,
      'text_answer': textAnswer,
      'is_correct': isCorrect,
      'points_earned': pointsEarned,
    };
  }

  StudentAnswer copyWith({
    String? id,
    String? sessionId,
    String? questionId,
    String? selectedOptionId,
    String? textAnswer,
    bool? isCorrect,
    int? pointsEarned,
  }) {
    return StudentAnswer(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      questionId: questionId ?? this.questionId,
      selectedOptionId: selectedOptionId ?? this.selectedOptionId,
      textAnswer: textAnswer ?? this.textAnswer,
      isCorrect: isCorrect ?? this.isCorrect,
      pointsEarned: pointsEarned ?? this.pointsEarned,
    );
  }
}