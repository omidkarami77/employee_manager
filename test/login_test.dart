import 'dart:async';
import 'dart:convert';

import 'package:employee_manager/data/auth_repository.dart';
import 'package:employee_manager/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pocketbase/pocketbase.dart';

import 'auth_test_support.dart';

void main() {
  testWidgets(
    'login gates employee requests, validates, loads, translates errors and retries',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1600, 1100));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final pending = Completer<http.Response>();
      var logins = 0;
      var employeeRequests = 0;
      final client = PocketBase(
        'http://example.test',
        httpClientFactory: () => MockClient((request) async {
          if (request.url.path.endsWith('auth-with-password')) {
            logins++;
            if (logins == 1) return pending.future;
            return http.Response(
              jsonEncode({
                'token': testToken(),
                'record': testUserRecord().toJson(),
              }),
              200,
              headers: {'content-type': 'application/json; charset=utf-8'},
            );
          }
          employeeRequests++;
          expect(request.headers['authorization'], isNotEmpty);
          return http.Response(
            jsonEncode({'page': 1, 'perPage': 1000, 'items': []}),
            200,
          );
        }),
      );
      final storage = MemorySessionStorage();
      await tester.pumpWidget(
        EmployeeManagerApp(
          authRepository: AuthRepository(client, storage: storage),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('ورود به مدیریت کارکنان'), findsOneWidget);
      expect(employeeRequests, 0);
      await tester.tap(find.text('ورود'));
      await tester.pumpAndSettle();
      expect(find.text('ایمیل معتبر وارد کنید.'), findsOneWidget);
      expect(find.text('رمز عبور را وارد کنید.'), findsOneWidget);
      expect(logins, 0);
      await tester.enterText(
        find.widgetWithText(TextFormField, 'ایمیل'),
        'test@example.test',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'رمز عبور'),
        'test-password',
      );
      await tester.tap(find.text('ورود'));
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
      );
      pending.complete(http.Response('{"message":"invalid"}', 400));
      await tester.pumpAndSettle();
      expect(find.text('ایمیل یا رمز عبور نادرست است.'), findsOneWidget);
      await tester.enterText(
        find.widgetWithText(TextFormField, 'رمز عبور'),
        'test-password',
      );
      await tester.tap(find.text('ورود'));
      await tester.pumpAndSettle();
      expect(find.text('ورود به مدیریت کارکنان'), findsNothing);
      expect(find.text('مدیر آزمایشی'), findsOneWidget);
      expect(find.byIcon(Icons.settings_outlined), findsOneWidget);
      expect(employeeRequests, 1);
      expect(storage.value, isNotNull);
      await tester.tap(find.text('خروج از حساب'));
      await tester.pumpAndSettle();
      expect(find.text('ورود به مدیریت کارکنان'), findsOneWidget);
      expect(storage.value, isNull);
      expect(client.authStore.isValid, isFalse);
      expect(tester.takeException(), isNull);
    },
  );
}
