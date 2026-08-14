import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/theme.dart';
import '../../core/database/app_database.dart';
import '../../core/database/enums.dart';
import '../../core/database/repositories/repositories.dart';
import '../../l10n/app_localizations.dart';

/// The column widths every set row and its header share.
const _columns = [34.0, null, null, 52.0];

/// One set: its number, the load, the reps, and the checkmark.
///
/// This is the row the whole product is built around — the spec's principle 12
/// calls logging a set the main UX. Everything here optimises for a single tap
/// on the checkmark, with the numbers already filled in from last time.
class SetRow extends ConsumerStatefulWidget {
  const SetRow({
    super.key,
    required this.set,
    required this.restSeconds,
    required this.onCompleted,
  });

  final WorkoutSet set;

  /// Rest to start when this set is checked off.
  final int restSeconds;

  /// Called after a set is checked off, so the screen can start resting.
  final void Function(int restSeconds) onCompleted;

  @override
  ConsumerState<SetRow> createState() => _SetRowState();
}

class _SetRowState extends ConsumerState<SetRow> {
  late final TextEditingController _weight = TextEditingController(
    text: _formatWeight(widget.set.weight),
  );
  late final TextEditingController _reps = TextEditingController(
    text: widget.set.reps?.toString() ?? '',
  );

  @override
  void didUpdateWidget(SetRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    // The fields are only re-seeded when the row starts showing a different
    // set. Writing the streamed value back on every rebuild would fight the
    // user's keystrokes, because each keystroke is itself a write.
    if (oldWidget.set.id != widget.set.id) {
      _weight.text = _formatWeight(widget.set.weight);
      _reps.text = widget.set.reps?.toString() ?? '';
    }
  }

  @override
  void dispose() {
    _weight.dispose();
    _reps.dispose();
    super.dispose();
  }

  WorkoutRepository get _workouts => ref.read(workoutRepositoryProvider);

  double? get _parsedWeight => parseWeight(_weight.text);
  int? get _parsedReps => int.tryParse(_reps.text.trim());

  Future<void> _toggle() async {
    if (widget.set.completed) {
      await _workouts.uncompleteSet(widget.set.id);
      return;
    }

    await _workouts.completeSet(
      widget.set.id,
      weight: _parsedWeight,
      reps: _parsedReps,
    );
    widget.onCompleted(widget.restSeconds);
  }

  void _persistEdits() {
    _workouts.updateSet(
      widget.set.id,
      weight: _parsedWeight,
      reps: _parsedReps,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final done = widget.set.completed;

    return Container(
      margin: const EdgeInsets.only(bottom: PwrSpacing.listGap),
      padding: const EdgeInsets.symmetric(horizontal: PwrSpacing.md),
      height: 54,
      decoration: BoxDecoration(
        color: done ? PwrColors.surfaceAccent : PwrColors.surface,
        borderRadius: PwrRadius.rowAll,
        border: Border.all(
          color: done ? PwrColors.borderAccent : Colors.transparent,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: _columns[0],
            child: Text(
              _marker(l10n),
              style: PwrTypography.label.copyWith(color: _markerColor),
            ),
          ),
          Expanded(
            child: _NumberField(controller: _weight, onEdited: _persistEdits),
          ),
          const SizedBox(width: PwrSpacing.xs),
          Expanded(
            child: _NumberField(
              controller: _reps,
              onEdited: _persistEdits,
              decimal: false,
            ),
          ),
          SizedBox(
            width: _columns[3],
            child: Align(
              alignment: Alignment.centerRight,
              child: _CheckButton(done: done, onPressed: _toggle),
            ),
          ),
        ],
      ),
    );
  }

  String _marker(AppLocalizations l10n) => switch (widget.set.type) {
    SetType.warmup => l10n.workoutSetWarmup,
    SetType.failure => l10n.workoutSetFailure,
    SetType.dropSet => l10n.workoutSetDrop,
    SetType.normal => '${widget.set.setNumber}',
  };

  Color get _markerColor => switch (widget.set.type) {
    SetType.warmup => PwrColors.setWarmup,
    SetType.failure => PwrColors.setFailure,
    SetType.dropSet => PwrColors.setDropSet,
    SetType.normal => PwrColors.textMuted,
  };
}

/// Header above a run of [SetRow]s, on the same column grid.
class SetRowHeader extends StatelessWidget {
  const SetRowHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final style = PwrTypography.navLabel.copyWith(
      color: PwrColors.textMuted,
      letterSpacing: 1.26,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        PwrSpacing.md,
        PwrSpacing.lg,
        PwrSpacing.md,
        PwrSpacing.xs,
      ),
      child: Row(
        children: [
          SizedBox(
            width: _columns[0],
            child: Text(l10n.workoutColSet.toUpperCase(), style: style),
          ),
          Expanded(
            child: Text(l10n.workoutColWeight.toUpperCase(), style: style),
          ),
          const SizedBox(width: PwrSpacing.xs),
          Expanded(
            child: Text(l10n.workoutColReps.toUpperCase(), style: style),
          ),
          SizedBox(
            width: _columns[3],
            child: Text(
              l10n.workoutColDone.toUpperCase(),
              style: style,
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}

class _NumberField extends StatelessWidget {
  const _NumberField({
    required this.controller,
    required this.onEdited,
    this.decimal = true,
  });

  final TextEditingController controller;
  final VoidCallback onEdited;
  final bool decimal;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.numberWithOptions(decimal: decimal),
      inputFormatters: [
        FilteringTextInputFormatter.allow(
          decimal ? RegExp(r'[0-9.,]') : RegExp(r'[0-9]'),
        ),
      ],
      style: PwrTypography.metricSm,
      textAlignVertical: TextAlignVertical.center,
      decoration: const InputDecoration(
        filled: false,
        isDense: true,
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        contentPadding: EdgeInsets.zero,
        hintText: '–',
      ),
      onChanged: (_) => onEdited(),
    );
  }
}

class _CheckButton extends StatelessWidget {
  const _CheckButton({required this.done, required this.onPressed});

  final bool done;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: done ? PwrColors.accentStrong : Colors.transparent,
      shape: const CircleBorder(
        side: BorderSide(color: PwrColors.borderStrong),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: SizedBox(
          width: 32,
          height: 32,
          child: Icon(
            Icons.check,
            size: 16,
            color: done ? PwrColors.onAccent : PwrColors.textFaint,
          ),
        ),
      ),
    );
  }
}

/// Parses a typed load, accepting both decimal separators.
///
/// A Brazilian types `22,5` and an American types `22.5`; the field cannot
/// know which keyboard produced it, so both are read the same way.
double? parseWeight(String raw) {
  final normalised = raw.trim().replaceAll(',', '.');
  if (normalised.isEmpty) return null;
  return double.tryParse(normalised);
}

String _formatWeight(double? weight) {
  if (weight == null) return '';
  // Whole numbers lose the trailing `.0`: nobody writes 80.0 kg on a notepad.
  return weight == weight.roundToDouble()
      ? weight.toInt().toString()
      : weight.toString();
}
