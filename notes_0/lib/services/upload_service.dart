import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/recording.dart';

class RecordingUploadResult {
  final bool success;
  final String? error;
  final int? statusCode;

  RecordingUploadResult({
    required this.success,
    this.error,
    this.statusCode,
  });
}

class UploadService {
  static UploadService? _instance;

  factory UploadService() {
    _instance ??= UploadService._internal();
    return _instance!;
  }

  UploadService._internal();

  Future<RecordingUploadResult> uploadRecording(Recording recording, String apiEndpoint) async {
    if (apiEndpoint.isEmpty) {
      print('Upload failed: No API endpoint configured');
      return RecordingUploadResult(
        success: false,
        error: 'No API endpoint configured',
      );
    }

    try {
      final file = File(recording.filePath);
      if (!await file.exists()) {
        print('Upload failed: File does not exist: ${recording.filePath}');
        return RecordingUploadResult(
          success: false,
          error: 'File does not exist',
        );
      }

      // Create multipart request
      final request = http.MultipartRequest('POST', Uri.parse(apiEndpoint));

      // Add audio file
      request.files.add(
        await http.MultipartFile.fromPath(
          'audio',
          recording.filePath,
          filename: recording.fileName,
        ),
      );

      // Add timestamp
      request.fields['timestamp'] = recording.timestamp.millisecondsSinceEpoch
          .toString();

      // Send request
      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 60),
        onTimeout: () {
          throw Exception('Upload timeout after 60 seconds');
        },
      );

      final response = await http.Response.fromStream(streamedResponse);

      // Check if successful (2xx status codes)
      if (response.statusCode >= 200 && response.statusCode < 300) {
        print('Upload successful: ${recording.fileName}');
        return RecordingUploadResult(success: true);
      } else {
        final errorMsg = 'HTTP ${response.statusCode}: ${response.body}';
        print('Upload failed with status ${response.statusCode}: ${response.body}');
        return RecordingUploadResult(
          success: false,
          error: errorMsg,
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      print('Upload error for ${recording.fileName}: $e');
      return RecordingUploadResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  Future<Map<String, int>> uploadAll(
    List<Recording> recordings,
    String apiEndpoint,
  ) async {
    int successCount = 0;
    int failedCount = 0;

    for (final recording in recordings) {
      final result = await uploadRecording(recording, apiEndpoint);
      if (result.success) {
        successCount++;
      } else {
        failedCount++;
      }
    }

    return {'success': successCount, 'failed': failedCount};
  }
}
