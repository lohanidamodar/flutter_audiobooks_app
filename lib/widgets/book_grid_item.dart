import 'package:audiobooks/resources/models/models.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class BookGridItem extends StatelessWidget {
  final Book book;
  final void Function() onTap;

  const BookGridItem({Key key, @required this.book, this.onTap}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: <Widget>[
          Hero(
            tag: "${book.id}_image",
            child: Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: CachedNetworkImageProvider(book.image),
                  fit: BoxFit.cover,
                ),
                borderRadius: BorderRadius.circular(10.0)
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10.0),
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  Colors.black
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter
              )
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Spacer(),
                Text(book.title, style: TextStyle(
                  color: Colors.white,
                  fontSize: 16.0,
                  fontWeight: FontWeight.bold
                ),),
                Text(book.author, style: TextStyle(
                  color: Colors.white,
                  fontSize: 12
                ),)
              ],
            ),
          ),
        ],
      ),
    );
  }
}