import 'package:audiobooks/providers/providers.dart';
import 'package:audiobooks/theme/audiobook_theme.dart';
import 'package:audiobooks/widgets/immersive_scrubber.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

class NowPlayingPage extends ConsumerWidget {
  const NowPlayingPage({super.key});

  static Route<void> route() => PageRouteBuilder(
        opaque: true,
        transitionDuration: const Duration(milliseconds: 360),
        reverseTransitionDuration: const Duration(milliseconds: 280),
        pageBuilder: (_, __, ___) => const NowPlayingPage(),
        transitionsBuilder: (_, anim, __, child) {
          final curved =
              CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
          return SlideTransition(
            position: Tween(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          );
        },
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mediaItem = ref.watch(mediaItemProvider).value;
    final artUrl = mediaItem?.artUri?.toString();
    final coverColor = artUrl != null
        ? ref.watch(coverColorProvider(artUrl)).value
        : null;
    final accent = Theme.of(context).colorScheme.primary;
    const bg = Color(0xFF0B0A09);
    final glow = coverColor ?? accent;

    return Scaffold(
      backgroundColor: bg,
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.alphaBlend(glow.withValues(alpha: 0.55), bg),
              Color.alphaBlend(glow.withValues(alpha: 0.12), bg),
              bg,
            ],
            stops: const [0.0, 0.45, 0.85],
          ),
        ),
        child: SafeArea(
          child: GestureDetector(
            onVerticalDragEnd: (d) {
              if ((d.primaryVelocity ?? 0) > 250) Navigator.of(context).pop();
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  _TopBar(album: mediaItem?.album),
                  const Spacer(flex: 2),
                  _Cover(artUrl: artUrl, glow: glow),
                  const Spacer(flex: 2),
                  _TitleBlock(
                    title: mediaItem?.title ?? 'Nothing playing',
                    author: mediaItem?.artist ?? '',
                  ),
                  const SizedBox(height: 28),
                  _Scrubber(accent: accent),
                  const SizedBox(height: 8),
                  _Transport(accent: accent),
                  const SizedBox(height: 12),
                  const _BottomRow(),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final String? album;
  const _TopBar({this.album});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white),
          iconSize: 30,
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        Expanded(
          child: Column(
            children: [
              const Text(
                'NOW PLAYING',
                style: TextStyle(
                  color: Colors.white60,
                  fontSize: 11,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (album != null)
                Text(
                  album!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
            ],
          ),
        ),
        const SizedBox(width: 48),
      ],
    );
  }
}

class _Cover extends StatelessWidget {
  final String? artUrl;
  final Color glow;
  const _Cover({required this.artUrl, required this.glow});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.maxWidth.clamp(0.0, 340.0);
        return Center(
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: glow.withValues(alpha: 0.45),
                  blurRadius: 60,
                  spreadRadius: 4,
                  offset: const Offset(0, 24),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: artUrl != null
                  ? Image.network(
                      artUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _coverFallback(),
                    )
                  : _coverFallback(),
            ),
          ),
        );
      },
    );
  }

  Widget _coverFallback() => Container(
        color: Colors.white10,
        child: const Center(
          child: Icon(Icons.menu_book, color: Colors.white38, size: 64),
        ),
      );
}

class _TitleBlock extends StatelessWidget {
  final String title;
  final String author;
  const _TitleBlock({required this.title, required this.author});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: double.infinity,
          child: Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AudiobookTheme.display(
              context,
              fontSize: 26,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              height: 1.1,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          author,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: Colors.white60, fontSize: 15),
        ),
      ],
    );
  }
}

class _Scrubber extends ConsumerWidget {
  final Color accent;
  const _Scrubber({required this.accent});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = ref.watch(audiobookPlayerProvider).player;
    final mediaItem = ref.watch(mediaItemProvider).value;
    final position = ref.watch(positionProvider).value ?? Duration.zero;
    return ImmersiveScrubber(
      duration: mediaItem?.duration ?? Duration.zero,
      position: position,
      accent: accent,
      onSeek: player.seek,
    );
  }
}

