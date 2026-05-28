import 'package:audiobooks/pages/book_details.dart';
import 'package:audiobooks/pages/settings_page.dart';
import 'package:audiobooks/providers/providers.dart';
import 'package:audiobooks/resources/models/models.dart';
import 'package:audiobooks/widgets/book_cards.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final _scrollController = ScrollController();
  static const _scrollThreshold = 320.0;

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
    final max = _scrollController.position.maxScrollExtent;
    if (max - _scrollController.position.pixels <= _scrollThreshold) {
      ref.read(recentBooksProvider.notifier).loadMore();
    }
  }

  void _openDetail(Book book) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => DetailPage(book)),
    );
  }

  Future<void> _refresh() async {
    ref.invalidate(topBooksProvider);
    ref.invalidate(recentBooksProvider);
    ref.invalidate(libraryProvider);
    try {
      await ref.read(recentBooksProvider.future);
    } catch (_) {
      // surfaced via the provider's error state; don't reject the indicator
    }
  }

  @override
  Widget build(BuildContext context) {
    final recent = ref.watch(recentBooksProvider);
    final top = ref.watch(topBooksProvider);
    final library = ref.watch(libraryProvider).value;

    final recentBooks = recent.value?.books ?? const <Book>[];
    final topBooks = top.value ?? const <Book>[];
    final continueBooks = library?.continueListening ?? const <Book>[];
    final hasAnyData = recentBooks.isNotEmpty || topBooks.isNotEmpty;

    return Scaffold(
      body: !hasAnyData
          ? CustomScrollView(slivers: [
              _appBar(),
              SliverFillRemaining(
                hasScrollBody: false,
                child: _FullScreenState(
                  isLoading: recent.isLoading || top.isLoading,
                  hasError: recent.hasError && top.hasError,
                  onRetry: _refresh,
                ),
              ),
            ])
          : RefreshIndicator(
              onRefresh: _refresh,
              child: CustomScrollView(
                controller: _scrollController,
                slivers: [
                  _appBar(),
                  if (continueBooks.isNotEmpty)
                    _rail('Continue listening', continueBooks,
                        showPlayBadge: true),
                  if (topBooks.isNotEmpty) _rail('Most downloaded', topBooks),
                  const SliverToBoxAdapter(
                    child: SectionHeader(title: 'Recently added'),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverList.builder(
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
                        return BookListRow(
                          book: recentBooks[index],
                          onTap: () => _openDetail(recentBooks[index]),
                        );
                      },
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 16)),
                ],
              ),
            ),
    );
  }

  Widget _appBar() => SliverAppBar.large(
        title: const Text('Audiobooks'),
        floating: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SettingsPage()),
            ),
          ),
        ],
      );

  Widget _rail(String title, List<Book> books, {bool showPlayBadge = false}) {
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(title: title),
          SizedBox(
            height: 218,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: books.length,
              separatorBuilder: (_, __) => const SizedBox(width: 14),
              itemBuilder: (context, index) => BookPosterCard(
                book: books[index],
                width: 140,
                showPlayBadge: showPlayBadge,
                onTap: () => _openDetail(books[index]),
              ),
            ),
          ),
        ],
      ),
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
          child: Text('That\'s everything',
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
    if (isLoading) return const Center(child: CircularProgressIndicator());
    final theme = Theme.of(context);
    final icon = hasError ? Icons.cloud_off : Icons.menu_book_outlined;
    final title = hasError ? 'Could not load books' : 'No books yet';
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: theme.colorScheme.outline),
          const SizedBox(height: 16),
          Text(title, style: theme.textTheme.titleMedium),
          if (hasError) ...[
            const SizedBox(height: 8),
            Text('Check your connection and try again.',
                style: theme.textTheme.bodySmall, textAlign: TextAlign.center),
          ],
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
}
