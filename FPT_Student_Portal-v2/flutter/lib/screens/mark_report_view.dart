import 'package:flutter/material.dart';

const _background = Color(0xFF0C1425);
const _card = Color(0xFF202B3F);
const _orange = Color(0xFFFF9800);
const _muted = Color(0xFF9AA9BE);
const _pass = Color(0xFF10C38E);
const _red = Color(0xFFFF555B);

/// Mark report driven entirely by /portal/marks. Semester/ClassName can be
/// null for legacy rows; such records remain visible under "Tất cả".
class MarkReportView extends StatefulWidget {
  const MarkReportView({super.key, required this.marks, this.onCourseSelected});
  final ValueChanged<Map<String, dynamic>>? onCourseSelected;
  final List<Map<String, dynamic>> marks;

  @override
  State<MarkReportView> createState() => _MarkReportViewState();
}

class _MarkReportViewState extends State<MarkReportView> {
  String selected = 'Tất cả';

  String _semester(Map<String, dynamic> row) =>
      (row['SemesterCode'] ?? row['Semester'] ?? '')
          .toString()
          .replaceAll(RegExp(r'\s+'), '')
          .toUpperCase();

  double? _average(dynamic raw) {
    if (raw == null || raw.toString().trim().isEmpty) return null;
    return raw is num ? raw.toDouble() : double.tryParse('$raw');
  }

  bool _isPassed(String status) =>
      const {'PASSED', 'PASS', 'ĐẠT'}.contains(status.toUpperCase());

  @override
  Widget build(BuildContext context) {
    final semesters =
        widget.marks.map(_semester).where((s) => s.isNotEmpty).toSet().toList()
          ..sort((a, b) => b.compareTo(a));
    final allTabs = <String>['Tất cả', ...semesters];
    final visible = widget.marks
        .where((m) => selected == 'Tất cả' || _semester(m) == selected)
        .toList();

    return Container(
      color: _background,
      child: Column(
        children: [
          const SizedBox(height: 18),
          SizedBox(
            height: 54,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: allTabs.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final semester = allTabs[index];
                final active = selected == semester;
                return InkWell(
                  onTap: () => setState(() => selected = semester),
                  borderRadius: BorderRadius.circular(50),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: active ? _orange : Colors.white,
                      borderRadius: BorderRadius.circular(50),
                      boxShadow: active
                          ? [
                              BoxShadow(
                                color: _orange.withValues(alpha: 0.20),
                                blurRadius: 13,
                              ),
                            ]
                          : null,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.park,
                          size: 18,
                          color: active
                              ? Colors.white
                              : const Color(0xFF8794A8),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          semester,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: active
                                ? Colors.white
                                : const Color(0xFF1B3455),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 15),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(18, 4, 18, 28),
              itemCount: visible.isEmpty ? 1 : visible.length,
              itemBuilder: (context, index) {
                if (visible.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.only(top: 90),
                    child: Center(
                      child: Text(
                        'Học kỳ này chưa có điểm',
                        style: TextStyle(color: _muted, fontSize: 16),
                      ),
                    ),
                  );
                }
                final row = visible[index];
                final code = (row['SubjectCode'] ?? '').toString();
                final name = (row['SubjectName'] ?? '').toString();
                final cls = (row['ClassName'] ?? '').toString().trim();
                final status = (row['GradeStatus'] ?? '')
                    .toString()
                    .toUpperCase();
                final average = _average(row['AverageMark']);
                final passed = _isPassed(status);
                final studying =
                    status == 'STUDYING' ||
                    status == 'IN_PROGRESS' ||
                    status == 'IN PROGRESS';
                final label = passed
                    ? 'Passed'
                    : studying
                    ? 'Studying'
                    : (status.isEmpty ? 'Not graded' : status);
                final accent = passed ? _pass : _red;

                return GestureDetector(
                  onTap: widget.onCourseSelected == null
                      ? null
                      : () => widget.onCourseSelected!(row),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: _card,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Container(width: 5, color: accent),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(
                                18,
                                20,
                                18,
                                21,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Wrap(
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      Text(
                                        code,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 19,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                      Text(
                                        '- $name',
                                        style: const TextStyle(
                                          color: _muted,
                                          fontSize: 17,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      DecoratedBox(
                                        decoration: BoxDecoration(
                                          color: accent.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(
                                            26,
                                          ),
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 13,
                                            vertical: 6,
                                          ),
                                          child: Text(
                                            label,
                                            style: TextStyle(
                                              color: accent,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 14),
                                  const Divider(
                                    height: 1,
                                    color: Color(0xFF39495D),
                                  ),
                                  const SizedBox(height: 14),
                                  Text(
                                    'Class name: ${cls.isEmpty ? "Chưa cập nhật" : cls}',
                                    style: const TextStyle(
                                      color: _muted,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Text(
                                        'Average: ',
                                        style: TextStyle(
                                          color: _muted,
                                          fontSize: 16,
                                        ),
                                      ),
                                      if (average != null)
                                        Text(
                                          average.toStringAsFixed(1),
                                          style: TextStyle(
                                            color: passed
                                                ? _pass
                                                : Colors.white,
                                            fontWeight: FontWeight.w900,
                                            fontSize: 23,
                                          ),
                                        ),
                                    ],
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
              },
            ),
          ),
        ],
      ),
    );
  }
}
