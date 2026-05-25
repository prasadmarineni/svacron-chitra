import 'package:flutter/material.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  bool _offlineMode = true;
  bool _lowStorageMode = false;
  bool _darkMode = false;
  bool _enableAppLock = false;
  bool _compressOnImport = true;
  bool _autoDeleteTemp = true;
  String _textSize = 'medium';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    // Load saved preferences here if using shared_preferences
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _saveSettings() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Settings saved.')),
    );
    // Save to shared_preferences or local database
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.tune_outlined), text: 'General'),
            Tab(icon: Icon(Icons.security_outlined), text: 'Security'),
            Tab(icon: Icon(Icons.palette_outlined), text: 'Display'),
            Tab(icon: Icon(Icons.info_outlined), text: 'About'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildGeneralTab(),
          _buildSecurityTab(),
          _buildDisplayTab(),
          _buildAboutTab(),
        ],
      ),
    );
  }

  // ── General Settings Tab ──────────────────────────────────────────────────
  Widget _buildGeneralTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Processing',
          style: Theme.of(context).textTheme.labelSmall,
        ),
        const SizedBox(height: 8),
        Card(
          child: Column(
            children: [
              SwitchListTile(
                value: _offlineMode,
                onChanged: (v) {
                  setState(() => _offlineMode = v);
                  _saveSettings();
                },
                title: const Text('Offline Mode'),
                subtitle: const Text(
                  'Process scans and OCR locally without cloud connection.',
                ),
              ),
              const Divider(height: 1),
              SwitchListTile(
                value: _compressOnImport,
                onChanged: (v) {
                  setState(() => _compressOnImport = v);
                  _saveSettings();
                },
                title: const Text('Compress on Import'),
                subtitle: const Text(
                  'Automatically compress images when importing from gallery.',
                ),
              ),
              const Divider(height: 1),
              SwitchListTile(
                value: _autoDeleteTemp,
                onChanged: (v) {
                  setState(() => _autoDeleteTemp = v);
                  _saveSettings();
                },
                title: const Text('Auto-delete Temp Files'),
                subtitle: const Text(
                  'Remove temporary files to save storage space.',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Storage',
          style: Theme.of(context).textTheme.labelSmall,
        ),
        const SizedBox(height: 8),
        Card(
          child: Column(
            children: [
              SwitchListTile(
                value: _lowStorageMode,
                onChanged: (v) {
                  setState(() => _lowStorageMode = v);
                  _saveSettings();
                },
                title: const Text('Low Storage Mode'),
                subtitle: const Text(
                  'Prefer compressed drafts and optimized previews.',
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.delete_sweep_outlined),
                title: const Text('Clear Cache'),
                subtitle: const Text('Free up temporary files (0 MB)'),
                trailing: const Icon(Icons.arrow_forward, size: 18),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Cache cleared.')),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Security Settings Tab ────────────────────────────────────────────────
  Widget _buildSecurityTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Authentication',
          style: Theme.of(context).textTheme.labelSmall,
        ),
        const SizedBox(height: 8),
        Card(
          child: Column(
            children: [
              SwitchListTile(
                value: _enableAppLock,
                onChanged: (v) {
                  setState(() => _enableAppLock = v);
                  if (v) {
                    _showAppLockDialog();
                  } else {
                    _saveSettings();
                  }
                },
                title: const Text('App Lock'),
                subtitle: const Text('PIN and biometric authentication'),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.vpn_key_outlined),
                title: const Text('Change PIN'),
                subtitle: const Text('Update your app lock PIN'),
                trailing: const Icon(Icons.arrow_forward, size: 18),
                onTap: _enableAppLock ? () {} : null,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Sensitive Content',
          style: Theme.of(context).textTheme.labelSmall,
        ),
        const SizedBox(height: 8),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.folder_outlined),
                title: const Text('Locked Folders'),
                subtitle: const Text('Hide and protect sensitive documents'),
                trailing: const Icon(Icons.arrow_forward, size: 18),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Feature coming soon')),
                  );
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.lock_outlined),
                title: const Text('Encrypt PDFs'),
                subtitle: const Text(
                  'Protect PDFs with password encryption',
                ),
                trailing: const Icon(Icons.arrow_forward, size: 18),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Feature coming soon')),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Display Settings Tab ──────────────────────────────────────────────────
  Widget _buildDisplayTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Theme',
          style: Theme.of(context).textTheme.labelSmall,
        ),
        const SizedBox(height: 8),
        Card(
          child: Column(
            children: [
              SwitchListTile(
                value: _darkMode,
                onChanged: (v) {
                  setState(() => _darkMode = v);
                  _saveSettings();
                },
                title: const Text('Dark Mode'),
                subtitle: const Text(
                  'Use night-friendly colors for reading and editing.',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Text & Display',
          style: Theme.of(context).textTheme.labelSmall,
        ),
        const SizedBox(height: 8),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.text_fields_outlined),
                title: const Text('Text Size'),
                subtitle: Text(_textSize),
                trailing: DropdownButton<String>(
                  value: _textSize,
                  items: const [
                    DropdownMenuItem(value: 'small', child: Text('Small')),
                    DropdownMenuItem(value: 'medium', child: Text('Medium')),
                    DropdownMenuItem(value: 'large', child: Text('Large')),
                  ],
                  onChanged: (v) {
                    if (v != null) {
                      setState(() => _textSize = v);
                      _saveSettings();
                    }
                  },
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.contrast_outlined),
                title: const Text('High Contrast'),
                subtitle: const Text('Improves visibility'),
                trailing: Switch(
                  value: false,
                  onChanged: (v) => _saveSettings(),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Interface',
          style: Theme.of(context).textTheme.labelSmall,
        ),
        const SizedBox(height: 8),
        Card(
          child: ListTile(
            leading: const Icon(Icons.palette_outlined),
            title: const Text('Accent Color'),
            trailing: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
              ),
            ),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Feature coming soon')),
              );
            },
          ),
        ),
      ],
    );
  }

  // ── About Tab ────────────────────────────────────────────────────────────
  Widget _buildAboutTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Icon(
              Icons.description_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  'Svacron Chitra',
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Document Scanner, PDF Viewer & Editor',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Version 1.0.0',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Information',
          style: Theme.of(context).textTheme.labelSmall,
        ),
        const SizedBox(height: 8),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.language_outlined),
                title: const Text('Website'),
                subtitle: const Text('www.svacron.com'),
                trailing: const Icon(Icons.arrow_forward, size: 18),
                onTap: () {},
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.privacy_tip_outlined),
                title: const Text('Privacy Policy'),
                trailing: const Icon(Icons.arrow_forward, size: 18),
                onTap: () {},
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.description_outlined),
                title: const Text('Terms of Service'),
                trailing: const Icon(Icons.arrow_forward, size: 18),
                onTap: () {},
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.help_outline),
                title: const Text('Help & Feedback'),
                trailing: const Icon(Icons.arrow_forward, size: 18),
                onTap: () {},
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Credits',
          style: Theme.of(context).textTheme.labelSmall,
        ),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                RichText(
                  text: const TextSpan(
                    children: [
                      TextSpan(
                        text: 'Built with ',
                        style: TextStyle(color: Colors.grey),
                      ),
                      TextSpan(
                        text: 'Flutter',
                        style: TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextSpan(
                        text: ' and powered by ',
                        style: TextStyle(color: Colors.grey),
                      ),
                      TextSpan(
                        text: 'Google ML Kit',
                        style: TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  void _showAppLockDialog() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Set App Lock'),
        content: const TextField(
          obscureText: true,
          decoration: InputDecoration(
            labelText: 'Enter 4-digit PIN',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
          maxLength: 4,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              _saveSettings();
            },
            child: const Text('Set PIN'),
          ),
        ],
      ),
    );
  }
}
