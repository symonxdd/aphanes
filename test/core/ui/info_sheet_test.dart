import 'package:aphanes/core/ui/info_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  // Regression: the details controller used to be a lazy `late final`
  // field initializer. A sheet with no `details` never touched it during
  // build, so dispose became the first read - building an
  // AnimationController against an element that was already deactivated,
  // which throws in createTicker. Disposing a plain sheet is the whole
  // test; the failure showed up as an exception during finalizeTree.
  testWidgets('a sheet with no details disposes cleanly', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        const InfoSheet(
          icon: Icons.info_outline,
          title: 'Plain',
          body: 'No read more here.',
        ),
      ),
    );
    expect(find.text('Read more'), findsNothing);

    await tester.pumpWidget(_wrap(const SizedBox.shrink()));
    await tester.pump();

    expect(tester.takeException(), isNull);
  });

  testWidgets('a sheet with details disposes cleanly too', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        const InfoSheet(
          icon: Icons.info_outline,
          title: 'Expandable',
          body: 'The short half.',
          details: 'The longer half.',
        ),
      ),
    );

    await tester.pumpWidget(_wrap(const SizedBox.shrink()));
    await tester.pump();

    expect(tester.takeException(), isNull);
  });

  testWidgets('details stay hidden until Read more is tapped', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        const InfoSheet(
          icon: Icons.info_outline,
          title: 'Expandable',
          body: 'The short half.',
          details: 'The longer half.',
        ),
      ),
    );

    // SizeTransition collapses the details to zero height rather than
    // removing them, so presence in the tree is not the question - the
    // toggle's own label is what says which state it is in.
    expect(find.text('Read more'), findsOneWidget);
    expect(find.text('Collapse'), findsNothing);

    await tester.tap(find.text('Read more'));
    await tester.pumpAndSettle();

    expect(find.text('Collapse'), findsOneWidget);
    expect(find.text('Read more'), findsNothing);

    await tester.tap(find.text('Collapse'));
    await tester.pumpAndSettle();

    expect(find.text('Read more'), findsOneWidget);
  });
}
