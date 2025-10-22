import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static const String url = 'https://bjfmvmkdfjpngtwtrczq.supabase.co';
  static const String anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJqZm12bWtkZmpwbmd0d3RyY3pxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTg5NzQ2NTMsImV4cCI6MjA3NDU1MDY1M30.nASHkx6Gk-ah36ejFuA4Ru-p1Fi8DOHOD6ZKFS8QtdM';

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: url,
      anonKey: anonKey,
    );
  }

  static SupabaseClient get client => Supabase.instance.client;
}