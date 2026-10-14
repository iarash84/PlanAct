import 'dart:convert';
import 'dart:ui' as ui;

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/features/finance/domain/finance.dart';
import 'package:planact/features/finance/presentation/account_identity_icon.dart';

void main() {
  test(
    'reviewed source mapping and complete asset hashes stay intact',
    () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      const sources = {
        'melli': 'bmi',
        'mellat': 'mellat',
        'saderat': 'bsi',
        'tejarat': 'tejarat',
        'refah': 'rb',
        'maskan': 'maskan',
        'sepah': 'sepah',
        'keshavarzi': 'bki',
        'pasargad': 'bpi',
        'saman': 'sb',
        'parsian': 'parsian',
        'shahr': 'shahr',
        'ayandeh': 'ba',
        'eghtesad_novin': 'en',
        'day': 'day',
        'gardeshgari': 'tourism',
        'iran_zamin': 'iz',
        'karafarin': 'kar',
        'sina': 'sina',
        'ghavamin': 'ghbi',
      };
      final manifest = jsonDecode(
        await rootBundle.loadString('assets/banks/manifest.json'),
      ) as Map<String, dynamic>;
      expect(
        sources.keys.toSet(),
        IranianBank.values.map((b) => b.code).toSet(),
      );
      for (final entry in sources.entries) {
        expect(manifest[entry.key]['source'], '${entry.value}-300-wc.png');
      }
      for (final entry in manifest.entries) {
        final bytes = await rootBundle.load('assets/banks/${entry.key}.png');
        expect(
          sha256.convert(bytes.buffer.asUint8List()).toString(),
          entry.value['sha256'],
          reason: entry.key,
        );
      }
    },
  );
  test('every selectable bank has a decodable bundled logo', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    for (final bank in IranianBank.values) {
      final data = await rootBundle.load('assets/banks/${bank.code}.png');
      final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
      final frame = await codec.getNextFrame();
      expect(frame.image.width, 300, reason: bank.code);
      expect(frame.image.height, 300, reason: bank.code);
      frame.image.dispose();
      codec.dispose();
    }
  });

  testWidgets('saved bank controls image and Persian semantics', (
    tester,
  ) async {
    final account = FinancialAccount(
      id: StableId.generate(),
      name: 'حساب شخصی',
      currency: 'IRR',
      type: FinancialAccountType.bank,
      bank: IranianBank.mellat,
    );
    await tester.pumpWidget(
      MaterialApp(home: AccountIdentityIcon(account: account)),
    );
    await tester.pumpAndSettle();
    final image = tester.widget<Image>(find.byType(Image));
    expect((image.image as AssetImage).assetName, 'assets/banks/mellat.png');
    expect(image.semanticLabel, 'نشان بانک ملت');
    expect(tester.takeException(), isNull);
  });

  testWidgets('bank is never inferred from account name', (tester) async {
    for (final type in [FinancialAccountType.bank, FinancialAccountType.cash]) {
      final account = FinancialAccount(
        id: StableId.generate(),
        name: 'بانک ملت',
        currency: 'IRR',
        type: type,
      );
      await tester.pumpWidget(
        MaterialApp(home: AccountIdentityIcon(account: account)),
      );
      expect(find.byType(Image), findsNothing);
      expect(
        find.byIcon(
          type == FinancialAccountType.bank
              ? Icons.account_balance
              : Icons.account_balance_wallet,
        ),
        findsOneWidget,
      );
    }
  });
}
