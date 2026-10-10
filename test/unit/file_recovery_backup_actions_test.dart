import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:planact/features/backup/presentation/backup_settings_card.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:planact/features/backup/application/backup_service.dart';
import 'package:planact/features/backup/data/file_backup_actions.dart';
import 'package:planact/features/backup/data/secure_backup_keys.dart';
import 'package:planact/features/backup/domain/backup_encryption.dart';
import 'package:planact/features/backup/domain/backup_package.dart';
import 'package:planact/features/backup/domain/backup_recovery_key.dart';

class _Keys implements BackupKeyStorage {
  int loads = 0;
  @override
  Future<Uint8List> loadKey(String _) async {
    loads++;
    return Uint8List(32);
  }
}

class _Storage implements BackupStorage, BackupPayloadValidation {
  Uint8List current = Uint8List.fromList([1]);
  Uint8List? candidate;
  @override
  Future<void> validatePayload(Uint8List payload) async {}
  @override
  Future<Uint8List> readCurrent() async => current;
  @override
  Future<void> writeSafetySnapshot(Uint8List payload) async {}
  @override
  Future<void> writeTemporary(Uint8List payload) async {
    candidate = payload;
  }

  @override
  Future<void> flushTemporary() async {}
  @override
  Future<void> writeRecoveryMarker() async {}
  @override
  Future<void> replaceTemporary() async {
    current = candidate!;
  }

  @override
  Future<void> clearRecoveryMarker() async {}
  @override
  Future<void> recoverIfNeeded() async {}
  @override
  Future<void> restoreSafetySnapshot() async {}
}

class _Rebuild implements BackupRebuildHook {
  @override
  Future<void> rebuild() async {}
}

class _Picker extends FilePicker {
  String? savePath;
  String? importPath;
  int saves = 0;
  bool fail = false;
  Uint8List? savedBytes;
  @override
  Future<String?> saveFile({
    String? dialogTitle,
    String? fileName,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Uint8List? bytes,
    bool lockParentWindow = false,
  }) async {
    saves++;
    if (fail) throw const FileSystemException('injected save failure');
    savedBytes = bytes;
    return savePath;
  }

