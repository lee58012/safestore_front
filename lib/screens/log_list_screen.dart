import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/abnormal_log.dart';
import 'video_player_screen.dart';

class LogListScreen extends StatefulWidget {
  final bool showAll;
  const LogListScreen({Key? key, this.showAll = true}) : super(key: key);

  @override
  _LogListScreenState createState() => _LogListScreenState();
}

class _LogListScreenState extends State<LogListScreen> {
  List<AbnormalLog> _logs = [];
  bool _isLoading = true;

  // [주의] Ngrok 주소가 바뀌면 여기를 꼭 수정하세요!
  final String baseUrl = "https://becomingly-vowless-peggy.ngrok-free.dev";

  @override
  void initState() {
    super.initState();
    _fetchLogs();
  }

  // 서버에서 로그 목록 가져오기
  Future<void> _fetchLogs() async {
    setState(() { _isLoading = true; });
    try {
      var uri = Uri.parse('$baseUrl/logs');
      var response = await http.get(uri);

      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));

        List<AbnormalLog> fetchedLogs = data.map((json) {
          // 영상 URL 조합
          String fullVideoUrl = baseUrl + (json['videoUrl'] ?? '');
          return AbnormalLog(
            // timestamp 예시: "2024-05-30 14:00:00 (00:15)"
            timestamp: "${json['upload_date']} (${json['timestamp']})",
            videoUrl: fullVideoUrl,
          );
        }).toList();

        setState(() {
          _logs = fetchedLogs.reversed.toList(); // 최신순 정렬
          _isLoading = false;
        });
      } else {
        throw Exception('서버 연결 실패');
      }
    } catch (e) {
      print("로그 에러: $e");
      setState(() { _isLoading = false; });
    }
  }

  // 로그 삭제 함수
  Future<void> _deleteLog(int index) async {
    final log = _logs[index];
    String filename = log.videoUrl.split('/').last;

    try {
      var uri = Uri.parse('$baseUrl/logs/$filename');
      var response = await http.delete(uri);

      if (response.statusCode == 200) {
        setState(() {
          _logs.removeAt(index);
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("삭제되었습니다.")));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("삭제 실패")));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("에러: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.showAll ? '전체 감지 기록' : '오늘의 감지 기록'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        actions: [
          IconButton(
              icon: Icon(Icons.refresh),
              onPressed: _fetchLogs
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _logs.isEmpty
          ? Center(child: Text('저장된 기록이 없습니다.', style: TextStyle(color: Colors.grey)))
          : ListView.separated(
        padding: EdgeInsets.all(16),
        itemCount: _logs.length,
        separatorBuilder: (context, index) => SizedBox(height: 12),
        itemBuilder: (context, index) {
          final log = _logs[index];
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 5)],
            ),
            child: ListTile(
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: CircleAvatar(
                backgroundColor: Colors.red[50],
                child: Icon(Icons.warning_rounded, color: Colors.red),
              ),
              title: Text(
                '이상행동 감지',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                log.timestamp,
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // [수정됨] 재생 버튼: 시간 추출 로직 추가
                  IconButton(
                    icon: Icon(Icons.play_circle_fill, color: Colors.blue, size: 32),
                    onPressed: () {
                      if (log.videoUrl.isNotEmpty) {

                        String? extractedTime;
                        try {
                          // "(00:15)" 형태에서 시간만 추출
                          if (log.timestamp.contains('(')) {
                            extractedTime = log.timestamp.split('(')[1].replaceAll(')', '').trim();
                          }
                        } catch (e) {
                          print("시간 추출 실패: $e");
                        }

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => VideoPlayerScreen(
                              videoUrl: log.videoUrl,
                              startTime: extractedTime, // 추출한 시간 전달
                            ),
                          ),
                        );
                      }
                    },
                  ),
                  // 삭제 버튼
                  IconButton(
                    icon: Icon(Icons.delete, color: Colors.grey),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: Text("기록 삭제"),
                          content: Text("정말 삭제하시겠습니까?"),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: Text("취소"),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(ctx);
                                _deleteLog(index);
                              },
                              child: Text("삭제", style: TextStyle(color: Colors.red)),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}