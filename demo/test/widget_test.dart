import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:demo/main.dart'; // Using the root package 'demo' based on pubspec.yaml

void main() {
  testWidgets('ECommerceApp smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ECommerceApp());

    // Verify that our base MainScreen loaded
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
