import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'upload_screen.dart';
import 'log_list_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    DashboardScreen(),
    UploadScreen(),
    LogListScreen(showAll: true),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: '홈'),
          BottomNavigationBarItem(icon: Icon(Icons.cloud_upload), label: '영상 분석'),
          BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: '기록 확인'),
        ],
      ),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _todayCount = 0;
  bool _isLoading = true;
  bool _isServerOnline = false; // 서버 연결 상태 변수 추가

  // [주의] 실행 중인 Ngrok 주소 확인!
  final String baseUrl = "https://becomingly-vowless-peggy.ngrok-free.dev";

  @override
  void initState() {
    super.initState();
    _fetchTodayAbnormalCount();
  }

  Future<void> _fetchTodayAbnormalCount() async {
    setState(() { _isLoading = true; });
    try {
      var uri = Uri.parse('$baseUrl/logs');
      // 3초 안에 응답 없으면 오프라인으로 간주
      var response = await http.get(uri).timeout(Duration(seconds: 3));

      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        String todayString = DateFormat('yyyy-MM-dd').format(DateTime.now());

        int count = data.where((item) {
          String uploadDate = item['upload_date'] ?? '';
          return uploadDate.startsWith(todayString);
        }).length;

        setState(() {
          _todayCount = count;
          _isServerOnline = true; // 연결 성공 -> 온라인
          _isLoading = false;
        });
      } else {
        setState(() {
          _isServerOnline = false; // 에러 코드 -> 오프라인
          _isLoading = false;
        });
      }
    } catch (e) {
      print("서버 연결 실패: $e");
      setState(() {
        _isServerOnline = false; // 예외 발생(타임아웃 등) -> 오프라인
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.black),
            onPressed: _fetchTodayAbnormalCount,
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 40),
            Row(
              children: [
                Text(
                  'SAFESTORE',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Colors.black,
                    letterSpacing: 1.0,
                  ),
                ),
                SizedBox(width: 8),
                Text(
                  'AI',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
            SizedBox(height: 60),

            // 오늘 발생한 이상행동 카드
            GestureDetector(
              onTap: () {
                // 클릭 시 '오늘의 기록'만 보여주는 리스트 화면으로 이동
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => LogListScreen(showAll: false),
                  ),
                );
              },
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.all(30),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.4),
                      blurRadius: 15,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '오늘의 감지 리포트',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    Text(
                      '이상행동 감지',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 10),
                    _isLoading
                        ? SizedBox(
                      height: 60,
                      child: Center(child: CircularProgressIndicator(color: Colors.white)),
                    )
                        : Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '$_todayCount',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 60,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(width: 10),
                        Text(
                          '건',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            Spacer(),

            Text(
              "시스템 상태",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[800]),
            ),
            SizedBox(height: 10),
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  // 서버 연결 상태 표시 (색상 및 텍스트 자동 변경)
                  ListTile(
                    leading: Icon(
                        Icons.wifi,
                        color: _isServerOnline ? Colors.green : Colors.red // 연결 상태에 따라 색상 변경
                    ),
                    title: Text("서버 연결", style: TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(_isServerOnline ? "온라인" : "오프라인"), // 텍스트 변경
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                  ),
                ],
              ),
            ),
            SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}