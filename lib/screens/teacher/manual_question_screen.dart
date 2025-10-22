import 'package:flutter/material.dart';
import '../../models/quiz_model.dart';
import '../../models/question_model.dart';
import '../../services/database_service.dart';










class ManualQuestionScreen extends StatefulWidget {
  final Quiz quiz;

  const ManualQuestionScreen({
    super.key,
    required this.quiz,
  });

  @override
  State<ManualQuestionScreen> createState() => _ManualQuestionScreenState();
}

class _ManualQuestionScreenState extends State<ManualQuestionScreen> {
  final DatabaseService _databaseService = DatabaseService();
  final PageController _pageController = PageController();
  final List<QuestionBuilder> _questions = [];

  int _currentQuestionIndex = 0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _addNewQuestion();
  }

  @override
  void dispose() {
    _pageController.dispose();
    for (final question in _questions) {
      question.dispose();
    }
    super.dispose();
  }

  void _addNewQuestion() {
    setState(() {
      _questions.add(QuestionBuilder(
        orderIndex: _questions.length,
        onDelete: () => _deleteQuestion(_questions.length - 1),
      ));
    });
  }

  void _deleteQuestion(int index) {
    if (_questions.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Потрібно щонайменше одне питання')),
      );
      return;
    }

    setState(() {
      _questions[index].dispose();
      _questions.removeAt(index);


      for (int i = 0; i < _questions.length; i++) {

      }


      if (_currentQuestionIndex >= _questions.length) {
        _currentQuestionIndex = _questions.length - 1;
        _pageController.animateToPage(
          _currentQuestionIndex,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _navigateToQuestion(int index) {
    setState(() {
      _currentQuestionIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _saveQuestions() async {

    for (int i = 0; i < _questions.length; i++) {
      if (!_questions[i].isValid()) {
        _navigateToQuestion(i);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Будь ласка, заповніть питання ${i + 1}')),
        );
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
      for (final questionBuilder in _questions) {
        final question = await _databaseService.createQuestion(
          quizId: widget.quiz.id,
          questionText: questionBuilder.questionController.text.trim(),
          questionType: questionBuilder.selectedType,
          points: questionBuilder.points,
          orderIndex: _questions.indexOf(questionBuilder),
          isAiGenerated: false,
        );


        if (questionBuilder.selectedType == QuestionType.multipleChoice) {
          final options = <Map<String, dynamic>>[];
          for (int i = 0; i < questionBuilder.optionControllers.length; i++) {
            final optionText = questionBuilder.optionControllers[i].text.trim();
            if (optionText.isNotEmpty) {
              options.add({
                'text': optionText,
                'isCorrect': questionBuilder.correctAnswerIndex == i,
                'orderIndex': i,
              });
            }
          }
          if (options.isNotEmpty) {
            await _databaseService.createAnswerOptions(
              questionId: question.id,
              options: options,
            );
          }
        } else if (questionBuilder.selectedType == QuestionType.trueFalse) {

          await _databaseService.createAnswerOptions(
            questionId: question.id,
            options: [
              {
                'text': 'True',
                'isCorrect': questionBuilder.trueFalseAnswer == true,
                'orderIndex': 0,
              },
              {
                'text': 'False',
                'isCorrect': questionBuilder.trueFalseAnswer == false,
                'orderIndex': 1,
              },
            ],
          );
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Успішно додано ${_questions.length} питань!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Помилка збереження питань: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Додати питання до ${widget.quiz.title}'),
        actions: [
          TextButton.icon(
            onPressed: _isLoading ? null : _saveQuestions,
            icon: const Icon(Icons.save),
            label: const Text('Зберегти'),
          ),
        ],
      ),
      body: Column(
        children: [

          Container(
            height: 80,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _questions.length + 1,
                    itemBuilder: (context, index) {
                      if (index == _questions.length) {

                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: SizedBox(
                            width: 60,
                            child: OutlinedButton(
                              onPressed: () {
                                _addNewQuestion();
                                _navigateToQuestion(_questions.length - 1);
                              },
                              style: OutlinedButton.styleFrom(
                                padding: EdgeInsets.zero,
                                shape: const CircleBorder(),
                              ),
                              child: const Icon(Icons.add),
                            ),
                          ),
                        );
                      }

                      final isActive = index == _currentQuestionIndex;
                      final isComplete = _questions[index].isValid();

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: SizedBox(
                          width: 60,
                          child: FilledButton(
                            onPressed: () => _navigateToQuestion(index),
                            style: FilledButton.styleFrom(
                              backgroundColor: isActive
                                  ? Theme.of(context).primaryColor
                                  : isComplete
                                      ? Colors.green[400]
                                      : Colors.grey[300],
                              foregroundColor: isActive || isComplete
                                  ? Colors.white
                                  : Colors.black87,
                              padding: EdgeInsets.zero,
                              shape: const CircleBorder(),
                            ),
                            child: Text('${index + 1}'),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Text(
                  'Питання ${_currentQuestionIndex + 1} з ${_questions.length}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),


          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentQuestionIndex = index;
                });
              },
              itemCount: _questions.length,
              itemBuilder: (context, index) {
                return _questions[index];
              },
            ),
          ),


          if (_isLoading)
            const LinearProgressIndicator()
          else
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Text(
                    '${_questions.length} ${_questions.length == 1 ? 'питання' : _questions.length < 5 ? 'питання' : 'питань'}',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  const Spacer(),
                  FilledButton.icon(
                    onPressed: _saveQuestions,
                    icon: const Icon(Icons.save),
                    label: const Text('Зберегти всі питання'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class QuestionBuilder extends StatefulWidget {
  final int orderIndex;
  final VoidCallback onDelete;

  QuestionBuilder({
    super.key,
    required this.orderIndex,
    required this.onDelete,
  });

  final TextEditingController questionController = TextEditingController();
  final List<TextEditingController> optionControllers = List.generate(4, (_) => TextEditingController());

  QuestionType selectedType = QuestionType.multipleChoice;
  int points = 1;
  int correctAnswerIndex = 0;
  bool? trueFalseAnswer;

  bool isValid() {
    if (questionController.text.trim().isEmpty) return false;

    switch (selectedType) {
      case QuestionType.multipleChoice:
        final nonEmptyOptions = optionControllers
            .where((controller) => controller.text.trim().isNotEmpty)
            .length;

        if (nonEmptyOptions < 2) return false;

        return correctAnswerIndex < optionControllers.length &&
               optionControllers[correctAnswerIndex].text.trim().isNotEmpty;
      case QuestionType.trueFalse:
        return trueFalseAnswer != null;
      case QuestionType.openText:
        return true;
    }
  }

  void dispose() {
    questionController.dispose();
    for (final controller in optionControllers) {
      controller.dispose();
    }
  }

  @override
  State<QuestionBuilder> createState() => _QuestionBuilderState();
}

class _QuestionBuilderState extends State<QuestionBuilder> {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Row(
            children: [
              Expanded(
                child: Text(
                  'Питання ${widget.orderIndex + 1}',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                onPressed: widget.onDelete,
                icon: const Icon(Icons.delete),
                color: Colors.red,
                tooltip: 'Видалити питання',
              ),
            ],
          ),

          const SizedBox(height: 16),


          TextFormField(
            controller: widget.questionController,
            decoration: const InputDecoration(
              labelText: 'Текст питання',
              hintText: 'Введіть ваше питання тут...',
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
            maxLines: 3,
            textCapitalization: TextCapitalization.sentences,
          ),

          const SizedBox(height: 16),


          Text(
            'Тип питання',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),

          Wrap(
            spacing: 8,
            children: QuestionType.values.map((type) {
              final isSelected = widget.selectedType == type;
              return ChoiceChip(
                selected: isSelected,
                label: Text(_getQuestionTypeLabel(type)),
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      widget.selectedType = type;

                      widget.correctAnswerIndex = 0;
                      widget.trueFalseAnswer = null;
                    });
                  }
                },
              );
            }).toList(),
          ),

          const SizedBox(height: 16),


          Row(
            children: [
              Text(
                'Бали: ',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 16),
              ...List.generate(5, (index) {
                final points = index + 1;
                final isSelected = widget.points == points;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    selected: isSelected,
                    label: Text('$points'),
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          widget.points = points;
                        });
                      }
                    },
                  ),
                );
              }),
            ],
          ),

          const SizedBox(height: 24),


          _buildTypeSpecificContent(),
        ],
      ),
    );
  }

  Widget _buildTypeSpecificContent() {
    switch (widget.selectedType) {
      case QuestionType.multipleChoice:
        return _buildMultipleChoiceOptions();
      case QuestionType.trueFalse:
        return _buildTrueFalseOptions();
      case QuestionType.openText:
        return _buildOpenTextInfo();
    }
  }

  Widget _buildMultipleChoiceOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Варіанти відповідей',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Додайте щонайменше 2 варіанти і виберіть правильну відповідь:',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 16),

        ...List.generate(4, (index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Radio<int>(
                  value: index,
                  groupValue: widget.correctAnswerIndex,
                  onChanged: (value) {
                    if (value != null && widget.optionControllers[index].text.trim().isNotEmpty) {
                      setState(() {
                        widget.correctAnswerIndex = value;
                      });
                    }
                  },
                ),
                Expanded(
                  child: TextFormField(
                    controller: widget.optionControllers[index],
                    decoration: InputDecoration(
                      labelText: 'Варіант ${String.fromCharCode(65 + index)}',
                      hintText: 'Введіть текст варіанту...',
                      border: const OutlineInputBorder(),
                      suffixIcon: widget.optionControllers[index].text.trim().isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                setState(() {
                                  widget.optionControllers[index].clear();
                                  if (widget.correctAnswerIndex == index) {
                                    widget.correctAnswerIndex = 0;
                                  }
                                });
                              },
                            )
                          : null,
                    ),
                    onChanged: (value) {
                      setState(() {

                        if (value.trim().isNotEmpty) {
                          final hasOtherOptions = widget.optionControllers
                              .asMap()
                              .entries
                              .where((entry) => entry.key != index)
                              .any((entry) => entry.value.text.trim().isNotEmpty);

                          if (!hasOtherOptions) {
                            widget.correctAnswerIndex = index;
                          }
                        }
                      });
                    },
                    textCapitalization: TextCapitalization.sentences,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildTrueFalseOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Правильна відповідь',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),

        Column(
          children: [
            RadioListTile<bool>(
              title: const Text('Правда'),
              value: true,
              groupValue: widget.trueFalseAnswer,
              onChanged: (value) {
                setState(() {
                  widget.trueFalseAnswer = value;
                });
              },
              contentPadding: EdgeInsets.zero,
            ),
            RadioListTile<bool>(
              title: const Text('Неправда'),
              value: false,
              groupValue: widget.trueFalseAnswer,
              onChanged: (value) {
                setState(() {
                  widget.trueFalseAnswer = value;
                });
              },
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOpenTextInfo() {
    return Card(
      color: Colors.blue[50],
      child: const Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.info, color: Colors.blue),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Питання з відкритою відповіддю потребують ручної перевірки. Студенти вводитимуть свої відповіді вільно.',
                style: TextStyle(color: Colors.blue),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getQuestionTypeLabel(QuestionType type) {
    switch (type) {
      case QuestionType.multipleChoice:
        return 'Множинний вибір';
      case QuestionType.trueFalse:
        return 'Правда/Неправда';
      case QuestionType.openText:
        return 'Відкрита відповідь';
    }
  }
}