import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:masteropening/core/theme/app_tokens.dart';
import 'package:masteropening/core/widgets/widgets.dart';

import '../helpers/pump_app.dart';

void main() {
  group('AppSwitch', () {
    testWidgets('meldet den Gegenwert beim Antippen', (tester) async {
      bool? received;

      await pumpWidgetInApp(
        tester,
        AppSwitch(value: false, onChanged: (v) => received = v),
      );

      await tester.tap(find.byType(AppSwitch));
      await tester.pumpAndSettle();

      expect(received, isTrue);
    });

    testWidgets('bleibt still, wenn er gesperrt ist', (tester) async {
      await pumpWidgetInApp(
        tester,
        const AppSwitch(value: true, onChanged: null),
      );

      await tester.tap(find.byType(AppSwitch), warnIfMissed: false);
      await tester.pumpAndSettle();

      // Kein Callback zum Prüfen — es genügt, dass nichts wirft.
      expect(tester.takeException(), isNull);
    });
  });

  group('AppSegmentedControl', () {
    testWidgets('wählt eine andere Option', (tester) async {
      String? picked;

      await pumpWidgetInApp(
        tester,
        AppSegmentedControl<String>(
          value: 'weiss',
          onChanged: (v) => picked = v,
          segments: const [
            AppSegment(value: 'weiss', label: 'Weiß'),
            AppSegment(value: 'schwarz', label: 'Schwarz'),
          ],
        ),
      );

      await tester.tap(find.text('Schwarz'));
      await tester.pumpAndSettle();

      expect(picked, 'schwarz');
    });

    testWidgets('ignoriert einen Tipp auf die bereits aktive Option', (
      tester,
    ) async {
      var calls = 0;

      await pumpWidgetInApp(
        tester,
        AppSegmentedControl<String>(
          value: 'weiss',
          onChanged: (_) => calls++,
          segments: const [
            AppSegment(value: 'weiss', label: 'Weiß'),
            AppSegment(value: 'schwarz', label: 'Schwarz'),
          ],
        ),
      );

      await tester.tap(find.text('Weiß'));
      await tester.pumpAndSettle();

      expect(calls, 0);
    });
  });

  group('AppButton', () {
    testWidgets('löst aus', (tester) async {
      var pressed = false;

      await pumpWidgetInApp(
        tester,
        AppButton(label: 'Trainieren', onPressed: () => pressed = true),
      );

      await tester.tap(find.text('Trainieren'));
      await tester.pumpAndSettle();

      expect(pressed, isTrue);
    });

    testWidgets('ist während des Ladens gesperrt', (tester) async {
      var pressed = false;

      await pumpWidgetInApp(
        tester,
        AppButton(
          label: 'Synchronisieren',
          busy: true,
          onPressed: () => pressed = true,
        ),
        settle: false,
      );

      await tester.tap(find.byType(AppButton), warnIfMissed: false);
      await tester.pump();

      expect(pressed, isFalse);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });

  group('AppProgressBar', () {
    testWidgets('kappt Werte außerhalb von 0…1', (tester) async {
      await pumpWidgetInApp(
        tester,
        const SizedBox(width: 200, child: AppProgressBar(value: 1.8)),
      );

      final box = tester.widget<FractionallySizedBox>(
        find.byType(FractionallySizedBox),
      );
      expect(box.widthFactor, lessThanOrEqualTo(1.0));
    });
  });

  group('FadingDivider', () {
    testWidgets('malt einen Verlauf statt einer Volltonlinie', (tester) async {
      await pumpWidgetInApp(
        tester,
        const SizedBox(width: 300, child: FadingDivider()),
      );

      final decorated = tester.widget<DecoratedBox>(
        find.descendant(
          of: find.byType(FadingDivider),
          matching: find.byType(DecoratedBox),
        ),
      );
      final decoration = decorated.decoration as BoxDecoration;
      final gradient = decoration.gradient! as LinearGradient;

      expect(gradient.colors.first.a, 0);
      expect(gradient.colors.last.a, 0);
      expect(gradient.colors[1].a, greaterThan(0));
    });
  });

  group('AppTag', () {
    testWidgets('nutzt die Akzent-Tönung aus den Tokens', (tester) async {
      await pumpWidgetInApp(
        tester,
        const AppTag('Fällig heute', variant: AppTagVariant.accent),
      );

      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(AppTag),
          matching: find.byType(Container),
        ),
      );
      final decoration = container.decoration! as BoxDecoration;

      expect(decoration.color, AppTokens.dark.tagAccentBg);
    });
  });
}
