// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ai_chatbot/main.dart';

void main() {
  testWidgets('ChatBot app basic structure test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ChatBotApp());
    
    // Wait for initial build
    await tester.pump();

    // Verify that the app bar title is correct
    expect(find.text('AI 문서 챗봇'), findsOneWidget);
    
    // Verify that the message input field exists
    expect(find.byType(TextField), findsOneWidget);
    
    // Verify that the send button exists
    expect(find.byIcon(Icons.send), findsOneWidget);
    
    // Verify that the settings button exists
    expect(find.byIcon(Icons.more_vert), findsOneWidget);
  });

  testWidgets('Message input functionality', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ChatBotApp());
    await tester.pump();

    // Find the text field and enter some text
    final textField = find.byType(TextField);
    await tester.enterText(textField, '테스트 메시지');
    await tester.pump();
    
    // Verify that the text was entered
    expect(find.text('테스트 메시지'), findsOneWidget);
  });
}
