import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'utils/supabase_config.dart';
import 'providers/auth_provider.dart';
import 'models/user_profile.dart';
import 'screens/auth/login_screen.dart';
import 'screens/teacher/teacher_dashboard.dart';
import 'screens/student/student_dashboard.dart';
import 'theme/app_theme.dart';
import 'theme/app_strings.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SupabaseConfig.initialize();

  runApp(const EPytanniaApp());
}

class EPytanniaApp extends StatelessWidget {
  const EPytanniaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: MaterialApp(
        title: AppStrings.appName,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        home: const AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        if (authProvider.isAuthenticated) {
          return const DashboardRouter();
        } else {
          return const LoginScreen();
        }
      },
    );
  }
}

class DashboardRouter extends StatefulWidget {
  const DashboardRouter({super.key});

  @override
  State<DashboardRouter> createState() => _DashboardRouterState();
}

class _DashboardRouterState extends State<DashboardRouter> {
  bool _isLoadingProfile = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ensureProfileLoaded();
    });
  }

  Future<void> _ensureProfileLoaded() async {
    final authProvider = context.read<AuthProvider>();
    if (authProvider.userProfile == null && !_isLoadingProfile) {
      setState(() => _isLoadingProfile = true);

      await Future.delayed(const Duration(milliseconds: 500));

      await authProvider.reloadUserProfile();

      if (authProvider.userProfile == null) {
        await Future.delayed(const Duration(seconds: 1));
        await authProvider.reloadUserProfile();
      }

      setState(() => _isLoadingProfile = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final userProfile = authProvider.userProfile;

        if (userProfile == null) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    AppStrings.loadingProfile,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 24),
                  if (_isLoadingProfile)
                    Text(
                      AppStrings.creatingProfile,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
          );
        }

        switch (userProfile.role) {
          case UserRole.teacher:
            return const TeacherDashboard();
          case UserRole.student:
            return const StudentDashboard();
        }
      },
    );
  }
}
