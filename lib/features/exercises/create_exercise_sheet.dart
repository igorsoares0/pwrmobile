import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/theme.dart';
import '../../core/database/app_database.dart';
import '../../core/database/enums.dart';
import '../../core/database/repositories/repositories.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/widgets.dart';
import 'exercise_labels.dart';

/// Creates a user-defined exercise.
///
/// A Free feature (spec §12), not a PRO one — the prototype shows it behind a
/// lock, but the library is only genuinely useful if the movement your gym has
/// and the catalogue lacks can be added without paying.
class CreateExerciseSheet extends ConsumerStatefulWidget {
  const CreateExerciseSheet({super.key, this.initialName});

  /// Prefills the name, so a search that found nothing can flow straight into
  /// creating what was searched for.
  final String? initialName;

  /// Opens the sheet and resolves to the created exercise, or null if
  /// dismissed.
  static Future<Exercise?> show(BuildContext context, {String? initialName}) {
    return showModalBottomSheet<Exercise>(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: CreateExerciseSheet(initialName: initialName),
      ),
    );
  }

  @override
  ConsumerState<CreateExerciseSheet> createState() =>
      _CreateExerciseSheetState();
}

class _CreateExerciseSheetState extends ConsumerState<CreateExerciseSheet> {
  late final TextEditingController _name = TextEditingController(
    text: widget.initialName,
  );

  MuscleGroup _muscleGroup = MuscleGroup.chest;
  Equipment _equipment = Equipment.barbell;
  bool _nameMissing = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _nameMissing = true);
      return;
    }

    final created = await ref
        .read(exerciseRepositoryProvider)
        .create(name: name, muscleGroup: _muscleGroup, equipment: _equipment);

    if (!mounted) return;
    Navigator.of(context).pop(created);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          PwrSpacing.screenH,
          PwrSpacing.xs,
          PwrSpacing.screenH,
          PwrSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.createExerciseTitle, style: PwrTypography.titleMedium),
            const SizedBox(height: PwrSpacing.lg),

            PwrOverline(l10n.createExerciseNameLabel),
            const SizedBox(height: PwrSpacing.xs),
            TextField(
              controller: _name,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              style: PwrTypography.bodyMedium,
              decoration: InputDecoration(
                hintText: l10n.createExerciseNameHint,
                errorText: _nameMissing
                    ? l10n.createExerciseNameRequired
                    : null,
              ),
              onChanged: (_) {
                if (_nameMissing) setState(() => _nameMissing = false);
              },
              onSubmitted: (_) => _save(),
            ),
            const SizedBox(height: PwrSpacing.lg),

            PwrOverline(l10n.createExerciseMuscleLabel),
            const SizedBox(height: PwrSpacing.xs),
            _ChoiceChips<MuscleGroup>(
              values: MuscleGroup.values,
              selected: _muscleGroup,
              labelOf: (value) => value.label(l10n),
              onSelected: (value) => setState(() => _muscleGroup = value),
            ),
            const SizedBox(height: PwrSpacing.lg),

            PwrOverline(l10n.createExerciseEquipmentLabel),
            const SizedBox(height: PwrSpacing.xs),
            _ChoiceChips<Equipment>(
              values: Equipment.values,
              selected: _equipment,
              labelOf: (value) => value.label(l10n),
              onSelected: (value) => setState(() => _equipment = value),
            ),
            const SizedBox(height: PwrSpacing.xl),

            PwrButton(label: l10n.createExerciseSave, onPressed: _save),
          ],
        ),
      ),
    );
  }
}

class _ChoiceChips<T> extends StatelessWidget {
  const _ChoiceChips({
    required this.values,
    required this.selected,
    required this.labelOf,
    required this.onSelected,
  });

  final List<T> values;
  final T selected;
  final String Function(T) labelOf;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: PwrSpacing.xs,
      runSpacing: PwrSpacing.xs,
      children: [
        for (final value in values)
          PwrTag(
            labelOf(value),
            tone: value == selected ? PwrTagTone.accent : PwrTagTone.neutral,
            textStyle: PwrTypography.buttonSmall,
            onTap: () => onSelected(value),
          ),
      ],
    );
  }
}
