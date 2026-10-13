import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planact/app/app_lock.dart';
import 'package:planact/app/app_settings.dart';
import 'package:planact/app/planact_app.dart';
import 'package:planact/app/theme/planact_theme.dart';
import 'package:planact/core/database/app_database.dart';
import 'package:planact/features/settings/presentation/app_lock_settings_card.dart';

class _Authenticator implements AppAuthenticator {
  final requests = <Completer<bool>>[];

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<bool> authenticate() {
    final request = Completer<bool>();
    requests.add(request);
    return request.future;
  }
}

// Uses the production More/Settings route and setting command. Only the native
// authenticator and storage-failure seam are controlled by the test.
class _Host extends StatefulWidget {
  const _Host({
    required this.settings,
    required this.controller,
    this.dark = false,
  });

  final AppSettings settings;
  final AppLockController controller;
  final bool dark;

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  bool enabled = false;
  bool loaded = false;
  bool failWrite = false;
  Completer<void>? pendingWrite;
  int writes = 0;

  @override
  void initState() {
    super.initState();
    widget.settings.readAppLockEnabled().then((value) {
      if (value) widget.controller.lock();
      if (mounted) {
        setState(() {
          enabled = value;
          loaded = true;
        });
      }
    });
  }

  Future<void> change(bool value) async {
    await widget.controller.changeSetting(
      enabled: value,
      persist: (value) async {
        writes++;
        if (failWrite) throw StateError('controlled storage failure');
        if (pendingWrite != null) await pendingWrite!.future;
        await widget.settings.writeAppLockEnabled(value);
      },
    );
    if (mounted) setState(() => enabled = value);
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    theme: widget.dark ? PlanActTheme.dark() : PlanActTheme.light(),
    builder: (_, child) => Directionality(
      textDirection: TextDirection.rtl,
      child: AppLockGate(
        enabled: enabled,
        controller: widget.controller,
        child: child!,
      ),
    ),
    home: loaded
        ? HomeShell(appLockEnabled: enabled, onAppLockChanged: change)
        : const Scaffold(body: CircularProgressIndicator()),
  );
}

Finder get _switch => find.descendant(
  of: find.byType(AppLockSettingsCard),
  matching: find.byType(SwitchListTile),
);

bool _value(WidgetTester tester) =>
    tester.widget<SwitchListTile>(_switch).value;

Future<void> _openSettings(WidgetTester tester) async {
  await tester.tap(find.text('بیشتر').last);
  await tester.pumpAndSettle();
  await tester.tap(find.text('تنظیمات'));
  await tester.pumpAndSettle();
}

