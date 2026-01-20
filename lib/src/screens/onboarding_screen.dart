import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../../services/storage_service.dart';
import '../core/theme.dart';

class OnboardingScreen extends StatefulWidget {
  final StorageService storage;
  final VoidCallback onComplete;

  /// Optional size (in logical pixels) for the Lottie animation. If null,
  /// onboarding will pick a responsive size based on screen width.
  final double? lottieSize;

  const OnboardingScreen({
    Key? key,
    required this.storage,
    required this.onComplete,
    this.lottieSize,
  }) : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _page = 0;

  static const _seenKey = 'seen_onboarding_v1';

  void _next() {
    if (_page < 2) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _finish();
    }
  }

  Future<void> _finish() async {
    await widget.storage.prefs.setBool(_seenKey, true);
    widget.onComplete();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildPage({
    required String title,
    required String subtitle,
    required IconData icon,
    String? lottieAsset,
    double? size,
  }) {
    // Keep this method for backwards compat if needed; now it only builds the
    // animation portion. Text is rendered in a fixed area so it doesn't slide.
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0),
      child: Builder(
        builder: (context) {
          final screenW = MediaQuery.of(context).size.width;
          final base = (size ?? widget.lottieSize) ?? (screenW * 0.9);
          final actual = base.clamp(150.0, 390.0).toDouble();
          return SizedBox(
            width: actual,
            height: actual,
            child: Builder(
              builder: (context) {
                try {
                  if (lottieAsset != null && lottieAsset.isNotEmpty) {
                    return Lottie.asset(lottieAsset, fit: BoxFit.contain);
                  }
                  return Icon(
                    icon,
                    size: actual * 0.35,
                    color: AppColors.primary,
                  );
                } catch (_) {
                  return Icon(
                    icon,
                    size: actual * 0.35,
                    color: AppColors.primary,
                  );
                }
              },
            ),
          );
        },
      ),
    );
  }

  // Data for pages: animations, titles and subtitles. Text will be shown in a
  // fixed area below the PageView so it doesn't slide.
  final List<String?> _lottieAssets = [
    'lib/assets/lottie/1.json',
    'lib/assets/lottie/2.json',
    'lib/assets/lottie/3.json',
  ];

  final List<String> _titles = [
    'Track Expenses',
    'Visualize Spending',
    'Backups & Sync',
  ];

  final List<String> _subtitles = [
    'Quickly add family expenses and view history.',
    'See category breakdowns and monthly summaries.',
    'Backup your data and restore across devices.',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _finish,
            child: const Text('Skip', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.0,
            colors: [AppColors.accent.withAlpha(150), AppColors.primaryDark],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: _lottieAssets.length,
                  onPageChanged: (i) => setState(() => _page = i),
                  itemBuilder: (context, index) {
                    return Center(
                      child: _buildPage(
                        title: _titles[index],
                        subtitle: _subtitles[index],
                        icon: Icons.circle,
                        lottieAsset: _lottieAssets[index],
                        size: switch (index) {
                          0 => 390,
                          1 => 390,
                          2 => 280,
                          _ => null,
                        },
                      ),
                    );
                  },
                ),
              ),
              // Fixed text area: title and subtitle stay in the same place
              // while animations slide above.
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  children: [
                    Text(
                      _titles[_page],
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _subtitles[_page],
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16, color: Colors.white),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 20.0,
                ),
                child: Row(
                  children: [
                    Row(
                      children: List.generate(3, (i) {
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4.0),
                          width: _page == i ? 14 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _page == i ? Colors.white : Colors.white54,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        );
                      }),
                    ),
                    const Spacer(),
                    ElevatedButton(
                      onPressed: _next,
                      child: Text(_page < 2 ? 'Next' : 'Get Started'),
                      style: ElevatedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        backgroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
