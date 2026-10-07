import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:planact/app/theme/planact_spacing.dart';

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
          stickyAuth: false,
        ),
      );
    } on PlatformException {
      return false;
    }
  }
}

class AppLockController extends ChangeNotifier {
  AppLockController({required this.authenticator});

  final AppAuthenticator authenticator;
  bool _locked = false;
  bool _authenticating = false;

  int _generation = 0;
  bool get isLocked => _locked;
  bool get isAuthenticating => _authenticating;

  Future<bool> enable() => verify();
  bool _changingSetting = false;

  /// The durable write precedes any change to effective protection.
  Future<void> changeSetting({
    required bool enabled,
    required Future<void> Function(bool) persist,
  }) async {
    if (_changingSetting) throw StateError('Setting change already running');
    _changingSetting = true;
    try {
      if (!await verify()) throw StateError('Authentication not completed');
      await persist(enabled);
      if (!enabled) disable();
    } finally {
      _changingSetting = false;
    }
  }

  /// Used for both enabling and disabling protection. Never changes settings.
  Future<bool> verify() async {
    if (_authenticating) return false;
    _authenticating = true;
    final generation = _generation;
    try {
      if (!await authenticator.isAvailable()) return false;
      return await authenticator.authenticate() && generation == _generation;
    } finally {
      _authenticating = false;
    }
  }

  void disable() {
    _generation++;
    _locked = false;
    notifyListeners();
  }

  void lock() {
    _generation++;
    _locked = true;
    notifyListeners();
  }

  Future<bool> unlock() async {
    if (!_locked) return true;
    if (_authenticating) return false;
    final generation = _generation;
    final success = await verify() && generation == _generation;
    if (success) {
      _locked = false;
      notifyListeners();
    }
    return success;
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
  bool _inactive = false;
  bool _checking = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.controller.addListener(_changed);
    if (widget.enabled) {
      widget.controller.lock();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _lockAndAuthenticate();
      });
    }
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  void didUpdateWidget(covariant AppLockGate oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_changed);
      widget.controller.addListener(_changed);
    }
    if (!oldWidget.enabled && widget.enabled && widget.controller.isLocked) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _lockAndAuthenticate();
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _inactive = state != AppLifecycleState.resumed;
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached ||
        (state == AppLifecycleState.inactive &&
            !widget.controller.isAuthenticating)) {
      _backgrounded = true;
      // Also invalidate setting-change authentication while protection is off.
      widget.controller.lock();
    } else if (state == AppLifecycleState.resumed && _backgrounded) {
      _backgrounded = false;
      if (widget.enabled && !widget.controller.isAuthenticating) {
        _lockAndAuthenticate();
      }
    }
    if (mounted) setState(() {});
  }

  Future<void> _lockAndAuthenticate() async {
    if (_checking || _inactive || !widget.enabled) {
      return;
    }
    _checking = true;
    if (mounted) setState(() => _error = null);
    try {
      final success = await widget.controller.unlock();
      if (!success) {
        _error = 'احراز هویت انجام نشد. برای تلاش دوباره دکمه را بزنید.';
      }
    } catch (_) {
      _error =
          'احراز هویت در دسترس نیست. قفل دستگاه را بررسی و دوباره تلاش کنید.';
    } finally {
      _checking = false;
      if (mounted) setState(() {});
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.controller.removeListener(_changed);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final obscured =
        widget.enabled && (widget.controller.isLocked || _inactive);
    final scheme = Theme.of(context).colorScheme;
    return Stack(
      fit: StackFit.expand,
      children: [
        Offstage(
          offstage: obscured,
          child: TickerMode(
            enabled: !obscured,
            child: ExcludeFocus(excluding: obscured, child: widget.child),
          ),
        ),
        if (obscured)
          Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(PlanActSpacing.xl),
                child: SingleChildScrollView(
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
                        onPressed: _checking || _inactive
                            ? null
                            : _lockAndAuthenticate,
                        icon: const Icon(Icons.fingerprint),
                        label: Text(
                          _checking ? 'در حال بررسی…' : 'باز کردن قفل',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
