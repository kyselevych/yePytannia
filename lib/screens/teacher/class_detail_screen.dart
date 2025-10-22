import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/class_model.dart';
import '../../models/quiz_model.dart';
import '../../services/database_service.dart';
import '../../widgets/quick_quiz_creator.dart';
import 'create_quiz_screen.dart';
import 'quiz_detail_screen.dart';

class ClassDetailScreen extends StatefulWidget {
  final ClassModel classModel;

  const ClassDetailScreen({
    super.key,
    required this.classModel,
  });

  @override
  State<ClassDetailScreen> createState() => _ClassDetailScreenState();
}

class _ClassDetailScreenState extends State<ClassDetailScreen> {
  final DatabaseService _databaseService = DatabaseService();
  List<Quiz> _quizzes = [];
  bool _isLoading = true;
  bool _showQuickCreator = false;

  @override
  void initState() {
    super.initState();
    _loadQuizzes();
  }

  Future<void> _loadQuizzes() async {
    setState(() => _isLoading = true);
    try {
      final quizzes = await _databaseService.getClassQuizzes(widget.classModel.id);
      setState(() {
        _quizzes = quizzes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Помилка завантаження тестів: $e')),
        );
      }
    }
  }

  void _copyAccessCode() {
    Clipboard.setData(ClipboardData(text: widget.classModel.accessCode));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Код доступу скопійовано')),
    );
  }

  Future<void> _createQuiz() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => CreateQuizScreen(classModel: widget.classModel),
      ),
    );

    if (result == true) {
      _loadQuizzes();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.classModel.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadQuizzes,
          ),
        ],
      ),
      body: _showQuickCreator
          ? SingleChildScrollView(
              child: Column(
                children: [

                  Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.school,
                        color: Theme.of(context).primaryColor,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          widget.classModel.name,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.key,
                          color: Theme.of(context).primaryColor,
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Код доступу',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              widget.classModel.accessCode,
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.copy),
                          onPressed: _copyAccessCode,
                          tooltip: 'Копіювати код доступу',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Студенти можуть приєднатися до класу використовуючи код доступу вище.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),


          QuickQuizCreator(
                    classModel: widget.classModel,
                    onQuizCreated: () {
                      _loadQuizzes();
                      setState(() {
                        _showQuickCreator = false;
                      });
                    },
                    onCancel: () {
                      setState(() {
                        _showQuickCreator = false;
                      });
                    },
                  ),
                ],
              ),
            )
          : Column(
              children: [

                Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.school,
                              color: Theme.of(context).primaryColor,
                              size: 28,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                widget.classModel.name,
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.key,
                                color: Theme.of(context).primaryColor,
                              ),
                              const SizedBox(width: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Код доступу',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    widget.classModel.accessCode,
                                    style: const TextStyle(
                                      fontFamily: 'monospace',
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const Spacer(),
                              IconButton(
                                icon: const Icon(Icons.copy),
                                onPressed: _copyAccessCode,
                                tooltip: 'Копіювати код доступу',
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Студенти можуть приєднатися до класу використовуючи код доступу вище.',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    leading: Icon(
                      Icons.auto_awesome,
                      color: Theme.of(context).primaryColor,
                    ),
                    title: const Text('Швидке створення тесту'),
                    subtitle: const Text('Завантажте файл і створіть тест з ШІ'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      setState(() {
                        _showQuickCreator = true;
                      });
                    },
                  ),
                ),


                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            Text(
                              'Вікторини',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(),
                            TextButton.icon(
                              onPressed: () {
                                setState(() {
                                  _showQuickCreator = true;
                                });
                              },
                              icon: const Icon(Icons.auto_awesome),
                              label: const Text('ШІ тест'),
                            ),
                            const SizedBox(width: 8),
                            TextButton.icon(
                              onPressed: _createQuiz,
                              icon: const Icon(Icons.add),
                              label: const Text('Вручну'),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: _isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : _quizzes.isEmpty
                                ? _buildEmptyQuizzesState()
                                : _buildQuizzesList(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createQuiz,
        icon: const Icon(Icons.quiz),
        label: const Text('Створити тест'),
      ),
    );
  }

  Widget _buildEmptyQuizzesState() {
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
            'Поки немає тестів',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Створіть свій перший тест для цього класу',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FilledButton.icon(
                onPressed: () {
                  setState(() {
                    _showQuickCreator = true;
                  });
                },
                icon: const Icon(Icons.auto_awesome),
                label: const Text('ШІ квіза'),
              ),
              const SizedBox(width: 16),
              FilledButton.tonal(
                onPressed: _createQuiz,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.edit),
                    SizedBox(width: 8),
                    Text('Вікторина вручну'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Завантажте файл для генерації ШІ або створіть вручну',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuizzesList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _quizzes.length,
      itemBuilder: (context, index) {
        final quiz = _quizzes[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: _buildQuizStatusIcon(quiz.status),
            title: Text(
              quiz.title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                _buildStatusChip(quiz.status),
                const SizedBox(height: 4),
                Text(
                  'Створено ${_formatDate(quiz.createdAt)}',
                  style: TextStyle(color: Colors.grey[500]),
                ),
              ],
            ),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => QuizDetailScreen(
                    quiz: quiz,
                    classModel: widget.classModel,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildQuizStatusIcon(QuizStatus status) {
    switch (status) {
      case QuizStatus.draft:
        return CircleAvatar(
          backgroundColor: Colors.grey[400],
          child: const Icon(Icons.edit, color: Colors.white),
        );
      case QuizStatus.active:
        return CircleAvatar(
          backgroundColor: Colors.green[400],
          child: const Icon(Icons.play_arrow, color: Colors.white),
        );
      case QuizStatus.completed:
        return CircleAvatar(
          backgroundColor: Colors.blue[400],
          child: const Icon(Icons.check, color: Colors.white),
        );
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
        label = 'Активна';
        break;
      case QuizStatus.completed:
        color = Colors.blue;
        label = 'Завершена';
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