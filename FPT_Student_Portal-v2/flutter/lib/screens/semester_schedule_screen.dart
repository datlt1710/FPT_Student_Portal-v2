import '../services/timetable_api.dart';
import '../services/semester_api.dart';

import 'package:flutter/material.dart';

/// Lịch học theo tháng; dữ liệu buổi học lấy từ timetable API.
class SemesterScheduleScreen extends StatefulWidget {
  final int studentId;
  const SemesterScheduleScreen({super.key, required this.studentId});

  @override
  State<SemesterScheduleScreen> createState() => _SemesterScheduleScreenState();
}

class _SemesterScheduleScreenState extends State<SemesterScheduleScreen> {
  static const bg = Color(0xFF0E1729);
  static const header = Color(0xFF1B304E);
  static const panel = Color(0xFF202D43);
  static const orange = Color(0xFFFF9900);
  static const muted = Color(0xFFA3AFC2);
  List<AcademicSemester> _terms = [];
  List<String> get semesters => _terms.map((term) => term.code).toList();
  static const monthNames = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime _selected = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day,
  );
  String _semester = '';
  bool _loading = false;
  String? _error;
  List<Map<String, dynamic>> _sessions = [];
  int _requestNumber = 0;

  @override
  void initState() {
    super.initState();
    _initializeSemesters();
  }

  Future<void> _initializeSemesters() async {
    final request = ++_requestNumber;
    setState(() {
      _loading = true;
      _error = null;
      _sessions = [];
    });
    try {
      final terms = await SemesterApi.list(widget.studentId);
      if (!mounted || request != _requestNumber) return;
      if (terms.isEmpty) {
        throw const FormatException('Chưa có kỳ học trong database');
      }
      final term = SemesterApi.initial(terms, DateTime.now());
      final date = term.openingDate(DateTime.now());
      setState(() {
        _terms = terms;
        _semester = term.code;
        _selected = date;
        _month = DateTime(date.year, date.month);
      });
      await _load();
    } catch (error) {
      if (!mounted || request != _requestNumber) return;
      setState(() {
        _loading = false;
        _error = '$error';
      });
    }
  }

  String _iso(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  String _time(dynamic v) {
    final s = v?.toString() ?? '';
    return s.length >= 5 ? s.substring(0, 5) : '--:--';
  }

  Future<void> _load() async {
    if (_terms.isEmpty) return _initializeSemesters();
    final request = ++_requestNumber;
    setState(() {
      _loading = true;
      _error = null;
    });
    final first = DateTime(_month.year, _month.month);
    final last = DateTime(_month.year, _month.month + 1, 0);
    try {
      final data = await TimetableApi.fetchRows(
        studentId: widget.studentId,
        start: first,
        end: last,
        semester: '${_terms.firstWhere((term) => term.code == _semester).id}',
      );
      if (!mounted || request != _requestNumber) return;
      setState(() {
        _sessions = data;
        _loading = false;
      });
    } catch (e) {
      if (!mounted || request != _requestNumber) return;
      setState(() {
        _error = e.toString();
        _loading = false;
        _sessions = [];
      });
    }
  }

  void _changeMonth(int delta) {
    final next = DateTime(_month.year, _month.month + delta);
    setState(() {
      _month = next;
      _selected = DateTime(next.year, next.month, 1);
    });
    _load();
  }

  void _chooseSemester(String sem) {
    final date = _terms
        .firstWhere((term) => term.code == sem)
        .openingDate(DateTime.now());
    setState(() {
      _semester = sem;
      _month = DateTime(date.year, date.month);
      _selected = date;
      _sessions = [];
    });
    _load();
  }

  List<Map<String, dynamic>> get _selectedSessions {
    final list = _sessions
        .where(
          (s) =>
              s['sessionDate']?.toString().startsWith(_iso(_selected)) ?? false,
        )
        .toList();
    list.sort((a, b) => _time(a['startTime']).compareTo(_time(b['startTime'])));
    return list;
  }

  Widget _semesterPills() => SizedBox(
    height: 72,
    child: ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      scrollDirection: Axis.horizontal,
      itemCount: semesters.length,
      separatorBuilder: (_, index) => const SizedBox(width: 10),
      itemBuilder: (context, index) {
        final semester = semesters[index];
        final chosen = semester == _semester;
        return InkWell(
          onTap: () => _chooseSemester(semester),
          borderRadius: BorderRadius.circular(28),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: chosen ? orange : Colors.white,
              borderRadius: BorderRadius.circular(28),
            ),
            child: Text(
              semester,
              style: TextStyle(
                color: chosen ? Colors.white : header,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        );
      },
    ),
  );

  Widget _monthHeader() => Container(
    color: panel,
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed: () => _changeMonth(-1),
          icon: const Icon(Icons.chevron_left, color: Colors.white),
        ),
        InkWell(
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: _selected,
              firstDate: DateTime(2020),
              lastDate: DateTime(2040),
            );
            if (!mounted || date == null) return;
            setState(() {
              _month = DateTime(date.year, date.month);
              _selected = date;
            });
            _load();
          },
          child: Text(
            '${monthNames[_month.month - 1]} ${_month.year}  ▾',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 22,
            ),
          ),
        ),
        IconButton(
          onPressed: () => _changeMonth(1),
          icon: const Icon(Icons.chevron_right, color: orange),
        ),
      ],
    ),
  );

  Widget _calendar() {
    final start = DateTime(_month.year, _month.month);
    final offset = start.weekday % 7; // Sunday first
    final days = DateTime(_month.year, _month.month + 1, 0).day;
    const weekdays = ['CN', 'Th2', 'Th3', 'Th4', 'Th5', 'Th6', 'Th7'];
    final rows = ((offset + days + 6) ~/ 7);
    final markedDays = _sessions
        .map((s) => DateTime.tryParse(s['sessionDate']?.toString() ?? '')?.day)
        .whereType<int>()
        .toSet();
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 4),
      child: Column(
        children: [
          Row(
            children: weekdays
                .map(
                  (w) => Expanded(
                    child: Center(
                      child: Text(
                        w,
                        style: const TextStyle(
                          color: muted,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 12),
          ...List.generate(
            rows,
            (r) => Row(
              children: List.generate(7, (col) {
                final day = r * 7 + col - offset + 1;
                if (day < 1 || day > days) {
                  return const Expanded(child: SizedBox(height: 58));
                }
                final date = DateTime(_month.year, _month.month, day);
                final selected =
                    date.year == _selected.year &&
                    date.month == _selected.month &&
                    date.day == _selected.day;
                return Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _selected = date),
                    borderRadius: BorderRadius.circular(30),
                    child: SizedBox(
                      height: 58,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircleAvatar(
                            radius: 17,
                            backgroundColor: selected
                                ? orange
                                : Colors.transparent,
                            child: Text(
                              '$day',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: selected
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                              ),
                            ),
                          ),
                          if (markedDays.contains(day))
                            const CircleAvatar(
                              radius: 2,
                              backgroundColor: orange,
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sessionCard(Map<String, dynamic> s) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: panel,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${s['subjectCode'] ?? ''} – ${s['subjectName'] ?? ''}',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 9),
        Text(
          'Class: ${s['classCode'] ?? '—'}',
          style: const TextStyle(color: muted),
        ),
        Text(
          'Time: ${_time(s['startTime'])} – ${_time(s['endTime'])}',
          style: const TextStyle(color: muted),
        ),
        Text(
          'Room: ${s['roomCode'] ?? '—'}',
          style: const TextStyle(color: muted),
        ),
        Text(
          'Lecturer: ${s['lecturerName'] ?? '—'}',
          style: const TextStyle(color: muted),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final selectedSessions = _selectedSessions;
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: header,
        foregroundColor: Colors.white,
        title: const Text(
          'Semester Schedule',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          children: [
            _semesterPills(),
            _monthHeader(),
            _calendar(),
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(22),
                child: Center(child: CircularProgressIndicator(color: orange)),
              ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.all(18),
                child: Text(
                  'Không tải được lịch: $_error',
                  style: const TextStyle(color: Colors.redAccent),
                ),
              ),
            if (!_loading && _error == null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Lịch học ngày ${_selected.day}/${_selected.month}/${_selected.year}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (selectedSessions.isEmpty)
                      const Text(
                        'Không có buổi học trong ngày này.',
                        style: TextStyle(color: muted),
                      ),
                    ...selectedSessions.map(_sessionCard),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
