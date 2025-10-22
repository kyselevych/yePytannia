import 'package:flutter/material.dart';
import '../../models/quiz_model.dart';
import '../../models/question_model.dart';
import '../../models/quiz_session_model.dart';
import '../../services/database_service.dart';
import '../../theme/app_strings.dart';

class TakeQuizScreen extends StatefulWidget {
  final Quiz quiz;
  final QuizSession session;

  const TakeQuizScreen({
    super.key,
    required this.quiz,
    required this.session,
  });

  @override
  State<TakeQuizScreen> createState() => _TakeQuizScreenState();
}

class _TakeQuizScreenState extends State<TakeQuizScreen> {
  final DatabaseService _databaseService = DatabaseService();
  final PageController _pageController = PageController();

  List<Question> _questions = [];
  final Map<String, String?> _answers = {};
  int _currentQuestionIndex = 0;
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadQuestions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final questions = await _databaseService.getQuizQuestions(widget.quiz.id);
      setState(() {
        _questions = questions;
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  void _answerQuestion(String questionId, String? answer) {
    setState(() {
      _answers[questionId] = answer;
    });
  }

  void _nextQuestion() {
    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() => _currentQuestionIndex++);
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousQuestion() {
    if (_currentQuestionIndex > 0) {
      setState(() => _currentQuestionIndex--);
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _submitQuiz() async {

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppStrings.submitQuiz),
        content: Text(
          '${AppStrings.submitConfirm}\n\n'
          '${AppStrings.answered}: ${_answers.length}/${_questions.length} ${AppStrings.questions}\n'
          '${AppStrings.unansweredWillBeIncorrect}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(AppStrings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(AppStrings.submit),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isSubmitting = true);

    try {

      for (final question in _questions) {
        final answer = _answers[question.id];
        if (answer != null) {
          if (question.questionType == QuestionType.multipleChoice ||
              question.questionType == QuestionType.trueFalse) {
            await _databaseService.submitAnswer(
              sessionId: widget.session.id,
              questionId: question.id,
              selectedOptionId: answer,
            );
          } else {
            await _databaseService.submitAnswer(
              sessionId: widget.session.id,
              questionId: question.id,
              textAnswer: answer,
            );
          }
        }
      }


      final completedSession = await _databaseService.completeQuizSession(widget.session.id);

      if (mounted) {

        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: Text(AppStrings.quizCompleted),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.check_circle,
                  color: Theme.of(context).colorScheme.tertiary,
                  size: 64,
                ),
                const SizedBox(height: 16),
                Text(
                  '${AppStrings.yourScore}: ${completedSession.score}/${completedSession.totalPoints}',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Text(
                  '${completedSession.percentage.toStringAsFixed(1)}%',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: _getScoreColor(completedSession.percentage),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            actions: [
              FilledButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop(true);
                },
                child: Text(AppStrings.continue_),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppStrings.errorSubmittingQuiz}: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.quiz.title)),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Завантаження питань...'),
            ],
          ),
        ),
      );
    }


    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.quiz.title)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 80,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  'Помилка завантаження питань',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  _errorMessage!,
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _loadQuestions,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Спробувати знову'),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Повернутися назад'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.quiz.title)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.quiz_outlined,
                  size: 80,
                  color: Theme.of(context).colorScheme.outline,
                ),
                const SizedBox(height: 16),
                Text(
                  AppStrings.noQuestionsAvailable,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Повернутися назад'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.quiz.title),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Center(
              child: Text(
                '${_currentQuestionIndex + 1}/${_questions.length}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [

          LinearProgressIndicator(
            value: (_currentQuestionIndex + 1) / _questions.length,
            backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
          ),


          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() => _currentQuestionIndex = index);
              },
              itemCount: _questions.length,
              itemBuilder: (context, index) {
                final question = _questions[index];
                return _buildQuestionCard(question);
              },
            ),
          ),


          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(
                top: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
              ),
            ),
            child: Row(
              children: [
                if (_currentQuestionIndex > 0)
                  OutlinedButton.icon(
                    onPressed: _previousQuestion,
                    icon: const Icon(Icons.arrow_back),
                    label: Text(AppStrings.previous),
                  )
                else
                  const SizedBox(width: 120),

                const Spacer(),


                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _questions.asMap().entries.map((entry) {
                        final index = entry.key;
                        final question = entry.value;
                        final isAnswered = _answers.containsKey(question.id);
                        final isCurrent = index == _currentQuestionIndex;

                        return Semantics(
                          label: 'Питання ${index + 1}${isCurrent ? ' (поточне)' : ''}${isAnswered ? ' (відповіли)' : ''}',
                          button: true,
                          child: GestureDetector(
                            onTap: () {
                              setState(() => _currentQuestionIndex = index);
                              _pageController.animateToPage(
                                index,
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            },
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isCurrent
                                    ? Theme.of(context).primaryColor
                                    : isAnswered
                                        ? Colors.green
                                        : Colors.grey[300],
                              ),
                              child: Center(
                                child: Text(
                                  '${index + 1}',
                                  style: TextStyle(
                                    color: isCurrent || isAnswered
                                        ? Colors.white
                                        : Colors.grey[600],
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),

                const Spacer(),

                if (_currentQuestionIndex < _questions.length - 1)
                  FilledButton.icon(
                    onPressed: _nextQuestion,
                    icon: const Icon(Icons.arrow_forward),
                    label: Text(AppStrings.next),
                  )
                else
                  FilledButton.icon(
                    onPressed: _isSubmitting ? null : _submitQuiz,
                    icon: _isSubmitting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check),
                    label: Text(AppStrings.submit),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(Question question) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              Text(
                question.questionText,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),


              if (question.questionType == QuestionType.multipleChoice)
                _buildMultipleChoiceOptions(question)
              else if (question.questionType == QuestionType.trueFalse)
                _buildTrueFalseOptions(question)
              else
                _buildTextAnswerField(question),

              const SizedBox(height: 16),


              Row(
                children: [
                  Icon(Icons.star, color: Colors.amber[600], size: 16),
                  const SizedBox(width: 4),
                  Text(
                    '${question.points} ${question.points == 1 ? 'бал' : question.points < 5 ? 'бали' : 'балів'}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMultipleChoiceOptions(Question question) {
    final selectedOptionId = _answers[question.id];

    return Column(
      children: question.options.map((option) {
        final isSelected = selectedOptionId == option.id;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            onTap: () => _answerQuestion(question.id, option.id),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(
                  color: isSelected
                      ? Theme.of(context).primaryColor
                      : Colors.grey[300]!,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(8),
                color: isSelected
                    ? Theme.of(context).primaryColor.withOpacity(0.1)
                    : null,
              ),
              child: Row(
                children: [
                  Radio<String>(
                    value: option.id,
                    groupValue: selectedOptionId,
                    onChanged: (value) => _answerQuestion(question.id, value),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      option.optionText,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTrueFalseOptions(Question question) {
    final selectedOptionId = _answers[question.id];

    return Column(
      children: question.options.map((option) {
        final isSelected = selectedOptionId == option.id;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            onTap: () => _answerQuestion(question.id, option.id),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(
                  color: isSelected
                      ? Theme.of(context).primaryColor
                      : Colors.grey[300]!,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(8),
                color: isSelected
                    ? Theme.of(context).primaryColor.withOpacity(0.1)
                    : null,
              ),
              child: Row(
                children: [
                  Radio<String>(
                    value: option.id,
                    groupValue: selectedOptionId,
                    onChanged: (value) => _answerQuestion(question.id, value),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      option.optionText,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTextAnswerField(Question question) {
    return TextFormField(
      initialValue: _answers[question.id],
      onChanged: (value) => _answerQuestion(question.id, value),
      decoration: const InputDecoration(
        labelText: 'Ваша відповідь',
        hintText: 'Введіть вашу відповідь тут...',
        border: OutlineInputBorder(),
        alignLabelWithHint: true,
      ),
      maxLines: 4,
      textCapitalization: TextCapitalization.sentences,
    );
  }

  Color _getScoreColor(double percentage) {
    if (percentage >= 80) return Colors.green;
    if (percentage >= 60) return Colors.orange;
    return Colors.red;
  }
}