import 'package:audiobooks/icons/phosphor_icons.dart';
import 'package:audiobooks/providers/providers.dart';
import 'package:audiobooks/resources/models/models.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// Rounded square cover with a graceful fallback.
class BookCover extends StatelessWidget {
  final Book book;
  final double size;
  final double radius;
  const BookCover({
    super.key,
    required this.book,
    this.size = 120,
    this.radius = 14,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Decorative: the title and author sit next to every cover.
    return ExcludeSemantics(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: CachedNetworkImage(
          imageUrl: book.image,
          width: size,
          height: size,
          fit: BoxFit.cover,
          placeholder: (_, __) => Container(
            width: size,
            height: size,
            color: theme.colorScheme.surfaceContainerHighest,
          ),
          errorWidget: (_, __, ___) => Container(
            width: size,
            height: size,
            color: theme.colorScheme.surfaceContainerHighest,
            child: Icon(
              PhosphorIcons.bookOpen,
              color: theme.colorScheme.primary,
              size: size * 0.3,
            ),
          ),
        ),
      ),
    );
  }
}

/// Height of a horizontal rail of [BookPosterCard]s. Grows with the text scale
/// so the title and author lines never overflow at large font sizes.
double posterRailHeight(BuildContext context, {double width = 140}) =>
    width + 8 + MediaQuery.textScalerOf(context).scale(70);

/// Poster-style card for rails and grids: cover + title + author.
class BookPosterCard extends StatelessWidget {
  final Book book;
  final double width;
  final VoidCallback onTap;
  final bool showPlayBadge;
  final bool showFavorite;
  const BookPosterCard({
    super.key,
    required this.book,
    required this.onTap,
    this.width = 140,
    this.showPlayBadge = false,
    this.showFavorite = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = book.author == null
        ? book.title
        : '${book.title}, ${book.author}';
    return SizedBox(
      width: width,
      child: Stack(
        children: [
          Semantics(
            button: true,
            label: label,
            excludeSemantics: true,
            onTap: onTap,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: onTap,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      BookCover(book: book, size: width, radius: 16),
                      if (showPlayBadge)
                        Positioned(
                          right: 8,
                          bottom: 8,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.3),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                            child: Icon(
                              PhosphorIcons.play,
                              size: 20,
                              color: theme.colorScheme.onPrimary,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    book.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall,
                  ),
                  if (book.author != null)
                    Text(
                      book.author!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (showFavorite)
            Positioned(right: 0, top: 0, child: _FavoriteHeart(book: book)),
        ],
      ),
    );
  }
}

/// Small heart overlay that toggles a book's favourite state in place.
class _FavoriteHeart extends ConsumerWidget {
  final Book book;
  const _FavoriteHeart({required this.book});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isFav = ref.watch(favoritesProvider).contains(book.id);
    // 48dp hit area around a 32dp visual circle.
    return Tooltip(
      message: isFav ? 'Remove from favourites' : 'Add to favourites',
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () {
          // Cache the book so Library can resolve it later, then toggle.
          ref.read(repositoryProvider).cacheBook(book);
          ref.read(favoritesProvider.notifier).toggle(book.id);
        },
        child: SizedBox(
          width: 48,
          height: 48,
          child: Center(
            child: DecoratedBox(
              decoration: const BoxDecoration(
                color: Colors.black45,
                shape: BoxShape.circle,
              ),
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Icon(
                  isFav ? PhosphorIcons.heartFill : PhosphorIcons.heart,
                  size: 20,
                  color: isFav ? theme.colorScheme.primary : Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Horizontal-rail row: cover + texts, used in lists.
class BookListRow extends StatelessWidget {
  final Book book;
  final VoidCallback onTap;
  final Widget? trailing;
  final String? subtitleOverride;

  /// When set and the book has an author, the author line becomes a tappable
  /// link (e.g. to that author's page).
  final VoidCallback? onAuthorTap;

  const BookListRow({
    super.key,
    required this.book,
    required this.onTap,
    this.trailing,
    this.subtitleOverride,
    this.onAuthorTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final linkAuthor =
        onAuthorTap != null &&
        subtitleOverride == null &&
        (book.author ?? '').isNotEmpty;
    final subtitleText = subtitleOverride ?? book.author ?? 'Unknown author';
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          children: [
            BookCover(book: book, size: 60, radius: 12),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 2),
                  if (linkAuthor)
                    Semantics(
                      button: true,
                      label: 'More by $subtitleText',
                      excludeSemantics: true,
                      onTap: onAuthorTap,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: onAuthorTap,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            minHeight: 48,
                            minWidth: 48,
                          ),
                          child: Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: Text(
                              subtitleText,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    )
                  else
                    Text(
                      subtitleText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
            trailing ?? ExcludeSemantics(child: Icon(PhosphorIcons.caretRight)),
          ],
        ),
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String title;
  final Widget? action;
  const SectionHeader({super.key, required this.title, this.action});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 12, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
          if (action != null) action!,
        ],
      ),
    );
  }
}
