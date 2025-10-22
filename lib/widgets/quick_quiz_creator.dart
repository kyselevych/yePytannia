import 'dart:io';
import 'package:flutter/material.dart';
import '../models/class_model.dart';
import '../models/quiz_model.dart';
import '../services/file_service.dart';
import '../services/database_service.dart';








class QuickQuizCreator extends StatefulWidget {
  final ClassModel classModel;
  final VoidCallback? onQuizCreated;
  final VoidCallback? onCancel;

  const QuickQuizCreator({
    super.key,
    required this.classModel,
    this.onQuizCreated,
    this.onCancel,
  });

  @override
  State<QuickQuizCreator> createState() => _QuickQuizCreatorState();
}

class _QuickQuizCreatorState extends State<QuickQuizCreator> {
  final DatabaseService _databaseService = DatabaseService();
  final FileService _fileService = FileService();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  File? _selectedFile;
  String? _fileName;
  bool _isUploading = false;
  bool _isGenerating = false;
  int _questionCount = 10;
  int _timeLimitMinutes = 30;
  bool _makeActive = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    try {
      final file = await _fileService.pickFile();
      if (file != null) {
        setState(() {
          _selectedFile = file;
          _fileName = file.path.split('/').last;

          if (_titleController.text.isEmpty) {
            final nameWithoutExtension = _fileName!.split('.').first;
            _titleController.text = 'Вікторина: $nameWithoutExtension';
          }
        });
      }
    } catch (e) {
      _showError('Помилка вибору файлу: $e');
    }
  }

  Future<void> _createQuizFromFile() async {
    if (_selectedFile == null) {
      _showError('Будь ласка, спочатку виберіть файл');
      return;
    }

    if (_titleController.text.trim().isEmpty) {
      _showError('Будь ласка, введіть назву тесту');
      return;
    }

    setState(() => _isUploading = true);

    try {

      final userId = _databaseService.getCurrentUserId();
      if (userId == null) {
        throw Exception('Користувач не автентифікований');
      }


      final fileUrl = await _fileService.uploadFile(
        file: _selectedFile!,
        fileName: _fileName!,
        userId: userId,
      );

      setState(() {
        _isUploading = false;
        _isGenerating = true;
      });


      final quiz = await _databaseService.createQuiz(
        classId: widget.classModel.id,
        title: _titleController.text.trim(),
        sourceFileUrl: fileUrl,
      );


      final questions = await _fileService.generateQuestions(
        fileUrl: fileUrl,
        quizId: quiz.id,
        questionCount: _questionCount,
      );

      if (questions.isEmpty) {
        throw Exception('З файлу не було згенеровано жодного питання');
      }


      if (_makeActive) {
        await _databaseService.updateQuizStatus(quiz.id, QuizStatus.active);
      }

      setState(() => _isGenerating = false);

      _showSuccess(
        'Вікторину успішно створено з ${questions.length} питаннями!',
      );


      _resetForm();


      widget.onQuizCreated?.call();

    } catch (e) {
      setState(() {
        _isUploading = false;
        _isGenerating = false;
      });
      _showError('Помилка створення тесту: $e');
    }
  }

  void _resetForm() {
    setState(() {
      _selectedFile = null;
      _fileName = null;
      _titleController.clear();
      _descriptionController.clear();
      _questionCount = 10;
      _timeLimitMinutes = 30;
      _makeActive = false;
    });
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showSuccess(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Row(
              children: [
                Icon(
                  Icons.auto_awesome,
                  color: Theme.of(context).primaryColor,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Швидке створення тесту',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: widget.onCancel,
                  icon: const Icon(Icons.close),
                  tooltip: 'Закрити',
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Завантажте PDF або DOCX файл для автоматичної генерації тесту за допомогою ШІ',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 20),


            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(
                  color: _selectedFile != null
                      ? Colors.green
                      : Colors.grey.shade300,
                  width: 2,
                  style: BorderStyle.solid,
                ),
                borderRadius: BorderRadius.circular(12),
                color: _selectedFile != null
                    ? Colors.green.shade50
                    : Colors.grey.shade50,
              ),
              child: Column(
                children: [
                  Icon(
                    _selectedFile != null ? Icons.check_circle : Icons.upload_file,
                    size: 48,
                    color: _selectedFile != null
                        ? Colors.green
                        : Colors.grey.shade400,
                  ),
                  const SizedBox(height: 12),
                  if (_selectedFile != null) ...[
                    Text(
                      _fileName!,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton.icon(
                          onPressed: _pickFile,
                          icon: const Icon(Icons.change_circle),
                          label: const Text('Змінити файл'),
                        ),
                        const SizedBox(width: 8),
                        TextButton.icon(
                          onPressed: () {
                            setState(() {
                              _selectedFile = null;
                              _fileName = null;
                            });
                          },
                          icon: const Icon(Icons.clear),
                          label: const Text('Видалити'),
                        ),
                      ],
                    ),
                  ] else ...[
                    const Text(
                      'Виберіть PDF або Word документ',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Підтримувані формати: PDF, DOCX, DOC',
                      style: TextStyle(color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: _pickFile,
                      icon: const Icon(Icons.folder_open),
                      label: const Text('Вибрати файл'),
                    ),
                  ],
                ],
              ),
            ),

            if (_selectedFile != null) ...[
              const SizedBox(height: 20),


              Text(
                'Налаштування тесту',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),


              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Назва тесту',
                  hintText: 'Введіть назву тесту...',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 12),


              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Опис (необов\'язково)',
                  hintText: 'Короткий опис тесту...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 16),


              LayoutBuilder(
                builder: (context, constraints) {
                  final isSmallScreen = constraints.maxWidth < 600;

                  if (isSmallScreen) {

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Питань: $_questionCount',
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                            Slider(
                              value: _questionCount.toDouble(),
                              min: 5,
                              max: 20,
                              divisions: 15,
                              onChanged: (value) {
                                setState(() {
                                  _questionCount = value.round();
                                });
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Час: $_timeLimitMinutes хв',
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                            Slider(
                              value: _timeLimitMinutes.toDouble(),
                              min: 10,
                              max: 120,
                              divisions: 22,
                              onChanged: (value) {
                                setState(() {
                                  _timeLimitMinutes = value.round();
                                });
                              },
                            ),
                          ],
                        ),
                      ],
                    );
                  }


                  return Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Питань: $_questionCount',
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                            Slider(
                              value: _questionCount.toDouble(),
                              min: 5,
                              max: 20,
                              divisions: 15,
                              onChanged: (value) {
                                setState(() {
                                  _questionCount = value.round();
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Час: $_timeLimitMinutes хв',
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                            Slider(
                              value: _timeLimitMinutes.toDouble(),
                              min: 10,
                              max: 120,
                              divisions: 22,
                              onChanged: (value) {
                                setState(() {
                                  _timeLimitMinutes = value.round();
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),


              CheckboxListTile(
                title: const Text('Активувати тест одразу'),
                subtitle: const Text('Студенти зможуть почати проходження тесту відразу'),
                value: _makeActive,
                onChanged: (value) {
                  setState(() {
                    _makeActive = value ?? false;
                  });
                },
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),

              const SizedBox(height: 20),


              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: (_isUploading || _isGenerating)
                      ? null
                      : _createQuizFromFile,
                  icon: _isUploading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : _isGenerating
                          ? const Icon(Icons.auto_awesome)
                          : const Icon(Icons.quiz),
                  label: Text(
                    _isUploading
                        ? 'Завантаження файлу...'
                        : _isGenerating
                            ? 'Генерація питань...'
                            : 'Створити тест з ШІ',
                  ),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),

              if (_isGenerating) ...[
                const SizedBox(height: 12),
                const LinearProgressIndicator(),
                const SizedBox(height: 8),
                Text(
                  'Це може зайняти 30-60 секунд залежно від розміру файлу...',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}