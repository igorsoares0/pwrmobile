import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pwrmobile/app/theme/theme.dart';
import 'package:pwrmobile/shared/widgets/widgets.dart';

void main() {
  group('PwrTheme', () {
    test('uses the PWR palette rather than a seeded scheme', () {
      final scheme = PwrTheme.dark.colorScheme;

      expect(scheme.brightness, Brightness.dark);
      expect(scheme.primary, PwrColors.accentStrong);
      expect(scheme.surface, PwrColors.background);
      expect(scheme.error, PwrColors.danger);
      expect(PwrTheme.dark.scaffoldBackgroundColor, PwrColors.background);
    });

    test('every text theme entry resolves to a bundled family', () {
      const families = {
        PwrTypography.interfaceFamily,
        PwrTypography.monoFamily,
      };

      final textTheme = PwrTheme.dark.textTheme;
      final styles = <TextStyle?>[
        textTheme.displayLarge,
        textTheme.displayMedium,
        textTheme.displaySmall,
        textTheme.headlineLarge,
        textTheme.titleLarge,
        textTheme.titleMedium,
        textTheme.titleSmall,
        textTheme.bodyLarge,
        textTheme.bodyMedium,
        textTheme.bodySmall,
        textTheme.labelLarge,
        textTheme.labelMedium,
        textTheme.labelSmall,
      ];

      for (final style in styles) {
        expect(style, isNotNull);
        expect(families, contains(style!.fontFamily));
      }
    });
  });

  group('PwrTypography', () {
    test('metric styles are monospaced so set rows do not reflow', () {
      const metrics = [
        PwrTypography.metricXl,
        PwrTypography.metricLg,
        PwrTypography.metricMd,
        PwrTypography.metricSm,
        PwrTypography.metricXs,
      ];

      for (final style in metrics) {
        expect(style.fontFamily, PwrTypography.monoFamily);
      }
    });

    test('overlines carry the wide tracking that defines them', () {
      expect(PwrTypography.overline.letterSpacing, greaterThan(1));
      expect(
        PwrTypography.overlineWide.letterSpacing,
        greaterThan(PwrTypography.overline.letterSpacing!),
      );
    });
  });

  group('components', () {
    testWidgets('PwrButton renders its label and fires onPressed', (
      tester,
    ) async {
      var pressed = 0;

      await tester.pumpWidget(
        _host(PwrButton(label: 'Começar', onPressed: () => pressed++)),
      );

      expect(find.text('Começar'), findsOneWidget);
      await tester.tap(find.text('Começar'));
      expect(pressed, 1);
    });

    testWidgets('a PwrButton without onPressed is inert', (tester) async {
      await tester.pumpWidget(_host(const PwrButton(label: 'Indisponível')));

      await tester.tap(find.text('Indisponível'));
      await tester.pump();

      // Nothing to assert beyond "it did not throw" — the button must simply
      // absorb the tap rather than crash on a null callback.
      expect(find.text('Indisponível'), findsOneWidget);
    });

    testWidgets('PwrOverline uppercases its label', (tester) async {
      await tester.pumpWidget(_host(const PwrOverline('recordes de hoje')));

      expect(find.text('RECORDES DE HOJE'), findsOneWidget);
    });

    testWidgets('PwrStat shows value, unit and uppercased caption', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const PwrStat(value: '18.4', unit: 't', caption: 'volume\ntotal'),
        ),
      );

      expect(find.text('VOLUME\nTOTAL'), findsOneWidget);
      expect(find.textContaining('18.4'), findsOneWidget);
    });

    testWidgets('PwrListRow renders title, subtitle and reacts to taps', (
      tester,
    ) async {
      var tapped = false;

      await tester.pumpWidget(
        _host(
          PwrListRow(
            title: 'Supino reto',
            subtitle: 'BARRA · 1RM 104KG',
            onTap: () => tapped = true,
          ),
        ),
      );

      expect(find.text('Supino reto'), findsOneWidget);
      expect(find.text('BARRA · 1RM 104KG'), findsOneWidget);

      await tester.tap(find.text('Supino reto'));
      expect(tapped, isTrue);
    });

    testWidgets('PwrProgressBar clamps out-of-range values', (tester) async {
      await tester.pumpWidget(
        _host(
          const Column(
            children: [PwrProgressBar(value: -1), PwrProgressBar(value: 5)],
          ),
        ),
      );
      await tester.pumpAndSettle();

      final factors = tester
          .widgetList<FractionallySizedBox>(find.byType(FractionallySizedBox))
          .map((box) => box.widthFactor)
          .toList();

      expect(factors, [0.0, 1.0]);
    });
  });
}

Widget _host(Widget child) {
  return MaterialApp(
    theme: PwrTheme.dark,
    home: Scaffold(body: Center(child: child)),
  );
}
