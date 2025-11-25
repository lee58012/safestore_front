import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // 날짜 형식을 위해 필요
import 'package:http/http.dart' as http; // 실제 서버 연동 시 필요
import 'upload_screen.dart';
import 'log_list_screen.dart';
import '../models/abnormal_log.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  // 탭별 화면 정의: 0번 인덱스에 대시보드(메인) 추가
  final List<Widget> _pages = [
    DashboardScreen(), // 메인 대시보드
    UploadScreen(),    // 영상 업로드
    LogListScreen(),   // 결과 리스트
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
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: '홈',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.cloud_upload),
            label: '영상 분석',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt),
            label: '기록 확인',
          ),
        ],
      ),
    );
  }
}

// 메인 페이지 (대시보드)
class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _todayCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchTodayAbnormalCount();
  }

  // 오늘 발생한 이상행동 횟수 가져오기 (더미 데이터 로직 유지)
  Future<void> _fetchTodayAbnormalCount() async {
    try {
      // 로딩 시뮬레이션
      await Future.delayed(Duration(seconds: 1));

      // 가상의 서버 응답 데이터
      List<AbnormalLog> dummyLogs = [
        AbnormalLog(timestamp: DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now()), videoUrl: ''),
        AbnormalLog(timestamp: DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now().subtract(Duration(hours: 2))), videoUrl: ''),
        AbnormalLog(timestamp: '2023-01-01 10:00:00', videoUrl: ''),
      ];

      // 오늘 날짜와 비교하여 카운트
      String todayString = DateFormat('yyyy-MM-dd').format(DateTime.now());
      int count = dummyLogs.where((log) {
        return log.timestamp.startsWith(todayString);
      }).length;

      setState(() {
        _todayCount = count;
        _isLoading = false;
      });
    } catch (e) {
      print("Error fetching logs: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      // AppBar를 제거하거나 투명하게 하여 본문과 합쳐 보이게 할 수 있습니다.
      // 여기서는 상단 여백을 위해 AppBar는 최소화하고 body에 여백을 줍니다.
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.black),
            onPressed: () {
              setState(() { _isLoading = true; });
              _fetchTodayAbnormalCount();
            },
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'SAFESTORE',
                  style: TextStyle(
                    fontSize: 28, // 크기 키움
                    fontWeight: FontWeight.w900, // 볼드체 중에서도 가장 두껍게
                    color: Colors.black,
                    letterSpacing: 1.0,
                  ),
                ),
                SizedBox(width: 8),
                Text(
                  'AI',
                  style: TextStyle(
                    fontSize: 32, // 강조를 위해 조금 더 크게
                    fontWeight: FontWeight.w900, // 볼드체
                    color: Colors.blue, // 포인트 컬러
                  ),
                ),
              ],
            ),

            SizedBox(height: 60), // 로고와 카드 사이 여백

            // 오늘 발생한 이상행동 카드
            Container(
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
                      Icon(Icons.notifications_active, color: Colors.white),
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
                          fontWeight: FontWeight.w900, // 숫자 강조
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

            // 3. 시스템 상태창을 하단으로 밀어내기 위해 Spacer 사용
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
                  ListTile(
                    leading: Icon(Icons.check_circle, color: Colors.green),
                    title: Text("AI 분석 엔진", style: TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text("정상 작동 중"),
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                  ),
                  Divider(),
                  ListTile(
                    leading: Icon(Icons.wifi, color: Colors.green),
                    title: Text("서버 연결", style: TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text("온라인"),
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                  ),
                ],
              ),
            ),
            SizedBox(height: 40), // 하단 네비게이션 바와의 여백
          ],
        ),
      ),
    );
  }
}