import 'package:flutter/services.dart';
import '../models/recording.dart';

class RecordingService {
  static const MethodChannel _channel =
      MethodChannel('com.example.notes_0/recording');

  static RecordingService? _instance;

  factory RecordingService() {
    _instance ??= RecordingService._internal();
    return _instance!;
  }

  RecordingService._internal();

  // Callbacks for native events
  void Function()? onRecordingStarted;
  void Function(String filePath)? onRecordingStopped;
  void Function(int successCount, int failedCount)? onUploadCompleted;
  void Function(bool granted)? onPermissionsResult;
  void Function()? onUploadTrigger;

  void initialize() {
    _channel.setMethodCallHandler(_handleMethodCall);
  }

  Future<void> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onRecordingStarted':
        onRecordingStarted?.call();
        break;
      case 'onRecordingStopped':
        final filePath = call.arguments as String?;
        if (filePath != null) {
          onRecordingStopped?.call(filePath);
        }
        break;
      case 'onUploadCompleted':
        final args = call.arguments as Map<dynamic, dynamic>;
        final successCount = args['successCount'] as int? ?? 0;
        final failedCount = args['failedCount'] as int? ?? 0;
        onUploadCompleted?.call(successCount, failedCount);
        break;
      case 'onPermissionsResult':
        final granted = call.arguments as bool? ?? false;
        onPermissionsResult?.call(granted);
        break;
      case 'onUploadTrigger':
        onUploadTrigger?.call();
        break;
    }
  }

  Future<bool> startService() async {
    try {
      final result = await _channel.invokeMethod<bool>('startService');
      return result ?? false;
    } on PlatformException catch (e) {
      print('Error starting service: ${e.message}');
      return false;
    }
  }

  Future<bool> stopService() async {
    try {
      final result = await _channel.invokeMethod<bool>('stopService');
      return result ?? false;
    } on PlatformException catch (e) {
      print('Error stopping service: ${e.message}');
      return false;
    }
  }

  Future<bool> checkPermissions() async {
    try {
      final result = await _channel.invokeMethod<bool>('checkPermissions');
      return result ?? false;
    } on PlatformException catch (e) {
      print('Error checking permissions: ${e.message}');
      return false;
    }
  }

  Future<void> requestPermissions() async {
    try {
      await _channel.invokeMethod('requestPermissions');
    } on PlatformException catch (e) {
      print('Error requesting permissions: ${e.message}');
    }
  }

  Future<List<Recording>> getAllRecordings() async {
    try {
      final result = await _channel.invokeMethod<List<dynamic>>('getAllRecordings');
      if (result == null) return [];

      return result.map((item) => Recording.fromMap(item as Map<dynamic, dynamic>)).toList();
    } on PlatformException catch (e) {
      print('Error getting recordings: ${e.message}');
      return [];
    }
  }

  Future<bool> deleteRecording(String filePath) async {
    try {
      final result = await _channel.invokeMethod<bool>(
        'deleteRecording',
        {'filePath': filePath},
      );
      return result ?? false;
    } on PlatformException catch (e) {
      print('Error deleting recording: ${e.message}');
      return false;
    }
  }

  Future<bool> saveApiEndpoint(String endpoint) async {
    try {
      final result = await _channel.invokeMethod<bool>(
        'saveApiEndpoint',
        {'endpoint': endpoint},
      );
      return result ?? false;
    } on PlatformException catch (e) {
      print('Error saving API endpoint: ${e.message}');
      return false;
    }
  }

  Future<String> getApiEndpoint() async {
    try {
      final result = await _channel.invokeMethod<String>('getApiEndpoint');
      return result ?? '';
    } on PlatformException catch (e) {
      print('Error getting API endpoint: ${e.message}');
      return '';
    }
  }

  Future<bool> triggerUpload() async {
    try {
      final result = await _channel.invokeMethod<bool>('triggerUpload');
      return result ?? false;
    } on PlatformException catch (e) {
      print('Error triggering upload: ${e.message}');
      return false;
    }
  }
}
