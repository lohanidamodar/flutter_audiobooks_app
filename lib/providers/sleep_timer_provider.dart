import 'dart:async';

import 'package:audiobooks/providers/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Remaining sleep-timer duration, or null when inactive.
final sleepTimerProvider =
    NotifierProvider<SleepTimerNotifier, Duration?>(SleepTimerNotifier.new);

class SleepTimerNotifier extends Notifier<Duration?> {
  Timer? _timer;

  @override
  Duration? build() {
    ref.onDispose(() => _timer?.cancel());
    return null;
  }

  void start(Duration duration) {
    _timer?.cancel();
    if (duration <= Duration.zero) {
      state = null;
      return;
    }
    state = duration;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final remaining = (state ?? Duration.zero) - const Duration(seconds: 1);
      if (remaining <= Duration.zero) {
        _timer?.cancel();
        state = null;
        ref.read(audiobookPlayerProvider).player.pause();
      } else {
        state = remaining;
      }
    });
  }

  /// Stops at the end of the currently playing chapter.
  void startEndOfChapter() {
    final player = ref.read(audiobookPlayerProvider).player;
    final duration = player.duration;
    if (duration == null) return;
    start(duration - player.position);
  }

  void cancel() {
    _timer?.cancel();
    state = null;
  }
}
