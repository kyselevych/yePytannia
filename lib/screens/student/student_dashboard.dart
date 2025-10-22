import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/class_model.dart';
import '../../models/quiz_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/database_service.dart';
import '../../theme/app_strings.dart';
import 'join_class_dialog.dart';
import 'quiz_list_screen.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  final DatabaseService _databaseService = DatabaseService();
  List<ClassModel> _classes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadClasses();
  }

  Future<void> _loadClasses() async {
    setState(() => _isLoading = true);
    try {
      final authProvider = context.read<AuthProvider>();
      final userId = authProvider.userProfile?.id;
      if (userId != null) {
        final classes = await _databaseService.getStudentClasses(userId);
        setState(() {
          _classes = classes;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppStrings.errorLoadingClasses}: $e')),
        );
      }
    }
  }

  Future<void> _joinClass() async {
    final accessCode = await showDialog<String>(
      context: context,
      builder: (context) => const JoinClassDialog(),
    );

    if (accessCode != null) {
      try {
        final authProvider = context.read<AuthProvider>();
        final userId = authProvider.userProfile?.id;
        if (userId != null) {
          final classModel = await _databaseService.joinClass(accessCode, userId);
          if (classModel != null) {
            _loadClasses();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${AppStrings.joinedSuccessfully} "${classModel.name}"!'),
                  backgroundColor: Theme.of(context).colorScheme.tertiaryContainer,
                ),
              );
            }
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(AppStrings.invalidAccessCode),
                  backgroundColor: Theme.of(context).colorScheme.errorContainer,
                ),
              );
            }
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${AppStrings.errorJoiningClass}: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.myClasses),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadClasses,
            tooltip: AppStrings.refresh,
          ),
          PopupMenuButton(
            itemBuilder: (context) => [
              PopupMenuItem(
                child: ListTile(
                  leading: const Icon(Icons.logout),
                  title: Text(AppStrings.logout),
                ),
                onTap: () async {
                  await authProvider.signOut();

                },
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${AppStrings.welcome}, ${authProvider.userProfile?.fullName ?? AppStrings.student}!',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  AppStrings.studentWelcome,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),


          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _classes.isEmpty
                    ? _buildEmptyState()
                    : _buildClassesList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _joinClass,
        icon: const Icon(Icons.add),
        label: Text(AppStrings.joinClass),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.school_outlined,
            size: 80,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            AppStrings.notInClasses,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppStrings.joinFirstClass,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          FilledButton.tonal(
            onPressed: _joinClass,
            child: Text(AppStrings.joinClass),
          ),
        ],
      ),
    );
  }

  Widget _buildClassesList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _classes.length,
      itemBuilder: (context, index) {
        final classModel = _classes[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Text(
                classModel.name.substring(0, 1).toUpperCase(),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              classModel.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.person,
                      size: 16,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      AppStrings.teacher,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                FutureBuilder<List<Quiz>>(
                  future: _databaseService.getClassQuizzes(classModel.id),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      final activeQuizzes = snapshot.data!
                          .where((quiz) => quiz.status == QuizStatus.active)
                          .length;
                      return Row(
                        children: [
                          Icon(
                            Icons.quiz,
                            size: 16,
                            color: activeQuizzes > 0
                                ? Theme.of(context).colorScheme.tertiary
                                : Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            AppStrings.getActiveQuizCount(activeQuizzes),
                            style: TextStyle(
                              color: activeQuizzes > 0
                                  ? Theme.of(context).colorScheme.tertiary
                                  : Theme.of(context).colorScheme.onSurfaceVariant,
                              fontWeight: activeQuizzes > 0 ? FontWeight.w500 : null,
                            ),
                          ),
                        ],
                      );
                    }
                    return Row(
                      children: [
                        Icon(
                          Icons.quiz,
                          size: 16,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          AppStrings.loading,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => QuizListScreen(classModel: classModel),
                ),
              );
            },
          ),
        );
      },
    );
  }
}