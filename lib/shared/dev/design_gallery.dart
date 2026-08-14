import 'package:flutter/material.dart';

import '../../app/theme/theme.dart';
import '../widgets/widgets.dart';

/// A living reference for the PWR design system.
///
/// Every token and component is rendered here so a visual regression is
/// obvious at a glance. This screen ships in debug builds only — it is not
/// registered in any user-facing navigation.
class DesignGalleryScreen extends StatelessWidget {
  const DesignGalleryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            PwrSpacing.screenH,
            PwrSpacing.screenTop,
            PwrSpacing.screenH,
            PwrSpacing.xxl,
          ),
          children: const [
            _Header(),
            _Section(title: 'Color', child: _ColorSwatches()),
            _Section(title: 'Interface type', child: _InterfaceType()),
            _Section(title: 'Mono type', child: _MonoType()),
            _Section(title: 'Buttons', child: _Buttons()),
            _Section(title: 'Tags', child: _Tags()),
            _Section(title: 'Cards', child: _Cards()),
            _Section(title: 'List rows', child: _ListRows()),
            _Section(title: 'Stats', child: _Stats()),
            _Section(title: 'Progress', child: _Progress()),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(bottom: PwrSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('PWR', style: PwrTypography.wordmark),
          SizedBox(height: PwrSpacing.sm),
          Text('Design system', style: PwrTypography.displaySmall),
          SizedBox(height: PwrSpacing.xs),
          Text(
            'Reference build. Not part of the user-facing navigation.',
            style: PwrTypography.caption,
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: PwrSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PwrOverline(title),
          const SizedBox(height: PwrSpacing.sm),
          const Divider(),
          const SizedBox(height: PwrSpacing.md),
          child,
        ],
      ),
    );
  }
}

class _ColorSwatches extends StatelessWidget {
  const _ColorSwatches();

  static const _swatches = <(String, Color)>[
    ('background', PwrColors.background),
    ('surface', PwrColors.surface),
    ('surfaceRaised', PwrColors.surfaceRaised),
    ('surfaceAccent', PwrColors.surfaceAccent),
    ('surfaceAccentRaised', PwrColors.surfaceAccentRaised),
    ('border', PwrColors.border),
    ('borderStrong', PwrColors.borderStrong),
    ('borderAccent', PwrColors.borderAccent),
    ('accent', PwrColors.accent),
    ('accentStrong', PwrColors.accentStrong),
    ('accentDeep', PwrColors.accentDeep),
    ('danger', PwrColors.danger),
    ('textPrimary', PwrColors.textPrimary),
    ('textMuted', PwrColors.textMuted),
    ('textFaint', PwrColors.textFaint),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final (name, color) in _swatches)
          Padding(
            padding: const EdgeInsets.only(bottom: PwrSpacing.xs),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: PwrRadius.barAll,
                    border: Border.all(color: PwrColors.border),
                  ),
                ),
                const SizedBox(width: PwrSpacing.sm),
                Expanded(child: Text(name, style: PwrTypography.bodyMedium)),
                Text(
                  '#${(color.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}',
                  style: PwrTypography.label,
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _InterfaceType extends StatelessWidget {
  const _InterfaceType();

  static const _samples = <(String, TextStyle)>[
    ('displayLarge', PwrTypography.displayLarge),
    ('displayMedium', PwrTypography.displayMedium),
    ('displaySmall', PwrTypography.displaySmall),
    ('headline', PwrTypography.headline),
    ('wordmark', PwrTypography.wordmark),
    ('titleLarge', PwrTypography.titleLarge),
    ('titleMedium', PwrTypography.titleMedium),
    ('titleSmall', PwrTypography.titleSmall),
    ('bodyLarge', PwrTypography.bodyLarge),
    ('bodyMedium', PwrTypography.bodyMedium),
    ('bodySmall', PwrTypography.bodySmall),
    ('caption', PwrTypography.caption),
    ('button', PwrTypography.button),
    ('buttonSmall', PwrTypography.buttonSmall),
  ];

  @override
  Widget build(BuildContext context) => const _TypeSpecimens(samples: _samples);
}

class _MonoType extends StatelessWidget {
  const _MonoType();

  static const _samples = <(String, TextStyle)>[
    ('metricXl', PwrTypography.metricXl),
    ('metricLg', PwrTypography.metricLg),
    ('metricMd', PwrTypography.metricMd),
    ('metricSm', PwrTypography.metricSm),
    ('metricXs', PwrTypography.metricXs),
    ('overline', PwrTypography.overline),
    ('overlineWide', PwrTypography.overlineWide),
    ('label', PwrTypography.label),
    ('tag', PwrTypography.tag),
    ('metricCaption', PwrTypography.metricCaption),
    ('navLabel', PwrTypography.navLabel),
  ];

  @override
  Widget build(BuildContext context) =>
      const _TypeSpecimens(samples: _samples, mono: true);
}

class _TypeSpecimens extends StatelessWidget {
  const _TypeSpecimens({required this.samples, this.mono = false});

  final List<(String, TextStyle)> samples;
  final bool mono;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final (name, style) in samples)
          Padding(
            padding: const EdgeInsets.only(bottom: PwrSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$name · ${style.fontSize!.toInt()}/${style.fontWeight!.value}',
                  style: PwrTypography.tag.copyWith(color: PwrColors.textFaint),
                ),
                const SizedBox(height: 6),
                // Mono styles almost always carry digits, so the specimen
                // shows digits — that is what has to line up in a set row.
                Text(
                  mono ? '0123456789 · 85KG × 6' : 'Supino reto',
                  style: style,
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _Buttons extends StatelessWidget {
  const _Buttons();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        PwrButton(label: 'Começar', onPressed: () {}),
        const SizedBox(height: PwrSpacing.cardGap),
        PwrButton.secondary(label: 'Já tenho conta', onPressed: () {}),
        const SizedBox(height: PwrSpacing.cardGap),
        PwrButton.ghost(label: 'Pular por agora', onPressed: () {}),
        const SizedBox(height: PwrSpacing.cardGap),
        const PwrButton(label: 'Indisponível'),
        const SizedBox(height: PwrSpacing.cardGap),
        Row(
          children: [
            PwrButton(
              label: 'Liberar',
              size: PwrButtonSize.compact,
              expand: false,
              onPressed: () {},
            ),
            const SizedBox(width: PwrSpacing.xs),
            PwrButton.secondary(
              label: 'Pausar',
              size: PwrButtonSize.compact,
              expand: false,
              onPressed: () {},
            ),
          ],
        ),
      ],
    );
  }
}

