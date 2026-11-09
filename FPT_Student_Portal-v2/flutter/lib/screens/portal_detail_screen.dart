import 'package:flutter/material.dart';

import '../services/portal_api.dart';

const portalBg = Color(0xFF0F1729);
const portalCard = Color(0xFF1E293B);
const portalNavy = Color(0xFF1B304B);
const portalGreen = Color(0xFF10B987);
const portalOrange = Color(0xFFFF9900);
const portalMuted = Color(0xFF94A3B8);

String portalText(Map<String, dynamic> row, String key) =>
    row[key] == null || '${row[key]}'.trim().isEmpty ? '—' : '${row[key]}';
String portalDate(dynamic raw) {
  final date = DateTime.tryParse('$raw');
  if (date == null) return '—';
  return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}

List<Map<String, dynamic>> portalRows(dynamic raw) => raw is List
    ? raw.whereType<Map>().map((row) => Map<String, dynamic>.from(row)).toList()
    : [];

Widget portalPanel(Widget child, {Color? accent, Color? background}) =>
    Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: background ?? portalCard,
        borderRadius: BorderRadius.circular(22),
        border: accent == null
            ? null
            : Border(top: BorderSide(color: accent, width: 4)),
      ),
      child: child,
    );

class PortalDetailScreen extends StatefulWidget {
  const PortalDetailScreen({
    super.key,
    required this.studentId,
    required this.enrollmentId,
    required this.section,
  });
  final int studentId, enrollmentId;
  final String section;
  @override
  State<PortalDetailScreen> createState() => _PortalDetailScreenState();
}

