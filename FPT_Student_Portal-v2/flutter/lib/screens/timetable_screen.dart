import '../services/timetable_api.dart';
import '../services/semester_api.dart';

import 'package:flutter/material.dart';

class TimetableScreen extends StatefulWidget {
  final int studentId;

  const TimetableScreen({super.key, required this.studentId});

  @override
  State<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends State<TimetableScreen> {
  static const Color navy = Color(0xFF1B2F4B);
  static const Color background = Color(0xFF0D172A);
  static const Color panel = Color(0xFF1D2A40);
  static const Color muted = Color(0xFF94A3B8);
  static const Color orange = Color(0xFFFF9800);
  static const Color green = Color(0xFF2DD4A3);

  late DateTime selectedDate;

  String selectedSemester = '';
  bool isLoading = false;
  String? errorMessage;

  List<Map<String, dynamic>> classes = [];

  int _requestId = 0;

  List<AcademicSemester> _terms = [];
  List<String> get semesters => _terms.map((term) => term.code).toList();

  final List<String> weekdayNames = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  @override
  void initState() {
    super.initState();

    final now = DateTime.now();
    selectedDate = DateTime(now.year, now.month, now.day);

    _initializeSemesters();
  }

  Future<void> _initializeSemesters() async {
    final request = ++_requestId;
    setState(() {
      isLoading = true;
      errorMessage = null;
      classes = [];
    });
    try {
      final terms = await SemesterApi.list(widget.studentId);
      if (!mounted || request != _requestId) return;
      if (terms.isEmpty) {
        throw const FormatException('Chưa có kỳ học trong database');
      }
      final term = SemesterApi.initial(terms, DateTime.now());
      setState(() {
        _terms = terms;
        selectedSemester = term.code;
        selectedDate = term.openingDate(DateTime.now());
      });
      await _loadTimetable();
    } catch (error) {
      if (!mounted || request != _requestId) return;
      setState(() {
        isLoading = false;
        errorMessage = '$error';
      });
    }
  }

  // ==========================================================
  // DATE HELPERS
  // ==========================================================

  DateTime get weekStart {
    final date = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
    );

    return date.subtract(Duration(days: date.weekday - 1));
  }

  DateTime get weekEnd => weekStart.add(const Duration(days: 6));

  String _twoDigits(int value) {
    return value.toString().padLeft(2, '0');
  }

  String _formatDate(DateTime date) {
    return '${_twoDigits(date.day)}/'
        '${_twoDigits(date.month)}/'
        '${date.year}';
  }

  String _formatMonth(DateTime date) {
    const months = [
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

    return '${months[date.month - 1]} ${date.year}';
  }

  String _timeText(dynamic value) {
    if (value == null) return '--:--';

    final text = value.toString();

    return text.length >= 5 ? text.substring(0, 5) : text;
  }

  bool _sameDay(DateTime first, DateTime second) {
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }

  // ==========================================================
  // LOAD TIMETABLE FROM SPRING BOOT API
  // ==========================================================

  Future<void> _loadTimetable() async {
    if (!mounted) return;
    if (_terms.isEmpty) return _initializeSemesters();

    // Mỗi request có ID riêng để tránh response cũ ghi đè dữ liệu mới.
    final requestId = ++_requestId;

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final result = await TimetableApi.fetchRows(
        studentId: widget.studentId,
        start: weekStart,
        end: weekEnd,
        semester:
            '${_terms.firstWhere((term) => term.code == selectedSemester).id}',
      );

      if (!mounted || requestId != _requestId) return;

      setState(() {
        classes = result;
        isLoading = false;
        errorMessage = null;
      });

      debugPrint('Loaded ${result.length} timetable sessions.');
    } catch (e) {
      if (!mounted || requestId != _requestId) return;

      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });

