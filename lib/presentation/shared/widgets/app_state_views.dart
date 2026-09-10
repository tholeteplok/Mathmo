import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import 'chunky_button.dart';

class AppLoadingView extends StatelessWidget {
  const AppLoadingView({super.key, this.message = 'Memuat...'});
  final String message;
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const CircularProgressIndicator(color: AppTheme.colorWoodMedium),
        const SizedBox(height: 12),
        Text(message, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.colorTaupe, fontWeight: FontWeight.w700)),
      ]),
    );
  }
}

class AppErrorView extends StatelessWidget {
  const AppErrorView({super.key, required this.message, this.onRetry});
  final String message;
  final VoidCallback? onRetry;
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.error_outline_rounded, size: 44, color: AppTheme.colorDanger),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.colorEspresso, fontWeight: FontWeight.w700)),
          if (onRetry != null) ...[
            const SizedBox(height: 16),
            ChunkyButton(onPressed: onRetry, backgroundColor: AppTheme.colorHoney, child: const Text('Coba Lagi', style: TextStyle(fontWeight: FontWeight.w800))),
          ],
        ]),
      ),
    );
  }
}

class AppEmptyView extends StatelessWidget {
  const AppEmptyView({super.key, required this.message, this.icon = Icons.inbox_rounded});
  final String message;
  final IconData icon;
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 44, color: AppTheme.colorTaupe),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.colorTaupe, fontWeight: FontWeight.w700)),
        ]),
      ),
    );
  }
}