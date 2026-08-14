import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/theme.dart';
import '../../core/database/repositories/repositories.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/widgets.dart';

/// Adjusts one exercise slot: sets, target reps, rest, and whether it is
/// chained into a superset with the next one.
class SlotEditorSheet extends ConsumerStatefulWidget {
  const SlotEditorSheet({
    super.key,
    required this.detail,
    required this.exerciseName,
    required this.canChain,
    required this.chained,
  });

  final RoutineExerciseDetail detail;
  final String exerciseName;

  /// False for the last slot — there is nothing after it to chain to.
  final bool canChain;

  final bool chained;

  /// Resolves to the chain flag the user left it on, or null if dismissed.
  static Future<bool?> show(
    BuildContext context, {
    required RoutineExerciseDetail detail,
    required String exerciseName,
    required bool canChain,
    required bool chained,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => SlotEditorSheet(
        detail: detail,
        exerciseName: exerciseName,
        canChain: canChain,
        chained: chained,
      ),
    );
  }

  @override
  ConsumerState<SlotEditorSheet> createState() => _SlotEditorSheetState();
}

class _SlotEditorSheetState extends ConsumerState<SlotEditorSheet> {
  late int _sets = widget.detail.entry.targetSets;
  late int? _reps = widget.detail.entry.targetReps;
  late int _rest = widget.detail.entry.restSeconds;
  late bool _chained = widget.chained;

  /// Rest values people actually use, rather than a free-running stepper that
  /// takes twelve taps to get from 60 to 180.
  static const _restSteps = [30, 45, 60, 90, 120, 150, 180, 240];

  RoutineRepository get _routines => ref.read(routineRepositoryProvider);

  Future<void> _persist() {
    return _routines.updateExercise(
      widget.detail.entry.id,
      targetSets: _sets,
      targetReps: _reps,
      restSeconds: _rest,
    );
  }

  Future<void> _remove() async {
    await _routines.removeExercise(widget.detail.entry.id);
    if (!mounted) return;
    Navigator.of(context).pop(false);
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
            Text(widget.exerciseName, style: PwrTypography.titleMedium),
            const SizedBox(height: PwrSpacing.lg),

            _Stepper(
              label: l10n.slotSets,
              value: '$_sets',
              onDecrement: _sets > 1 ? () => setState(() => _sets -= 1) : null,
              onIncrement: _sets < 12 ? () => setState(() => _sets += 1) : null,
            ),
            const SizedBox(height: PwrSpacing.md),

            _Stepper(
              label: l10n.slotReps,
              value: _reps == null ? l10n.slotRepsAny : '$_reps',
              // Stepping below 1 clears the target: not every movement is
              // tracked by reps, and "any" has to be reachable.
              onDecrement: _reps == null
                  ? null
                  : () =>
                        setState(() => _reps = _reps == 1 ? null : _reps! - 1),
              onIncrement: () =>
                  setState(() => _reps = _reps == null ? 1 : _reps! + 1),
            ),
            const SizedBox(height: PwrSpacing.md),

            PwrOverline(l10n.slotRest),
            const SizedBox(height: PwrSpacing.xs),
            Wrap(
              spacing: PwrSpacing.xs,
              runSpacing: PwrSpacing.xs,
              children: [
                for (final seconds in _restSteps)
                  PwrTag(
                    l10n.slotRestSeconds(seconds),
                    tone: seconds == _rest
                        ? PwrTagTone.accent
                        : PwrTagTone.neutral,
                    onTap: () => setState(() => _rest = seconds),
                  ),
              ],
            ),

            if (widget.canChain) ...[
              const SizedBox(height: PwrSpacing.lg),
              // A Free feature per spec §12, despite the prototype gating
              // supersets behind PRO.
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.routineSupersetToggle,
                      style: PwrTypography.bodySmall,
                    ),
                  ),
                  Switch(
                    value: _chained,
                    onChanged: (value) => setState(() => _chained = value),
                  ),
                ],
              ),
            ],

            const SizedBox(height: PwrSpacing.xl),
            PwrButton(
              label: l10n.routineDone,
              onPressed: () async {
                await _persist();
                if (!context.mounted) return;
                Navigator.of(context).pop(_chained);
              },
            ),
            const SizedBox(height: PwrSpacing.cardGap),
            PwrButton.ghost(label: l10n.slotRemove, onPressed: _remove),
          ],
        ),
      ),
    );
  }
}

class _Stepper extends StatelessWidget {
  const _Stepper({
    required this.label,
    required this.value,
    this.onDecrement,
    this.onIncrement,
  });

  final String label;
  final String value;
  final VoidCallback? onDecrement;
  final VoidCallback? onIncrement;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: PwrOverline(label)),
        _StepButton(icon: Icons.remove, onPressed: onDecrement),
        SizedBox(
          width: 72,
          child: Text(
            value,
            textAlign: TextAlign.center,
            style: PwrTypography.metricSm,
          ),
        ),
        _StepButton(icon: Icons.add, onPressed: onIncrement),
      ],
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({required this.icon, this.onPressed});

  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: onPressed == null ? 0.3 : 1,
      child: Material(
        color: PwrColors.surface,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: SizedBox(
            width: 36,
            height: 36,
            child: Icon(icon, size: 18, color: PwrColors.textPrimary),
          ),
        ),
      ),
    );
  }
}
