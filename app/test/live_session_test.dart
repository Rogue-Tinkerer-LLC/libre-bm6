import 'dart:async';
import 'dart:math';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:libre_bm6_app/live_session.dart';
import 'package:libre_bm6_universal_ble/libre_bm6_universal_ble.dart';

const deviceId = 'A1:B2:C3:D4:E5:F6';

LiveData frame({double voltage = 12.6}) => LiveData(
  temperature: 20,
  status: 0,
  stateOfCharge: 80,
  voltage: voltage,
  rapidAccelerations: 0,
  rapidDecelerations: 0,
);

/// A fake `liveData` that records every connection.
class FakeLink {
  FakeLink({this.cancelDelay = Duration.zero});

  final Duration cancelDelay;
  final streams = <StreamController<LiveData>>[];
  int active = 0;
  int maxActive = 0;
  int cancels = 0;

  StreamController<LiveData> get last => streams.last;

  Stream<LiveData> call(String id) {
    final controller = StreamController<LiveData>(
      onListen: () => maxActive = max(maxActive, ++active),
      onCancel: () async {
        cancels++;
        // A zero delay would still be a timer, which defers onDone.
        if (cancelDelay > Duration.zero) {
          await Future<void>.delayed(cancelDelay);
        }
        active--;
      },
    );
    streams.add(controller);
    return controller.stream;
  }
}

