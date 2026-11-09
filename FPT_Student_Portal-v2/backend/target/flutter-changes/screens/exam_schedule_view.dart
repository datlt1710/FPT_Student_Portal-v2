import 'package:flutter/material.dart';

import '../services/portal_api.dart';
import 'portal_detail_screen.dart';

class ExamScheduleView extends StatefulWidget {
  const ExamScheduleView({super.key, required this.studentId});
  final int studentId;
  @override
  State<ExamScheduleView> createState() => _ExamScheduleViewState();
}

class _ExamScheduleViewState extends State<ExamScheduleView> {
  late Future<List<Map<String, dynamic>>> _future;
  String _selected = '';
  String _semester(dynamic value) =>
      '${value ?? ''}'.replaceAll(RegExp(r'\s+'), '').toUpperCase();
  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _future = PortalApi.list(widget.studentId, 'exams');
  }

  Future<void> _reload() async {
    setState(_load);
    try {
      await _future;
    } catch (_) {
      /* Rendered below. */
    }
  }

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: portalBg,
    child: FutureBuilder<List<Map<String, dynamic>>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Không tải được lịch thi: ${snapshot.error}',
                    style: const TextStyle(color: portalMuted),
                  ),
                  TextButton(onPressed: _reload, child: const Text('Thử lại')),
                ],
              ),
            ),
          );
        }
        final all = snapshot.data ?? [];
        final semesters =
            all
                .map((row) => _semester(row['SemesterCode'] ?? row['Semester']))
                .where((s) => s.isNotEmpty)
                .toSet()
                .toList()
              ..sort((a, b) => b.compareTo(a));
        final tabs = ['', ...semesters];
        final selected = tabs.contains(_selected) ? _selected : '';
        final exams = all
            .where(
              (row) =>
                  selected.isEmpty || _semester(row['SemesterCode'] ?? row['Semester']) == selected,
            )
            .toList();
        return Column(
          children: [
            SizedBox(
              height: 86,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 18,
                ),
                itemCount: tabs.length,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (context, index) => ChoiceChip(
                  label: Text(tabs[index].isEmpty ? 'TẤT CẢ' : tabs[index]),
                  avatar: const Icon(Icons.school, size: 18),
                  showCheckmark: false,
                  selected: selected == tabs[index],
                  onSelected: (_) => setState(() => _selected = tabs[index]),
                  selectedColor: portalOrange,
                  backgroundColor: Colors.white,
                  labelStyle: TextStyle(
                    color: selected == tabs[index] ? Colors.white : portalNavy,
                    fontWeight: FontWeight.w800,
                  ),
                  shape: const StadiumBorder(),
                  side: BorderSide.none,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Number of exams: ${exams.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _reload,
                    tooltip: 'Tải lại',
                    icon: const Icon(Icons.refresh, color: Colors.white),
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Text(
                'Date format: dd/mm/yyyy',
                style: TextStyle(color: portalMuted),
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _reload,
                child: ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  itemCount: exams.isEmpty ? 1 : exams.length,
                  itemBuilder: (context, index) {
                    if (exams.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.all(40),
                        child: Center(
                          child: Text(
                            'Chưa có lịch thi',
                            style: TextStyle(color: portalMuted),
                          ),
                        ),
                      );
                    }
                    final row = exams[index];
                    final status = row['ExamStatus'];
                    final past = status == 'PAST';
                    final color = past
                        ? portalMuted
                        : status == 'TODAY'
                        ? portalOrange
                        : portalGreen;
                    final label = past
                        ? 'Đã thi'
                        : status == 'TODAY'
                        ? 'Hôm nay'
                        : status == 'UPCOMING'
                        ? 'Sắp tới'
                        : 'Chưa rõ ngày';
                    return portalPanel(
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 10,
                            runSpacing: 8,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: past
                                      ? const Color(0xFFF1F5F9)
                                      : color.withValues(alpha: .12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.calendar_month,
                                  color: color,
                                  size: 28,
                                ),
                              ),
                              Text(
                                'Date: ${portalDate(row['ExamDate'])}',
                                style: TextStyle(
                                  color: past ? portalMuted : Colors.white,
                                  fontSize: 21,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Chip(
                                label: Text(
                                  label,
                                  style: TextStyle(
                                    color: color,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                backgroundColor: past
                                    ? const Color(0xFFF1F5F9)
                                    : color.withValues(alpha: .12),
                                side: BorderSide.none,
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: portalNavy,
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                child: Text(
                                  '#${index + 1}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 24, color: Color(0xFF334155)),
                          _line(
                            'Subject',
                            portalText(row, 'SubjectCode'),
                            past: past,
                          ),
                          _line('Room', portalText(row, 'Room'), past: past),
                          _line(
                            'Time',
                            portalText(row, 'ExamTime'),
                            past: past,
                          ),
                          _line(
                            'Type',
                            portalText(row, 'ExamType'),
                            past: past,
                          ),
                        ],
                      ),
                      accent: color,
                      background: past ? const Color(0xFF334155) : portalCard,
                    );
                  },
                ),
              ),
            ),
          ],
        );
      },
    ),
  );

  Widget _line(String title, String value, {bool past = false}) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '$title: ',
            style: const TextStyle(color: portalMuted),
          ),
          TextSpan(text: value),
        ],
      ),
      style: TextStyle(color: past ? portalMuted : Colors.white, fontSize: 18),
    ),
  );
}
