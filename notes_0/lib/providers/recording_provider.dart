import 'package:flutter/foundation.dart';
import '../models/recording.dart';
import '../models/upload_status.dart';
import '../services/recording_service.dart';
import '../services/upload_service.dart';

class RecordingProvider extends ChangeNotifier {
  final RecordingService _recordingService = RecordingService();
  final UploadService _uploadService = UploadService();

  List<Recording> _recordings = [];
  bool _isServiceRunning = false;
  bool _hasPermissions = false;
  UploadStatus _uploadStatus = UploadStatus.idle;
  UploadResult? _lastUploadResult;
  String _apiEndpoint = '';

  List<Recording> get recordings => _recordings;
  bool get isServiceRunning => _isServiceRunning;
  bool get hasPermissions => _hasPermissions;
  UploadStatus get uploadStatus => _uploadStatus;
  UploadResult? get lastUploadResult => _lastUploadResult;
  String get apiEndpoint => _apiEndpoint;

  RecordingProvider() {
    _initialize();
  }

  Future<void> _initialize() async {
    _recordingService.initialize();

    // Set up callbacks
    _recordingService.onRecordingStarted = _handleRecordingStarted;
    _recordingService.onRecordingStopped = _handleRecordingStopped;
    _recordingService.onUploadCompleted = _handleUploadCompleted;
    _recordingService.onPermissionsResult = _handlePermissionsResult;
    _recordingService.onUploadTrigger = _handleUploadTrigger;

    // Load initial data
    await checkPermissions();
    await loadRecordings();
    await loadApiEndpoint();
  }

  void _handleUploadTrigger() {
    // WorkManager detected Wi-Fi, trigger upload
    triggerUpload();
  }

  void _handleRecordingStarted() {
    notifyListeners();
  }

  void _handleRecordingStopped(String filePath) {
    loadRecordings();
  }

  void _handleUploadCompleted(int successCount, int failedCount) {
    _uploadStatus = UploadStatus.success;
    _lastUploadResult = UploadResult(
      successCount: successCount,
      failedCount: failedCount,
      timestamp: DateTime.now(),
    );
    loadRecordings();
    notifyListeners();
  }

  void _handlePermissionsResult(bool granted) {
    _hasPermissions = granted;
    notifyListeners();
  }

  Future<void> checkPermissions() async {
    _hasPermissions = await _recordingService.checkPermissions();
    notifyListeners();
  }

  Future<void> requestPermissions() async {
    await _recordingService.requestPermissions();
  }

  Future<void> startService() async {
    if (!_hasPermissions) {
      await requestPermissions();
      return;
    }

    final success = await _recordingService.startService();
    if (success) {
      _isServiceRunning = true;
      notifyListeners();
    }
  }

  Future<void> stopService() async {
    final success = await _recordingService.stopService();
    if (success) {
      _isServiceRunning = false;
      notifyListeners();
    }
  }

  Future<void> loadRecordings() async {
    _recordings = await _recordingService.getAllRecordings();
    notifyListeners();
  }

  Future<void> deleteRecording(Recording recording) async {
    final success = await _recordingService.deleteRecording(recording.filePath);
    if (success) {
      _recordings.remove(recording);
      notifyListeners();
    }
  }

  Future<void> saveApiEndpoint(String endpoint) async {
    final success = await _recordingService.saveApiEndpoint(endpoint);
    if (success) {
      _apiEndpoint = endpoint;
      notifyListeners();
    }
  }

  Future<void> loadApiEndpoint() async {
    _apiEndpoint = await _recordingService.getApiEndpoint();
    notifyListeners();
  }

  Future<void> triggerUpload() async {
    if (_recordings.isEmpty) {
      return;
    }

    if (_apiEndpoint.isEmpty) {
      _uploadStatus = UploadStatus.failed;
      _lastUploadResult = UploadResult(
        successCount: 0,
        failedCount: _recordings.length,
        timestamp: DateTime.now(),
      );
      notifyListeners();
      return;
    }

    _uploadStatus = UploadStatus.uploading;
    notifyListeners();

    try {
      int successCount = 0;
      int failedCount = 0;
      final recordingsToDelete = <Recording>[];

      for (final recording in _recordings) {
        // Mark as uploading
        recording.uploadStatus = RecordingUploadStatus.uploading;
        notifyListeners();

        final result = await _uploadService.uploadRecording(
          recording,
          _apiEndpoint,
        );

        if (result.success) {
          successCount++;
          recording.uploadStatus = RecordingUploadStatus.success;
          recordingsToDelete.add(recording);
        } else {
          failedCount++;
          recording.uploadStatus = RecordingUploadStatus.failed;
          recording.uploadError = result.error;
          recording.lastUploadAttempt = DateTime.now();
        }

        notifyListeners();
      }

      // Delete successfully uploaded recordings from Android storage
      for (final recording in recordingsToDelete) {
        await _recordingService.deleteRecording(recording.filePath);
        _recordings.remove(recording);
      }

      _uploadStatus = UploadStatus.success;
      _lastUploadResult = UploadResult(
        successCount: successCount,
        failedCount: failedCount,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      print('Upload error: $e');
      _uploadStatus = UploadStatus.failed;
      _lastUploadResult = UploadResult(
        successCount: 0,
        failedCount: _recordings.length,
        timestamp: DateTime.now(),
      );
    }

    notifyListeners();
  }

  Future<void> onAppResume() async {
    // Refresh data when app comes to foreground
    await loadRecordings();

    // Auto-upload if we have recordings and API endpoint configured
    if (_recordings.isNotEmpty && _apiEndpoint.isNotEmpty) {
      await triggerUpload();
    }
  }

  Future<void> refreshData() async {
    await loadRecordings();
    notifyListeners();
  }

  int get pendingRecordingsCount => _recordings.length;

  int get failedRecordingsCount => _recordings.where((r) => r.hasFailed).length;

  bool get hasApiEndpoint => _apiEndpoint.isNotEmpty;
}
