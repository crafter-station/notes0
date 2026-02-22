enum UploadStatus {
  idle,
  uploading,
  success,
  failed,
}

class UploadResult {
  final int successCount;
  final int failedCount;
  final DateTime timestamp;

  UploadResult({
    required this.successCount,
    required this.failedCount,
    required this.timestamp,
  });

  bool get hasFailures => failedCount > 0;
  bool get hasSuccess => successCount > 0;
  int get totalCount => successCount + failedCount;
}
