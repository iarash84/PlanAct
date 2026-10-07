import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planact/features/backup/data/secure_backup_keys.dart';
import 'package:planact/features/backup/domain/backup_package.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));
  test('import never provisions a missing key', () async {
    const keys = SecureBackupKeys();
    await expectLater(keys.loadKey(backupKeyId), throwsException);
    expect(await keys.storage.read(key: backupKeyId), isNull);
  });
  test(
    'export provisions a stable 256-bit key across adapter recreation',
    () async {
      const keys = SecureBackupKeys();
      await keys.provisionForExport();
      final first = await keys.loadKey(backupKeyId);
      expect(first.length, 32);
      await keys.provisionForExport();
      expect(await const SecureBackupKeys().loadKey(backupKeyId), first);
      await expectLater(keys.loadKey('unknown'), throwsException);
    },
  );
  test(
    'invalid stored key is rejected rather than silently replaced',
    () async {
      FlutterSecureStorage.setMockInitialValues({backupKeyId: 'invalid'});
      const keys = SecureBackupKeys();
      await expectLater(keys.loadKey(backupKeyId), throwsException);
      await keys.provisionForExport();
      expect(await keys.storage.read(key: backupKeyId), 'invalid');
    },
  );
}
