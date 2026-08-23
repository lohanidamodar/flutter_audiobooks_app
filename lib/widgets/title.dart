import 'package:material_ui/material_ui.dart';

class BookTitle extends StatelessWidget {
  final String title;
  final TextStyle? style;

  const BookTitle(this.title, {super.key, this.style});

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).textTheme.titleLarge ??
        const TextStyle(fontSize: 18, fontWeight: FontWeight.w600);
    return Text(
      title,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: base.merge(style),
    );
  }
}
