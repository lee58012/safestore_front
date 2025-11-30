import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

class VideoPlayerScreen extends StatefulWidget {
  final String videoUrl;
  final String? startTime;

  const VideoPlayerScreen({
    Key? key,
    required this.videoUrl,
    this.startTime
  }) : super(key: key);

  @override
  _VideoPlayerScreenState createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late VideoPlayerController _videoController;
  ChewieController? _chewieController;

  @override
  void initState() {
    super.initState();
    initializePlayer();
  }

  // "MM:SS" 문자열을 Duration으로 변환하는 함수
  Duration parseDuration(String timeString) {
    try {
      List<String> parts = timeString.split(':');
      int minutes = int.parse(parts[0]);
      int seconds = int.parse(parts[1]);
      return Duration(minutes: minutes, seconds: seconds);
    } catch (e) {
      return Duration.zero;
    }
  }

  Future<void> initializePlayer() async {
    _videoController = VideoPlayerController.network(widget.videoUrl);
    await _videoController.initialize();

    // [추가] 시작 시간이 있으면 해당 위치로 이동
    if (widget.startTime != null && widget.startTime!.isNotEmpty) {
      Duration startDuration = parseDuration(widget.startTime!);
      // 사건 발생 3초 전부터 보여주면 더 좋음 (음수가 안 되게 처리)
      Duration seekDuration = startDuration - Duration(seconds: 3);
      if (seekDuration.isNegative) seekDuration = Duration.zero;

      await _videoController.seekTo(seekDuration);
    }

    setState(() {
      _chewieController = ChewieController(
        videoPlayerController: _videoController,
        autoPlay: true,
        looping: true,
        aspectRatio: _videoController.value.aspectRatio,
        errorBuilder: (context, errorMessage) {
          return Center(child: Text('영상 로드 실패\n$errorMessage', style: TextStyle(color: Colors.white)));
        },
      );
    });
  }

  @override
  void dispose() {
    _videoController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(widget.startTime != null ? "이상행동 시점: ${widget.startTime}" : "영상 재생"),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: _chewieController != null && _chewieController!.videoPlayerController.value.isInitialized
            ? Chewie(controller: _chewieController!)
            : CircularProgressIndicator(),
      ),
    );
  }
}