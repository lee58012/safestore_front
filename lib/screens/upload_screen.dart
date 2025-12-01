import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart';
import '../models/abnormal_log.dart';
import 'log_list_screen.dart';

class UploadScreen extends StatefulWidget {
  @override
  _UploadScreenState createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  File? _selectedVideo;
  VideoPlayerController? _thumbnailController;
  bool _isUploading = false;

  @override
  void dispose() {
    _thumbnailController?.dispose();
    super.dispose();
  }

  Future<void> _pickVideo() async {
    final pickedFile = await ImagePicker().pickVideo(source: ImageSource.gallery);
    if (pickedFile != null) {
      File videoFile = File(pickedFile.path);
      _thumbnailController?.dispose();
      _thumbnailController = VideoPlayerController.file(videoFile);
      try {
        await _thumbnailController!.initialize();
        await _thumbnailController!.setVolume(0.0);
        if (_thumbnailController!.value.duration > Duration(seconds: 1)) {
          await _thumbnailController!.seekTo(Duration(seconds: 1));
        }
        await _thumbnailController!.pause();
        setState(() {
          _selectedVideo = videoFile;
        });
      } catch (e) {
        print("비디오 로드 에러: $e");
      }
    }
  }

  Future<void> _uploadAndAnalyze() async {
    if (_selectedVideo == null) return;

    setState(() { _isUploading = true; });

    try {
      // [주의] Ngrok 주소 확인 필수!
      var uri = Uri.parse('https://becomingly-vowless-peggy.ngrok-free.dev/upload');

      var request = http.MultipartRequest('POST', uri);
      request.files.add(await http.MultipartFile.fromPath('file', _selectedVideo!.path));

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        var jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));
        List<dynamic> logsJson = jsonResponse['data'];

        List<AbnormalLog> analysisResults = logsJson.map((json) => AbnormalLog(
          timestamp: json['timestamp'] ?? '',
          videoUrl: json['videoUrl'] ?? '',
          type: json['type'] ?? '알 수 없음',
        )).toList();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('분석 완료!')));

          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text("분석 결과"),
              content: Container(
                width: double.maxFinite,
                height: 300,
                child: analysisResults.isEmpty
                    ? Center(child: Text("이상행동이 발견되지 않았습니다."))
                    : ListView.builder(
                  itemCount: analysisResults.length,
                  itemBuilder: (context, index) {
                    var log = analysisResults[index];
                    // 아이콘 및 색상 설정
                    bool isDanger = log.type.contains("위험");
                    Color iconColor = isDanger ? Colors.red : Colors.orange;

                    return ListTile(
                      leading: Icon(Icons.warning, color: iconColor),
                      title: Text("이상행동 감지"),
                      subtitle: Text("${log.type}\n시간: ${log.timestamp}"),
                      isThreeLine: true,
                    );
                  },
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: Text("확인"))
              ],
            ),
          );
        }
      } else {
        print("서버 에러: ${response.body}");
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('분석 실패: 서버 오류')));
      }
    } catch (e) {
      print("에러: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('에러 발생: $e')));
    } finally {
      setState(() { _isUploading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('영상 업로드 분석'), elevation: 0, backgroundColor: Colors.white, foregroundColor: Colors.black),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Center(
              child: Container(
                height: 250,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: _selectedVideo == null
                    ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.cloud_upload, size: 80, color: Colors.grey),
                    SizedBox(height: 10),
                    Text("분석할 영상을 선택해주세요", style: TextStyle(color: Colors.grey)),
                  ],
                )
                    : _thumbnailController != null && _thumbnailController!.value.isInitialized
                    ? ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: AspectRatio(
                    aspectRatio: _thumbnailController!.value.aspectRatio,
                    child: VideoPlayer(_thumbnailController!),
                  ),
                )
                    : Center(child: CircularProgressIndicator()),
              ),
            ),
            SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: Icon(Icons.video_library),
                label: Text(_selectedVideo == null ? '갤러리에서 선택' : '다른 영상 선택'),
                onPressed: _pickVideo,
                style: OutlinedButton.styleFrom(padding: EdgeInsets.all(15)),
              ),
            ),
            SizedBox(height: 15),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (_selectedVideo != null && !_isUploading) ? _uploadAndAnalyze : null,
                child: _isUploading
                    ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                    SizedBox(width: 15),
                    Text('영상 분석 중...'),
                  ],
                )
                    : Text('업로드 및 분석 시작', style: TextStyle(fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.all(15),
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}