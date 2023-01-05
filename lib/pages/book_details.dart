import 'package:audio_service/audio_service.dart';
import 'package:audiobooks/main.dart';
import 'package:audiobooks/resources/models/models.dart';
import 'package:audiobooks/resources/repository.dart';
import 'package:audiobooks/widgets/player_service.dart';
import 'package:audiobooks/widgets/title.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'dart:async';
// import 'package:flutter_downloader/flutter_downloader.dart';


class DetailPage extends StatefulWidget {
  final Book book;
  const DetailPage(this.book, {Key? key}) : super(key: key);

  @override
  DetailPageState createState() {
    return DetailPageState();
  }
}

class DetailPageState extends State<DetailPage> {
  // var taskId;
  String? url;
  String? title;
  late bool toplay;
  late StreamSubscription<PlaybackState> playbackStateListner;

  /* _downloadBook() async{
    var path = await getApplicationDocumentsDirectory();
    taskId = await FlutterDownloader.enqueue(
      url: widget.book.id,
      savedDir: path.path,
      showNotification: true, // show download progress in status bar (for Android)
      openFileFromNotification: true, // click on notification to open downloaded file (for Android)
    );
    await FlutterDownloader.loadTasks();
  } */

  @override
  void initState() {
    super.initState();
    toplay = false;
    playbackStateListner = audioHandler.playbackState.listen((state) {
      if (state.processingState == AudioProcessingState.idle) {
        if (toplay) {
          // start();
          if (mounted) toplay = false;
        }
      }
    });
  }

  @override
  void dispose() {
    playbackStateListner.cancel();
    super.dispose();
  }

  Future<List<AudioFile>> _getRssFeeds() {
    return Repository().fetchAudioFiles(widget.book.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(widget.book.title),
        ),
        body: Stack(
          children: <Widget>[
            ListView(
              padding:
                  EdgeInsets.fromLTRB(20.0, 20.0, 20.0, url != null ? 70 : 20),
              children: <Widget>[
                SizedBox(
                  height: 100,
                  child: Row(
                    children: <Widget>[
                      Hero(
                        tag: "${widget.book.id}_image",
                        child: CachedNetworkImage(
                            imageUrl: widget.book.image, fit: BoxFit.contain),
                      ),
                      const SizedBox(width: 20.0),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            BookTitle(widget.book.title),
                            Text(
                              "${widget.book.author}",
                              style: Theme.of(context)
                                  .textTheme
                                  .subtitle1!
                                  .copyWith(),
                            ),
                            const SizedBox(
                              height: 5.0,
                            ),
                            Text(
                              "Total time: ${widget.book.totalTime}",
                              style: Theme.of(context).textTheme.subtitle1,
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
                const SizedBox(
                  height: 20,
                ),
                FutureBuilder(
                  future: _getRssFeeds(),
                  builder: (BuildContext context,
                      AsyncSnapshot<List<AudioFile>> snapshot) {
                    if (snapshot.hasData) {
                      final audios = snapshot.data!;
                      return Column(
                        children: audios
                            .map((item) => ListTile(
                                  title: Text(item.title!),
                                  leading: const Icon(Icons.play_circle_filled),
                                  onTap: () async {
                                    // // if(url == item.url) AudioService.play();
                                    // SharedPreferences prefs =
                                    //     await SharedPreferences.getInstance();
                                    // await prefs.setString(
                                    //     "play_url", item.url);
                                    // await prefs.setString(
                                    //     "book_id", item.bookId);
                                    // await prefs.setInt(
                                    //     "track", snapshot.data.indexOf(item));
                                    // setState(() {
                                    //   toplay = true;
                                    // });
                                    // await audioHandler.prepare();
                                    // audioHandler.play();
                                    // AudioService.stop();
                                    // start();
                                    final mediaItems = audios
                                        .map((chapter) => MediaItem(
                                              id: chapter.url ?? '',
                                              album: widget.book.title,
                                              title: chapter.name ?? '',
                                              extras: {
                                                'url': chapter.url,
                                                'bookId': chapter.bookId
                                              },
                                            ))
                                        .toList();

                                    // print('tap index $index');
                                    // print('tap index media ${mediaItems.length}');
                                    // print('tap index media ID=== ${mediaItems[index].title}');

                                    await audioHandler
                                        .updateQueue(mediaItems);
                                    await audioHandler.skipToQueueItem(
                                        audios.indexOf(item));
                                    audioHandler.play();
                                    setState(() {
                                      url = item.url;
                                      title = item.title;
                                    });
                                  },
                                ))
                            .toList(),
                      );
                    } else {
                      return const CircularProgressIndicator();
                    }
                  },
                )
              ],
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                color: Colors.grey.shade100,
                child: const PlayerService(),
              ),
            ),
          ],
        ));
  }
}
