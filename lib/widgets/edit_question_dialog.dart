import 'package:flutter/material.dart';
import '../models/question_model.dart';
import '../services/database_service.dart';









class EditQuestionDialog extends StatefulWidget {
  final Question question;

  const EditQuestionDialog({
    super.key,
    required this.question,
  });

  @override
  State<EditQuestionDialog> createState() => _EditQuestionDialogState();
}

class _EditQuestionDialogState extends State<EditQuestionDialog> {
  final DatabaseService _databaseService = DatabaseService();
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _questionController;
  late QuestionType _selectedType;
  late int _points;
  late List<TextEditingController> _optionControllers;
  late int _correctAnswerIndex;
  late bool? _trueFalseAnswer;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    _questionController = TextEditingController(text: widget.question.questionText);
    _selectedType = widget.question.questionType;
    _points = widget.question.points;


    _optionControllers = List.generate(4, (index) => TextEditingController());
    _correctAnswerIndex = 0;
    _trueFalseAnswer = null;

    if (widget.question.questionType == QuestionType.multipleChoice) {

      for (int i = 0; i < widget.question.options.length && i < 4; i++) {
        _optionControllers[i].text = widget.question.options[i].optionText;
        if (widget.question.options[i].isCorrect) {
          _correctAnswerIndex = i;
        }
      }
    } else if (widget.question.questionType == QuestionType.trueFalse) {

      final trueOption = widget.question.options.firstWhere(
        (option) => option.optionText.toLowerCase() == 'true',
        orElse: () => widget.question.options.first,
      );
      _trueFalseAnswer = trueOption.isCorrect;
    }
  }

  @override
  void dispose() {
    _questionController.dispose();
    for (final controller in _optionControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;


    if (_selectedType == QuestionType.multipleChoice) {
      final nonEmptyOptions = _optionControllers
          .where((controller) => controller.text.trim().isNotEmpty)
          .length;
      if (nonEmptyOptions < 2) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Питання з множинним вибором потребують щонайменше 2 варіанти')),
        );
        return;
      }
      if (_optionControllers[_correctAnswerIndex].text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Будь ласка, виберіть правильну відповідь')),
        );
        return;
      }
    } else if (_selectedType == QuestionType.trueFalse && _trueFalseAnswer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Будь ласка, виберіть Правда або Неправда як правильну відповідь')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      List<Map<String, dynamic>>? options;

      if (_selectedType == QuestionType.multipleChoice) {
        options = [];
        for (int i = 0; i < _optionControllers.length; i++) {
          final optionText = _optionControllers[i].text.trim();
          if (optionText.isNotEmpty) {
            options.add({
              'text': optionText,
              'isCorrect': _correctAnswerIndex == i,
              'orderIndex': i,
            });
          }
        }
      } else if (_selectedType == QuestionType.trueFalse) {
        options = [
          {
            'text': 'Правда',
            'isCorrect': _trueFalseAnswer == true,
            'orderIndex': 0,
          },
          {
            'text': 'Неправда',
            'isCorrect': _trueFalseAnswer == false,
            'orderIndex': 1,
          },
        ];
      }

      await _databaseService.updateQuestionWithOptions(
        questionId: widget.question.id,
        questionText: _questionController.text.trim(),
        questionType: _selectedType,
        points: _points,
        options: options,
      );

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Питання успішно оновлено!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Помилка оновлення питання: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final maxWidth = screenSize.width > 600 ? 600.0 : screenSize.width * 0.9;
    final maxHeight = screenSize.height * 0.85;

    return Dialog(
      child: Container(
        constraints: BoxConstraints(
          maxWidth: maxWidth,
          maxHeight: maxHeight,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.edit,
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Редагувати питання',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),


            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      TextFormField(
                        controller: _questionController,
                        decoration: const InputDecoration(
                          labelText: 'Текст питання',
                          hintText: 'Введіть ваше питання тут...',
                          border: OutlineInputBorder(),
                          alignLabelWithHint: true,
                        ),
                        maxLines: 3,
                        textCapitalization: TextCapitalization.sentences,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Текст питання обов\'язковий';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 24),


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
                          final isSelected = _selectedType == type;
                          return ChoiceChip(
                            selected: isSelected,
                            label: Text(_getQuestionTypeLabel(type)),
                            onSelected: (selected) {
                              if (selected) {
                                setState(() {
                                  _selectedType = type;

                                  _correctAnswerIndex = 0;
                                  _trueFalseAnswer = null;

                                  if (type != QuestionType.multipleChoice) {
                                    for (final controller in _optionControllers) {
                                      controller.clear();
                                    }
                                  }
                                });
                              }
                            },
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 24),


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
                            final isSelected = _points == points;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                selected: isSelected,
                                label: Text('$points'),
                                onSelected: (selected) {
                                  if (selected) {
                                    setState(() {
                                      _points = points;
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
                ),
              ),
            ),


            Container(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                    child: const Text('Скасувати'),
                  ),
                  const SizedBox(width: 12),
                  FilledButton(
                    onPressed: _isLoading ? null : _saveChanges,
                    child: _isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Зберегти зміни'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeSpecificContent() {
    switch (_selectedType) {
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
                  groupValue: _correctAnswerIndex,
                  onChanged: (value) {
                    if (value != null && _optionControllers[index].text.trim().isNotEmpty) {
                      setState(() {
                        _correctAnswerIndex = value;
                      });
                    }
                  },
                ),
                Expanded(
                  child: TextFormField(
                    controller: _optionControllers[index],
                    decoration: InputDecoration(
                      labelText: 'Варіант ${String.fromCharCode(65 + index)}',
                      hintText: 'Введіть текст варіанту...',
                      border: const OutlineInputBorder(),
                      suffixIcon: _optionControllers[index].text.trim().isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                setState(() {
                                  _optionControllers[index].clear();
                                  if (_correctAnswerIndex == index) {
                                    _correctAnswerIndex = 0;
                                  }
                                });
                              },
                            )
                          : null,
                    ),
                    onChanged: (value) {
                      setState(() {

                        if (value.trim().isNotEmpty) {
                          final hasOtherOptions = _optionControllers
                              .asMap()
                              .entries
                              .where((entry) => entry.key != index)
                              .any((entry) => entry.value.text.trim().isNotEmpty);

                          if (!hasOtherOptions) {
                            _correctAnswerIndex = index;
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
              groupValue: _trueFalseAnswer,
              onChanged: (value) {
                setState(() {
                  _trueFalseAnswer = value;
                });
              },
              contentPadding: EdgeInsets.zero,
            ),
            RadioListTile<bool>(
              title: const Text('Неправда'),
              value: false,
              groupValue: _trueFalseAnswer,
              onChanged: (value) {
                setState(() {
                  _trueFalseAnswer = value;
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
                'Питання з відкритою відповіддю потребують ручної перевірки. Студенти будуть вводити свої відповіді вільно.',
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