class TimetableItem {
  final int sessionId;
  final String subjectCode;
  final String subjectName;
  final String classCode;
  final DateTime sessionDate;
  final String startTime;
  final String endTime;
  final int slotNumber;
  final int sessionNumber;
  final String roomCode;
  final String building;
  final String lecturerName;
  final String sessionStatus;
  final String? meetingUrl;

  const TimetableItem({
    required this.sessionId,
    required this.subjectCode,
    required this.subjectName,
    required this.classCode,
    required this.sessionDate,
    required this.startTime,
    required this.endTime,
    required this.slotNumber,
    required this.sessionNumber,
    required this.roomCode,
    required this.building,
    required this.lecturerName,
    required this.sessionStatus,
    this.meetingUrl,
  });

  factory TimetableItem.fromJson(Map<String, dynamic> json) {
    return TimetableItem(
      sessionId: json['sessionId'] as int,
      subjectCode: json['subjectCode'] ?? '',
      subjectName: json['subjectName'] ?? '',
      classCode: json['classCode'] ?? '',
      sessionDate: DateTime.parse(json['sessionDate']),
      startTime: json['startTime'] ?? '',
      endTime: json['endTime'] ?? '',
      slotNumber: json['slotNumber'] ?? 0,
      sessionNumber: json['sessionNumber'] ?? 0,
      roomCode: json['roomCode'] ?? '',
      building: json['building'] ?? '',
      lecturerName: json['lecturerName'] ?? '',
      sessionStatus: json['sessionStatus'] ?? '',
      meetingUrl: json['meetingUrl'],
    );
  }
}