void main() {
  late FakeLink link;
  late LiveSession session;
  late int changes;

  void startSession(FakeAsync async, {Duration? cancelDelay}) {
    link = FakeLink(cancelDelay: cancelDelay ?? Duration.zero);
    changes = 0;
    session = LiveSession(link.call, deviceId, onChange: () => changes++)
      ..start();
    async.flushMicrotasks();
  }

  /// Asserts that the next connection opens after exactly [delay].
  void expectReconnectAfter(FakeAsync async, Duration delay) {
    final count = link.streams.length;
    async.elapse(delay - const Duration(milliseconds: 1));
    expect(link.streams, hasLength(count), reason: 'too early for $delay');
    async.elapse(const Duration(milliseconds: 1));
    expect(link.streams, hasLength(count + 1), reason: 'late for $delay');
  }

  group('LiveSession', () {
    test('connects on start and goes live on the first frame', () {
      fakeAsync((async) {
        startSession(async);
        expect(link.streams, hasLength(1));
        expect(session.state, LinkState.connecting);

        link.last.add(frame(voltage: 12.5));
        async.flushMicrotasks();

        expect(session.state, LinkState.live);
        expect(session.latest?.voltage, 12.5);
        expect(changes, 1);
      });
    });

    test('reconnects after an error followed by done', () {
      fakeAsync((async) {
        startSession(async);
        final error = Exception('setup failed');
        link.last
          ..addError(error)
          ..close();
        async.flushMicrotasks();

        expect(session.state, LinkState.reconnecting);
        expect(session.lastError, error);
        expectReconnectAfter(async, const Duration(seconds: 2));
      });
    });

    test('reconnects after done and reports a disconnect', () {
      fakeAsync((async) {
        startSession(async);
        link.last.add(frame());
        link.last.close();
        async.flushMicrotasks();

        expect(session.state, LinkState.reconnecting);
        expect(session.lastError, LinkProblem.disconnected);
        expectReconnectAfter(async, const Duration(seconds: 2));
      });
    });

    test('treats an error event as non-fatal', () {
      fakeAsync((async) {
        startSession(async);
        link.last.add(frame());
        final error = ArgumentError('short notification');
        link.last.addError(error);
        async.elapse(const Duration(seconds: 5));

        expect(session.state, LinkState.live);
        expect(session.lastError, error);
        expect(link.streams, hasLength(1));
      });
    });

    test('doubles the delay up to 30 seconds', () {
      fakeAsync((async) {
        startSession(async);
        for (final seconds in [2, 4, 8, 16, 30, 30]) {
          link.last.close();
          async.flushMicrotasks();
          expectReconnectAfter(async, Duration(seconds: seconds));
        }
      });
    });

    test('resets the delay after a frame arrives', () {
      fakeAsync((async) {
        startSession(async);
        for (final seconds in [2, 4]) {
          link.last.close();
          async.flushMicrotasks();
          expectReconnectAfter(async, Duration(seconds: seconds));
        }
        link.last.add(frame());
        link.last.close();
        async.flushMicrotasks();

        expectReconnectAfter(async, const Duration(seconds: 2));
        expect(session.lastError, LinkProblem.disconnected);
      });
    });

    test('clears the last error on the first frame of a connection', () {
      fakeAsync((async) {
        startSession(async);
        link.last.close();
        async.elapse(const Duration(seconds: 2));
        link.last.add(frame());
        async.flushMicrotasks();

        expect(session.lastError, isNull);
      });
    });

    test('restarts when no frame arrives for 10 seconds while live', () {
      fakeAsync((async) {
        startSession(async);
        link.last.add(frame());
        async.elapse(const Duration(seconds: 9));
        link.last.add(frame());
        async.elapse(const Duration(seconds: 9));
        expect(session.state, LinkState.live);

        async.elapse(const Duration(seconds: 1));
        expect(session.state, LinkState.reconnecting);
        expect(session.lastError, LinkProblem.stalled);
        expect(link.cancels, 1);
        expectReconnectAfter(async, const Duration(seconds: 2));
      });
    });

    test('waits for the old cancel before connecting again', () {
      fakeAsync((async) {
        startSession(async, cancelDelay: const Duration(seconds: 3));
        link.last.add(frame());
        async.elapse(const Duration(seconds: 10));
        expect(session.state, LinkState.reconnecting);

        // 3 s of cancel, then the 2 s delay.
        async.elapse(const Duration(milliseconds: 4999));
        expect(link.streams, hasLength(1));
        async.elapse(const Duration(milliseconds: 1));
        expect(link.streams, hasLength(2));
        expect(link.maxActive, 1);
      });
    });

    test('a cancel during the reconnect wait stops reconnecting', () {
      fakeAsync((async) {
        startSession(async);
        link.last.close();
        async.elapse(const Duration(seconds: 1));
        var closed = false;
        session.close().then((_) => closed = true);
        async.elapse(const Duration(minutes: 5));

        expect(closed, isTrue);
        expect(link.streams, hasLength(1));
      });
    });

    test('close disconnects and completes after the cancel', () {
      fakeAsync((async) {
        startSession(async, cancelDelay: const Duration(seconds: 2));
        link.last.add(frame());
        async.flushMicrotasks();
        var closed = false;
        session.close().then((_) => closed = true);
        async.elapse(const Duration(seconds: 1));
        expect(link.cancels, 1);
        expect(closed, isFalse);

        async.elapse(const Duration(minutes: 1));
        expect(closed, isTrue);
        expect(link.active, 0);
        expect(link.streams, hasLength(1));
      });
    });

    test('restart while live waits for the old cancel and resets backoff', () {
      fakeAsync((async) {
        startSession(async, cancelDelay: const Duration(seconds: 2));
        // Grow the backoff first. Each end waits 2 s for its cancel.
        link.last.close();
        async.elapse(const Duration(seconds: 4));
        link.last.close();
        async.elapse(const Duration(seconds: 6));
        link.last.add(frame(voltage: 12.4));
        async.flushMicrotasks();
        expect(link.streams, hasLength(3));

        var done = false;
        session.restart().then((_) => done = true);
        async.flushMicrotasks();
        expect(session.state, LinkState.reconnecting);
        expect(session.latest?.voltage, 12.4);
        expect(link.streams, hasLength(3));

        async.elapse(const Duration(seconds: 2));
        expect(link.streams, hasLength(4));
        expect(link.maxActive, 1);
        expect(done, isFalse);

        link.last.add(frame());
        async.flushMicrotasks();
        expect(done, isTrue);
        expect(session.history, [12.4, 12.6]);

        // The backoff is back at its first value, after the 2 s cancel.
        link.last.close();
        async.elapse(const Duration(seconds: 2));
        expectReconnectAfter(async, const Duration(seconds: 2));
      });
    });

    test('restart during a backoff wait connects once, immediately', () {
      fakeAsync((async) {
        startSession(async);
        link.last.close();
        async.elapse(const Duration(seconds: 1));

        session.restart();
        async.flushMicrotasks();
        expect(link.streams, hasLength(2));

        async.elapse(const Duration(minutes: 1));
        expect(link.streams, hasLength(2));
      });
    });

    test('restart while an automatic cancel is pending connects once', () {
      fakeAsync((async) {
        startSession(async, cancelDelay: const Duration(seconds: 3));
        link.last.add(frame());
        async.elapse(const Duration(seconds: 10)); // stall, cancel pending

        session.restart();
        async.elapse(const Duration(minutes: 1));

        expect(link.streams, hasLength(2));
        expect(link.maxActive, 1);
      });
    });

    test('restart twice in a row is a single restart', () {
      fakeAsync((async) {
        startSession(async);
        link.last.add(frame());
        async.flushMicrotasks();

        final first = session.restart();
        final second = session.restart();
        async.elapse(const Duration(seconds: 1));

        expect(identical(first, second), isTrue);
        expect(link.streams, hasLength(2));
        expect(link.cancels, 1);
      });
    });

    test('restart completes when the new connection reports an error', () {
      fakeAsync((async) {
        startSession(async);
        var done = false;
        session.restart().then((_) => done = true);
        async.flushMicrotasks();

        link.last.addError(Exception('setup failed'));
        async.flushMicrotasks();
        expect(done, isTrue);
      });
    });

    test('restart after close does nothing', () {
      fakeAsync((async) {
        startSession(async);
        session.close();
        async.flushMicrotasks();

        var done = false;
        session.restart().then((_) => done = true);
        async.elapse(const Duration(minutes: 1));

        expect(done, isTrue);
        expect(link.streams, hasLength(1));
      });
    });

    test('keeps only the most recent voltages', () {
      fakeAsync((async) {
        link = FakeLink();
        session = LiveSession(
          link.call,
          deviceId,
          onChange: () {},
          historyLength: 3,
        )..start();
        for (final voltage in [12.1, 12.2, 12.3, 12.4]) {
          link.last.add(frame(voltage: voltage));
        }
        async.flushMicrotasks();

        expect(session.history, [12.2, 12.3, 12.4]);
        session.close();
        async.flushMicrotasks();
      });
    });
  });
}
