import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

abstract interface class AppAuthenticator {
  Future<bool> isAvailable();
  Future<bool> authenticate();
}

class LocalAppAuthenticator implements AppAuthenticator {
  LocalAppAuthenticator([LocalAuthentication? authentication])
    : _authentication = authentication ?? LocalAuthentication();

  final LocalAuthentication _authentication;

  @override
  Future<bool> isAvailable() async {
    try {
      return await _authentication.isDeviceSupported();
    } on PlatformException {
      return false;
    }
  }

  @override
  Future<bool> authenticate() async {
    try {
      return await _authentication.authenticate(
        localizedReason: 'برای ورود به پلن‌اکت هویت خود را تأیید کنید.',
        options: const AuthenticationOptions(
          biometricOnly: false,
          useErrorDialogs: true,
          stickyAuth: true,
        ),
      );
    } on PlatformException {
      return false;
    }
  }
}

class AppLockController {
  AppLockController({required this.authenticator});

  final AppAuthenticator authenticator;
  bool _locked = false;
  bool _authenticating = false;

  bool get isLocked => _locked;

  Future<bool> enable() async {
    if (!await authenticator.isAvailable()) return false;
    if (!await authenticator.authenticate()) return false;
    _locked = false;
    return true;
  }

  void disable() => _locked = false;

  void lock() {
    if (!_authenticating) _locked = true;
  }

  Future<bool> unlock() async {
    if (!_locked || _authenticating) return !_locked;
    _authenticating = true;
    try {
      final success = await authenticator.authenticate();
      if (success) _locked = false;
      return success;
    } finally {
      _authenticating = false;
    }
  }
}

class AppLockGate extends StatefulWidget {
  const AppLockGate({
    super.key,
    required this.enabled,
    required this.controller,
    required this.child,
  });

  final bool enabled;
  final AppLockController controller;
  final Widget child;

  @override
  State<AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends State<AppLockGate> with WidgetsBindingObserver {
  bool _backgrounded = false;
  bool _checking = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.enabled) {
      widget.controller.lock();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _lockAndAuthenticate();
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _backgrounded = true;
    } else if (state == AppLifecycleState.resumed && _backgrounded) {
      _backgrounded = false;
      if (widget.enabled) {
        widget.controller.lock();
        setState(() {});
        _lockAndAuthenticate();
      }
    }
  }

  Future<void> _lockAndAuthenticate() async {
    if (_checking || !widget.enabled) {
      return;
    }
    _checking = true;
    widget.controller.lock();
    if (mounted) setState(() => _error = null);
    final success = await widget.controller.unlock();
    if (mounted) {
      setState(() {
        _checking = false;
        if (!success) {
          _error = 'احراز هویت انجام نشد. برای تلاش دوباره دکمه را بزنید.';
        }
      });
    } else {
      _checking = false;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled || !widget.controller.isLocked) return widget.child;
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lock_outline, size: 56, color: scheme.primary),
              const SizedBox(height: 16),
              Text(
                'پلن‌اکت قفل است',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                _error ?? 'برای ادامه، هویت خود را تأیید کنید.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _checking ? null : _lockAndAuthenticate,
                icon: const Icon(Icons.fingerprint),
                label: Text(_checking ? 'در حال بررسی…' : 'باز کردن قفل'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
