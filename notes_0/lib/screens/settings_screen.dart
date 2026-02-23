import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/recording_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _apiEndpointController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _apiEndpointController = TextEditingController();
    _loadApiEndpoint();
  }

  Future<void> _loadApiEndpoint() async {
    final provider = Provider.of<RecordingProvider>(context, listen: false);
    await provider.loadApiEndpoint();
    _apiEndpointController.text = provider.apiEndpoint;
  }

  @override
  void dispose() {
    _apiEndpointController.dispose();
    super.dispose();
  }

  Future<void> _saveApiEndpoint() async {
    final endpoint = _apiEndpointController.text.trim();

    if (endpoint.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter an API endpoint'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Basic URL validation
    if (!endpoint.startsWith('http://') && !endpoint.startsWith('https://')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('URL must start with http:// or https://'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final provider = Provider.of<RecordingProvider>(context, listen: false);
    await provider.saveApiEndpoint(endpoint);

    setState(() {
      _isSaving = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('API endpoint saved successfully'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildApiEndpointSection(),
            const SizedBox(height: 24),
            _buildUploadInfoSection(),
            const SizedBox(height: 24),
            _buildUsageInstructions(),
            const SizedBox(height: 24),
            _buildAccessibilitySetupSection(),
            const SizedBox(height: 24),
            _buildPermissionsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildApiEndpointSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.cloud, color: Colors.blue),
                SizedBox(width: 12),
                Text(
                  'API Configuration',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _apiEndpointController,
              decoration: const InputDecoration(
                labelText: 'API Endpoint URL',
                hintText: 'https://api.example.com/upload',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.link),
                helperText: 'Recordings will be uploaded to this endpoint',
              ),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _isSaving ? null : _saveApiEndpoint,
              icon: _isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save),
              label: Text(_isSaving ? 'Saving...' : 'Save Endpoint'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadInfoSection() {
    return Consumer<RecordingProvider>(
      builder: (context, provider, child) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.wifi, color: Colors.green),
                    SizedBox(width: 12),
                    Text(
                      'Upload Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildInfoRow(
                  'Pending uploads',
                  '${provider.pendingRecordingsCount} recordings',
                  Icons.queue,
                ),
                _buildInfoRow(
                  'Upload trigger',
                  'Automatic (Wi-Fi only)',
                  Icons.network_wifi,
                ),
                _buildInfoRow(
                  'API status',
                  provider.hasApiEndpoint ? 'Configured' : 'Not configured',
                  Icons.info,
                  color: provider.hasApiEndpoint ? Colors.green : Colors.orange,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(
    String label,
    String value,
    IconData icon, {
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color ?? Colors.grey),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsageInstructions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.help_outline, color: Colors.purple),
                SizedBox(width: 12),
                Text(
                  'How to Use',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildInstructionStep(
              '1',
              'Enable Accessibility Service (see above)',
            ),
            _buildInstructionStep('2', 'Lock your phone or turn off screen'),
            _buildInstructionStep('3', 'Press Power button to wake screen'),
            _buildInstructionStep(
              '4',
              'Hold Volume ↑ for 1 second to start recording',
            ),
            _buildInstructionStep(
              '5',
              'Phone will vibrate once - now recording',
            ),
            _buildInstructionStep('6', 'Speak your voice note'),
            _buildInstructionStep(
              '7',
              'Hold Volume ↑ for 1 second again to stop',
            ),
            _buildInstructionStep(
              '8',
              'Phone will vibrate twice - recording saved',
            ),
            _buildInstructionStep('9', 'Recording auto-uploads when on Wi-Fi'),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructionStep(String number, String instruction) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: Colors.purple.withOpacity(0.2),
            child: Text(
              number,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.purple,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(instruction, style: const TextStyle(fontSize: 14)),
          ),
        ],
      ),
    );
  }

  Widget _buildAccessibilitySetupSection() {
    return Card(
      color: Colors.orange.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.accessibility_new,
                  color: Colors.orange.shade700,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Accessibility Service Setup',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange.shade900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.warning_amber,
                        color: Colors.orange.shade700,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Required for volume button recording',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange.shade900,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'To record with volume buttons while the screen is locked, you must enable the Accessibility Service.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.orange.shade900,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Setup Steps:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.orange.shade900,
              ),
            ),
            const SizedBox(height: 12),
            _buildSetupStep(
              '1',
              'IMPORTANT: If you installed the APK manually',
              'Go to: Settings → Apps → Voice Notes → ⋮ (three dots) → "Allow restricted settings"',
              Colors.red,
            ),
            _buildSetupStep(
              '2',
              'Enable Accessibility Service',
              'Go to: Settings → Accessibility → Downloaded apps → Voice Notes → Turn ON',
              Colors.orange,
            ),
            _buildSetupStep(
              '3',
              'Grant Permission',
              'Tap "Allow" on the security warning (this is normal for accessibility services)',
              Colors.blue,
            ),
            _buildSetupStep(
              '4',
              'Test It',
              'Lock your screen, then hold Volume ↑ for 1 second',
              Colors.green,
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () {
                // Open accessibility settings
                // Note: This would need platform channel implementation
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Go to Settings → Accessibility → Downloaded apps → Voice Notes',
                    ),
                    duration: Duration(seconds: 5),
                  ),
                );
              },
              icon: const Icon(Icons.settings),
              label: const Text('Open Accessibility Settings'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 16,
                ),
                side: BorderSide(color: Colors.orange.shade700),
                foregroundColor: Colors.orange.shade900,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSetupStep(
    String number,
    String title,
    String description,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: color.withOpacity(0.2),
            child: Text(
              number,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionsSection() {
    return Consumer<RecordingProvider>(
      builder: (context, provider, child) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      provider.hasPermissions
                          ? Icons.check_circle
                          : Icons.warning,
                      color: provider.hasPermissions
                          ? Colors.green
                          : Colors.orange,
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Permissions',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  provider.hasPermissions
                      ? 'All required permissions granted'
                      : 'Some permissions are missing',
                  style: TextStyle(
                    fontSize: 14,
                    color: provider.hasPermissions
                        ? Colors.green
                        : Colors.orange,
                  ),
                ),
                const SizedBox(height: 16),
                if (!provider.hasPermissions)
                  ElevatedButton.icon(
                    onPressed: () async {
                      await provider.requestPermissions();
                    },
                    icon: const Icon(Icons.security),
                    label: const Text('Grant Permissions'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
