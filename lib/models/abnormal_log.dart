class AbnormalLog {
  final String timestamp; // 이상행동 발생 시간
  final String videoUrl;  // 영상 URL
  final String type;      // 이상행동 유형 (예: 위험, 경고)

  AbnormalLog({
    required this.timestamp,
    required this.videoUrl,
    required this.type,
  });

  // 서버 JSON 데이터를 객체로 변환
  factory AbnormalLog.fromJson(Map<String, dynamic> json) {
    return AbnormalLog(
      timestamp: json['timestamp'] ?? 'Unknown Time',
      videoUrl: json['videoUrl'] ?? '',
      type: json['type'] ?? '알 수 없음',
    );
  }
}