import 'dart:async';

import 'package:libre_bm6_universal_ble/libre_bm6_universal_ble.dart';

enum LinkState { connecting, live, reconnecting }

/// Why a session was restarted when the stream itself reported no error.
enum LinkProblem { disconnected, stalled }

/// Keeps a live-data stream running: reconnects with a capped backoff when
/// the stream ends, and restarts it when frames stop arriving or never start.
///
/// Error events are recorded in [lastError] but are not fatal, because the
/// adapter reports a malformed notification as an error and keeps going. A
/// setup failure arrives as an error followed by done.
class LiveSession {
  LiveSession(
    this._connect,
    this.deviceId, {
    required this.onChange,
    this.firstDelay = const Duration(seconds: 2),
    this.maxDelay = const Duration(seconds: 30),
    this.stallTimeout = const Duration(seconds: 10),
    this.firstFrameTimeout = const Duration(seconds: 40),
    this.restartTimeout = const Duration(seconds: 10),
    this.historyLength = 300,
  }) : _delay = firstDelay;

  final Stream<LiveData> Function(String deviceId) _connect;
  final String deviceId;
  final void Function() onChange;
  final Duration firstDelay;
  final Duration maxDelay;
  final Duration stallTimeout;

  /// How long a connection may go without its first frame. Longer than
  /// Android's 30 s connect attempt, so the platform's own failure wins when
  /// the monitor is out of range.
  final Duration firstFrameTimeout;

  /// How long [restart] waits for the new connection before completing.
  final Duration restartTimeout;

  /// How many voltages [history] keeps; at ~1 frame per second, 300 is five
  /// minutes.
  final int historyLength;

  LinkState state = LinkState.connecting;
  LiveData? latest;

  /// The last stream error or [LinkProblem], cleared by the first frame of
  /// each connection.
  Object? lastError;

  final List<double> history = [];

  Duration _delay;
  StreamSubscription<LiveData>? _subscription;
  Object? _sessionError;
  bool _gotFrame = false;
  Future<void> _cancelling = Future.value();
  Timer? _retry;
  Timer? _watchdog;
  bool _closed = false;
  // Bumped by restart() so an automatic reconnect already waiting on a
  // cancel does not open a second connection.
  int _generation = 0;
  Completer<void>? _restartDone;
  Timer? _restartTimer;

  void start() => _open();

  void _open() {
    if (_closed) return;
    _sessionError = null;
    _gotFrame = false;
    _subscription = _connect(deviceId).listen(
      _onData,
      onError: _onError,
      onDone: () =>
          _restart(_sessionError ?? LinkProblem.disconnected, ended: true),
    );
    _watchdog?.cancel();
    _watchdog = Timer(
      firstFrameTimeout,
      () => _restart(_sessionError ?? LinkProblem.disconnected, ended: false),
    );
  }

  /// Reconnects now, skipping any backoff wait. Completes when the new
  /// connection delivers a frame, reports an error, or ends, or after
  /// [restartTimeout]. A call while a restart is in flight joins it.
  Future<void> restart() {
    if (_closed) return Future.value();
    final inFlight = _restartDone;
    if (inFlight != null) return inFlight.future;
    final done = _restartDone = Completer<void>();
    _restartTimer = Timer(restartTimeout, _settleRestart);
    _generation++;
    _retry?.cancel();
    _watchdog?.cancel();
    final old = _subscription;
    _subscription = null;
    _delay = firstDelay;
    state = LinkState.reconnecting;
    onChange();
    _cancelling = _cancelling
        .then<void>((_) => old?.cancel())
        .catchError((Object _) {});
    _cancelling.then((_) => _open());
    return done.future;
  }

  void _settleRestart() {
    _restartTimer?.cancel();
    _restartDone?.complete();
    _restartDone = null;
  }

  void _onData(LiveData data) {
    _settleRestart();
    if (!_gotFrame) lastError = null;
    _gotFrame = true;
    latest = data;
    state = LinkState.live;
    _delay = firstDelay;
    history.add(data.voltage);
    if (history.length > historyLength) history.removeAt(0);
    _watchdog?.cancel();
    _watchdog = Timer(
      stallTimeout,
      () => _restart(LinkProblem.stalled, ended: false),
    );
    onChange();
  }

  void _onError(Object error) {
    _settleRestart();
    _sessionError = error;
    lastError = error;
    onChange();
  }

  void _restart(Object problem, {required bool ended}) {
    final old = _subscription;
    if (_closed || old == null) return;
    // A restart in flight has had no frame yet, so this ends its wait.
    _settleRestart();
    _subscription = null;
    _watchdog?.cancel();
    lastError = problem;
    state = LinkState.reconnecting;
    onChange();
    final delay = _delay;
    _delay = _delay * 2 > maxDelay ? maxDelay : _delay * 2;
    // Cancel disconnects and takes ~2 s on hardware, so the next connection
    // must not start until it has finished. An ended stream has nothing to
    // cancel.
    _cancelling = ended
        ? Future.value()
        : old.cancel().catchError((Object _) {});
    final generation = _generation;
    _cancelling.then((_) {
      if (!_closed && generation == _generation) {
        _retry = Timer(delay, _open);
      }
    });
  }

  /// Stops reconnecting and disconnects. Completes once the disconnect has.
  Future<void> close() async {
    _closed = true;
    _settleRestart();
    _retry?.cancel();
    _watchdog?.cancel();
    final subscription = _subscription;
    _subscription = null;
    await _cancelling;
    await subscription?.cancel().catchError((Object _) {});
  }
}