      debugPrint('Timetable API error: $e');
    }
  }

  // ==========================================================
  // FILTER CLASSES FOR SELECTED DATE
  // ==========================================================

  List<Map<String, dynamic>> get selectedDayClasses {
    final result = classes.where((item) {
      final rawDate = item['sessionDate'];

      if (rawDate == null) return false;

      final date = DateTime.tryParse(rawDate.toString());

      return date != null && _sameDay(date, selectedDate);
    }).toList();

    result.sort((a, b) {
      return _timeText(a['startTime']).compareTo(_timeText(b['startTime']));
    });

    return result;
  }

  bool _hasClassesOn(DateTime date) {
    return classes.any((item) {
      final rawDate = item['sessionDate'];

      if (rawDate == null) return false;

      final lessonDate = DateTime.tryParse(rawDate.toString());

      return lessonDate != null && _sameDay(lessonDate, date);
    });
  }

  // ==========================================================
  // CHANGE WEEK AND DATE
  // ==========================================================

  void _changeWeek(int amount) {
    setState(() {
      selectedDate = selectedDate.add(Duration(days: amount * 7));
    });

    _loadTimetable();
  }

  void _selectDate(DateTime date) {
    setState(() {
      selectedDate = date;
    });
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: orange,
              surface: panel,
            ),
          ),
          child: child!,
        );
      },
    );

    if (!mounted || date == null) return;

    final previousWeekStart = weekStart;

    setState(() {
      selectedDate = date;
    });

    if (!_sameDay(previousWeekStart, weekStart)) {
      _loadTimetable();
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: panel,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ==========================================================
  // MAIN SCREEN
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildSemesterSelector(),
            _buildWeekSummary(),
            _buildCalendar(),
            Expanded(child: _buildScheduleList()),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  // ==========================================================
  // HEADER
  // ==========================================================

  Widget _buildHeader() {
    return Container(
      color: navy,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      child: Row(
        children: [
          InkWell(
            onTap: () => Navigator.pop(context),
            borderRadius: BorderRadius.circular(12),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4, vertical: 6),
              child: Row(
                children: [
                  Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 23),
                  SizedBox(width: 5),
                  Text(
                    'Home',
                    style: TextStyle(color: Colors.white, fontSize: 17),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Weekly timetable',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 23,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Choose date',
            onPressed: _pickDate,
            icon: const Icon(Icons.calendar_month, color: Colors.white),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // SEMESTER SELECTOR
  // ==========================================================

  Widget _buildSemesterSelector() {
    return Container(
      height: 82,
      color: background,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        scrollDirection: Axis.horizontal,
        itemCount: semesters.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final semester = semesters[index];
          final isSelected = semester == selectedSemester;

          return InkWell(
            borderRadius: BorderRadius.circular(40),
            onTap: () {
              setState(() {
                selectedSemester = semester;
                selectedDate = _terms[index].openingDate(DateTime.now());
                classes = [];
              });

              _loadTimetable();
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? orange : Colors.white,
                borderRadius: BorderRadius.circular(40),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: orange.withValues(alpha: 0.25),
                          blurRadius: 12,
                        ),
                      ]
                    : null,
              ),
              child: Row(
                children: [
                  Icon(
                    index == 0
                        ? Icons.park
                        : index == 1
                        ? Icons.wb_sunny
                        : Icons.spa,
                    color: isSelected ? Colors.white : muted,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    semester,
                    style: TextStyle(
                      color: isSelected ? Colors.white : navy,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ==========================================================
  // WEEK SUMMARY
  // ==========================================================

  Widget _buildWeekSummary() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      color: const Color(0xFFF3F5F8),
      child: Text(
        'Current week: ${_formatDate(weekStart)} – ${_formatDate(weekEnd)}',
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Color(0xFF6B7280),
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  // ==========================================================
  // WEEK CALENDAR
  // ==========================================================

  Widget _buildCalendar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.only(top: 10, bottom: 12),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => _changeWeek(-1),
                icon: const Icon(Icons.arrow_left, color: navy, size: 32),
              ),
              Expanded(
                child: Text(
                  _formatMonth(selectedDate),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: navy,
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => _changeWeek(1),
                icon: const Icon(Icons.arrow_right, color: navy, size: 32),
              ),
            ],
          ),
          Row(
            children: List.generate(7, (index) {
              final date = weekStart.add(Duration(days: index));

              final isSelected = _sameDay(date, selectedDate);

              return Expanded(
                child: InkWell(
                  onTap: () => _selectDate(date),
                  child: Column(
                    children: [
                      Text(
                        weekdayNames[index],
                        style: TextStyle(
                          color: isSelected ? navy : muted,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: 42,
                        height: 42,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isSelected ? navy : Colors.transparent,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${date.day}',
                          style: TextStyle(
                            color: isSelected ? Colors.white : navy,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          color: _hasClassesOn(date)
                              ? orange
                              : Colors.transparent,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // SCHEDULE LIST
  // ==========================================================

  Widget _buildScheduleList() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator(color: orange));
    }

    if (errorMessage != null) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off, color: orange, size: 58),
              const SizedBox(height: 16),
              const Text(
                'Cannot load timetable',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: muted),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadTimetable,
                icon: const Icon(Icons.refresh),
                label: const Text('Try again'),
              ),
            ],
          ),
        ),
      );
    }

    final dayClasses = selectedDayClasses;

    if (dayClasses.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadTimetable,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: 300,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.event_available, color: muted, size: 64),
                      const SizedBox(height: 16),
                      const Text(
                        'No classes today',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _formatDate(selectedDate),
                        style: const TextStyle(color: muted),
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: _pickDate,
                        icon: const Icon(Icons.calendar_month),
                        label: const Text('Choose another date'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadTimetable,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
        itemCount: dayClasses.length,
        itemBuilder: (context, index) {
          return _buildClassCard(dayClasses[index]);
        },
      ),
    );
  }

  // ==========================================================
  // CLASS CARD
  // ==========================================================

  Widget _buildClassCard(Map<String, dynamic> item) {
    final rawSlot = item['slotNumber'];
    final slot = rawSlot is num ? rawSlot.toInt() : 0;

    final attendance = (item['attendanceStatus'] ?? '')
        .toString()
        .trim()
        .toLowerCase();
    final status = attendance == 'present'
        ? 'Present'
        : attendance == 'absent'
        ? 'Absent'
        : 'Not yet';
    final meetingUrl = item['meetingUrl']?.toString();

    final slotColor = slot == 2 ? green : orange;

    final roomCode = (item['roomCode'] ?? 'TBA').toString();
    final building = (item['building'] ?? '').toString();

    final subjectCode = (item['subjectCode'] ?? '').toString();
    final subjectName = (item['subjectName'] ?? 'Unknown subject').toString();

    final classCode = (item['classCode'] ?? '-').toString();
    final lecturerName = (item['lecturerName'] ?? '-').toString();
    final sessionNumber = (item['sessionNumber'] ?? '-').toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: panel,
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: slotColor, width: 5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 76,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: slotColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      slot > 0 ? 'Slot $slot' : '—',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: slotColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _timeText(item['startTime']),
                    style: const TextStyle(
                      color: muted,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Container(
                    height: 20,
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 5),
                    color: const Color(0xFF34445B),
                  ),
                  Text(
                    _timeText(item['endTime']),
                    style: const TextStyle(
                      color: muted,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF334257),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Room',
                          style: TextStyle(color: muted, fontSize: 14),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          roomCode,
                          style: const TextStyle(
                            color: Color(0xFFF1F5F9),
                            fontSize: 21,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (building.isNotEmpty)
                          Text(
                            'Building: $building',
                            style: const TextStyle(color: muted, fontSize: 13),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    subjectCode,
                    style: const TextStyle(
                      color: muted,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subjectName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Session No: $sessionNumber',
                    style: const TextStyle(color: muted, fontSize: 14),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Class: $classCode',
                    style: const TextStyle(color: muted, fontSize: 14),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Lecturer: $lecturerName',
                    style: const TextStyle(color: muted, fontSize: 14),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          color: status == 'Present'
                              ? const Color(0xFF087F5B)
                              : status == 'Absent'
                              ? const Color(0xFFDC2626)
                              : const Color(0xFF475569),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Text(
                          status,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      if (meetingUrl != null && meetingUrl.isNotEmpty)
                        InkWell(
                          onTap: () {
                            _showMessage('Meeting URL: $meetingUrl');
                          },
                          borderRadius: BorderRadius.circular(24),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 9,
                            ),
                            decoration: BoxDecoration(
                              color: green,
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: const Text(
                              'Meet URL',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // BOTTOM NAVIGATION
  // ==========================================================

  Widget _buildBottomNavigation() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
      decoration: const BoxDecoration(
        color: navy,
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(Icons.home_rounded, 'Home', 0),
          _buildNavItem(Icons.chat_bubble_rounded, 'Chat', 1),
          _buildNavItem(Icons.person_rounded, 'Profile', 2),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = index == 0;

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () {
        if (index == 0) {
          Navigator.pop(context);
        } else {
          _showMessage('$label screen has not been connected yet.');
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF35404D) : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Icon(icon, color: isSelected ? orange : muted, size: 28),
      ),
    );
  }
}
