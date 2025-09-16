import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/prefs_service.dart';
import '../services/notification_service.dart';
import 'record_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    // Varsayılan saatleri garanti altına al + bildirimleri planla
    await PrefsService.ensureDefaults();
    await NotificationPlanner.rescheduleFromPrefs();
    await PrefsService.setFirstRun(false);

    if (!mounted) return;
    Navigator.of(context).pop(true); // Journal’a geri dön
  }

  @override
  Widget build(BuildContext context) {
    final pages = <_Slide>[
      const _Slide(
        title: 'Speak your thoughts',
        body:
            'Capture a quick voice note in the morning or evening. No pressure—just speak naturally.',
        icon: Icons.mic_none,
      ),
      const _Slide(
        title: 'AI suggests goals',
        body:
            'We turn your words into text and suggest 1–3 concrete goals you can act on.',
        icon: Icons.check_circle_outline,
      ),
      const _Slide(
        title: 'Build your streak',
        body:
            'Track how many days you showed up. Small, consistent steps beat giant bursts.',
        icon: Icons.local_fire_department_outlined,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Welcome'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: pages.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (_, i) => pages[i],
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                pages.length,
                (i) => Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i == _index ? Colors.black87 : Colors.black26,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  TextButton(
                    onPressed: _finish,
                    child: const Text('Skip'),
                  ),
                  const Spacer(),
                  if (_index < pages.length - 1)
                    FilledButton(
                      onPressed: () {
                        _controller.nextPage(
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeOut,
                        );
                      },
                      child: const Text('Next'),
                    )
                  else
                    FilledButton(
                      onPressed: _finish,
                      child: const Text('Get Started'),
                    ),
                ],
              ),
            ),
            // Opsiyonel: “Try a sample” → Record ekranına at
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: TextButton.icon(
                onPressed: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const RecordScreen()),
                  );
                },
                icon: const Icon(Icons.play_circle_outline),
                label: const Text('Try a sample record'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Slide extends StatelessWidget {
  final String title;
  final String body;
  final IconData icon;

  const _Slide({
    required this.title,
    required this.body,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('EEE, MMM d');
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 72),
          const SizedBox(height: 16),
          Text(title, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 12),
          Text(
            body,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 24),
          Text(
            'Today is ${fmt.format(DateTime.now())}',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Colors.black54,
                ),
          ),
        ],
      ),
    );
  }
}