class _Tags extends StatelessWidget {
  const _Tags();

  @override
  Widget build(BuildContext context) {
    return const Wrap(
      spacing: PwrSpacing.xs,
      runSpacing: PwrSpacing.xs,
      children: [
        PwrTag('SUPERSÉRIE', tone: PwrTagTone.accent),
        PwrTag('ANTERIOR 4×8 · 80KG'),
        PwrTag('1RM 101'),
        PwrTag('SÃO LEOPOLDO', tone: PwrTagTone.outlined),
        PwrTag(
          'Peito',
          tone: PwrTagTone.accent,
          textStyle: PwrTypography.buttonSmall,
        ),
        PwrTag('Costas', textStyle: PwrTypography.buttonSmall),
      ],
    );
  }
}

class _Cards extends StatelessWidget {
  const _Cards();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        PwrCard.accent(
          onTap: () {},
          child: Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Push A\nPeito & Tríceps',
                      style: TextStyle(
                        fontFamily: PwrTypography.interfaceFamily,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                        color: PwrColors.onAccent,
                      ),
                    ),
                    SizedBox(height: PwrSpacing.sm),
                    Text('6 EXERCÍCIOS · ~58 MIN', style: PwrTypography.tag),
                  ],
                ),
              ),
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: PwrColors.textPrimary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.play_arrow_rounded,
                  color: PwrColors.accentStrong,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: PwrSpacing.cardGap),
        PwrCard(
          onTap: () {},
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Descanso', style: PwrTypography.titleSmall),
              SizedBox(height: PwrSpacing.sm),
              Text(
                '01:30',
                style: TextStyle(
                  fontFamily: PwrTypography.monoFamily,
                  fontSize: 34,
                  fontWeight: FontWeight.w600,
                  height: 1,
                  color: PwrColors.accent,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: PwrSpacing.cardGap),
        PwrCard.dashed(
          onTap: () {},
          child: const Row(
            children: [
              Icon(Icons.lock_outline, size: 16, color: PwrColors.textMuted),
              SizedBox(width: PwrSpacing.sm),
              Expanded(
                child: Text('Nova rotina', style: PwrTypography.bodyMedium),
              ),
              Icon(Icons.arrow_forward, size: 16, color: PwrColors.textMuted),
            ],
          ),
        ),
      ],
    );
  }
}

class _ListRows extends StatelessWidget {
  const _ListRows();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        PwrListRow(
          title: 'Supino reto',
          subtitle: 'BARRA · 1RM 104KG',
          onTap: () {},
        ),
        const SizedBox(height: PwrSpacing.listGap),
        PwrListRow(
          title: 'Crucifixo inclinado',
          subtitle: 'SUPERSÉRIE COM O PRÓXIMO',
          subtitleColor: PwrColors.accent,
          accentBar: true,
          leading: const Icon(
            Icons.drag_indicator,
            size: 18,
            color: PwrColors.textFaint,
          ),
          trailing: const Icon(Icons.edit_outlined, size: 16),
          onTap: () {},
        ),
        const SizedBox(height: PwrSpacing.listGap),
        PwrListRow.placeholder(
          title: 'Criar exercício próprio',
          subtitle: 'DISPONÍVEL NO PRO',
          leading: const Icon(
            Icons.lock_outline,
            size: 16,
            color: PwrColors.textMuted,
          ),
          onTap: () {},
        ),
      ],
    );
  }
}

class _Stats extends StatelessWidget {
  const _Stats();

  @override
  Widget build(BuildContext context) {
    return const PwrCard(
      child: Column(
        children: [
          PwrStatRow(
            stats: [
              PwrStat(
                value: '4',
                caption: 'treinos\nna semana',
                valueColor: PwrColors.accent,
              ),
              PwrStat(value: '18.4', unit: 't', caption: 'volume\ntotal'),
              PwrStat(value: '3', caption: 'recordes\nnovos'),
            ],
          ),
          SizedBox(height: PwrSpacing.lg),
          Divider(),
          SizedBox(height: PwrSpacing.lg),
          Align(
            alignment: Alignment.centerLeft,
            child: PwrStat(
              value: '8.240',
              unit: ' KG',
              caption: 'volume total · +12% vs. último',
              valueStyle: PwrTypography.metricXl,
            ),
          ),
        ],
      ),
    );
  }
}

class _Progress extends StatelessWidget {
  const _Progress();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        PwrProgressBar(value: 0.62),
        SizedBox(height: PwrSpacing.sm),
        PwrProgressBar(value: 1),
        SizedBox(height: PwrSpacing.sm),
        PwrProgressBar(value: 0.2, color: PwrColors.danger),
      ],
    );
  }
}
