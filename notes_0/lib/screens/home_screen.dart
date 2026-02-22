import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/recording_provider.dart';
import '../models/recording.dart';
import '../models/upload_status.dart';
import 'settings_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Voice Notes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: Consumer<RecordingProvider>(
        builder: (context, provider, child) {
          return Column(
            children: [
              _buildServiceControl(context, provider),
              _buildUploadStatus(provider),
              _buildRecordingsList(context, provider),
            ],
          );
        },
      ),
    );
  }

  Widget _buildServiceControl(BuildContext context, RecordingProvider provider) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  provider.isServiceRunning
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: provider.isServiceRunning ? Colors.green : Colors.grey,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        provider.isServiceRunning
                            ? 'Service Active'
                            : 'Service Stopped',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        provider.isServiceRunning
                            ? 'Hold volume ↑ for 1 second to record'
                            : 'Start the service to enable recording',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () async {
                if (provider.isServiceRunning) {
                  await provider.stopService();
                } else {
                  if (!provider.hasPermissions) {
                    await provider.requestPermissions();
                  } else {
                    await provider.startService();
                  }
                }
              },
              icon: Icon(
                provider.isServiceRunning ? Icons.stop : Icons.play_arrow,
              ),
              label: Text(
                provider.isServiceRunning ? 'Stop Service' : 'Start Service',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: provider.isServiceRunning
                    ? Colors.red
                    : Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
            if (!provider.hasPermissions)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Permissions required: Microphone, Notifications',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.orange[700],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadStatus(RecordingProvider provider) {
    if (provider.uploadStatus == UploadStatus.idle &&
        provider.lastUploadResult == null) {
      return const SizedBox.shrink();
    }

    String statusText = '';
    Color statusColor = Colors.grey;
    IconData statusIcon = Icons.info;

    if (provider.uploadStatus == UploadStatus.uploading) {
      statusText = 'Uploading recordings...';
      statusColor = Colors.blue;
      statusIcon = Icons.cloud_upload;
    } else if (provider.lastUploadResult != null) {
      final result = provider.lastUploadResult!;
      if (result.hasFailures) {
        statusText =
            'Uploaded: ${result.successCount}, Failed: ${result.failedCount}';
        statusColor = Colors.orange;
        statusIcon = Icons.warning;
      } else if (result.hasSuccess) {
        statusText = 'Successfully uploaded ${result.successCount} recordings';
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
      }
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(statusIcon, color: statusColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              statusText,
              style: TextStyle(color: statusColor, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordingsList(BuildContext context, RecordingProvider provider) {
    return Expanded(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recordings (${provider.recordings.length})',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (provider.recordings.isNotEmpty)
                  TextButton.icon(
                    onPressed: () async {
                      await provider.triggerUpload();
                    },
                    icon: const Icon(Icons.cloud_upload, size: 18),
                    label: const Text('Upload Now'),
                  ),
              ],
            ),
          ),
          Expanded(
            child: provider.recordings.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.mic_none,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No recordings yet',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          provider.isServiceRunning
                              ? 'Hold volume ↑ for 1s to start recording'
                              : 'Start the service to begin',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: provider.loadRecordings,
                    child: ListView.builder(
                      itemCount: provider.recordings.length,
                      itemBuilder: (context, index) {
                        final recording = provider.recordings[index];
                        return _buildRecordingItem(
                          context,
                          recording,
                          provider,
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordingItem(
    BuildContext context,
    Recording recording,
    RecordingProvider provider,
  ) {
    return Dismissible(
      key: Key(recording.filePath),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Recording'),
            content: const Text('Are you sure you want to delete this recording?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) {
        provider.deleteRecording(recording);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${recording.fileName} deleted'),
            duration: const Duration(seconds: 2),
          ),
        );
      },
      child: ListTile(
        leading: const CircleAvatar(
          child: Icon(Icons.mic),
        ),
        title: Text(
          recording.fileName,
          style: const TextStyle(fontSize: 14),
        ),
        subtitle: Text(
          '${recording.formattedDuration} • ${recording.formattedSize}',
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          // Could open a detailed view or play the recording
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Recording: ${recording.fileName}'),
              duration: const Duration(seconds: 1),
            ),
          );
        },
      ),
    );
  }
}