  @override
  Future<FilePickerResult?> pickFiles({
    String? dialogTitle,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Function(FilePickerStatus)? onFileLoading,
    bool allowCompression = true,
    int compressionQuality = 30,
    bool allowMultiple = false,
    bool withData = false,
    bool withReadStream = false,
    bool lockParentWindow = false,
    bool readSequential = false,
  }) async => importPath == null
      ? null
      : FilePickerResult([
          PlatformFile(name: 'backup', size: 1, path: importPath),
        ]);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory directory;
  late _Picker picker;
  late _Keys keys;
  late _Storage storage;
  late BackupService service;
  late FileBackupActions actions;
  var exclusives = 0;
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('recovery-actions-');
    picker = _Picker();
    FilePicker.platform = picker;
    PackageInfo.setMockInitialValues(
      appName: 'PlanAct',
      packageName: 'test',
      version: '1',
      buildNumber: '1',
      buildSignature: '',
    );
    keys = _Keys();
    storage = _Storage();
    exclusives = 0;
    service = BackupService(
      storage: storage,
      validator: const BackupValidator(currentSchemaVersion: 18),
      rebuildHook: _Rebuild(),
      keyStorage: keys,
      encryptor: AesGcmBackupEncryptor(),
      nonceGenerator: SecureBackupNonce(),
    );
    actions = FileBackupActions(
      service: service,
      keys: const SecureBackupKeys(),
      exportPayload: () async => Uint8List.fromList([9]),
      exclusive: (operation) async {
        exclusives++;
        return operation();
      },
    );
  });
  tearDown(() async => directory.delete(recursive: true));

  testWidgets(
    'real card dispatch requires privacy and key acknowledgement before production save',
    (tester) async => tester.runAsync(() async {
      picker.savePath = '${directory.path}/journey.planact';
      await tester.pumpWidget(
        MaterialApp(
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(body: BackupSettingsCard(actions: actions)),
          ),
        ),
      );
      await tester.tap(find.text('ذخیره نسخه پشتیبان'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('تأیید ذخیره'));
      await Future<void>.delayed(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('کلید بازیابی این نسخه'), findsOneWidget);
      expect(picker.saves, 0);
      expect(exclusives, 0);
      final text = tester
          .widget<SelectableText>(find.byType(SelectableText))
          .data!;
      await tester.tap(find.byType(CheckboxListTile));
      await tester.pump();
      await tester.tap(find.text('ادامه و ذخیره فایل'));
      await Future<void>.delayed(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();
      expect(picker.saves, 1);
      expect(keys.loads, 0);
      final package = BackupPackage.decode(
        await File(picker.savePath!).readAsString(),
      );
      final key = BackupRecoveryKey.parse(text);
      await service.restore(package, recoveryKey: key.bytes);
      key.dispose();
      expect(storage.current, [9]);
      expect(tester.takeException(), isNull);
    }),
  );

  test('each retry gets fresh key; acknowledgement precedes snapshot/save; no sidecar', () async {
    final seen = <String>[];
    expect(
      await actions.exportRecoveryBackup((key) async {
        seen.add(key);
        return false;
      }),
      false,
    );
    expect(exclusives, 0);
    expect(picker.saves, 0);
    picker.savePath = '${directory.path}/export.planact';
    expect(
      await actions.exportRecoveryBackup((key) async {
        seen.add(key);
        return true;
      }),
      true,
    );
    expect(seen[0], isNot(seen[1]));
    expect(keys.loads, 0);
    final file = File(picker.savePath!);
    final decoded = BackupPackage.decode(await file.readAsString());
    expect(decoded.formatVersion, 2);
    expect(await file.readAsString(), isNot(contains(seen[1])));
    expect(await directory.list().length, 1);
    final entered = BackupRecoveryKey.parse(seen[1]);
    await service.restore(decoded, recoveryKey: entered.bytes);
    entered.dispose();
    expect(storage.current, [9]);
  });

  test('concurrent admission, picker cancellation and write failure never change live state', () async {
    final confirm = Completer<bool>();
    final first = actions.exportRecoveryBackup((_) => confirm.future);
    await expectLater(
      actions.exportRecoveryBackup((_) async => true),
      throwsException,
    );
    confirm.complete(false);
    expect(await first, false);
    expect(await actions.exportRecoveryBackup((_) async => true), false);
    picker.fail = true;
    await expectLater(
      actions.exportRecoveryBackup((_) async => true),
      throwsException,
    );
    expect(storage.current, [1]);
    expect(keys.loads, 0);
  });

  test('format2 import asks only recovery key; cancelled and wrong key preserve data', () async {
    final key = await BackupRecoveryKey.generate();
    final package = await service.create(
      payload: Uint8List.fromList([8]),
      appVersion: 'test',
      createdAt: DateTime.utc(2026),
      recoveryKey: key.bytes,
    );
    final file = File('${directory.path}/import.planact');
    await file.writeAsString(package.encode());
    picker.importPath = file.path;
    expect(
      await actions.importRecoveryBackup(
        requestKey: () async => null,
        confirmLegacy: () async => throw StateError('legacy'),
      ),
      false,
    );
    expect(exclusives, 0);
    final wrong = await BackupRecoveryKey.generate();
    await expectLater(
      actions.importRecoveryBackup(
        requestKey: () async => wrong.text,
        confirmLegacy: () async => false,
      ),
      throwsException,
    );
    expect(storage.current, [1]);
    expect(
      await actions.importRecoveryBackup(
        requestKey: () async => key.text,
        confirmLegacy: () async => throw StateError('legacy'),
      ),
      true,
    );
    expect(storage.current, [8]);
    expect(keys.loads, 0);
    key.dispose();
    wrong.dispose();
  });

  test('legacy import requires acknowledgement, uses old key and never rewrites file', () async {
    final package = await service.create(
      payload: Uint8List.fromList([7]),
      appVersion: 'legacy',
      createdAt: DateTime.utc(2026),
    );
    final file = File('${directory.path}/legacy.planact');
    final encoded = package.encode();
    await file.writeAsString(encoded);
    picker.importPath = file.path;
    keys.loads = 0;
    expect(
      await actions.importRecoveryBackup(
        requestKey: () async => throw StateError('recovery'),
        confirmLegacy: () async => false,
      ),
      false,
    );
    expect(keys.loads, 0);
    expect(exclusives, 0);
    expect(
      await actions.importRecoveryBackup(
        requestKey: () async => throw StateError('recovery'),
        confirmLegacy: () async => true,
      ),
      true,
    );
    expect(keys.loads, 1);
    expect(storage.current, [7]);
    expect(await file.readAsString(), encoded);
  });
}