class _PortalDetailScreenState extends State<PortalDetailScreen> {
  late Future<Map<String, dynamic>> _future;
  bool get _marks => widget.section == 'marks';
  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _future = PortalApi.detail(
      widget.studentId,
      widget.section,
      widget.enrollmentId,
    );
  }

  Future<void> _reload() async {
    setState(_load);
    try {
      await _future;
    } catch (_) {
      /* Rendered by FutureBuilder. */
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: portalBg,
    appBar: AppBar(
      backgroundColor: portalNavy,
      foregroundColor: Colors.white,
      centerTitle: true,
      title: Text(_marks ? 'Mark Details' : 'Attendance Details'),
      actions: [
        IconButton(
          onPressed: _reload,
          tooltip: 'Tải lại',
          icon: const Icon(Icons.refresh),
        ),
      ],
    ),
    body: FutureBuilder<Map<String, dynamic>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Không tải được dữ liệu: ${snapshot.error}',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  TextButton(onPressed: _reload, child: const Text('Thử lại')),
                ],
              ),
            ),
          );
        }
        final data = snapshot.data!;
        return RefreshIndicator(
          onRefresh: _reload,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            children: _marks ? _markContent(data) : _attendanceContent(data),
          ),
        );
      },
    ),
  );

  Widget _title(Map<String, dynamic> data) => Text(
    '${portalText(data, 'SubjectCode')} - ${portalText(data, 'SubjectName')}',
    style: const TextStyle(
      color: Colors.white,
      fontSize: 23,
      fontWeight: FontWeight.w800,
    ),
  );

  List<Widget> _markContent(Map<String, dynamic> data) {
    final assessments = portalRows(data['Assessments']);
    final average = data['AverageMark'] as num?;
    final passed = data['GradeStatus'] == 'PASSED';
    final status = average == null
        ? 'In progress'
        : passed
        ? 'Passed'
        : 'Not passed';
    final color = average == null
        ? portalOrange
        : passed
        ? portalGreen
        : Colors.redAccent;
    return [
      portalPanel(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _title(data),
            const Divider(height: 30, color: Color(0xFF334155)),
            Wrap(
              spacing: 14,
              runSpacing: 10,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Chip(
                  label: Text(
                    status,
                    style: TextStyle(color: color, fontWeight: FontWeight.bold),
                  ),
                  backgroundColor: color.withValues(alpha: .15),
                  side: BorderSide.none,
                ),
                Text(
                  'Class name: ${portalText(data, 'ClassName')}',
                  style: const TextStyle(color: portalMuted, fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Average: ${average?.toStringAsFixed(1) ?? '—'}',
              style: TextStyle(
                color: color,
                fontSize: 25,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        accent: color,
      ),
      if (assessments.isEmpty)
        portalPanel(
          const Text(
            'Chưa có điểm thành phần',
            style: TextStyle(color: portalMuted),
          ),
        )
      else
        portalPanel(
          LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: constraints.maxWidth),
                child: DataTable(
                  headingRowColor: const WidgetStatePropertyAll(portalNavy),
                  dataRowColor: const WidgetStatePropertyAll(Color(0xFFF8FAFC)),
                  headingTextStyle: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  dataTextStyle: const TextStyle(color: Color(0xFF334155)),
                  columnSpacing: 26,
                  columns: const [
                    DataColumn(label: Text('Grade item')),
                    DataColumn(label: Text('Weight')),
                    DataColumn(label: Text('Value')),
                  ],
                  rows: [
                    ...assessments.map((row) {
                      final weight = row['Weight'] as num?;
                      final score = row['Score'] as num?;
                      return DataRow(
                        cells: [
                          DataCell(Text(portalText(row, 'AssessmentName'))),
                          DataCell(
                            Text(
                              weight == null
                                  ? '—'
                                  : '${(weight * 100).toStringAsFixed(1)} %',
                            ),
                          ),
                          DataCell(Text(score?.toStringAsFixed(1) ?? '—')),
                        ],
                      );
                    }),
                    DataRow(
                      cells: [
                        const DataCell(Text('Course total')),
                        const DataCell(Text('Average')),
                        DataCell(Text(average?.toStringAsFixed(1) ?? '—')),
                      ],
                    ),
                    DataRow(
                      cells: [
                        const DataCell(Text('Status')),
                        const DataCell(Text('')),
                        DataCell(
                          Text(
                            status,
                            style: TextStyle(
                              color: color,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
    ];
  }

  List<Widget> _attendanceContent(Map<String, dynamic> data) {
    final sessions = portalRows(data['Sessions']);
    final total = (data['TotalSessions'] as num?)?.toInt() ?? 0;
    final attended = (data['Attended'] as num?)?.toInt() ?? 0;
    final ratio = total == 0 ? 0.0 : (attended / total).clamp(0.0, 1.0);
    return [
      portalPanel(
        Column(
          children: [
            Row(
              children: [
                SizedBox(
                  width: 74,
                  height: 74,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox.expand(
                        child: CircularProgressIndicator(
                          value: ratio,
                          strokeWidth: 10,
                          backgroundColor: portalOrange,
                          color: portalGreen,
                        ),
                      ),
                      Text(
                        total == 0 ? '—' : '${(ratio * 100).round()}',
                        style: const TextStyle(
                          color: portalOrange,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _title(data),
                      const SizedBox(height: 8),
                      Text(
                        'Class name: ${portalText(data, 'ClassCode')}',
                        style: const TextStyle(color: portalMuted),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Attended: $attended/$total',
                        style: const TextStyle(
                          color: portalOrange,
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 32, color: Color(0xFF334155)),
            Wrap(
              spacing: 18,
              runSpacing: 10,
              children: [
                _counter(attended, 'Present', portalGreen),
                _counter(data['Absent'] ?? 0, 'Absent', Colors.redAccent),
                _counter(data['Future'] ?? 0, 'Future', portalMuted),
                _counter(
                  data['Unrecorded'] ?? 0,
                  'Chưa ghi nhận',
                  portalOrange,
                ),
              ],
            ),
          ],
        ),
      ),
      if (sessions.isEmpty)
        portalPanel(
          const Text('Chưa có buổi học', style: TextStyle(color: portalMuted)),
        ),
      ...sessions.map((row) {
        final status = '${row['AttendanceStatus']}'.toLowerCase();
        final present = status == 'present';
        final absent = status == 'absent';
        final future = status == 'future';
        final color = present
            ? portalGreen
            : absent
            ? Colors.redAccent
            : future
            ? portalMuted
            : portalOrange;
        final label = present
            ? 'Present'
            : absent
            ? 'Absent'
            : future
            ? 'Future'
            : 'Chưa ghi nhận';
        return portalPanel(
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Date: ${portalDate(row['SessionDate'])}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${portalText(row, 'StartTime')}–${portalText(row, 'EndTime')}',
                      style: const TextStyle(color: portalMuted, fontSize: 17),
                    ),
                    Text(
                      'Room: ${portalText(row, 'Room')}',
                      style: const TextStyle(color: portalMuted),
                    ),
                    Text(label, style: TextStyle(color: color)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              CircleAvatar(
                backgroundColor: color,
                foregroundColor: Colors.white,
                radius: 24,
                child: Icon(
                  present
                      ? Icons.check
                      : absent
                      ? Icons.close
                      : future
                      ? Icons.schedule
                      : Icons.question_mark,
                ),
              ),
            ],
          ),
          accent: color,
        );
      }),
    ];
  }

  Widget _counter(Object count, String label, Color color) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          '$count',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      const SizedBox(width: 7),
      Text(label, style: const TextStyle(color: portalMuted)),
    ],
  );
}
