// lib/screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/prefs_service.dart';
import '../services/notification_service.dart' show NotificationService, NotificationPlanner;


class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // ---- Retention (mevcut özelliğin) ----
  static const _prefsKeyRetentionDays = 'retention_days';
  int _days = 7;

  // ---- Reminders (yeni) ----
  TimeOfDay _morning = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _evening = const TimeOfDay(hour: 20, minute: 0);

  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    // Retention
    final prefs = await SharedPreferences.getInstance();
    final savedDays = prefs.getInt(_prefsKeyRetentionDays) ?? 7;

    // Reminder saatleri (PrefsService ile; yoksa fallback 08:00 / 20:00)
    final (mh, mm) = await PrefsService.getMorning();
    final (eh, em) = await PrefsService.getEvening();

    if (!mounted) return;
    setState(() {
      _days = savedDays;
      _morning = TimeOfDay(hour: mh, minute: mm);
      _evening = TimeOfDay(hour: eh, minute: em);
      _loading = false;
    });
  }

  Future<void> _pickMorning() async {
    final picked = await showTimePicker(context: context, initialTime: _morning);
    if (picked != null) setState(() => _morning = picked);
  }

  Future<void> _pickEvening() async {
    final picked = await showTimePicker(context: context, initialTime: _evening);
    if (picked != null) setState(() => _evening = picked);
  }

  Future<void> _save() async {
    setState(() => _saving = true);

    // Retention gün sayısını sakla
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefsKeyRetentionDays, _days);

    // Reminder saatlerini sakla
    await PrefsService.setMorning(_morning.hour, _morning.minute);
    await PrefsService.setEvening(_evening.hour, _evening.minute);

    // iOS izinleri kapalıysa tekrar iste (no-op olabilir)
    await NotificationService.requestPermissions();
    // Tüm bildirimleri yeni saatlere göre yeniden planla
    await NotificationPlanner.rescheduleFromPrefs();

    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Settings saved')),
    );
    Navigator.pop(context, true);
  }

  @override
Widget build(BuildContext context) {
  if (_loading) {
    // ⚠️ Burada 'const Scaffold' KULLANMIYORUZ çünkü AppBar const değil.
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
        // ===== Reminders section =====
        Text(
          'Daily reminders',
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        _RowTile(
          title: 'Morning reminder',
          value: _morning.format(context),
          onTap: _pickMorning,
        ),
        const SizedBox(height: 8),
        _RowTile(
          title: 'Evening reminder',
          value: _evening.format(context),
          onTap: _pickEvening,
        ),

        const SizedBox(height: 24),

        // ===== Retention section =====
        Text(
          'Data retention on this device',
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.w600),
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
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save'),
          ),
        ),
      ],
    ),
  );
}
}

// ===== Helper widgets (senin mevcut bileşenlerini koruyoruz) =====

class _RetentionTile extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _RetentionTile({required this.label, required this.selected, required this.onTap});

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

class _RowTile extends StatelessWidget {
  final String title;
  final String value;
  final VoidCallback onTap;
  const _RowTile({required this.title, required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.black12),
        ),
        child: Row(
          children: [
            Expanded(child: Text(title, style: Theme.of(context).textTheme.bodyLarge)),
            Text(value, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}
