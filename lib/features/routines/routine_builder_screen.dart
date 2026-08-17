import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/theme.dart';
import '../../core/catalog/catalog_provider.dart';
import '../../core/catalog/exercise_display.dart';
import '../../core/database/app_database.dart';
import '../../core/database/repositories/repositories.dart';
import '../../core/settings/preferences.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/widgets.dart';
import 'routine_builder_providers.dart';
import 'slot_editor_sheet.dart';

/// Builds and edits a routine.
///
/// Every change writes through immediately rather than accumulating in a draft
/// the user has to remember to save. That is the offline-first rule (principles
/// 3 and 4) applied to editing: a routine half-built when the process is killed
/// is still there afterwards. "Done" navigates back; it does not commit
/// anything.
class RoutineBuilderScreen extends ConsumerWidget {
  const RoutineBuilderScreen({
    super.key,
    required this.routineId,
    this.onPickExercise,
    this.onDone,
  });

  final String routineId;

  /// Opens the library as a picker and resolves to the chosen exercise.
  final Future<Exercise?> Function()? onPickExercise;

  final VoidCallback? onDone;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final routine = ref.watch(routineProvider(routineId)).value;
    final slots =
        ref.watch(routineSlotsProvider(routineId)).value ??
        const <RoutineExerciseDetail>[];

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  PwrSpacing.screenH,
                  PwrSpacing.screenTop,
                  PwrSpacing.screenH,
                  PwrSpacing.lg,
                ),
                children: [
                  _Header(routineId: routineId, onDone: onDone),
                  const SizedBox(height: PwrSpacing.lg),
                  if (routine != null) _NameFields(routine: routine),
                  const SizedBox(height: PwrSpacing.xl),
                  PwrOverline(
                    l10n.routineExercisesHeader(slots.length),
                    trailing: slots.length > 1
                        ? Text(
                            l10n.routineReorderHint,
                            style: PwrTypography.caption,
                          )
                        : null,
                  ),
                  const SizedBox(height: PwrSpacing.sm),
                  if (slots.isEmpty)
                    const _NoExercises()
                  else
                    _SlotList(routineId: routineId, slots: slots),
                  const SizedBox(height: PwrSpacing.listGap),
                  _AddExerciseRow(
                    routineId: routineId,
                    onPickExercise: onPickExercise,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                PwrSpacing.screenH,
                0,
                PwrSpacing.screenH,
                PwrSpacing.md,
              ),
              child: PwrButton(label: l10n.routineDone, onPressed: onDone),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends ConsumerWidget {
  const _Header({required this.routineId, this.onDone});

  final String routineId;
  final VoidCallback? onDone;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    return Row(
      children: [
        IconButton(
          onPressed: onDone,
          icon: const Icon(Icons.arrow_back),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
        ),
        const SizedBox(width: PwrSpacing.sm),
        Expanded(
          child: Text(l10n.routineEdit, style: PwrTypography.titleMedium),
        ),
        IconButton(
          onPressed: () => _confirmDelete(context, ref),
          icon: const Icon(Icons.delete_outline),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
        ),
      ],
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.routineDelete),
        content: Text(l10n.routineDeleteConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              l10n.commonDelete,
              style: const TextStyle(color: PwrColors.danger),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    await ref.read(routineRepositoryProvider).delete(routineId);
    onDone?.call();
  }
}

class _NameFields extends ConsumerStatefulWidget {
  const _NameFields({required this.routine});

  final Routine routine;

  @override
  ConsumerState<_NameFields> createState() => _NameFieldsState();
}

class _NameFieldsState extends ConsumerState<_NameFields> {
  late final TextEditingController _name = TextEditingController(
    text: widget.routine.name,
  );
  late final TextEditingController _focus = TextEditingController(
    text: widget.routine.focus ?? '',
  );

  @override
  void dispose() {
    _name.dispose();
    _focus.dispose();
    super.dispose();
  }

  /// Writes on every keystroke.
  ///
  /// Cheap — it is a local row — and it means there is no unsaved state to
  /// lose if the app is killed mid-edit.
  void _persist() {
    ref
        .read(routineRepositoryProvider)
        .update(
          widget.routine.id,
          name: _name.text.trim().isEmpty ? null : _name.text,
          focus: _focus.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PwrOverline(l10n.routineNameLabel),
        TextField(
          controller: _name,
          style: PwrTypography.displaySmall,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            filled: false,
            hintText: l10n.routineNameHint,
            hintStyle: PwrTypography.displaySmall.copyWith(
              color: PwrColors.textFaint,
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: PwrSpacing.sm),
            enabledBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: PwrColors.border),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: PwrColors.accentStrong),
            ),
          ),
          onChanged: (_) => _persist(),
        ),
        const SizedBox(height: PwrSpacing.md),
        PwrOverline(l10n.routineFocusLabel),
        TextField(
          controller: _focus,
          style: PwrTypography.bodyMedium,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            filled: false,
            hintText: l10n.routineFocusHint,
            contentPadding: const EdgeInsets.symmetric(vertical: PwrSpacing.xs),
            enabledBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: PwrColors.border),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: PwrColors.accentStrong),
            ),
          ),
          onChanged: (_) => _persist(),
        ),
      ],
    );
  }
}

