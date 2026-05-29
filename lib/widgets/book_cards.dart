import 'package:audiobooks/providers/providers.dart';
import 'package:audiobooks/resources/models/models.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:audiobooks/icons/phosphor_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    return ClipRRect(
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
          child: Icon(PhosphorIcons.bookOpen,
              color: theme.colorScheme.primary, size: size * 0.3),
        ),
      ),
    );
  }
}

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
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: width,
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
                      child: Icon(PhosphorIcons.play,
                          size: 20, color: theme.colorScheme.onPrimary),
                    ),
                  ),
                if (showFavorite)
                  Positioned(
                    right: 4,
                    top: 4,
                    child: _FavoriteHeart(book: book),
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
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
          ],
        ),
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
    return Material(
      color: Colors.black45,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () {
          // Cache the book so Library can resolve it later, then toggle.
          ref.read(repositoryProvider).cacheBook(book);
          ref.read(favoritesProvider.notifier).toggle(book.id);
        },
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(
            isFav ? PhosphorIcons.heartFill : PhosphorIcons.heart,
            size: 20,
            color: isFav ? theme.colorScheme.primary : Colors.white,
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
    final linkAuthor = onAuthorTap != null &&
        subtitleOverride == null &&
        (book.author ?? '').isNotEmpty;
    final subtitleText =
        subtitleOverride ?? book.author ?? 'Unknown author';
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
                    GestureDetector(
                      onTap: onAuthorTap,
                      child: Text(
                        subtitleText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  else
                    Text(
                      subtitleText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                ],
              ),
            ),
            trailing ?? Icon(PhosphorIcons.caretRight),
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
            child: Text(title, style: Theme.of(context).textTheme.headlineSmall),
          ),
          if (action != null) action!,
        ],
      ),
    );
  }
}
