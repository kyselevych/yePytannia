enum QuestionType { multipleChoice, trueFalse, openText }

class Question {
  final String id;
  final String quizId;
  final String questionText;
  final QuestionType questionType;
  final int points;
  final int orderIndex;
  final bool isAiGenerated;
  final List<AnswerOption> options;

  Question({
    required this.id,
    required this.quizId,
    required this.questionText,
    required this.questionType,
    this.points = 1,
    required this.orderIndex,
    this.isAiGenerated = true,
    this.options = const [],
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    QuestionType type = QuestionType.multipleChoice;
    final typeString = json['question_type'] as String?;
    if (typeString != null) {
      switch (typeString) {
        case 'multiple_choice':
          type = QuestionType.multipleChoice;
          break;
        case 'true_false':
          type = QuestionType.trueFalse;
          break;
        case 'open_text':
          type = QuestionType.openText;
          break;
      }
    }

    return Question(
      id: json['id'] as String,
      quizId: json['quiz_id'] as String,
      questionText: json['question_text'] as String,
      questionType: type,
      points: json['points'] as int? ?? 1,
      orderIndex: json['order_index'] as int,
      isAiGenerated: json['is_ai_generated'] as bool? ?? true,
      options: (json['answer_options'] as List<dynamic>?)
              ?.map((option) => AnswerOption.fromJson(option as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    String typeString;
    switch (questionType) {
      case QuestionType.multipleChoice:
        typeString = 'multiple_choice';
        break;
      case QuestionType.trueFalse:
        typeString = 'true_false';
        break;
      case QuestionType.openText:
        typeString = 'open_text';
        break;
    }

    return {
      'id': id,
      'quiz_id': quizId,
      'question_text': questionText,
      'question_type': typeString,
      'points': points,
      'order_index': orderIndex,
      'is_ai_generated': isAiGenerated,
    };
  }

  Question copyWith({
    String? id,
    String? quizId,
    String? questionText,
    QuestionType? questionType,
    int? points,
    int? orderIndex,
    bool? isAiGenerated,
    List<AnswerOption>? options,
  }) {
    return Question(
      id: id ?? this.id,
      quizId: quizId ?? this.quizId,
      questionText: questionText ?? this.questionText,
      questionType: questionType ?? this.questionType,
      points: points ?? this.points,
      orderIndex: orderIndex ?? this.orderIndex,
      isAiGenerated: isAiGenerated ?? this.isAiGenerated,
      options: options ?? this.options,
    );
  }
}

class AnswerOption {
  final String id;
  final String questionId;
  final String optionText;
  final bool isCorrect;
  final int orderIndex;

  AnswerOption({
    required this.id,
    required this.questionId,
    required this.optionText,
    this.isCorrect = false,
    required this.orderIndex,
  });

  factory AnswerOption.fromJson(Map<String, dynamic> json) {
    return AnswerOption(
      id: json['id'] as String,
      questionId: json['question_id'] as String,
      optionText: json['option_text'] as String,
      isCorrect: json['is_correct'] as bool? ?? false,
      orderIndex: json['order_index'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question_id': questionId,
      'option_text': optionText,
      'is_correct': isCorrect,
      'order_index': orderIndex,
    };
  }

  AnswerOption copyWith({
    String? id,
    String? questionId,
    String? optionText,
    bool? isCorrect,
    int? orderIndex,
  }) {
    return AnswerOption(
      id: id ?? this.id,
      questionId: questionId ?? this.questionId,
      optionText: optionText ?? this.optionText,
      isCorrect: isCorrect ?? this.isCorrect,
      orderIndex: orderIndex ?? this.orderIndex,
    );
  }
}