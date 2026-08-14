import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/theme.dart';
import '../../core/catalog/catalog_provider.dart';
import '../../core/catalog/exercise_display.dart';
import '../../core/database/app_database.dart';
import '../../core/database/enums.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/widgets.dart';
import 'create_exercise_sheet.dart';
import 'exercise_labels.dart';
import 'library_providers.dart';

/// Browse, search and extend the exercise library.
class ExerciseLibraryScreen extends ConsumerWidget {
  const ExerciseLibraryScreen({super.key, this.onSelect, this.onBack});

  /// Called when an exercise is tapped. Lets the routine builder reuse this
  /// screen as a picker instead of growing a second one.
  final void Function(Exercise exercise)? onSelect;

  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final filter = ref.watch(libraryFilterProvider);
    final sections = ref.watch(librarySectionsProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                PwrSpacing.screenH,
                PwrSpacing.screenTop,
                PwrSpacing.screenH,
                0,
              ),
              child: Column(
                children: [
                  _Header(title: l10n.libraryTitle, onBack: onBack),
                  const SizedBox(height: PwrSpacing.md),
                  const _SearchField(),
                  const SizedBox(height: PwrSpacing.sm),
                  const _RegionChips(),
                ],
              ),
            ),
            Expanded(
              child: sections.isEmpty
                  ? _EmptyResults(query: filter.query)
                  : _SectionList(sections: sections, onSelect: onSelect),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.title, this.onBack});

  final String title;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (onBack != null)
          Padding(
            padding: const EdgeInsets.only(right: PwrSpacing.sm),
            child: IconButton(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
          ),
        Text(title, style: PwrTypography.titleMedium),
      ],
    );
  }
}

class _SearchField extends ConsumerStatefulWidget {
  const _SearchField();

  @override
  ConsumerState<_SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends ConsumerState<_SearchField> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final hasText = _controller.text.isNotEmpty;

    return TextField(
      controller: _controller,
      style: PwrTypography.bodySmall,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: l10n.librarySearchHint,
        prefixIcon: const Icon(Icons.search, size: 18),
        prefixIconConstraints: const BoxConstraints(minWidth: 42),
        suffixIcon: hasText
            ? IconButton(
                icon: const Icon(Icons.close, size: 16),
                onPressed: () {
                  _controller.clear();
                  ref.read(libraryFilterProvider.notifier).search('');
                  setState(() {});
                },
              )
            : null,
        border: const OutlineInputBorder(
          borderRadius: PwrRadius.pillAll,
          borderSide: BorderSide.none,
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: PwrRadius.pillAll,
          borderSide: BorderSide.none,
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: PwrRadius.pillAll,
          borderSide: BorderSide(color: PwrColors.accentStrong),
        ),
      ),
      onChanged: (value) {
        ref.read(libraryFilterProvider.notifier).search(value);
        setState(() {});
      },
    );
  }
}

class _RegionChips extends ConsumerWidget {
  const _RegionChips();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final selected = ref.watch(libraryFilterProvider).region;
    final notifier = ref.read(libraryFilterProvider.notifier);

    return SizedBox(
      height: 34,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          PwrTag(
            l10n.libraryFilterAll,
            tone: selected == null ? PwrTagTone.accent : PwrTagTone.neutral,
            textStyle: PwrTypography.buttonSmall,
            onTap: notifier.clearRegion,
          ),
          for (final region in MuscleGroupRegion.values) ...[
            const SizedBox(width: PwrSpacing.xs),
            PwrTag(
              region.label(l10n),
              tone: selected == region ? PwrTagTone.accent : PwrTagTone.neutral,
              textStyle: PwrTypography.buttonSmall,
              onTap: () => notifier.toggleRegion(region),
            ),
          ],
        ],
      ),
    );
  }
}

class _SectionList extends ConsumerWidget {
  const _SectionList({required this.sections, this.onSelect});

  final List<LibrarySection> sections;
  final void Function(Exercise exercise)? onSelect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final catalog = ref.watch(exerciseCatalogProvider);
    final language = Localizations.localeOf(context).languageCode;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        PwrSpacing.screenH,
        PwrSpacing.lg,
        PwrSpacing.screenH,
        PwrSpacing.xxl,
      ),
      children: [
        for (final section in sections) ...[
          PwrOverline(
            l10n.librarySection(
              section.region.label(l10n),
              section.exercises.length,
            ),
          ),
          const SizedBox(height: PwrSpacing.sm),
          for (final exercise in section.exercises) ...[
            PwrListRow(
              title: exercise.displayName(catalog, language),
              subtitle: [
                exercise.equipment.label(l10n),
                if (exercise.isCustom) l10n.libraryCustomBadge,
              ].join(' · ').toUpperCase(),
              subtitleColor: exercise.isCustom ? PwrColors.accent : null,
              onTap: onSelect == null ? null : () => onSelect!(exercise),
            ),
            const SizedBox(height: PwrSpacing.listGap),
          ],
          const SizedBox(height: PwrSpacing.md),
        ],
        const _CreateCustomRow(),
      ],
    );
  }
}

class _CreateCustomRow extends ConsumerWidget {
  const _CreateCustomRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final query = ref.watch(libraryFilterProvider).query;

    return PwrListRow.placeholder(
      title: l10n.libraryCreateCustom,
      subtitle: l10n.libraryCreateCustomHint.toUpperCase(),
      leading: const Icon(Icons.add, size: 16, color: PwrColors.textMuted),
      onTap: () => CreateExerciseSheet.show(
        context,
        // Carry the failed search across, so "not found" flows straight into
        // creating what was looked for.
        initialName: query.trim().isEmpty ? null : query.trim(),
      ),
    );
  }
}

class _EmptyResults extends ConsumerWidget {
  const _EmptyResults({required this.query});

  final String query;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final trimmed = query.trim();

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        PwrSpacing.screenH,
        PwrSpacing.lg,
        PwrSpacing.screenH,
        PwrSpacing.xxl,
      ),
      children: [
        PwrCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.libraryEmptySearch(trimmed),
                style: PwrTypography.titleLarge,
              ),
              const SizedBox(height: PwrSpacing.xs),
              Text(
                l10n.libraryEmptySearchBody,
                style: PwrTypography.bodyLarge.copyWith(
                  color: PwrColors.textMuted,
                ),
              ),
              const SizedBox(height: PwrSpacing.md),
              PwrButton(
                label: l10n.libraryCreateCustom,
                onPressed: () => CreateExerciseSheet.show(
                  context,
                  initialName: trimmed.isEmpty ? null : trimmed,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
