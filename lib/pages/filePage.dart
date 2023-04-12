import 'dart:io';

import 'package:cli_calendar_app/model/todo.dart';
import 'package:cli_calendar_app/services/parser/regex.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class FilePage extends StatelessWidget {
  FilePage({super.key, required this.fileList, required this.initialIndex});

  final List<TodoFile> fileList;
  final int initialIndex;
  final ValueNotifier<bool> hideAppBarNotifier = ValueNotifier(false);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Files')),
      body: _body(),
    );
  }

  ///Widgets
  Widget _body() {
    return PageView.builder(
      physics: const PageScrollPhysics(),
      itemCount: fileList.length,
      controller: PageController(initialPage: initialIndex),
      itemBuilder: (context, index) {
        return _decideFileType(context, fileList[index]);
      },
    );
  }

  Widget _decideFileType(BuildContext context, TodoFile file) {
    switch (file.getFileType()) {
      ///picture
      case FileType.picture:
        return Image.file(
          width: MediaQuery.of(context).size.width,
          file.content,
          fit: BoxFit.cover,
        );

      ///video & audio
      case FileType.videoOrAudio:
        return FullVideoPlayer(file: file.content);

      ///other
      case FileType.other:
        return OtherFile(path: file.content.path);
    }
  }
}

//
//
//
//
///-----VideoPlayer-----
class FullVideoPlayer extends StatefulWidget {
  const FullVideoPlayer({super.key, required this.file});

  final File file;

  @override
  State<FullVideoPlayer> createState() => _FullVideoPlayerState();
}

class _FullVideoPlayerState extends State<FullVideoPlayer> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(widget.file)
      ..addListener(() => setState(() {}))
      ..setLooping(true)
      ..initialize().then((_) => _controller.play());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    //scaffold so that aspectRatio is possible
    return Scaffold(
      body: Center(
        child: _controller.value.isInitialized
            ? _videoPlayerWithProgressIndicator()
            : _loadingWidget(),
      ),
    );
  }

  Widget _videoPlayerWithProgressIndicator() {
    return Stack(
      alignment: Alignment.center,
      children: [
        _videoPlayer(),
        _playButton(),
        Positioned.fill(child: _videoProgressIndicator()),
      ],
    );
  }

  Widget _videoPlayer() {
    return GestureDetector(
      onTap: pauseResume,
      child: AspectRatio(
        aspectRatio: _controller.value.aspectRatio,
        child: VideoPlayer(_controller),
      ),
    );
  }

  Widget _playButton() {
    if (!isPlaying) {
      return GestureDetector(
          onTap: pauseResume,
          child: const Icon(
            CupertinoIcons.play_circle_fill,
            size: 50,
            color: CupertinoColors.secondaryLabel,
          ));
    } else {
      return const SizedBox.shrink();
    }
  }

  Widget _videoProgressIndicator() {
    return Stack(
      children: [
        Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: VideoProgressIndicator(_controller, allowScrubbing: true)),
      ],
    );
  }

  Widget _loadingWidget() {
    return const CupertinoActivityIndicator();
  }

  ///functions
  bool isPlaying = true;

  void pauseResume() {
    if (isPlaying) {
      isPlaying = false;
      _controller.pause();
    } else {
      isPlaying = true;
      _controller.play();
    }
  }
}

//
//
//
//
///-----OtherFile-----
class OtherFile extends StatelessWidget {
  const OtherFile({super.key, required this.path});

  final String path;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      //width: MediaQuery.of(context).size.width,
      color: CupertinoColors.lightBackgroundGray,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(CupertinoIcons.doc),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(getFilenameFromPath(path)),
          ),
        ],
      ),
    );
  }

  String getFilenameFromPath(String filePath) {
    assert(filePath.isNotEmpty);
    //get everything that is not a '/' from the end of the string
    //example: test/assets/test_image.jpg -> test_image.jpg
    return getFirstRegexMatch(filePath, r'([^/]+)$');
  }
}
