import 'dart:math';

import 'package:audiobooks/resources/duration_format.dart';
import 'package:flutter/material.dart';

/// A scrubber tuned for the dark now-playing gradient: light track, amber
/// thumb, time labels beneath.
class ImmersiveScrubber extends StatefulWidget {
  final Duration duration;
  final Duration position;
  final ValueChanged<Duration> onSeek;
  final Color accent;

  const ImmersiveScrubber({
    super.key,
    required this.duration,
    required this.position,
    required this.onSeek,
    required this.accent,
  });

  @override
  State<ImmersiveScrubber> createState() => _ImmersiveScrubberState();
}

class _ImmersiveScrubberState extends State<ImmersiveScrubber> {
  double? _dragValue;

  @override
  Widget build(BuildContext context) {
    final maxMs = widget.duration.inMilliseconds.toDouble();
    final value = (_dragValue ?? widget.position.inMilliseconds.toDouble())
        .clamp(0.0, maxMs > 0 ? maxMs : 1.0);
    final remaining = widget.duration - widget.position;

    return Column(
      children: [
        SliderTheme(
          data: SliderThemeData(
            trackHeight: 4,
            activeTrackColor: widget.accent,
            inactiveTrackColor: Colors.white24,
            thumbColor: widget.accent,
            overlayColor: widget.accent.withValues(alpha: 0.2),
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
            trackShape: const RoundedRectSliderTrackShape(),
          ),
          child: Slider(
            min: 0,
            max: maxMs > 0 ? maxMs : 1,
            value: value,
            onChanged: maxMs > 0
                ? (v) => setState(() => _dragValue = v)
                : null,
            onChangeEnd: maxMs > 0
                ? (v) {
                    widget.onSeek(Duration(milliseconds: v.round()));
                    setState(() => _dragValue = null);
                  }
                : null,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                formatDuration(Duration(milliseconds: value.round())),
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
              Text(
                '-${formatDuration(Duration(milliseconds: max(0, remaining.inMilliseconds)))}',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
