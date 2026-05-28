import 'package:audiobooks/pages/book_details.dart';
import 'package:audiobooks/resources/models/models.dart';
import 'package:audiobooks/resources/notifiers/audio_books_notifier.dart';
import 'package:audiobooks/widgets/book_grid_item.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
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
      context.read<AudioBooksNotifier>().loadMoreBooks();
    }
  }

  Future<void> _openDetail(Book book) {
    return Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => DetailPage(book)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<AudioBooksNotifier>(
        builder: (context, notifier, _) {
          final showFullScreen = notifier.books.isEmpty &&
              notifier.topBooks.isEmpty &&
              notifier.status != LoadStatus.ready;
          if (showFullScreen) {
            return CustomScrollView(
              slivers: [
                _appBar(),
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _FullScreenState(notifier: notifier),
                ),
              ],
            );
          }
          return RefreshIndicator(
            onRefresh: notifier.refresh,
            child: CustomScrollView(
              controller: _scrollController,
              slivers: [
                _appBar(),
                if (notifier.topBooks.isNotEmpty) ...[
                  _SectionTitle(title: 'Most downloaded'),
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
                          book: notifier.topBooks[index],
                          onTap: () => _openDetail(notifier.topBooks[index]),
                        ),
                        childCount: notifier.topBooks.length,
                      ),
                    ),
                  ),
                ],
                _SectionTitle(title: 'Recent books'),
                SliverList.builder(
                  itemCount: notifier.books.length + 1,
                  itemBuilder: (context, index) {
                    if (index >= notifier.books.length) {
                      return _ListFooter(notifier: notifier);
                    }
                    return _BookListTile(
                      book: notifier.books[index],
                      onTap: () => _openDetail(notifier.books[index]),
                    );
                  },
                ),
              ],
            ),
          );
        },
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
      title: Text(
        book.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: book.author != null
          ? Text(book.author!,
              maxLines: 1, overflow: TextOverflow.ellipsis)
          : null,
      trailing: const Icon(Icons.chevron_right),
    );
  }
}

class _ListFooter extends StatelessWidget {
  final AudioBooksNotifier notifier;
  const _ListFooter({required this.notifier});

  @override
  Widget build(BuildContext context) {
    if (notifier.hasReachedMax) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Text(
            'No more books',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      );
    }
    if (notifier.status == LoadStatus.error) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: TextButton.icon(
            onPressed: notifier.loadMoreBooks,
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
  final AudioBooksNotifier notifier;
  const _FullScreenState({required this.notifier});

  @override
  Widget build(BuildContext context) {
    if (notifier.status == LoadStatus.loading ||
        notifier.status == LoadStatus.initial) {
      return const Center(child: CircularProgressIndicator());
    }
    if (notifier.status == LoadStatus.error) {
      final theme = Theme.of(context);
      return Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off,
                size: 64, color: theme.colorScheme.outline),
            const SizedBox(height: 16),
            Text(
              'Could not load books',
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Check your internet connection and try again.',
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: notifier.refresh,
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
          Text(
            'No books yet',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: notifier.refresh,
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh'),
          ),
        ],
      ),
    );
  }
}
