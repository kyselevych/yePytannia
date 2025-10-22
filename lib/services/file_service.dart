import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/supabase_config.dart';

class FileService {
  static final SupabaseClient _client = SupabaseConfig.client;
  static const String bucketName = 'quiz-files';


  Future<File?> pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'docx', 'doc'],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        return File(file.path!);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }


  Future<String> uploadFile({
    required File file,
    required String fileName,
    required String userId,
  }) async {
    try {
      final fileExtension = fileName.split('.').last;
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final storagePath = '$userId/$timestamp.$fileExtension';

      await _client.storage.from(bucketName).upload(
        storagePath,
        file,
        fileOptions: const FileOptions(
          cacheControl: '3600',
          upsert: false,
        ),
      );

      return _client.storage.from(bucketName).getPublicUrl(storagePath);
    } catch (e) {
      rethrow;
    }
  }


  Future<int> generateQuestions({
    required String fileUrl,
    required String quizId,
    int questionCount = 10,
  }) async {
    try {
      final response = await _client.functions.invoke(
        'generate-quiz-from-file',
        body: {
          'fileUrl': fileUrl,
          'quizId': quizId,
        },
      );

      if (response.data != null && response.data['success'] == true) {
        // Parse message to get question count: "Generated X questions"
        final message = response.data['message'] as String?;
        if (message != null) {
          final match = RegExp(r'Generated (\d+) questions').firstMatch(message);
          if (match != null) {
            return int.parse(match.group(1)!);
          }
        }
        return questionCount; // Default if can't parse
      }
      return 0;
    } catch (e) {
      rethrow;
    }
  }


  Future<void> deleteFile(String filePath) async {
    try {
      await _client.storage.from(bucketName).remove([filePath]);
    } catch (e) {
      rethrow;
    }
  }


  String getFileUrl(String filePath) {
    return _client.storage.from(bucketName).getPublicUrl(filePath);
  }


  Future<bool> fileExists(String filePath) async {
    try {
      await _client.storage.from(bucketName).download(filePath);
      return true;
    } catch (e) {
      return false;
    }
  }
}