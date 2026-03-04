import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../core/services/database_service.dart';
import '../../../../shared/models/glucose_record.dart';
import '../../../data_center/providers/data_center_provider.dart';

/// Bottom sheet for manually logging a single glucose reading.
class LogGlucoseSheet extends StatefulWidget {
  const LogGlucoseSheet({super.key});

  /// Convenience method to show the sheet from any context.
  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const LogGlucoseSheet(),
    );
  }

  @override
  State<LogGlucoseSheet> createState() => _LogGlucoseSheetState();
}

class _LogGlucoseSheetState extends State<LogGlucoseSheet> {
  final _formKey = GlobalKey<FormState>();
  final _glucoseCtrl = TextEditingController();
  final _carbsCtrl = TextEditingController();
  final _insulinCtrl = TextEditingController();

  DateTime _timestamp = DateTime.now();
  bool _saving = false;

  @override
  void dispose() {
    _glucoseCtrl.dispose();
    _carbsCtrl.dispose();
    _insulinCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _timestamp,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_timestamp),
    );
    if (time == null || !mounted) return;

    setState(() {
      _timestamp = DateTime(
        date.year, date.month, date.day, time.hour, time.minute,
      );
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    final record = GlucoseRecord(
      timestamp: _timestamp,
      glucoseLevel: double.parse(_glucoseCtrl.text.trim()),
      carbsIntake: _carbsCtrl.text.trim().isNotEmpty
          ? double.tryParse(_carbsCtrl.text.trim())
          : null,
      insulinDose: _insulinCtrl.text.trim().isNotEmpty
          ? double.tryParse(_insulinCtrl.text.trim())
          : null,
    );

    await DatabaseService.addRecord(record);

    // Refresh the Data Center chart if provider is listening
    if (mounted) {
      context.read<DataCenterProvider>().loadRecords();
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '✓ Logged ${record.glucoseLevel.toStringAsFixed(0)} mg/dL',
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Handle bar ──────────────────────────────────────
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Title ───────────────────────────────────────────
            Text(
              'Log Glucose Reading',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            // ── Timestamp Picker ────────────────────────────────
            InkWell(
              onTap: _pickDateTime,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  border: Border.all(color: colorScheme.outlineVariant),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.schedule_rounded,
                        color: colorScheme.primary, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        DateFormat('MMM d, yyyy — h:mm a').format(_timestamp),
                        style: theme.textTheme.bodyLarge,
                      ),
                    ),
                    Icon(Icons.edit_rounded,
                        color: colorScheme.outline, size: 16),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Glucose Level (required) ────────────────────────
            TextFormField(
              controller: _glucoseCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Glucose Level *',
                suffixText: 'mg/dL',
                prefixIcon: Icon(Icons.water_drop_outlined,
                    color: colorScheme.primary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Required';
                }
                final n = double.tryParse(v.trim());
                if (n == null || n < 0 || n > 700) {
                  return 'Enter a valid glucose level (0–700)';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),

            // ── Carbs & Insulin (optional, side by side) ────────
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _carbsCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Carbs',
                      suffixText: 'g',
                      prefixIcon: Icon(Icons.restaurant_rounded,
                          color: colorScheme.tertiary, size: 20),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _insulinCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Insulin',
                      suffixText: 'units',
                      prefixIcon: Icon(Icons.medication_rounded,
                          color: colorScheme.secondary, size: 20),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ── Save Button ─────────────────────────────────────
            SizedBox(
              height: 50,
              child: FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.check_rounded),
                label: Text(_saving ? 'Saving...' : 'Save Reading'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
