import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nita/core/localization/language_provider.dart';
import 'package:nita/data/visitors/visitor_repository.dart';
import 'package:nita/views/splash/visitor_gate_form.dart';

/// Local save resolves immediately; remote sync never resolves unless the
/// test releases it. If the form still awaited the upload, [onEntered]
/// would never fire and the assertions below would fail.
class _ControlledRepo extends VisitorRepository {
  final List<String> calls = <String>[];
  final Completer<bool> remote = Completer<bool>();

  _ControlledRepo();

  @override
  Future<void> saveVisitorLocal({
    required String name,
    required String address,
  }) async {
    calls.add('local');
  }

  @override
  Future<bool> syncVisitor({
    required String name,
    required String address,
    String lang = 'tl',
  }) {
    calls.add('sync');
    return remote.future;
  }
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('gate enters before the background visitor sync completes', (
    tester,
  ) async {
    final repo = _ControlledRepo();
    addTearDown(() {
      if (!repo.remote.isCompleted) repo.remote.complete(false);
    });

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => LanguageProvider(),
        child: MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: VisitorGateForm(
                repository: repo,
                onEntered: () => repo.calls.add('entered'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.enterText(find.byType(TextField).at(0), 'Test Visitor');
    await tester.enterText(
      find.byType(TextField).at(1),
      'Purok 3, Mercedes, Camarines Norte',
    );
    await tester.pump();

    await tester.tap(find.text('Pumasok'));
    await tester.pump(const Duration(milliseconds: 50));

    // Entry happened after the fast local save and before the upload.
    expect(repo.calls, ['local', 'entered', 'sync']);
    expect(repo.remote.isCompleted, isFalse);
  });
}
