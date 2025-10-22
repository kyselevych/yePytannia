import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/class_model.dart';
import '../models/quiz_model.dart';
import '../models/question_model.dart';
import '../models/quiz_session_model.dart';
import '../utils/supabase_config.dart';

class DatabaseService {
  static final SupabaseClient _client = SupabaseConfig.client;


  String? getCurrentUserId() {
    return _client.auth.currentUser?.id;
  }


  Future<List<ClassModel>> getTeacherClasses(String teacherId) async {
    try {
      final response = await _client
          .from('classes')
          .select()
          .eq('teacher_id', teacherId)
          .order('created_at', ascending: false);

      return response.map<ClassModel>((json) => ClassModel.fromJson(json)).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<ClassModel> createClass({
    required String teacherId,
    required String name,
  }) async {
    try {
      final response = await _client
          .from('classes')
          .insert({
            'teacher_id': teacherId,
            'name': name,
          })
          .select()
          .single();

      return ClassModel.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  Future<ClassModel?> joinClass(String accessCode, String studentId) async {
    try {

      final classResponse = await _client
          .from('classes')
          .select()
          .eq('access_code', accessCode)
          .maybeSingle();

      if (classResponse == null) return null;

      final classModel = ClassModel.fromJson(classResponse);


      final existingMember = await _client
          .from('class_students')
          .select()
          .eq('class_id', classModel.id)
          .eq('student_id', studentId)
          .maybeSingle();

      if (existingMember == null) {

        await _client.from('class_students').insert({
          'class_id': classModel.id,
          'student_id': studentId,
        });
      }

      return classModel;
    } catch (e) {
      rethrow;
    }
  }

  Future<List<ClassModel>> getStudentClasses(String studentId) async {
    try {
      final response = await _client
          .from('class_students')
          .select('classes(*)')
          .eq('student_id', studentId)
          .order('joined_at', ascending: false);

      return response
          .map<ClassModel>((json) => ClassModel.fromJson(json['classes'] as Map<String, dynamic>))
          .toList();
    } catch (e) {
      rethrow;
    }
  }


  Future<List<Quiz>> getClassQuizzes(String classId) async {
    try {
      final response = await _client
          .from('quizzes')
          .select()
          .eq('class_id', classId)
          .order('created_at', ascending: false);

      return response.map<Quiz>((json) => Quiz.fromJson(json)).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<Quiz> createQuiz({
    required String classId,
    required String title,
    String? sourceFileUrl,
  }) async {
    try {
      final response = await _client
          .from('quizzes')
          .insert({
            'class_id': classId,
            'title': title,
            'source_file_url': sourceFileUrl,
          })
          .select()
          .single();

      return Quiz.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateQuizStatus(String quizId, QuizStatus status) async {
    try {
      await _client
          .from('quizzes')
          .update({'status': status.name})
          .eq('id', quizId);
    } catch (e) {
      rethrow;
    }
  }


  Future<List<Question>> getQuizQuestions(String quizId) async {
    try {
      final response = await _client
          .from('questions')
          .select('*, answer_options(*)')
          .eq('quiz_id', quizId)
          .order('order_index', ascending: true);

      return response.map<Question>((json) => Question.fromJson(json)).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<Question> createQuestion({
    required String quizId,
    required String questionText,
    required QuestionType questionType,
    int points = 1,
    required int orderIndex,
    bool isAiGenerated = false,
  }) async {
    try {
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

      final response = await _client
          .from('questions')
          .insert({
            'quiz_id': quizId,
            'question_text': questionText,
            'question_type': typeString,
            'points': points,
            'order_index': orderIndex,
            'is_ai_generated': isAiGenerated,
          })
          .select()
          .single();

      return Question.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  Future<AnswerOption> createAnswerOption({
    required String questionId,
    required String optionText,
    bool isCorrect = false,
    required int orderIndex,
  }) async {
    try {
      final response = await _client
          .from('answer_options')
          .insert({
            'question_id': questionId,
            'option_text': optionText,
            'is_correct': isCorrect,
            'order_index': orderIndex,
          })
          .select()
          .single();

      return AnswerOption.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  Future<List<AnswerOption>> createAnswerOptions({
    required String questionId,
    required List<Map<String, dynamic>> options,
  }) async {
    try {
      final data = options.map((option) => {
        'question_id': questionId,
        'option_text': option['text'] as String,
        'is_correct': option['isCorrect'] as bool? ?? false,
        'order_index': option['orderIndex'] as int,
      }).toList();

      final response = await _client
          .from('answer_options')
          .insert(data)
          .select();

      return response.map<AnswerOption>((json) => AnswerOption.fromJson(json)).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<Question> updateQuestion({
    required String questionId,
    required String questionText,
    required QuestionType questionType,
    int? points,
  }) async {
    try {
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

      final response = await _client
          .from('questions')
          .update({
            'question_text': questionText,
            'question_type': typeString,
            if (points != null) 'points': points,
          })
          .eq('id', questionId)
          .select('*, answer_options(*)')
          .single();

      return Question.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteAnswerOptions(String questionId) async {
    try {
      await _client
          .from('answer_options')
          .delete()
          .eq('question_id', questionId);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateQuestionWithOptions({
    required String questionId,
    required String questionText,
    required QuestionType questionType,
    int? points,
    List<Map<String, dynamic>>? options,
  }) async {
    try {

      await updateQuestion(
        questionId: questionId,
        questionText: questionText,
        questionType: questionType,
        points: points,
      );


      await deleteAnswerOptions(questionId);


      if (options != null && options.isNotEmpty) {
        await createAnswerOptions(
          questionId: questionId,
          options: options,
        );
      }
    } catch (e) {
      rethrow;
    }
  }


  Future<QuizSession> startQuizSession({
    required String quizId,
    required String studentId,
  }) async {
    try {
      final response = await _client
          .from('quiz_sessions')
          .insert({
            'quiz_id': quizId,
            'student_id': studentId,
          })
          .select()
          .single();

      return QuizSession.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  Future<StudentAnswer> submitAnswer({
    required String sessionId,
    required String questionId,
    String? selectedOptionId,
    String? textAnswer,
  }) async {
    try {
      final response = await _client
          .from('student_answers')
          .upsert({
            'session_id': sessionId,
            'question_id': questionId,
            'selected_option_id': selectedOptionId,
            'text_answer': textAnswer,
          })
          .select()
          .single();

      return StudentAnswer.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  Future<QuizSession> completeQuizSession(String sessionId) async {
    try {

      final response = await _client.functions.invoke(
        'submit-quiz',
        body: {'session_id': sessionId},
      );


      final sessionResponse = await _client
          .from('quiz_sessions')
          .select()
          .eq('id', sessionId)
          .single();

      return QuizSession.fromJson(sessionResponse);
    } catch (e) {
      rethrow;
    }
  }

  Future<List<QuizSession>> getQuizSessions(String quizId) async {
    try {
      final response = await _client
          .from('quiz_sessions')
          .select('*, profiles(full_name)')
          .eq('quiz_id', quizId)
          .order('started_at', ascending: false);

      return response.map<QuizSession>((json) => QuizSession.fromJson(json)).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<QuizSession?> getStudentQuizSession({
    required String quizId,
    required String studentId,
  }) async {
    try {
      final response = await _client
          .from('quiz_sessions')
          .select()
          .eq('quiz_id', quizId)
          .eq('student_id', studentId)
          .maybeSingle();

      return response != null ? QuizSession.fromJson(response) : null;
    } catch (e) {
      rethrow;
    }
  }


  Stream<List<QuizSession>> watchQuizSessions(String quizId) {
    return _client
        .from('quiz_sessions')
        .stream(primaryKey: ['id'])
        .eq('quiz_id', quizId)
        .map((data) => data.map<QuizSession>((json) => QuizSession.fromJson(json)).toList());
  }

  Stream<List<Quiz>> watchClassQuizzes(String classId) {
    return _client
        .from('quizzes')
        .stream(primaryKey: ['id'])
        .eq('class_id', classId)
        .map((data) => data.map<Quiz>((json) => Quiz.fromJson(json)).toList());
  }
}