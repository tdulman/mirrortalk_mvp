import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const _prefsKey = 'retention_days';
  int _days = 7;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _days = prefs.getInt(_prefsKey) ?? 7;
      _loading = false;
    });
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefsKey, _days);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Saved')),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
  return Scaffold(
    appBar: AppBar(title: const Text('Settings')),
    body: const Center(child: CircularProgressIndicator()),
  );
}


    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'How long should MirrorTalk keep your entries on this device?',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          _RetentionTile(
            label: '1 week (7 days)',
            selected: _days == 7,
            onTap: () => setState(() => _days = 7),
          ),
          _RetentionTile(
            label: '1 month (30 days)',
            selected: _days == 30,
            onTap: () => setState(() => _days = 30),
          ),
          _RetentionTile(
            label: '3 months (90 days)',
            selected: _days == 90,
            onTap: () => setState(() => _days = 90),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Text('Custom:'),
              const SizedBox(width: 12),
              _NumberStepper(
                value: _days,
                onChanged: (v) => setState(() => _days = v.clamp(1, 365)),
              ),
              const SizedBox(width: 8),
              const Text('days'),
            ],
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _save,
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class _RetentionTile extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _RetentionTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      trailing: selected ? const Icon(Icons.check_circle) : null,
      onTap: onTap,
    );
  }
}

class _NumberStepper extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;

  const _NumberStepper({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          visualDensity: VisualDensity.compact,
          onPressed: () => onChanged(value - 1),
          icon: const Icon(Icons.remove),
        ),
        Text('$value'),
        IconButton(
          visualDensity: VisualDensity.compact,
          onPressed: () => onChanged(value + 1),
          icon: const Icon(Icons.add),
        ),
      ],
    );
  }
}
