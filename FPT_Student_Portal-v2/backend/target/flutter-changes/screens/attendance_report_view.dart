import 'package:flutter/material.dart';

class AttendanceReportView extends StatefulWidget {
  const AttendanceReportView({
    super.key,
    required this.rows,
    this.onCourseSelected,
  });
  final ValueChanged<Map<String, dynamic>>? onCourseSelected;
  final List<Map<String, dynamic>> rows;

  @override
  State<AttendanceReportView> createState() => _AttendanceReportViewState();
}

class _AttendanceReportViewState extends State<AttendanceReportView> {
  String _selected = 'ALL';
  static const bg = Color(0xFF0C1425);
  static const card = Color(0xFF202B3E);
  static const muted = Color(0xFF98A7BD);
  static const orange = Color(0xFFFF9900);
  static const green = Color(0xFF12BE90);

  String _field(Map<String, dynamic> row, String key, [String fallback = '—']) {
    final value = row[key];
    return value == null || '$value'.trim().isEmpty ? fallback : '$value';
  }

  int _number(Map<String, dynamic> row, String key) {
    final value = row[key];
    return value is num ? value.toInt() : int.tryParse('$value') ?? 0;
  }

  String _date(dynamic value) {
    if (value == null || '$value'.isEmpty) return '—';
    final date = DateTime.tryParse('$value');
    if (date == null) return '$value';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final semesters =
        widget.rows
            .map((r) => _field(r, 'Semester', ''))
            .where((s) => s.isNotEmpty)
            .toSet()
            .toList()
          ..sort((a, b) => b.compareTo(a));
    final tabs = <String>['ALL', ...semesters];
    final current = tabs.contains(_selected) ? _selected : 'ALL';
    final items = widget.rows
        .where((r) => current == 'ALL' || _field(r, 'Semester', '') == current)
        .toList();
    return Container(
      color: bg,
      child: Column(
        children: [
          SizedBox(
            height: 94,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 20),
              scrollDirection: Axis.horizontal,
              itemCount: tabs.length,
              separatorBuilder: (_, index) => const SizedBox(width: 10),
              itemBuilder: (context, i) {
                final selected = tabs[i] == current;
                return ChoiceChip(
                  label: Text(tabs[i] == 'ALL' ? 'TẤT CẢ' : tabs[i]),
                  selected: selected,
                  onSelected: (_) => setState(() => _selected = tabs[i]),
                  selectedColor: orange,
                  backgroundColor: Colors.white,
                  labelStyle: TextStyle(
                    color: selected ? Colors.white : const Color(0xFF1D3557),
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                  side: BorderSide.none,
                  shape: const StadiumBorder(),
                  showCheckmark: false,
                );
              },
            ),
          ),
          Expanded(
            child: items.isEmpty
                ? ListView(
                    children: const [
                      SizedBox(height: 95),
                      Center(
                        child: Text(
                          'Chưa có dữ liệu điểm danh',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ),
                    ],
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 30),
                    itemCount: items.length,
                    itemBuilder: (context, index) => _course(items[index]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _course(Map<String, dynamic> row) {
    final attended = _number(row, 'Attended');
    final total = _number(row, 'TotalSessions');
    final percentage = total > 0
        ? (attended / total * 100).clamp(0.0, 100.0)
        : 0.0;
    final code = _field(row, 'SubjectCode');
    final name = _field(row, 'SubjectName', code);
    return GestureDetector(
      onTap: widget.onCourseSelected == null
          ? null
          : () => widget.onCourseSelected!(row),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: card,
          borderRadius: BorderRadius.circular(20),
        ),
        child: IntrinsicHeight(
          child: Row(
            children: [
              Container(width: 5, color: orange),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: SizedBox(
                  width: 72,
                  height: 72,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox.expand(
                        child: CircularProgressIndicator(
                          value: total > 0 ? percentage / 100 : 0,
                          strokeWidth: 10,
                          backgroundColor: orange,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            green,
                          ),
                          strokeCap: StrokeCap.butt,
                        ),
                      ),
                      Text(
                        total > 0
                            ? (percentage % 1 == 0
                                  ? percentage.toStringAsFixed(0)
                                  : percentage.toStringAsFixed(2))
                            : '—',
                        style: const TextStyle(
                          fontSize: 17,
                          color: orange,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(0, 18, 14, 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$code - $name',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      _detail('Class name', _field(row, 'ClassCode')),
                      _detail('Start date', _date(row['StartDate'])),
                      _detail('End date', _date(row['EndDate'])),
                      const SizedBox(height: 9),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: orange, width: 1.5),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Text(
                          'Attended: $attended/$total',
                          style: const TextStyle(
                            color: orange,
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detail(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 2),
    child: Text(
      '$label: $value',
      style: const TextStyle(color: muted, fontSize: 15),
    ),
  );
}