class _Transport extends ConsumerWidget {
  final Color accent;
  const _Transport({required this.accent});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = ref.watch(audiobookPlayerProvider).player;
    final playerState = ref.watch(playerStateProvider).value;
    final processing = playerState?.processingState;
    final playing = playerState?.playing ?? false;
    final busy = processing == ProcessingState.loading ||
        processing == ProcessingState.buffering;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _ghost(Icons.skip_previous,
            player.hasPrevious ? player.seekToPrevious : null),
        _ghost(Icons.replay_10,
            () => player.seek(player.position - const Duration(seconds: 10))),
        _PlayButton(accent: accent, playing: playing, busy: busy, player: player),
        _ghost(Icons.forward_30,
            () => player.seek(player.position + const Duration(seconds: 30))),
        _ghost(Icons.skip_next, player.hasNext ? player.seekToNext : null),
      ],
    );
  }

  Widget _ghost(IconData icon, VoidCallback? onPressed) => IconButton(
        icon: Icon(icon),
        iconSize: 30,
        color: Colors.white,
        disabledColor: Colors.white24,
        onPressed: onPressed,
      );
}

class _PlayButton extends StatelessWidget {
  final Color accent;
  final bool playing;
  final bool busy;
  final AudioPlayer player;
  const _PlayButton({
    required this.accent,
    required this.playing,
    required this.busy,
    required this.player,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 76,
      height: 76,
      decoration: BoxDecoration(
        color: accent,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.4),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: busy
          ? const Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(
                  strokeWidth: 3, color: Color(0xFF14110E)),
            )
          : IconButton(
              icon: Icon(playing ? Icons.pause : Icons.play_arrow),
              iconSize: 40,
              color: const Color(0xFF14110E),
              onPressed: playing ? player.pause : player.play,
            ),
    );
  }
}

class _BottomRow extends ConsumerWidget {
  const _BottomRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = ref.watch(audiobookPlayerProvider).player;
    final speed = ref.watch(speedProvider).value ?? 1.0;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        TextButton.icon(
          onPressed: () => _cycleSpeed(player, speed),
          icon: const Icon(Icons.speed, color: Colors.white70, size: 20),
          label: Text('${_label(speed)}×',
              style: const TextStyle(color: Colors.white70)),
        ),
        TextButton.icon(
          onPressed: () => _showChapters(context, ref),
          icon: const Icon(Icons.list, color: Colors.white70, size: 20),
          label: const Text('Chapters',
              style: TextStyle(color: Colors.white70)),
        ),
      ],
    );
  }

  String _label(double s) =>
      s == s.roundToDouble() ? s.toStringAsFixed(1) : s.toString();

  void _cycleSpeed(AudioPlayer player, double current) {
    const options = [0.75, 1.0, 1.25, 1.5, 2.0];
    final idx = options.indexWhere((o) => (o - current).abs() < 0.01);
    player.setSpeed(options[(idx + 1) % options.length]);
  }

  void _showChapters(BuildContext context, WidgetRef ref) {
    final controller = ref.read(audiobookPlayerProvider);
    final player = controller.player;
    final chapters = controller.currentChapters;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF161310),
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: chapters.length,
          itemBuilder: (context, index) {
            final isCurrent = player.currentIndex == index;
            final c = chapters[index];
            return ListTile(
              leading: Icon(
                isCurrent ? Icons.equalizer : Icons.play_arrow,
                color: isCurrent
                    ? Theme.of(context).colorScheme.primary
                    : Colors.white54,
              ),
              title: Text(
                c.title ?? c.name ?? 'Chapter ${index + 1}',
                style: TextStyle(
                  color: isCurrent ? Colors.white : Colors.white70,
                  fontWeight: isCurrent ? FontWeight.w600 : FontWeight.normal,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              onTap: () {
                player.seek(Duration.zero, index: index);
                player.play();
                Navigator.of(context).pop();
              },
            );
          },
        ),
      ),
    );
  }
}
