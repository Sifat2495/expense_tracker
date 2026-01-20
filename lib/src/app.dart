import 'package:flutter/material.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:flutter/services.dart';

import '../services/storage_service.dart';
import 'core/theme.dart';
import 'screens/splash_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/expense_home.dart';

class ExpenseApp extends StatefulWidget {
  final StorageService storage;

  const ExpenseApp({Key? key, required this.storage}) : super(key: key);

  @override
  State<ExpenseApp> createState() => _ExpenseAppState();
}

class _ExpenseAppState extends State<ExpenseApp> {
  bool _showSplash = true;
  bool _showOnboarding = false;

  @override
  void initState() {
    super.initState();
    // Set status bar style
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );
    // Register ShowcaseView (v5+ API). This prepares global showcase configuration.
    try {
      ShowcaseView.register();
    } catch (_) {}
  }

  @override
  void dispose() {
    try {
      ShowcaseView.get().unregister();
    } catch (_) {}
    super.dispose();
  }

  void _onSplashComplete() {
    _handleSplashComplete();
  }

  Future<void> _handleSplashComplete() async {
    // For debug: always show onboarding. To restore one-time behaviour,
    // uncomment the prefs check below and set `_showOnboarding = !seen`.
    // final seen = widget.storage.prefs.getBool('seen_onboarding_v1') ?? false;
    setState(() {
      _showSplash = false;
      _showOnboarding = true; // always show onboarding for debugging
    });
  }

  void _onOnboardingComplete() {
    setState(() {
      _showOnboarding = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Family Expense Tracker',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: AnimatedSwitcher(
        duration: const Duration(milliseconds: 500),
        transitionBuilder: (Widget child, Animation<double> animation) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        child: _showSplash
          ? SplashScreen(key: const ValueKey('splash'), onComplete: _onSplashComplete)
          : (_showOnboarding
            ? OnboardingScreen(key: const ValueKey('onboarding'), storage: widget.storage, onComplete: _onOnboardingComplete)
            : ExpenseHome(key: const ValueKey('home'), storage: widget.storage)),
      ),
    );
  }
}
