import 'package:audiobooks/pages/book_details.dart';
import 'package:audiobooks/providers/providers.dart';
import 'package:audiobooks/resources/models/models.dart';
import 'package:audiobooks/widgets/book_cards.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final _controller = TextEditingController();
  final _focus = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _submit(String value) {
    FocusScope.of(context).unfocus();
    ref.read(searchProvider.notifier).search(value);
  }

  void _openDetail(Book book) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => DetailPage(book)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final results = ref.watch(searchProvider);
    final query = ref.read(searchProvider.notifier).query;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: SearchBar(
                controller: _controller,
                focusNode: _focus,
                hintText: 'Search titles…',
                leading: const Icon(Icons.search),
                trailing: [
                  if (_controller.text.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        _controller.clear();
                        ref.read(searchProvider.notifier).clear();
                        setState(() {});
                      },
                    ),
                ],
                onChanged: (_) => setState(() {}),
                onSubmitted: _submit,
              ),
            ),
            Expanded(
              child: results.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (_, __) => _message(theme, Icons.error_outline,
                    'Search failed. Try again.'),
                data: (books) {
                  if (query.isEmpty) {
                    return _message(theme, Icons.search,
                        'Find audiobooks from the LibriVox catalogue.');
                  }
                  if (books.isEmpty) {
                    return _message(theme, Icons.sentiment_dissatisfied,
                        'No results for "$query".');
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: books.length,
                    itemBuilder: (context, i) => BookListRow(
                      book: books[i],
                      onTap: () => _openDetail(books[i]),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _message(ThemeData theme, IconData icon, String text) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 56, color: theme.colorScheme.outline),
            const SizedBox(height: 16),
            Text(text,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}
