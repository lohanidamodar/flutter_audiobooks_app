import 'package:audiobooks/pages/book_details.dart';
import 'package:audiobooks/providers/providers.dart';
import 'package:audiobooks/resources/models/models.dart';
import 'package:audiobooks/widgets/book_grid_item.dart';
import 'package:audiobooks/widgets/mini_player.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final _scrollController = ScrollController();
  static const _scrollThreshold = 240.0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    if (maxScroll - currentScroll <= _scrollThreshold) {
      ref.read(recentBooksProvider.notifier).loadMore();
    }
  }

  Future<void> _openDetail(Book book) {
    return Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => DetailPage(book)),
    );
  }

  Future<void> _refresh() async {
    ref.invalidate(topBooksProvider);
    ref.invalidate(recentBooksProvider);
    await ref.read(recentBooksProvider.future);
  }

  @override
  Widget build(BuildContext context) {
    final recent = ref.watch(recentBooksProvider);
    final top = ref.watch(topBooksProvider);

    final recentBooks = recent.value?.books ?? const <Book>[];
    final topBooks = top.value ?? const <Book>[];
    final hasAnyData = recentBooks.isNotEmpty || topBooks.isNotEmpty;

    return Scaffold(
      body: Stack(
        children: [
          if (!hasAnyData)
            CustomScrollView(
              slivers: [
                _appBar(),
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _FullScreenState(
                    isLoading: recent.isLoading || top.isLoading,
                    hasError: recent.hasError && top.hasError,
                    onRetry: _refresh,
                  ),
                ),
              ],
            )
          else
            RefreshIndicator(
              onRefresh: _refresh,
              child: CustomScrollView(
                controller: _scrollController,
                slivers: [
                  _appBar(),
                  if (topBooks.isNotEmpty) ...[
                    const _SectionTitle(title: 'Most downloaded'),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      sliver: SliverGrid(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.78,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => BookGridItem(
                            book: topBooks[index],
                            onTap: () => _openDetail(topBooks[index]),
                          ),
                          childCount: topBooks.length,
                        ),
                      ),
                    ),
                  ],
                  const _SectionTitle(title: 'Recent books'),
                  SliverList.builder(
                    itemCount: recentBooks.length + 1,
                    itemBuilder: (context, index) {
                      if (index >= recentBooks.length) {
                        return _ListFooter(
                          recent: recent.value,
                          onRetry: () => ref
                              .read(recentBooksProvider.notifier)
                              .loadMore(),
                        );
                      }
                      return _BookListTile(
                        book: recentBooks[index],
                        onTap: () => _openDetail(recentBooks[index]),
                      );
                    },
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 88)),
                ],
              ),
            ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: MiniPlayer(onTap: _openDetail),
          ),
        ],
      ),
    );
  }

  Widget _appBar() => const SliverAppBar(
        title: Text('Audiobooks'),
        floating: true,
        snap: true,
      );
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      sliver: SliverToBoxAdapter(
        child: Text(title, style: Theme.of(context).textTheme.titleLarge),
      ),
    );
  }
}

class _BookListTile extends StatelessWidget {
  final Book book;
  final VoidCallback onTap;
  const _BookListTile({required this.book, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundImage: CachedNetworkImageProvider(book.image),
      ),
      title: Text(book.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: book.author != null
          ? Text(book.author!, maxLines: 1, overflow: TextOverflow.ellipsis)
          : null,
      trailing: const Icon(Icons.chevron_right),
    );
  }
}

class _ListFooter extends StatelessWidget {
  final RecentBooks? recent;
  final VoidCallback onRetry;
  const _ListFooter({required this.recent, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    if (recent?.hasReachedMax ?? false) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Text('No more books',
              style: Theme.of(context).textTheme.bodySmall),
        ),
      );
    }
    if (recent?.loadMoreError != null) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Failed to load — retry'),
          ),
        ),
      );
    }
    return const Padding(
      padding: EdgeInsets.all(24),
      child: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}

class _FullScreenState extends StatelessWidget {
  final bool isLoading;
  final bool hasError;
  final Future<void> Function() onRetry;
  const _FullScreenState({
    required this.isLoading,
    required this.hasError,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    final theme = Theme.of(context);
    if (hasError) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off, size: 64, color: theme.colorScheme.outline),
            const SizedBox(height: 16),
            Text('Could not load books',
                style: theme.textTheme.titleMedium,
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text('Check your internet connection and try again.',
                style: theme.textTheme.bodySmall, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.menu_book_outlined, size: 64),
          const SizedBox(height: 16),
          Text('No books yet', style: theme.textTheme.titleMedium),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh'),
          ),
        ],
      ),
    );
  }
}
