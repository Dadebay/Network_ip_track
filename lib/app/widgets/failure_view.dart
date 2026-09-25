import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../core/errors/app_failure.dart';
import 'themed_huge_icon.dart';

/// Shared error state: a short user message with a recovery action, plus a
/// collapsible technical-detail section carrying the correlation ID that
/// also appears in the log line for this failure.
class FailureView extends StatelessWidget {
  const FailureView({super.key, required this.failure, this.onRetry});

  final AppFailure failure;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ThemedHugeIcon(
                HugeIcons.strokeRoundedAlertCircle,
                size: 40,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 12),
              Text(
                failure.userMessage,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              if (onRetry != null) ...[
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: onRetry,
                  icon: const ThemedHugeIcon(HugeIcons.strokeRoundedRefresh),
                  label: const Text('Tekrar dene'),
                ),
              ],
              if (failure.technicalDetail != null) ...[
                const SizedBox(height: 12),
                ExpansionTile(
                  title: const Text('Teknik detay'),
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: SelectableText(
                        '${failure.technicalDetail}\n\nCorrelation ID: ${failure.correlationId}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
