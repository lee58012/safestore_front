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

  // [주의] Ngrok 주소 확인 필수!
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
          String fullVideoUrl = baseUrl + (json['videoUrl'] ?? '');
          return AbnormalLog(
            timestamp: "${json['upload_date']} (${json['timestamp']})",
            videoUrl: fullVideoUrl,
            type: json['type'] ?? '알 수 없음',
          );
        }).toList();

        // 필터링 로직 (오늘 날짜만 보기 기능이 있다면)
        if (!widget.showAll) {
          String today = DateTime.now().toString().substring(0, 10);
          fetchedLogs = fetchedLogs.where((log) => log.timestamp.startsWith(today)).toList();
        }

        setState(() {
          _logs = fetchedLogs.reversed.toList();
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

          // [디자인 로직] 타입에 따라 색상과 아이콘 변경
          bool isDanger = log.type.contains("위험");
          Color statusColor = isDanger ? Colors.red : Colors.orange;
          IconData statusIcon = isDanger ? Icons.error_outline : Icons.warning_amber_rounded;

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
                backgroundColor: statusColor.withOpacity(0.1),
                child: Icon(statusIcon, color: statusColor),
              ),
              title: Text(
                '이상행동 감지 ${log.type}',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  log.timestamp,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.play_circle_fill, color: Colors.blue, size: 32),
                    onPressed: () {
                      if (log.videoUrl.isNotEmpty) {
                        String? extractedTime;
                        try {
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
                              startTime: extractedTime,
                            ),
                          ),
                        );
                      }
                    },
                  ),
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