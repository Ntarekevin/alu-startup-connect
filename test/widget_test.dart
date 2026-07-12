import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:alu_startup_connect/app.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const AluStartupConnectApp());
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
