import 'package:flutter/material.dart';
import '../core/theme.dart';

class MonthProgress extends StatelessWidget {
  final double totalBudget;
  final double totalSpent;
  const MonthProgress({Key? key, required this.totalBudget, required this.totalSpent}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final hasBudget = totalBudget > 0;
    final progress = hasBudget ? (totalSpent / totalBudget).clamp(0.0, 1.0) : 0.0;
    final over = hasBudget && totalSpent > totalBudget;
    final remaining = totalBudget - totalSpent;
    final remainingPct = hasBudget ? (remaining / totalBudget * 100).clamp(-999.0, 999.0) : 0.0;

    final now = DateTime.now();
    const monthNames = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];

    return Container(
      width: double.infinity,
      child: Column(
        children: [
          // Month header
          Container(
            padding: const EdgeInsets.symmetric(
              vertical: AppDimens.paddingS,
              horizontal: AppDimens.paddingL,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primaryLight.withOpacity(0.3),
                  AppColors.primaryLight.withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(AppDimens.radiusL),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.calendar_month, size: 18, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  '${monthNames[now.month - 1]} ${now.year}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: AppDimens.paddingL),
          
          // Circular progress
          Stack(
            alignment: Alignment.center,
            children: [
              // Outer decorative ring
              Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      (over ? AppColors.errorLight : AppColors.primaryLight).withOpacity(0.5),
                      (over ? AppColors.errorLight : AppColors.primaryLight).withOpacity(0.1),
                    ],
                  ),
                ),
              ),
              
              // Progress ring background
              SizedBox(
                width: 170,
                height: 170,
                child: CircularProgressIndicator(
                  value: 1.0,
                  strokeWidth: 14,
                  strokeCap: StrokeCap.round,
                  color: AppColors.divider.withOpacity(0.5),
                ),
              ),
              
              // Actual progress
              SizedBox(
                width: 170,
                height: 170,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: progress),
                  duration: const Duration(milliseconds: 1000),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) {
                    return CircularProgressIndicator(
                      value: value,
                      strokeWidth: 14,
                      strokeCap: StrokeCap.round,
                      color: over ? AppColors.error : AppColors.success,
                      backgroundColor: Colors.transparent,
                    );
                  },
                ),
              ),
              
              // Inner white circle
              Container(
                width: 145,
                height: 145,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
              
              // Center content
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Spent',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: totalSpent),
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, child) {
                      return Text(
                        '${value.toStringAsFixed(0)} Tk',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: over ? AppColors.error : AppColors.textPrimary,
                        ),
                      );
                    },
                  ),
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    width: 60,
                    height: 1,
                    color: AppColors.divider,
                  ),
                  Text(
                    'Budget',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${totalBudget.toStringAsFixed(0)} Tk',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          const SizedBox(height: AppDimens.paddingL),
          
          // Status indicator
          Container(
            padding: const EdgeInsets.symmetric(
              vertical: AppDimens.paddingS,
              horizontal: AppDimens.paddingL,
            ),
            decoration: BoxDecoration(
              color: over 
                  ? AppColors.errorLight 
                  : hasBudget 
                      ? AppColors.successLight 
                      : AppColors.infoLight,
              borderRadius: BorderRadius.circular(AppDimens.radiusL),
              border: Border.all(
                color: over 
                    ? AppColors.error.withOpacity(0.3) 
                    : hasBudget 
                        ? AppColors.success.withOpacity(0.3) 
                        : AppColors.info.withOpacity(0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  over 
                      ? Icons.warning_amber_outlined 
                      : hasBudget 
                          ? Icons.check_circle_outline 
                          : Icons.info_outline,
                  size: 18,
                  color: over 
                      ? AppColors.error 
                      : hasBudget 
                          ? AppColors.success 
                          : AppColors.info,
                ),
                const SizedBox(width: 8),
                Text(
                  over
                      ? 'Over budget by ${(-remaining).toStringAsFixed(0)} Tk'
                      : hasBudget
                          ? '${remainingPct.toStringAsFixed(0)}% remaining (${remaining.toStringAsFixed(0)} Tk)'
                          : 'Set a budget to track progress',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: over 
                        ? AppColors.error 
                        : hasBudget 
                            ? AppColors.success 
                            : AppColors.info,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
