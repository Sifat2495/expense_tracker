import 'package:flutter/material.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../models/expense.dart';
import '../../services/storage_service.dart';
import '../../services/drive_backup_service.dart';
import '../core/theme.dart';
import '../core/app_dialogs.dart';
import '../core/snackbar_service.dart';
import '../core/loading_overlay.dart';
import 'categories_page.dart';
import '../widgets/add_expense_dialog.dart';
import 'summary_page.dart';
import 'expense_history_page.dart';
import '../widgets/expense_history.dart';
import '../widgets/month_progress.dart';
import '../widgets/category_breakdown.dart';

final _uuid = Uuid();

class ExpenseHome extends StatefulWidget {
  final StorageService storage;
  const ExpenseHome({Key? key, required this.storage}) : super(key: key);

  @override
  State<ExpenseHome> createState() => _ExpenseHomeState();
}

class _ExpenseHomeState extends State<ExpenseHome> {
  late List<Expense> _expenses;
  // Categories are loaded from storage; fallback defaults provided.
  late Map<String, List<String>> _categories;
  late Map<String, double> _budgets;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final DriveBackupService _driveBackup = DriveBackupService();
  bool _isBackupInProgress = false;
  // Showcase keys
  final GlobalKey _menuKey = GlobalKey();
  final GlobalKey _fabKey = GlobalKey();
  final GlobalKey _historyHeaderKey = GlobalKey();
  final GlobalKey _historyResultsKey = GlobalKey();
  final GlobalKey _categoryHeaderKey = GlobalKey();
  // Drawer showcase keys
  final GlobalKey _drawerCategoriesKey = GlobalKey();
  final GlobalKey _drawerSignInKey = GlobalKey();
  final GlobalKey _drawerBackupKey = GlobalKey();
  final GlobalKey _monthProgressKey = GlobalKey();
  final GlobalKey _drawerSummaryKey = GlobalKey();
  final GlobalKey _drawerExpenseHistoryKey = GlobalKey();
  final GlobalKey _drawerRestoreKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _expenses = widget.storage.loadExpenses();
    _categories = widget.storage.loadCategories();
    final now = DateTime.now();
    _budgets = widget.storage.loadBudgetsForMonth(now.year, now.month);
    // do not inject any default categories or subcategories; keep storage as-is (empty if nothing saved)
    _maybeStartTutorial();
    
