import 'package:aphanes/core/persistence/shared_preferences_provider.dart';
import 'package:aphanes/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('home shell shows all four tabs and switches on tap', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: const AphanesApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Devices'), findsWidgets);
    expect(find.text('No devices paired yet'), findsOneWidget);

    await tester.tap(find.widgetWithText(NavigationDestination, 'Apps'));
    await tester.pumpAndSettle();

    expect(find.text('Pair a device to manage apps'), findsOneWidget);
  });
}
