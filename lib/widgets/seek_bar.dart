import 'dart:math';

import 'package:audiobooks/resources/duration_format.dart';
import 'package:material_ui/material_ui.dart';

class SeekBar extends StatefulWidget {
  final Duration duration;
  final Duration position;
  final Duration bufferedPosition;
  final ValueChanged<Duration>? onChanged;
  final ValueChanged<Duration>? onChangeEnd;

  const SeekBar({
    super.key,
    required this.duration,
    required this.position,
    this.bufferedPosition = Duration.zero,
    this.onChanged,
    this.onChangeEnd,
  });

  @override
  State<SeekBar> createState() => _SeekBarState();
}

class _SeekBarState extends State<SeekBar> {
  double? _dragValue;
  bool _dragging = false;
  late SliderThemeData _sliderThemeData;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sliderThemeData = SliderTheme.of(context).copyWith(trackHeight: 2.0);
  }

  @override
  Widget build(BuildContext context) {
    final maxMs = widget.duration.inMilliseconds.toDouble();
    final value = min(
      _dragValue ?? widget.position.inMilliseconds.toDouble(),
      maxMs,
    );
    if (_dragValue != null && !_dragging) {
      _dragValue = null;
    }
    final theme = Theme.of(context);
    return Stack(
      children: [
        if (maxMs > 0)
          SliderTheme(
            data: _sliderThemeData.copyWith(
              thumbShape: _HiddenThumbComponentShape(),
              activeTrackColor: theme.colorScheme.primary.withValues(alpha: 0.35),
              inactiveTrackColor: theme.colorScheme.surfaceContainerHighest,
            ),
            child: ExcludeSemantics(
              child: Slider(
                min: 0.0,
                max: maxMs,
                value: min(
                  widget.bufferedPosition.inMilliseconds.toDouble(),
                  maxMs,
                ),
                onChanged: (_) {},
              ),
            ),
          ),
        SliderTheme(
          data: _sliderThemeData.copyWith(
            inactiveTrackColor: Colors.transparent,
          ),
          child: Slider(
            min: 0.0,
            max: maxMs > 0 ? maxMs : 1.0,
            value: maxMs > 0 ? value : 0.0,
            onChanged: maxMs > 0
                ? (v) {
                    if (!_dragging) _dragging = true;
                    setState(() => _dragValue = v);
                    widget.onChanged?.call(Duration(milliseconds: v.round()));
                  }
                : null,
            onChangeEnd: maxMs > 0
                ? (v) {
                    widget.onChangeEnd?.call(Duration(milliseconds: v.round()));
                    _dragging = false;
                  }
                : null,
          ),
        ),
        Positioned(
          right: 16.0,
          bottom: 0.0,
          child: Text(
            formatDuration(_remaining),
            style: theme.textTheme.bodySmall,
          ),
        ),
      ],
    );
  }

  Duration get _remaining => widget.duration - widget.position;
}

class _HiddenThumbComponentShape extends SliderComponentShape {
  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) => Size.zero;

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    Animation<double>? activationAnimation,
    Animation<double>? enableAnimation,
    bool? isDiscrete,
    TextPainter? labelPainter,
    RenderBox? parentBox,
    SliderThemeData? sliderTheme,
    TextDirection? textDirection,
    double? value,
    double? textScaleFactor,
    Size? sizeWithOverflow,
  }) {}
}
