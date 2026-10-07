import 'dart:async';

/// Implemented by durable adapters so commands inherit their owner's generation.
abstract interface class CommandGateProvider {
  CommandGate? get commandGate;
}

class StaleApplicationCommand implements Exception {
  const StaleApplicationCommand();
  @override
  String toString() => 'Application scope is suspended or retired';
}

/// Drains whole commands, not just individual writes. Nested operations retain
/// the admitted lease while suspension rejects new callers synchronously.
final class CommandGate {
  static final _owners = Expando<CommandGate>();
  static final Object _zoneKey = Object();
  bool _accepting = true;
  int _active = 0;
  Completer<void>? _drained;

  static void bind(Object owner, CommandGate gate) => _owners[owner] = gate;
  static CommandGate? forOwner(Object owner) => _owners[owner];
  static Future<T> runFor<T>(Object owner, Future<T> Function() operation) {
    final gate = owner is CommandGateProvider
        ? owner.commandGate
        : forOwner(owner);
    return gate == null ? Future.sync(operation) : gate.run(operation);
  }

  Future<T> run<T>(Future<T> Function() operation) async {
    final inherited = Zone.current[_zoneKey];
    if (inherited is _CommandLease &&
        identical(inherited.gate, this) &&
        inherited.active) {
      // Count nested work too, including work launched without being awaited.
      return _admit(operation);
    }
    if (!_accepting) throw const StaleApplicationCommand();
    return _admit(operation);
  }

  Future<T> _admit<T>(Future<T> Function() operation) async {
    _active++;
    final lease = _CommandLease(this);
    try {
      return await runZoned(operation, zoneValues: {_zoneKey: lease});
    } finally {
      lease.active = false;
      _active--;
      if (!_accepting && _active == 0) _drained?.complete();
    }
  }

  /// Irreversible: even an export/cancel creates a fresh application generation.
  Future<void> retire() {
    _accepting = false;
    if (_active == 0) return Future.value();
    return (_drained ??= Completer<void>()).future;
  }
}

final class _CommandLease {
  _CommandLease(this.gate);
  final CommandGate gate;
  bool active = true;
}
