import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('درباره پلن‌اکت')),
    body: FutureBuilder<PackageInfo>(
      future: PackageInfo.fromPlatform(),
      builder: (context, snapshot) {
        final info = snapshot.data;
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Image.asset(
                  'assets/icons/app_icon.png',
                  width: 96,
                  height: 96,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              info?.appName ?? 'پلن‌اکت',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            const Text(
              'دستیار محلی برای مدیریت تعهدها، برنامه‌ها و امور مالی روزمره.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.info_outline),
                    title: const Text('نسخه'),
                    subtitle: Text(
                      info == null
                          ? 'در حال بارگذاری…'
                          : '${info.version} (${info.buildNumber})',
                    ),
                  ),
                  const Divider(height: 1),
                  const ListTile(
                    leading: Icon(Icons.privacy_tip_outlined),
                    title: Text('حریم خصوصی'),
                    subtitle: Text(
                      'اطلاعات اصلی برنامه به‌صورت محلی روی دستگاه نگهداری می‌شود.',
                    ),
                  ),
                  const Divider(height: 1),
                  const ListTile(
                    leading: Icon(Icons.code_outlined),
                    title: Text('مجوز و متن‌باز'),
                    subtitle: Text(
                      'اطلاعات مجوز در زمان انتشار رسمی محصول اعلام می‌شود.',
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    ),
  );
}
