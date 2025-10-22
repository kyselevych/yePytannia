import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/class_model.dart';
import '../../models/quiz_model.dart';
import '../../models/quiz_session_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/database_service.dart';
import 'take_quiz_screen.dart';

class QuizListScreen extends StatefulWidget {
  final ClassModel classModel;

  const QuizListScreen({
    super.key,
    required this.classModel,
  });

  @override
  State<QuizListScreen> createState() => _QuizListScreenState();
}

class _QuizListScreenState extends State<QuizListScreen> {
  final DatabaseService _databaseService = DatabaseService();
  List<Quiz> _quizzes = [];
  Map<String, QuizSession?> _sessions = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadQuizzes();
  }

  Future<void> _loadQuizzes() async {
    setState(() => _isLoading = true);
    try {
      final authProvider = context.read<AuthProvider>();
      final userId = authProvider.userProfile?.id;
      if (userId != null) {
        final quizzes = await _databaseService.getClassQuizzes(widget.classModel.id);


        final sessions = <String, QuizSession?>{};
        for (final quiz in quizzes) {
          final session = await _databaseService.getStudentQuizSession(
            quizId: quiz.id,
            studentId: userId,
          );
          sessions[quiz.id] = session;
        }

        setState(() {
          _quizzes = quizzes;
          _sessions = sessions;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Помилка завантаження квіз: $e')),
        );
      }
    }
  }

  Future<void> _startQuiz(Quiz quiz) async {
    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.userProfile?.id;
    if (userId == null) return;

    try {
      QuizSession session;
      final existingSession = _sessions[quiz.id];

      if (existingSession != null && !existingSession.isCompleted) {

        session = existingSession;
      } else {

        session = await _databaseService.startQuizSession(
          quizId: quiz.id,
          studentId: userId,
        );
      }

      if (mounted) {
        final result = await Navigator.of(context).push<bool>(
          MaterialPageRoute(
            builder: (context) => TakeQuizScreen(
              quiz: quiz,
              session: session,
            ),
          ),
        );

        if (result == true) {
          _loadQuizzes();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Помилка запуску квізи: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.classModel.name),
      ),
      body: Column(
        children: [

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.school,
                      color: Theme.of(context).primaryColor,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.classModel.name,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Код доступу: ${widget.classModel.accessCode}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontFamily: 'monospace',
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),


          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _quizzes.isEmpty
                    ? _buildEmptyState()
                    : _buildQuizzesList(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.quiz_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Немає доступних квіз',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ваш вчитель ще не створив жодної квізи',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuizzesList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _quizzes.length,
      itemBuilder: (context, index) {
        final quiz = _quizzes[index];
        final session = _sessions[quiz.id];

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _buildQuizIcon(quiz, session),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            quiz.title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          _buildQuizStatus(quiz, session),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),


                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      'Створено ${_formatDate(quiz.createdAt)}',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),


                if (session != null) ...[
                  const SizedBox(height: 8),
                  if (session.isCompleted) ...[
                    Row(
                      children: [
                        Icon(Icons.score, size: 16, color: Colors.green[600]),
                        const SizedBox(width: 4),
                        Text(
                          'Бали: ${session.score}/${session.totalPoints} (${session.percentage.toStringAsFixed(1)}%)',
                          style: TextStyle(
                            color: Colors.green[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    Row(
                      children: [
                        Icon(Icons.play_circle, size: 16, color: Colors.orange[600]),
                        const SizedBox(width: 4),
                        Text(
                          'В процесі - Продовжити',
                          style: TextStyle(
                            color: Colors.orange[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],

                const SizedBox(height: 16),


                _buildActionButton(quiz, session),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuizIcon(Quiz quiz, QuizSession? session) {
    if (session?.isCompleted == true) {
      return CircleAvatar(
        backgroundColor: Colors.green[400],
        child: const Icon(Icons.check, color: Colors.white),
      );
    } else if (session != null) {
      return CircleAvatar(
        backgroundColor: Colors.orange[400],
        child: const Icon(Icons.play_arrow, color: Colors.white),
      );
    } else if (quiz.status == QuizStatus.active) {
      return CircleAvatar(
        backgroundColor: Colors.blue[400],
        child: const Icon(Icons.quiz, color: Colors.white),
      );
    } else {
      return CircleAvatar(
        backgroundColor: Colors.grey[400],
        child: const Icon(Icons.quiz, color: Colors.white),
      );
    }
  }

  Widget _buildQuizStatus(Quiz quiz, QuizSession? session) {
    if (session?.isCompleted == true) {
      return Chip(
        label: const Text(
          'Завершено',
          style: TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.green[400],
      );
    } else if (session != null) {
      return Chip(
        label: const Text(
          'В процесі',
          style: TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.orange[400],
      );
    } else {
      return _buildStatusChip(quiz.status);
    }
  }

  Widget _buildStatusChip(QuizStatus status) {
    MaterialColor color;
    String label;

    switch (status) {
      case QuizStatus.draft:
        color = Colors.grey;
        label = 'Чернетка';
        break;
      case QuizStatus.active:
        color = Colors.green;
        label = 'Доступна';
        break;
      case QuizStatus.completed:
        color = Colors.blue;
        label = 'Закрита';
        break;
    }

    return Chip(
      label: Text(
        label,
        style: TextStyle(
          color: color[700],
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: color[100],
      side: BorderSide(color: color[300]!),
    );
  }

  Widget _buildActionButton(Quiz quiz, QuizSession? session) {
    if (quiz.status != QuizStatus.active) {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: null,
          child: Text(
            quiz.status == QuizStatus.draft
                ? 'Поки недоступна'
                : 'Вікторина закрита',
          ),
        ),
      );
    }

    if (session?.isCompleted == true) {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: null,
          icon: const Icon(Icons.check_circle),
          label: const Text('Завершено'),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: () => _startQuiz(quiz),
        icon: Icon(session != null ? Icons.play_arrow : Icons.quiz),
        label: Text(session != null ? 'Продовжити квізу' : 'Розпочати квізу'),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'сьогодні';
    } else if (difference.inDays == 1) {
      return 'вчора';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} днів тому';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}