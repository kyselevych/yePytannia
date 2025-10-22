import 'package:flutter/material.dart';
import '../../models/class_model.dart';
import '../../models/quiz_model.dart';
import '../../models/question_model.dart';
import '../../models/quiz_session_model.dart';
import '../../services/database_service.dart';
import '../../widgets/edit_question_dialog.dart';
import 'manual_question_screen.dart';

class QuizDetailScreen extends StatefulWidget {
  final Quiz quiz;
  final ClassModel classModel;

  const QuizDetailScreen({
    super.key,
    required this.quiz,
    required this.classModel,
  });

  @override
  State<QuizDetailScreen> createState() => _QuizDetailScreenState();
}

class _QuizDetailScreenState extends State<QuizDetailScreen>
    with SingleTickerProviderStateMixin {
  final DatabaseService _databaseService = DatabaseService();
  late TabController _tabController;

  List<Question> _questions = [];
  List<QuizSession> _sessions = [];
  bool _isLoadingQuestions = true;
  bool _isLoadingSessions = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadQuestions();
    _loadSessions();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadQuestions() async {
    setState(() => _isLoadingQuestions = true);
    try {
      final questions = await _databaseService.getQuizQuestions(widget.quiz.id);
      setState(() {
        _questions = questions;
        _isLoadingQuestions = false;
      });
    } catch (e) {
      setState(() => _isLoadingQuestions = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Помилка завантаження питань: $e')),
        );
      }
    }
  }

  Future<void> _loadSessions() async {
    setState(() => _isLoadingSessions = true);
    try {
      final sessions = await _databaseService.getQuizSessions(widget.quiz.id);
      setState(() {
        _sessions = sessions;
        _isLoadingSessions = false;
      });
    } catch (e) {
      setState(() => _isLoadingSessions = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Помилка завантаження сесій: $e')),
        );
      }
    }
  }

  Future<void> _toggleQuizStatus() async {
    try {
      final newStatus = widget.quiz.status == QuizStatus.active
          ? QuizStatus.completed
          : QuizStatus.active;

      await _databaseService.updateQuizStatus(widget.quiz.id, newStatus);

      if (mounted) {
        setState(() {

        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newStatus == QuizStatus.active
                  ? 'Вікторину активовано! Студенти тепер можуть її проходити.'
                  : 'Вікторину завершено. Студенти більше не можуть її проходити.',
            ),
            backgroundColor: newStatus == QuizStatus.active ? Colors.green : Colors.blue,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Помилка оновлення статусу квізи: $e')),
        );
      }
    }
  }

  Future<void> _navigateToAddQuestions() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => ManualQuestionScreen(quiz: widget.quiz),
      ),
    );

    if (result == true) {

      _loadQuestions();
    }
  }

  Future<void> _editQuestion(Question question) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => EditQuestionDialog(question: question),
    );

    if (result == true) {

      _loadQuestions();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.quiz.title),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Огляд'),
            Tab(text: 'Питання'),
            Tab(text: 'Результати'),
          ],
        ),
        actions: [
          if (widget.quiz.status != QuizStatus.completed)
            IconButton(
              icon: Icon(
                widget.quiz.status == QuizStatus.active
                    ? Icons.stop
                    : Icons.play_arrow,
              ),
              onPressed: _toggleQuizStatus,
              tooltip: widget.quiz.status == QuizStatus.active
                  ? 'Зупинити квізу'
                  : 'Розпочати квізу',
            ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildQuestionsTab(),
          _buildResultsTab(),
        ],
      ),
      floatingActionButton: _tabController.index == 1 && widget.quiz.status == QuizStatus.draft
          ? FloatingActionButton.extended(
              onPressed: _navigateToAddQuestions,
              icon: const Icon(Icons.add),
              label: const Text('Додати питання'),
              tooltip: 'Додати питання вручну',
            )
          : null,
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _buildQuizStatusIcon(widget.quiz.status),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.quiz.title,
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            _buildStatusChip(widget.quiz.status),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow(Icons.school, 'Клас', widget.classModel.name),
                  _buildInfoRow(Icons.calendar_today, 'Створено',
                      _formatDate(widget.quiz.createdAt)),
                  _buildInfoRow(Icons.quiz, 'Питання', '${_questions.length}'),
                  if (widget.quiz.sourceFileUrl != null)
                    _buildInfoRow(Icons.attach_file, 'Вихідний файл', 'Завантажено'),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),


          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Статистика',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'Всього спроб',
                          '${_sessions.length}',
                          Icons.people,
                          Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          'Завершено',
                          '${_sessions.where((s) => s.isCompleted).length}',
                          Icons.check_circle,
                          Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'Середній бал',
                          _calculateAverageScore(),
                          Icons.trending_up,
                          Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          'Питання',
                          '${_questions.length}',
                          Icons.quiz,
                          Colors.purple,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionsTab() {
    return _isLoadingQuestions
        ? const Center(child: CircularProgressIndicator())
        : _questions.isEmpty
            ? Center(
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
                      'Поки немає питань',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Додайте питання до цієї квізи, щоб почати',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.grey[500],
                      ),
                    ),
                    if (widget.quiz.status == QuizStatus.draft) ...[
                      const SizedBox(height: 24),
                      FilledButton.icon(
                        onPressed: _navigateToAddQuestions,
                        icon: const Icon(Icons.add),
                        label: const Text('Додати питання вручну'),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Або завантажте файл на екрані створення квізи для генерації ШІ',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[500],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _questions.length,
                itemBuilder: (context, index) {
                  final question = _questions[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ExpansionTile(
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Питання ${index + 1}',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          if (widget.quiz.status == QuizStatus.draft)
                            IconButton(
                              onPressed: () => _editQuestion(question),
                              icon: const Icon(Icons.edit),
                              color: Theme.of(context).primaryColor,
                              tooltip: 'Редагувати питання',
                              constraints: const BoxConstraints.tightFor(width: 32, height: 32),
                            ),
                        ],
                      ),
                      subtitle: Text(
                        question.questionText,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                question.questionText,
                                style: const TextStyle(fontSize: 16),
                              ),
                              const SizedBox(height: 12),
                              if (question.options.isNotEmpty) ...[
                                const Text(
                                  'Варіанти відповідей:',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                ...question.options.map((option) => Padding(
                                      padding: const EdgeInsets.only(bottom: 4),
                                      child: Row(
                                        children: [
                                          Icon(
                                            option.isCorrect
                                                ? Icons.check_circle
                                                : Icons.radio_button_unchecked,
                                            color: option.isCorrect
                                                ? Colors.green
                                                : Colors.grey,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(child: Text(option.optionText)),
                                        ],
                                      ),
                                    )),
                              ],
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Chip(
                                    label: Text('${question.points} б'),
                                    backgroundColor: Colors.blue[100],
                                  ),
                                  const SizedBox(width: 8),
                                  if (question.isAiGenerated)
                                    Chip(
                                      label: const Text('Згенеровано ШІ'),
                                      backgroundColor: Colors.purple[100],
                                    ),
                                  const Spacer(),
                                  if (widget.quiz.status == QuizStatus.draft)
                                    TextButton.icon(
                                      onPressed: () => _editQuestion(question),
                                      icon: const Icon(Icons.edit, size: 16),
                                      label: const Text('Редагувати'),
                                      style: TextButton.styleFrom(
                                        foregroundColor: Theme.of(context).primaryColor,
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
  }

  Widget _buildResultsTab() {
    return _isLoadingSessions
        ? const Center(child: CircularProgressIndicator())
        : _sessions.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.analytics_outlined,
                      size: 80,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Поки немає результатів',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Результати студентів з\'являться тут',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _sessions.length,
                itemBuilder: (context, index) {
                  final session = _sessions[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: session.isCompleted
                            ? Colors.green[400]
                            : Colors.orange[400],
                        child: Icon(
                          session.isCompleted ? Icons.check : Icons.hourglass_empty,
                          color: Colors.white,
                        ),
                      ),
                      title: Text('Студент ${session.studentId.substring(0, 8)}...'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Розпочато: ${_formatDateTime(session.startedAt)}'),
                          if (session.isCompleted) ...[
                            Text('Завершено: ${_formatDateTime(session.completedAt!)}'),
                            Text('Оцінка: ${session.score}/${session.totalPoints} (${session.percentage.toStringAsFixed(1)}%)'),
                          ] else
                            const Text('Виконується'),
                        ],
                      ),
                      trailing: session.isCompleted
                          ? Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _getScoreColor(session.percentage),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${session.percentage.toStringAsFixed(0)}%',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            )
                          : const Icon(Icons.more_vert),
                    ),
                  );
                },
              );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: color,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
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
        label = 'Завершено';
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

  String _calculateAverageScore() {
    final completedSessions = _sessions.where((s) => s.isCompleted && s.score != null).toList();
    if (completedSessions.isEmpty) return '0%';

    final average = completedSessions
        .map((s) => s.percentage)
        .reduce((a, b) => a + b) / completedSessions.length;
    return '${average.toStringAsFixed(1)}%';
  }

  Color _getScoreColor(double percentage) {
    if (percentage >= 80) return Colors.green;
    if (percentage >= 60) return Colors.orange;
    return Colors.red;
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatDateTime(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}