class _SlotList extends ConsumerWidget {
  const _SlotList({required this.routineId, required this.slots});

  final String routineId;
  final List<RoutineExerciseDetail> slots;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final catalog = ref.watch(exerciseCatalogProvider);
    final language = Localizations.localeOf(context).languageCode;
    final chains = chainFlagsOf(slots);

    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      buildDefaultDragHandles: false,
      itemCount: slots.length,
      // `onReorderItem` rather than the deprecated `onReorder`: it hands over
      // the destination index already corrected for the removed item, so there
      // is no off-by-one to get wrong when dragging downwards.
      onReorderItem: (oldIndex, newIndex) {
        final ordered = [for (final slot in slots) slot.entry.id];
        ordered.insert(newIndex, ordered.removeAt(oldIndex));
        ref.read(routineRepositoryProvider).reorderExercises(ordered);
      },
      itemBuilder: (context, index) {
        final slot = slots[index];
        final name = slot.exercise.displayName(catalog, language);

        return Padding(
          key: ValueKey(slot.entry.id),
          padding: const EdgeInsets.only(bottom: PwrSpacing.listGap),
          child: PwrListRow(
            title: name,
            subtitle: chains[index]
                ? l10n.routineSupersetMarker.toUpperCase()
                : _summary(l10n, slot),
            subtitleColor: chains[index] ? PwrColors.accent : null,
            accentBar: chains[index] || (index > 0 && chains[index - 1]),
            leading: ReorderableDragStartListener(
              index: index,
              child: const Icon(
                Icons.drag_indicator,
                size: 18,
                color: PwrColors.textFaint,
              ),
            ),
            trailing: const Icon(Icons.tune, size: 16),
            onTap: () => _editSlot(context, ref, index, name),
          ),
        );
      },
    );
  }

  String _summary(AppLocalizations l10n, RoutineExerciseDetail slot) {
    final entry = slot.entry;
    final reps = entry.targetReps;
    final text = reps == null
        ? l10n.routineSlotSummary(entry.targetSets, entry.restSeconds)
        : l10n.routineSlotSummaryWithReps(
            entry.targetSets,
            reps,
            entry.restSeconds,
          );
    return text.toUpperCase();
  }

  Future<void> _editSlot(
    BuildContext context,
    WidgetRef ref,
    int index,
    String name,
  ) async {
    final chains = chainFlagsOf(slots);
    final isLast = index == slots.length - 1;

    final chained = await SlotEditorSheet.show(
      context,
      detail: slots[index],
      exerciseName: name,
      canChain: !isLast,
      chained: chains[index],
    );

    if (chained == null || isLast || chained == chains[index]) return;

    final updated = [...chains]..[index] = chained;
    await ref
        .read(routineRepositoryProvider)
        .setSupersetChains(routineId, updated);
  }
}

class _AddExerciseRow extends ConsumerWidget {
  const _AddExerciseRow({required this.routineId, this.onPickExercise});

  final String routineId;
  final Future<Exercise?> Function()? onPickExercise;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    return PwrListRow.placeholder(
      title: l10n.routineAddExercise,
      leading: const Icon(Icons.add, size: 16, color: PwrColors.textMuted),
      onTap: onPickExercise == null
          ? null
          : () async {
              final exercise = await onPickExercise!();
              if (exercise == null) return;
              await ref
                  .read(routineRepositoryProvider)
                  .addExercise(
                    routineId: routineId,
                    exerciseId: exercise.id,
                    restSeconds: ref.read(preferencesProvider).defaultRestSeconds,
                  );
            },
    );
  }
}

class _NoExercises extends StatelessWidget {
  const _NoExercises();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return PwrCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.routineNoExercises, style: PwrTypography.titleLarge),
          const SizedBox(height: PwrSpacing.xs),
          Text(
            l10n.routineNoExercisesBody,
            style: PwrTypography.bodyLarge.copyWith(color: PwrColors.textMuted),
          ),
        ],
      ),
    );
  }
}
