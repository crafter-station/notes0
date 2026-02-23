enum RecordingUploadStatus {
  pending,
  uploading,
  success,
  failed,
}

class Recording {
  final String filePath;
  final String fileName;
  final DateTime timestamp;
  final int size;
  RecordingUploadStatus uploadStatus;
  String? uploadError;
  DateTime? lastUploadAttempt;

  Recording({
    required this.filePath,
    required this.fileName,
    required this.timestamp,
    required this.size,
    this.uploadStatus = RecordingUploadStatus.pending,
    this.uploadError,
    this.lastUploadAttempt,
  });

  factory Recording.fromMap(Map<dynamic, dynamic> map) {
    return Recording(
      filePath: map['filePath'] as String,
      fileName: map['fileName'] as String,
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
      size: map['size'] as int,
    );
  }

  String get formattedSize {
    if (size < 1024) {
      return '$size B';
    } else if (size < 1024 * 1024) {
      return '${(size / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }

  String get formattedDuration {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }

  bool get isPending => uploadStatus == RecordingUploadStatus.pending;
  bool get isUploading => uploadStatus == RecordingUploadStatus.uploading;
  bool get isUploaded => uploadStatus == RecordingUploadStatus.success;
  bool get hasFailed => uploadStatus == RecordingUploadStatus.failed;

  Recording copyWith({
    RecordingUploadStatus? uploadStatus,
    String? uploadError,
    DateTime? lastUploadAttempt,
  }) {
    return Recording(
      filePath: filePath,
      fileName: fileName,
      timestamp: timestamp,
      size: size,
      uploadStatus: uploadStatus ?? this.uploadStatus,
      uploadError: uploadError,
      lastUploadAttempt: lastUploadAttempt ?? this.lastUploadAttempt,
    );
  }
}
