import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../app/theme/theme.dart';
import '../../core/database/app_database.dart';
import '../../core/database/repositories/repositories.dart';
import '../../core/settings/preferences.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/widgets.dart';
import '../workout/set_row.dart' show formatLoadInput, parseWeight;

/// Records a weigh-in, or corrects one already recorded.
///
/// The same sheet for both: the fields are identical, and a screen that can
/// only add would leave a mistyped number wrong forever — which quietly makes
/// the whole trend line untrue.
class WeighInSheet extends ConsumerStatefulWidget {
  const WeighInSheet({super.key, this.existing});

  /// The entry being corrected, or null when logging a new one.
  final BodyMeasurement? existing;

  static Future<void> show(BuildContext context, {BodyMeasurement? existing}) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => WeighInSheet(existing: existing),
    );
  }

  @override
  ConsumerState<WeighInSheet> createState() => _WeighInSheetState();
}

class _WeighInSheetState extends ConsumerState<WeighInSheet> {
  late final WeightUnit _unit = ref.read(weightUnitProvider);

  late final TextEditingController _weight = TextEditingController(
    text: formatLoadInput(widget.existing?.weightKg, _unit),
  );

  late DateTime _measuredAt =
      widget.existing?.measuredAt.toLocal() ?? DateTime.now();

  @override
  void dispose() {
    _weight.dispose();
    super.dispose();
  }

  double? get _weightKg {
    final typed = parseWeight(_weight.text);
    return typed == null ? null : _unit.toKilograms(typed);
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _measuredAt,
      // A weigh-in cannot be in the future, and nobody is back-filling a
      // decade of them into a phone.
      firstDate: DateTime(now.year - 5),
      lastDate: now,
    );
    if (picked != null) setState(() => _measuredAt = picked);
  }

  Future<void> _save() async {
    final weightKg = _weightKg;
    if (weightKg == null || weightKg <= 0) return;

    final body = ref.read(bodyRepositoryProvider);
    final existing = widget.existing;

    if (existing == null) {
      await body.log(weightKg: weightKg, measuredAt: _measuredAt.toUtc());
    } else {
      await body.update(
        existing.id,
        weightKg: weightKg,
        measuredAt: _measuredAt.toUtc(),
      );
    }

    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final existing = widget.existing;
    if (existing == null) return;

    await ref.read(bodyRepositoryProvider).remove(existing.id);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final today = DateUtils.isSameDay(_measuredAt, DateTime.now());

    return SafeArea(
      child: Padding(
        // Lifted by the keyboard: the weight field is focused on open, and a
        // save button hidden behind the keyboard is a dead end.
        padding: EdgeInsets.fromLTRB(
          PwrSpacing.screenH,
          PwrSpacing.xs,
          PwrSpacing.screenH,
          PwrSpacing.lg + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.bodyLogTitle, style: PwrTypography.titleMedium),
            const SizedBox(height: PwrSpacing.lg),

            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Expanded(
                  child: TextField(
                    controller: _weight,
                    autofocus: true,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                    ],
                    style: PwrTypography.metricLg,
                    decoration: const InputDecoration(
                      filled: false,
                      isDense: true,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                      hintText: '–',
                    ),
                    onSubmitted: (_) => _save(),
                  ),
                ),
                Text(
                  _unit.symbol.toUpperCase(),
                  style: PwrTypography.metricCaption,
                ),
              ],
            ),
            const Divider(color: PwrColors.border, height: PwrSpacing.xl),

            Row(
              children: [
                Expanded(child: PwrOverline(l10n.bodyLogDate)),
                PwrTag(
                  today
                      ? l10n.bodyLogToday.toUpperCase()
                      : DateFormat.yMMMd(locale).format(_measuredAt),
                  onTap: _pickDate,
                ),
              ],
            ),

            const SizedBox(height: PwrSpacing.xl),
            PwrButton(label: l10n.bodyLogSave, onPressed: _save),

            if (widget.existing != null) ...[
              const SizedBox(height: PwrSpacing.cardGap),
              PwrButton.ghost(label: l10n.bodyLogDelete, onPressed: _delete),
            ],
          ],
        ),
      ),
    );
  }
}
