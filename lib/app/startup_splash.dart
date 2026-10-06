import 'package:flutter/material.dart';
import 'package:planact/app/planact_app.dart';
import 'package:planact/app/theme/planact_theme.dart';
import 'package:planact/features/commitments/application/commitment_repository.dart';

class PlanActStartup extends StatefulWidget {
  const PlanActStartup({super.key, required this.repositoryLoader});

  final Future<CommitmentRepository> Function() repositoryLoader;

  @override
  State<PlanActStartup> createState() => _PlanActStartupState();
}

class _PlanActStartupState extends State<PlanActStartup> {
  late Future<CommitmentRepository> _repositoryFuture = widget
      .repositoryLoader();

  void _retry() {
    setState(() {
      _repositoryFuture = widget.repositoryLoader();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'پلن‌اکت',
      debugShowCheckedModeBanner: false,
      theme: PlanActTheme.light(),
      darkTheme: PlanActTheme.dark(),
      themeMode: ThemeMode.system,
      home: FutureBuilder<CommitmentRepository>(
        future: _repositoryFuture,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _StartupError(onRetry: _retry);
          }
          if (snapshot.hasData) {
            return PlanActApp(repository: snapshot.data);
          }
          return const _StartupSplash();
        },
      ),
    );
  }
}

class _StartupSplash extends StatelessWidget {
  const _StartupSplash();

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.rtl,
    child: Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/icons/app_icon.png',
                  width: 112,
                  height: 112,
                  excludeFromSemantics: true,
                ),
                const SizedBox(height: 24),
                Text(
                  'پلن‌اکت',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                const Text(
                  'برنامه‌ریزی برای انجام تعهدات',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                const CircularProgressIndicator(
                  semanticsLabel: 'آماده‌سازی فضای شخصی شما',
                ),
                const SizedBox(height: 16),
                const Text(
                  'آماده‌سازی فضای شخصی شما',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class _StartupError extends StatelessWidget {
  const _StartupError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.rtl,
    child: Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48),
              const SizedBox(height: 16),
              const Text('راه‌اندازی برنامه انجام نشد'),
              const SizedBox(height: 8),
              Text(
                'اتصال به فضای ذخیره‌سازی برقرار نشد.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('تلاش دوباره'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
