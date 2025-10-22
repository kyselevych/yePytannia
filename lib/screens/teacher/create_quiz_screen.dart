import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/class_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/database_service.dart';
import '../../services/file_service.dart';
import 'manual_question_screen.dart';

class CreateQuizScreen extends StatefulWidget {
  final ClassModel classModel;

  const CreateQuizScreen({
    super.key,
    required this.classModel,
  });

  @override
  State<CreateQuizScreen> createState() => _CreateQuizScreenState();
}

enum QuizCreationMethod { aiGeneration, manualCreation, skipForNow }

class _CreateQuizScreenState extends State<CreateQuizScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final DatabaseService _databaseService = DatabaseService();
  final FileService _fileService = FileService();

  File? _selectedFile;
  bool _isLoading = false;
  bool _isGeneratingQuestions = false;
  QuizCreationMethod _selectedMethod = QuizCreationMethod.aiGeneration;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    try {
      final file = await _fileService.pickFile();
      if (file != null) {
        setState(() {
          _selectedFile = file;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Помилка вибору файлу: $e')),
        );
      }
    }
  }

  Future<void> _createQuiz() async {
    if (!_formKey.currentState!.validate()) return;


    if (_selectedMethod == QuizCreationMethod.aiGeneration && _selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Будь ласка, завантажте файл для генерації питань ШІ'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authProvider = context.read<AuthProvider>();
      final userId = authProvider.userProfile?.id;
      if (userId == null) throw Exception('User not authenticated');

      String? publicUrl;
      String? storagePath;


      if (_selectedFile != null && _selectedMethod == QuizCreationMethod.aiGeneration) {
        final uploadResult = await _fileService.uploadFile(
          file: _selectedFile!,
          fileName: _selectedFile!.path.split('/').last,
          userId: userId,
        );
        publicUrl = uploadResult['publicUrl'];
        storagePath = uploadResult['storagePath'];
      }


      final quiz = await _databaseService.createQuiz(
        classId: widget.classModel.id,
        title: _titleController.text.trim(),
        sourceFileUrl: publicUrl,
      );

      if (_selectedMethod == QuizCreationMethod.aiGeneration && storagePath != null) {

        setState(() => _isGeneratingQuestions = true);

        try {
          final questionCount = await _fileService.generateQuestions(
            fileUrl: storagePath,
            quizId: quiz.id,
          );

          if (questionCount > 0 && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Згенеровано $questionCount питань з вашого файлу!'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Квіз створено, але генерація питань не вдалася: $e'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
      } else if (_selectedMethod == QuizCreationMethod.manualCreation) {

        if (mounted) {
          final result = await Navigator.of(context).push<bool>(
            MaterialPageRoute(
              builder: (context) => ManualQuestionScreen(quiz: quiz),
            ),
          );

          if (result == true && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Квіз з питаннями успішно створено!'),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      }

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Помилка створення квізу: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
        _isGeneratingQuestions = false;
      });
    }
  }

  String _getCreateButtonText() {
    switch (_selectedMethod) {
      case QuizCreationMethod.aiGeneration:
        return 'Створити квіз з ШІ';
      case QuizCreationMethod.manualCreation:
        return 'Створити квіз і додати питання';
      case QuizCreationMethod.skipForNow:
        return 'Створити квіз';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Створити квіз'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        Icons.school,
                        color: Theme.of(context).primaryColor,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Створення квізу для:',
                              style: TextStyle(fontSize: 12),
                            ),
                            Text(
                              widget.classModel.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),


              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Назва квізу',
                  hintText: 'наприклад, Розділ 1 - Перевірка знань',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.quiz),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Будь ласка, введіть назву квізу';
                  }
                  if (value.trim().length < 3) {
                    return 'Назва має містити принаймні 3 символи';
                  }
                  return null;
                },
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 24),


              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.quiz,
                            color: Theme.of(context).primaryColor,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Як ви хочете додати питання?',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),


                      Column(
                        children: [
                          RadioListTile<QuizCreationMethod>(
                            value: QuizCreationMethod.aiGeneration,
                            groupValue: _selectedMethod,
                            onChanged: (value) {
                              setState(() {
                                _selectedMethod = value!;
                              });
                            },
                            title: const Text('Генерація ШІ'),
                            subtitle: const Text('Завантажте файл і дозвольте ШІ згенерувати питання автоматично'),
                            secondary: const Icon(Icons.auto_awesome),
                            contentPadding: EdgeInsets.zero,
                          ),
                          RadioListTile<QuizCreationMethod>(
                            value: QuizCreationMethod.manualCreation,
                            groupValue: _selectedMethod,
                            onChanged: (value) {
                              setState(() {
                                _selectedMethod = value!;
                              });
                            },
                            title: const Text('Створення вручну'),
                            subtitle: const Text('Створіть питання вручну з повним контролем'),
                            secondary: const Icon(Icons.edit),
                            contentPadding: EdgeInsets.zero,
                          ),
                          RadioListTile<QuizCreationMethod>(
                            value: QuizCreationMethod.skipForNow,
                            groupValue: _selectedMethod,
                            onChanged: (value) {
                              setState(() {
                                _selectedMethod = value!;
                              });
                            },
                            title: const Text('Пропустити'),
                            subtitle: const Text('Створити квіз і додати питання пізніше'),
                            secondary: const Icon(Icons.schedule),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ],
                      ),


                      if (_selectedMethod == QuizCreationMethod.aiGeneration) ...[
                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 16),

                        Row(
                          children: [
                            Icon(
                              Icons.upload_file,
                              color: Theme.of(context).primaryColor,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Завантажити навчальний матеріал',
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Завантажте PDF або DOCX файл для автоматичної генерації питань.',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 16),

                        if (_selectedFile != null) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.green[50],
                              border: Border.all(color: Colors.green[200]!),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.file_present, color: Colors.green[700]),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _selectedFile!.path.split('/').last,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      color: Colors.green[700],
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close),
                                  onPressed: () {
                                    setState(() {
                                      _selectedFile = null;
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],

                        OutlinedButton.icon(
                          onPressed: _pickFile,
                          icon: const Icon(Icons.attach_file),
                          label: Text(_selectedFile == null ? 'Вибрати файл' : 'Змінити файл'),
                        ),
                      ],
                    ],
                  ),
                ),
              ),


              const SizedBox(height: 24),


              if (_isGeneratingQuestions) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    border: Border.all(color: Colors.blue[200]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Генерація питань за допомогою ШІ...',
                        style: TextStyle(
                          color: Colors.blue[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),


              FilledButton(
                onPressed: _isLoading ? null : _createQuiz,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(_getCreateButtonText()),
              ),
            ],
            ),
          ),
        ),
      ),
    );
  }
}