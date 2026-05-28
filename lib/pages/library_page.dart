import 'package:audiobooks/pages/book_details.dart';
import 'package:audiobooks/providers/providers.dart';
import 'package:audiobooks/resources/models/models.dart';
import 'package:audiobooks/widgets/book_cards.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LibraryPage extends ConsumerWidget {
  const LibraryPage({super.key});

  void _openDetail(BuildContext context, Book book) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => DetailPage(book)),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final library = ref.watch(libraryProvider);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => ref.read(libraryProvider.notifier).refresh(),
        child: CustomScrollView(
          slivers: [
            SliverAppBar.large(
              title: const Text('Library'),
              floating: true,
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () =>
                      ref.read(libraryProvider.notifier).refresh(),
                ),
              ],
            ),
            ...library.when(
              loading: () => [
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: CircularProgressIndicator()),
                ),
              ],
              error: (_, __) => [
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _empty(context, 'Could not load your library'),
                ),
              ],
              data: (data) {
                if (data.isEmpty) {
                  return [
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _empty(context,
                          'Books you play or download will appear here.'),
                    ),
                  ];
                }
                return [
                  if (data.continueListening.isNotEmpty)
                    _rail(context, 'Continue listening', data.continueListening),
                  if (data.downloaded.isNotEmpty) ...[
                    const SliverToBoxAdapter(
                      child: SectionHeader(title: 'Downloaded'),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      sliver: SliverList.builder(
                        itemCount: data.downloaded.length,
                        itemBuilder: (context, i) => BookListRow(
                          book: data.downloaded[i],
                          subtitleOverride: data.downloaded[i].author,
                          trailing: const Icon(Icons.download_done, size: 20),
                          onTap: () => _openDetail(context, data.downloaded[i]),
                        ),
                      ),
                    ),
                  ],
                  const SliverToBoxAdapter(child: SizedBox(height: 16)),
                ];
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _rail(BuildContext context, String title, List<Book> books) {
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
              itemBuilder: (context, i) => BookPosterCard(
                book: books[i],
                width: 140,
                onTap: () => _openDetail(context, books[i]),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _empty(BuildContext context, String message) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.library_books_outlined,
              size: 64, color: theme.colorScheme.outline),
          const SizedBox(height: 16),
          Text(message,
              textAlign: TextAlign.center, style: theme.textTheme.titleMedium),
        ],
      ),
    );
  }
}
