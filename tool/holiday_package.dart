import 'dart:convert';
import 'dart:io';

import 'package:cryptography/cryptography.dart';
import 'package:planact/features/calendar/domain/holiday_data_package.dart';

/// Publisher-only offline tool. Keep the seed outside the repository.
Future<void> main(List<String> args) async {
  try {
    final algorithm = Ed25519();
    if (args.length == 2 && args[0] == 'keygen') {
      final file = File(args[1]);
      if (file.existsSync()) throw StateError('Refusing to overwrite a key');
      final key = await algorithm.newKeyPair();
      await file.writeAsString(
        base64Encode(await key.extractPrivateKeyBytes()),
        flush: true,
      );
      stdout.writeln(
        'Private signing seed created. Restrict file access and keep it offline.',
      );
    } else if (args.length == 4 && args[0] == 'sign') {
      final output = File(args[3]);
      if (output.existsSync()) {
        throw StateError('Refusing to overwrite a package');
      }
      final seed = base64Decode((await File(args[1]).readAsString()).trim());
      if (seed.length != 32) throw StateError('Expected a 32-byte seed');
      final key = await algorithm.newKeyPairFromSeed(seed);
      final payload = await File(args[2]).readAsBytes();
      final signature = await algorithm.sign(payload, keyPair: key);
      final encoded = jsonEncode({
        'format': 'planact-holidays-v1',
        'payload': base64Encode(payload),
        'publicKey': base64Encode((await key.extractPublicKey()).bytes),
        'signature': base64Encode(signature.bytes),
      });
      final verified = await HolidayDataPackage.verify(encoded);
      await output.writeAsString(encoded, flush: true);
      stdout.writeln(
        'Signed year ${verified.year}, revision ${verified.revision}',
      );
      stdout.writeln(
        'Publish this fingerprint through an independent trusted channel: ${verified.fingerprint}',
      );
    } else if (args.length == 2 && args[0] == 'verify') {
      final package = await HolidayDataPackage.verify(
        await File(args[1]).readAsString(),
      );
      stdout.writeln(
        '${package.year} r${package.revision}: ${package.fingerprint}',
      );
    } else {
      stderr.writeln(
        'Usage: dart run tool/holiday_package.dart keygen SEED_FILE\n'
        '       dart run tool/holiday_package.dart sign SEED_FILE REVIEWED_JSON OUTPUT\n'
        '       dart run tool/holiday_package.dart verify PACKAGE',
      );
      exitCode = 64;
    }
  } catch (error) {
    stderr.writeln('Holiday package operation failed: $error');
    exitCode = 1;
  }
}
