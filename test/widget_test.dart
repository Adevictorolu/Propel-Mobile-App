// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:propel/core/services/supabase_service.dart';
import 'package:propel/features/dashboard/dashboard_screen.dart';
import 'package:propel/main.dart';
import 'package:propel/providers/auth_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await SupabaseService.initialize();
  });

  testWidgets('app boots without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(const PropelApp());

    expect(find.byType(MaterialApp), findsOneWidget);
  });

  testWidgets('dashboard shows quick actions', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()),
        ],
        child: const MaterialApp(home: DashboardScreen()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Quick actions'), findsOneWidget);
  });
}