void main() {
  for (final dark in [false, true]) {
    testWidgets('open Settings updates both directions after commit ($dark)', (
      tester,
    ) async {
      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final settings = AppSettings(database);
      final auth = _Authenticator();
      final controller = AppLockController(authenticator: auth);
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _Host(settings: settings, controller: controller, dark: dark),
      );
      await tester.pumpAndSettle();
      await _openSettings(tester);
      final route = tester.state(find.byType(AppLockSettingsCard));
      final host = tester.state<_HostState>(find.byType(_Host));

      for (final target in [true, false]) {
        host.pendingWrite = Completer<void>();
        await tester.tap(_switch);
        await tester.pump();
        expect(_value(tester), !target);
        expect(find.text('در حال تأیید و ذخیره…'), findsOneWidget);
        expect(tester.widget<SwitchListTile>(_switch).onChanged, isNull);
        await tester.tap(_switch);
        await tester.pump();
        expect(auth.requests.length, target ? 1 : 2);
        auth.requests.last.complete(true);
        await tester.pump();
        expect(_value(tester), !target);
        expect(host.enabled, !target);
        expect(await settings.readAppLockEnabled(), !target);
        host.pendingWrite!.complete();
        await tester.pumpAndSettle();
        expect(_value(tester), target);
        expect(host.enabled, target);
        expect(await settings.readAppLockEnabled(), target);
        expect(tester.state(find.byType(AppLockSettingsCard)), same(route));
        expect(
          find.text(target ? 'قفل برنامه فعال شد.' : 'قفل برنامه غیرفعال شد.'),
          findsOneWidget,
        );
      }
      expect(host.writes, 2);
    });
  }

  for (final initial in [false, true]) {
    for (final failure in ['cancel', 'storage', 'background']) {
      testWidgets('same Settings retains $initial on $failure and retries', (
        tester,
      ) async {
        final database = AppDatabase(NativeDatabase.memory());
        addTearDown(database.close);
        final settings = AppSettings(database);
        await settings.writeAppLockEnabled(initial);
        final auth = _Authenticator();
        final controller = AppLockController(authenticator: auth);
        addTearDown(controller.dispose);
        await tester.pumpWidget(
          _Host(settings: settings, controller: controller),
        );
        await tester.pumpAndSettle();
        if (initial) {
          expect(find.text('پلن‌اکت قفل است'), findsOneWidget);
          auth.requests.last.complete(true);
          await tester.pumpAndSettle();
        }
        await _openSettings(tester);
        final host = tester.state<_HostState>(find.byType(_Host));
        host.failWrite = failure == 'storage';
        await tester.tap(_switch);
        await tester.pump();
        if (failure == 'background') {
          tester.binding.handleAppLifecycleStateChanged(
            AppLifecycleState.inactive,
          );
          tester.binding.handleAppLifecycleStateChanged(
            AppLifecycleState.hidden,
          );
          tester.binding.handleAppLifecycleStateChanged(
            AppLifecycleState.paused,
          );
          await tester.pump();
        }
        auth.requests.last.complete(failure != 'cancel');
        await tester.pump();
        if (failure == 'background') {
          tester.binding.handleAppLifecycleStateChanged(
            AppLifecycleState.hidden,
          );
          tester.binding.handleAppLifecycleStateChanged(
            AppLifecycleState.inactive,
          );
          tester.binding.handleAppLifecycleStateChanged(
            AppLifecycleState.resumed,
          );
          await tester.pump();
          if (initial) {
            expect(find.text('پلن‌اکت قفل است'), findsOneWidget);
            auth.requests.last.complete(true);
          }
        }
        await tester.pumpAndSettle();
        expect(host.enabled, initial);
        expect(_value(tester), initial);
        expect(await settings.readAppLockEnabled(), initial);
        expect(find.textContaining('تغییر قفل انجام نشد'), findsOneWidget);
        expect(host.writes, failure == 'storage' ? 1 : 0);
        host.failWrite = false;
        await tester.tap(_switch);
        await tester.pump();
        auth.requests.last.complete(true);
        await tester.pumpAndSettle();
        if (!initial && failure == 'background') {
          expect(find.text('پلن‌اکت قفل است'), findsOneWidget);
          auth.requests.last.complete(true);
          await tester.pumpAndSettle();
        }
        expect(_value(tester), !initial);
        expect(host.enabled, !initial);
      });
    }
  }

  testWidgets(
    'cold reconstruction reloads committed setting and gates content',
    (tester) async {
      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final settings = AppSettings(database);
      final auth = _Authenticator();
      final controller = AppLockController(authenticator: auth);
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _Host(settings: settings, controller: controller),
      );
      await tester.pumpAndSettle();
      await _openSettings(tester);
      await tester.tap(_switch);
      await tester.pump();
      auth.requests.last.complete(true);
      await tester.pumpAndSettle();
      await tester.pumpWidget(const SizedBox.shrink());
      final coldAuth = _Authenticator();
      final coldController = AppLockController(authenticator: coldAuth);
      addTearDown(coldController.dispose);
      await tester.pumpWidget(
        _Host(settings: settings, controller: coldController),
      );
      await tester.pumpAndSettle();
      expect(find.text('پلن‌اکت قفل است'), findsOneWidget);
      expect(find.text('امروز'), findsNothing);
      coldAuth.requests.last.complete(true);
      await tester.pumpAndSettle();
      await _openSettings(tester);
      expect(_value(tester), isTrue);
      await tester.tap(_switch);
      await tester.pump();
      coldAuth.requests.last.complete(true);
      await tester.pumpAndSettle();
      await tester.pumpWidget(const SizedBox.shrink());
      final offAuth = _Authenticator();
      final offController = AppLockController(authenticator: offAuth);
      addTearDown(offController.dispose);
      await tester.pumpWidget(
        _Host(settings: settings, controller: offController),
      );
      await tester.pumpAndSettle();
      expect(find.text('پلن‌اکت قفل است'), findsNothing);
      expect(offAuth.requests, isEmpty);
      await _openSettings(tester);
      expect(_value(tester), isFalse);
    },
  );
}
