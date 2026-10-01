import 'package:flutter/material.dart';

import '../models/savings_goal.dart';
import '../state/app_state_scope.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/animated_progress_bar.dart';
import 'add_savings_goal_screen.dart';
import 'savings_goal_detail_screen.dart';

class SavingsScreen extends StatelessWidget {
  const SavingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appState = AppStateScope.of(context);

    if (appState.isLoading && appState.savingsGoals.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final goals = appState.savingsGoals;

    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        floatingActionButton: FloatingActionButton(
          heroTag: 'savings_add_goal',
          backgroundColor: AppColors.ink,
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AddSavingsGoalScreen()),
            );
          },
          child: const Icon(Icons.add),
        ),
        body: RefreshIndicator(
          onRefresh: appState.refreshSavingsGoals,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
            children: [
              Text('Capital', style: theme.textTheme.headlineMedium),
              const SizedBox(height: 4),
              Text('Tus metas', style: theme.textTheme.bodyMedium),
              const SizedBox(height: 20),
              if (goals.isEmpty)
                Text('Todavía no tienes metas de capital.', style: theme.textTheme.bodyMedium)
              else
                ...goals.map((g) => _GoalCard(goal: g)),
            ],
          ),
        ),
      ),
    );
  }
}

class _GoalCard extends StatelessWidget {
  final SavingsGoal goal;
  const _GoalCard({required this.goal});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => SavingsGoalDetailScreen(goal: goal)),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.line),
          borderRadius: BorderRadius.circular(AppRadii.card),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(goal.name, style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
                Icon(Icons.chevron_right, size: 18, color: AppColors.slate),
              ],
            ),
            const SizedBox(height: 10),
            AnimatedProgressBar(
              value: goal.progress,
              backgroundColor: AppColors.line,
              color: AppColors.brass,
            ),
            const SizedBox(height: 8),
            Text(
              '${AppFormatters.currency(goal.currentAmount)} de ${AppFormatters.currency(goal.targetAmount)} '
              '· ${(goal.progress * 100).toStringAsFixed(0)}%',
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
