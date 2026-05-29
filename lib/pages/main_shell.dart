import 'package:audiobooks/pages/home_page.dart';
import 'package:audiobooks/pages/library_page.dart';
import 'package:audiobooks/pages/now_playing.dart';
import 'package:audiobooks/widgets/mini_player.dart';
import 'package:flutter/material.dart';
import 'package:audiobooks/icons/phosphor_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  int _index = 0;

  static const _pages = [HomePage(), LibraryPage()];

  void _openNowPlaying() {
    Navigator.of(context).push(NowPlayingPage.route());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          MiniPlayer(onTap: (_) => _openNowPlaying()),
          NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: (i) => setState(() => _index = i),
            destinations: [
              NavigationDestination(
                icon: Icon(PhosphorIcons.house),
                selectedIcon: Icon(PhosphorIcons.houseFill),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Icon(PhosphorIcons.books),
                selectedIcon: Icon(PhosphorIcons.booksFill),
                label: 'Library',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