    // Restore persistent login from previous session
    _restorePersistentLogin();
  }
  
  /// Restores the persistent login session from app startup
  Future<void> _restorePersistentLogin() async {
    final restored = await _driveBackup.restorePersistentLogin();
    if (mounted && restored) {
      setState(() {});
    }
  }

  Future<void> _maybeStartTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getBool('seen_home_tutorial') ?? false;
    if (seen) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      try {
        ShowcaseView.get().startShowCase([_menuKey, _monthProgressKey, _categoryHeaderKey, _historyHeaderKey, _fabKey]);
      } catch (_) {}
    });

    await prefs.setBool('seen_home_tutorial', true);
  }

  // Future<void> _maybeStartTutorial() async {
  //   // Start showcase after first frame using the v5 API
  //   WidgetsBinding.instance.addPostFrameCallback((_) {
  //     if (!mounted) return;
  //     try {
  //       ShowcaseView.get().startShowCase([
  //         _menuKey,
  //         _monthProgressKey,
  //         _categoryHeaderKey,
  //         _historyResultsKey,
  //         _fabKey,
  //       ]);
  //     } catch (_) {}
  //   });
  // }

  Future<void> _addExpense({
    required String category,
    required String subCategory,
    required String title,
    required double amount,
    required String details,
    required DateTime date,
  }) async {
    final exp = Expense(
      id: _uuid.v4(),
      category: category,
      subCategory: subCategory,
      title: title,
      amount: amount,
      details: details,
      date: date,
    );
    setState(() => _expenses.insert(0, exp));
    await widget.storage.saveExpenses(_expenses);
  }

  Future<void> _removeExpense(String id) async {
    setState(() => _expenses.removeWhere((e) => e.id == id));
    await widget.storage.saveExpenses(_expenses);
  }

  void _showAddDialog() {
    showDialog(
      context: context,
      builder: (c) => AddExpenseDialog(
        categories: _categories,
        onAdd: (category, sub, title, amount, details, date) async {
          await _addExpense(
            category: category,
            subCategory: sub,
            title: title,
            amount: amount,
            details: details,
            date: date,
          );
        },
      ),
    );
  }

  Future<void> _handleGoogleSignIn() async {
    if (_driveBackup.isSignedIn()) {
      // Confirm sign out
      final confirm = await AppDialogs.showConfirmation(
        context,
        title: 'Sign Out',
        message: 'Are you sure you want to sign out from Google Drive?',
        confirmText: 'Sign Out',
        cancelText: 'Cancel',
      );

      if (!confirm) return;

      await _driveBackup.signOut();
      setState(() {});
      if (mounted) {
        SnackbarService.showInfo(context, 'Signed out from Google');
      }
    } else {
      // Sign in with loading
      AppDialogs.showLoading(context, message: 'Signing in...');

      final success = await _driveBackup.signIn();

      if (mounted) {
        AppDialogs.hideLoading(context);
        setState(() {});

        if (success) {
          SnackbarService.showSuccess(
            context,
            'Signed in as ${_driveBackup.getCurrentUserEmail()}',
          );
        } else {
          await AppDialogs.showError(
            context,
            title: 'Sign-in Failed',
            message:
                'Could not sign in with Google. Please check your internet connection and try again.',
          );
        }
      }
    }
  }

  Future<void> _handleBackup() async {
    if (!_driveBackup.isSignedIn()) {
      await AppDialogs.showWarning(
        context,
        title: 'Sign In Required',
        message: 'Please sign in with Google first to backup your data.',
      );
      return;
    }

    setState(() => _isBackupInProgress = true);

    try {
      final message = await _driveBackup.createBackup(widget.storage);
      if (mounted) {
        await AppDialogs.showSuccess(
          context,
          title: 'Backup Complete',
          message: message,
        );
      }
    } catch (e) {
      if (mounted) {
        await AppDialogs.showError(
          context,
          title: 'Backup Failed',
          message: 'Could not backup data: ${e.toString()}',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isBackupInProgress = false);
      }
    }
  }

  Future<void> _handleRestore() async {
    if (!_driveBackup.isSignedIn()) {
      await AppDialogs.showWarning(
        context,
        title: 'Sign In Required',
        message: 'Please sign in with Google first to restore your data.',
      );
      return;
    }

    // Confirm restore action
    final confirm = await AppDialogs.showConfirmation(
      context,
      title: 'Restore Backup',
      message:
          'This will replace all your current data with the backup. This action cannot be undone.',
      confirmText: 'Restore',
      cancelText: 'Cancel',
      isDangerous: true,
    );

    if (!confirm) return;

    setState(() => _isBackupInProgress = true);

    try {
      final message = await _driveBackup.restoreBackup(widget.storage);

      // Reload data after restore
      setState(() {
        _expenses = widget.storage.loadExpenses();
        _categories = widget.storage.loadCategories();
        final now = DateTime.now();
        _budgets = widget.storage.loadBudgetsForMonth(now.year, now.month);
      });

      if (mounted) {
        await AppDialogs.showSuccess(
          context,
          title: 'Restore Complete',
          message: message,
        );
      }
    } catch (e) {
      if (mounted) {
        await AppDialogs.showError(
          context,
          title: 'Restore Failed',
          message: 'Could not restore data: ${e.toString()}',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isBackupInProgress = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    final now = DateTime.now();
    final monthExpenses = _expenses
        .where((e) => e.date.year == now.year && e.date.month == now.month)
        .toList();
    final totalSpent = monthExpenses.fold<double>(0.0, (p, n) => p + n.amount);
    final totalBudget = _budgets.values.fold<double>(0.0, (p, n) => p + n);

    return LoadingOverlay(
      isLoading: _isBackupInProgress,
      message: 'Please wait...',
      child: Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          elevation: 0,
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: AppColors.primaryGradient,
            ),
          ),
          centerTitle: false,
          title: const Text(
            'Family Expense Tracker',
            style: AppTextStyles.appBarTitle,
          ),
          actions: [
            Container(
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Showcase(
                key: _menuKey,
                description: 'Open the menu to access settings and backups',
                child: IconButton(
                  icon: const Icon(Icons.menu, color: Colors.white),
                  onPressed: () {
                    _scaffoldKey.currentState?.openEndDrawer();
                    Future.delayed(const Duration(milliseconds: 600), () async {
                      try {
                        final prefs = await SharedPreferences.getInstance();
                        final seen = prefs.getBool('seen_drawer_tutorial') ?? false;
                        if (!seen) {
                          ShowcaseView.get().startShowCase([
                            _drawerCategoriesKey,
                            _drawerSummaryKey,
                            _drawerExpenseHistoryKey,
                            _drawerSignInKey,
                            _drawerBackupKey,
                            _drawerRestoreKey,
                          ]);
                          await prefs.setBool('seen_drawer_tutorial', true);
                        }
                      } catch (_) {}
                    });
                  },
                  tooltip: 'Open Menu',
                ),
              ),
            ),
          ],
        ),
        endDrawer: _buildDrawer(width),
        body: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async {
            setState(() {
              _expenses = widget.storage.loadExpenses();
              _categories = widget.storage.loadCategories();
              final now = DateTime.now();
              _budgets = widget.storage.loadBudgetsForMonth(
                now.year,
                now.month,
              );
            });
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Gradient header extension
                Showcase(
                  key: _monthProgressKey,
                  description: 'View your monthly budget progress here',
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: AppColors.primaryGradient,
                    ),
                    child: Container(
                      decoration: const BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(AppDimens.radiusXL),
                          topRight: Radius.circular(AppDimens.radiusXL),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppDimens.paddingL,
                          AppDimens.paddingL,
                          AppDimens.paddingL,
                          AppDimens.paddingS,
                        ),
                        child: MonthProgress(
                          totalBudget: totalBudget,
                          totalSpent: totalSpent,
                        ),
                      ),
                    ),
                  ),
                ),

                // Category section
                Showcase(
                  key: _categoryHeaderKey,
                  description: 'See spending by category',
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimens.paddingL,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionHeader(
                          'Category Wise Expenses',
                          Icons.pie_chart_outline,
                        ),
                        const SizedBox(height: AppDimens.paddingS),
                        CategoryBreakdown(
                          monthExpenses: monthExpenses,
                          budgets: _budgets,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: AppDimens.paddingL),

                // History section (header + list) showcased together to indicate scroll
                Showcase(
                  key: _historyResultsKey,
                  description: 'Recent transactions appear here — scroll down to see more',
                  enableAutoScroll: true,
                  child: Column(
                    children: [
                      // Header
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.symmetric(
                          horizontal: AppDimens.paddingL,
                        ),
                        padding: const EdgeInsets.symmetric(
                          vertical: AppDimens.paddingM,
                          horizontal: AppDimens.paddingL,
                        ),
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(AppDimens.radiusM),
                          boxShadow: AppShadows.small,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.history,
                              color: Colors.white,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Recent Transactions',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // List
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppDimens.paddingL,
                          vertical: AppDimens.paddingS,
                        ),
                        child: ExpenseHistory(
                          expenses: _expenses,
                          onRemove: (id) async {
                            final confirm = await AppDialogs.showConfirmation(
                              context,
                              title: 'Delete Expense',
                              message:
                                  'Are you sure you want to delete this expense?',
                              confirmText: 'Delete',
                              cancelText: 'Cancel',
                              isDangerous: true,
                            );
                            if (confirm) {
                              await _removeExpense(id);
                              if (mounted) {
                                SnackbarService.showSuccess(
                                  context,
                                  'Expense deleted',
                                );
                              }
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        floatingActionButton: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.4),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Showcase(
            key: _fabKey,
            description: 'Tap to quickly add a new expense',
            child: FloatingActionButton(
              elevation: 0,
              onPressed: _showAddDialog,
              child: const Icon(Icons.add, size: 28),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: AppDimens.paddingS,
        horizontal: AppDimens.paddingM,
      ),
      decoration: BoxDecoration(
        color: AppColors.primaryLight.withOpacity(0.3),
        borderRadius: BorderRadius.circular(AppDimens.radiusS),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: AppTextStyles.heading3.copyWith(color: AppColors.primary),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer(double width) {
    return Drawer(
      width: width * 0.78,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(AppDimens.radiusXL),
          bottomLeft: Radius.circular(AppDimens.radiusXL),
        ),
      ),
      child: Column(
        children: [
          // Drawer header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 50, 20, 14),
            decoration: const BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(AppDimens.radiusXL),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      'lib/assets/logo/logo.png',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.account_balance_wallet,
                          size: 32,
                          color: AppColors.primary,
                        );
                      },
                    ),
                  ),
                ),
                // const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'Menu',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppDimens.paddingM,
                          vertical: 0,
                        ),
                        backgroundColor: AppColors.primaryLight,
                        foregroundColor: AppColors.primaryDark,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Show Tutorial'),
                      onPressed: () {
                        Future.delayed(const Duration(milliseconds: 300), () {
                          try {
                            ShowcaseView.get().startShowCase([
                              _drawerCategoriesKey,
                              _drawerSummaryKey,
                              _drawerExpenseHistoryKey,
                              _drawerSignInKey,
                              _drawerBackupKey,
                              _drawerRestoreKey,
                            ]);
                          } catch (_) {}
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Menu items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: AppDimens.paddingL),
              children: [
                Showcase(
                  key: _drawerCategoriesKey,
                  description: 'Manage categories and budgets',
                  child: _buildDrawerItem(
                    icon: Icons.category_outlined,
                    title: 'Categories & Budgets',
                    subtitle: 'Manage spending categories',
                    onTap: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).push(
                        FadePageRoute(
                          page: CategoriesPage(
                            categories: _categories,
                            onChanged: (m) async {
                              setState(() => _categories = Map.from(m));
                              await widget.storage.saveCategories(_categories);
                            },
                            budgets: _budgets,
                            onBudgetsChanged: (b) async {
                              setState(() => _budgets = Map.from(b));
                              final now = DateTime.now();
                              await widget.storage.saveBudgetsForMonth(
                                now.year,
                                now.month,
                                _budgets,
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Showcase(
                  key: _drawerSummaryKey,
                  description: 'View spending analytics',
                  child: _buildDrawerItem(
                    icon: Icons.bar_chart_outlined,
                    title: 'Summary',
                    subtitle: 'View spending analytics',
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).push(
                      FadePageRoute(
                        page: SummaryPage(
                          expenses: _expenses,
                          budgets: _budgets,
                        ),
                      ),
                    );
                  },
                ),
                ),
                Showcase(
                  key: _drawerExpenseHistoryKey,
                  description: 'Browse all transactions',
                  child: _buildDrawerItem(
                    icon: Icons.history_outlined,
                    title: 'Expense History',
                    subtitle: 'Browse all transactions',
                    onTap: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).push(
                        FadePageRoute(
                          page: ExpenseHistoryPage(expenses: _expenses),
                        ),
                    );
                  },
                ),
                ),

                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Divider(),
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.cloud_outlined,
                        size: 18,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'GOOGLE DRIVE BACKUP',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textSecondary,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),

                Showcase(
                  key: _drawerSignInKey,
                  description: 'Sign in to enable Drive backups',
                  child: _buildDrawerItem(
                    icon: _driveBackup.isSignedIn()
                        ? Icons.logout
                        : Icons.login,
                    title: _driveBackup.isSignedIn()
                        ? 'Sign Out'
                        : 'Sign In with Google',
                    subtitle: _driveBackup.isSignedIn()
                        ? _driveBackup.getCurrentUserEmail() ?? 'Connected'
                        : 'Connect to backup your data',
                    onTap: _isBackupInProgress
                        ? null
                        : () {
                            Navigator.of(context).pop();
                            _handleGoogleSignIn();
                          },
                    isEnabled: !_isBackupInProgress,
                  ),
                ),
                Showcase(
                  key: _drawerBackupKey,
                  description: 'Backup your data to Google Drive',
                  child: _buildDrawerItem(
                    icon: Icons.cloud_upload_outlined,
                    title: 'Backup to Drive',
                    subtitle: 'Save your data securely',
                    onTap: _isBackupInProgress
                        ? null
                        : () {
                            Navigator.of(context).pop();
                            _handleBackup();
                          },
                    isEnabled:
                        !_isBackupInProgress && _driveBackup.isSignedIn(),
                  ),
                ),
                Showcase(
                  key: _drawerRestoreKey,
                  description: 'Recover your backup',
                  child:
                _buildDrawerItem(
                  icon: Icons.cloud_download_outlined,
                  title: 'Restore from Drive',
                  subtitle: 'Recover your backup',
                  onTap: _isBackupInProgress
                      ? null
                      : () {
                          Navigator.of(context).pop();
                          _handleRestore();
                        },
                  isEnabled: !_isBackupInProgress && _driveBackup.isSignedIn(),
                ),
                ),
              ],
            ),
          ),

          // Footer
          Container(
            padding: const EdgeInsets.all(20),
            child: Text(
              'Family Expense Tracker v1.0',
              style: TextStyle(fontSize: 12, color: AppColors.textHint),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
    bool isEnabled = true,
    GlobalKey? showcaseKey,
    String? showcaseDescription,
  }) {
    final tile = Opacity(
      opacity: isEnabled ? 1.0 : 0.5,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.primaryLight.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.primary),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          subtitle,
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        onTap: isEnabled ? onTap : null,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );

    if (showcaseKey != null) {
      return Showcase(
        key: showcaseKey,
        description: showcaseDescription ?? '',
        child: tile,
      );
    }
    return tile;
  }

  // category breakdown moved to `CategoryBreakdown` widget
}
