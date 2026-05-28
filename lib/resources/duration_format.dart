String formatDuration(Duration d) {
  final h = d.inHours;
  final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
  final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  return h > 0 ? '$h:$m:$s' : '$m:$s';
}

String formatChapterLength(double seconds) {
  final d = Duration(seconds: seconds.round());
  if (d.inHours > 0) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    return '${d.inHours}h ${m}m';
  }
  final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '${d.inMinutes}m ${s}s';
}
