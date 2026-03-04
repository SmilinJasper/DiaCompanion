import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/data_center_provider.dart';

/// Upload tab — file picker, upload status, and data management.
class UploadTab extends StatelessWidget {
  const UploadTab({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final provider = context.watch<DataCenterProvider>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Upload Dropzone Card ────────────────────────────────
          GestureDetector(
            onTap: provider.isLoading ? null : () => provider.uploadFile(),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: colorScheme.primary.withValues(alpha: 0.4),
                  width: 2,
                  strokeAlign: BorderSide.strokeAlignInside,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    provider.isLoading
                        ? Icons.hourglass_top_rounded
                        : Icons.cloud_upload_outlined,
                    size: 56,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    provider.isLoading
                        ? 'Processing file…'
                        : 'Tap to upload CSV or JSON',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Expected columns: timestamp, glucose_level,\ncarbs_intake, insulin_dose',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // ── Upload Result Banner ───────────────────────────────
          if (provider.lastResult != null) ...[
            _ResultBanner(result: provider.lastResult!),
            const SizedBox(height: 12),
          ],

          // ── Error Message ──────────────────────────────────────
          if (provider.errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: colorScheme.error),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      provider.errorMessage!,
                      style: TextStyle(color: colorScheme.onErrorContainer),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // ── Records Summary ────────────────────────────────────
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.storage_rounded,
                      color: colorScheme.secondary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Stored Records',
                          style: theme.textTheme.titleSmall,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${provider.records.length} glucose readings',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // ── Clear Data Button ──────────────────────────────────
          if (provider.records.isNotEmpty)
            OutlinedButton.icon(
              onPressed: () => _showClearDialog(context, provider),
              icon: const Icon(Icons.delete_outline_rounded),
              label: const Text('Clear All Data'),
              style: OutlinedButton.styleFrom(
                foregroundColor: colorScheme.error,
                side: BorderSide(color: colorScheme.error.withValues(alpha: 0.5)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
        ],
      ),
    );
  }

  void _showClearDialog(BuildContext context, DataCenterProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear All Data?'),
        content: const Text(
          'This will permanently delete all stored glucose readings. '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              provider.clearAllData();
              Navigator.pop(ctx);
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );
  }
}

// ─── Result Banner ──────────────────────────────────────────────────
class _ResultBanner extends StatelessWidget {
  const _ResultBanner({required this.result});

  final dynamic result; // FileParseResult

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final successCount = result.successCount as int;
    final errorCount = result.errorCount as int;
    final hasErrors = result.hasErrors as bool;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: hasErrors
            ? colorScheme.tertiaryContainer.withValues(alpha: 0.5)
            : colorScheme.primaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                hasErrors
                    ? Icons.warning_amber_rounded
                    : Icons.check_circle_outline_rounded,
                color: hasErrors ? colorScheme.tertiary : colorScheme.primary,
              ),
              const SizedBox(width: 10),
              Text(
                'Import Complete',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text('✓ $successCount records imported successfully'),
          if (hasErrors) ...[
            const SizedBox(height: 4),
            Text(
              '⚠ $errorCount rows skipped due to errors',
              style: TextStyle(color: colorScheme.error),
            ),
            const SizedBox(height: 8),
            ...List.generate(
              errorCount > 3 ? 3 : errorCount,
              (i) => Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  '  • ${(result.errors as List<String>)[i]}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
            if (errorCount > 3)
              Text(
                '  …and ${errorCount - 3} more',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
              ),
          ],
        ],
      ),
    );
  }
}
