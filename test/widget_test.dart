import 'package:aphanes/core/persistence/shared_preferences_provider.dart';
import 'package:aphanes/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('home shell shows default tabs and switches on tap', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'has_seen_onboarding': true,
    });
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: const AphanesApp(),
      ),
    );
    // Not pumpAndSettle: the home shell's ambient backdrop has a
    // perpetually repeating animation, which would never settle.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));

    expect(find.text('Devices'), findsWidgets);
    expect(find.text('No devices paired yet'), findsOneWidget);

    await tester.tap(find.widgetWithText(NavigationDestination, 'Apps'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Pair a device to manage apps'), findsOneWidget);
  });

  testWidgets(
    'Terminal tab is hidden by default and shown after enabling it',
    (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'has_seen_onboarding': true,
      });
      final SharedPreferences prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
          child: const AphanesApp(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));

      expect(
        find.widgetWithText(NavigationDestination, 'Terminal'),
        findsNothing,
      );

      await tester.tap(find.byTooltip('Settings'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final Finder terminalToggle = find.widgetWithText(
        SwitchListTile,
        'Terminal tab',
      );
      await tester.ensureVisible(terminalToggle);
      await tester.pump();
      await tester.tap(terminalToggle);
      await tester.pump();

      expect(
        find.widgetWithText(NavigationDestination, 'Terminal'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'onboarding shows the disclaimer and completing it reveals home',
    (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final SharedPreferences prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
          child: const AphanesApp(),
        ),
      );
      // Not pumpAndSettle: the onboarding backdrop has a perpetually
      // repeating animation, which would never settle.
      await tester.pump();

      expect(
        find.textContaining('Unaffiliated with LG Electronics'),
        findsOneWidget,
      );

      await tester.tap(find.text('Got it, boss'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));

      expect(find.text('No devices paired yet'), findsOneWidget);
    },
  );
}
