import 'package:flutter/material.dart';

import '../services/portal_api.dart';
import 'mark_report_view.dart';
import 'attendance_report_view.dart';
import 'portal_detail_screen.dart';
import 'exam_schedule_view.dart';

// ===============================
// COLORS
// ===============================

const _navy = Color(0xFF1B3455);
const _bg = Color(0xFF0C1425);
const _panel = Color(0xFF202E45);
const _orange = Color(0xFFFFA000);

// ===============================
// NOVA EXTRA SCREEN
// ===============================

class NovaExtraScreen extends StatefulWidget {
  const NovaExtraScreen({
    super.key,
    required this.page,
    required this.studentId,
    this.onSelectTab,
  });

  final String page;
  final int studentId;
  final ValueChanged<int>? onSelectTab;

  @override
  State<NovaExtraScreen> createState() => _NovaExtraScreenState();
}

class _NovaExtraScreenState extends State<NovaExtraScreen> {
  late Future<List<Map<String, dynamic>>> _future;

  String _query = '';

  // ===============================
  // XÁC ĐỊNH API THEO MÀN HÌNH
  // ===============================

  String get _section => switch (widget.page) {
    'Messages' => 'messages',
    'Notification' => 'notifications',
    'Application status' => 'applications',
    'Exam schedule' => 'exams',
    'Attendance report' => 'attendance',
    'Mark Report' => 'marks',
    'Student Fee' => 'fees',
    'Contact' => 'contacts',
    'Service review' => 'reviews',
    _ => '',
  };

  // ===============================
  // INITIALIZE
  // ===============================

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  // ===============================
  // LẤY DỮ LIỆU TỪ BACKEND
  // ===============================

  void _refresh() {
    if (_section.isEmpty) {
      _future = Future.value(<Map<String, dynamic>>[]);
    } else {
      _future = PortalApi.list(widget.studentId, _section);
    }
  }

  void _openCourse(Map<String, dynamic> row) {
    final id = int.tryParse('${row['EnrollmentID'] ?? ''}');
    if (id == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Thiếu EnrollmentID. Hãy kiểm tra phiên bản backend.')));
      return;
    }
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => PortalDetailScreen(
      studentId: widget.studentId, enrollmentId: id, section: _section,
    )));
  }

  // ===============================
  // TẢI LẠI DỮ LIỆU
  // ===============================

  Future<void> _reload() async {
    setState(_refresh);

    try {
      await _future;
    } catch (_) {
      // FutureBuilder sẽ hiển thị lỗi.
    }
  }

  // ===============================
  // CHUYỂN TAB
  // ===============================

  void _toTab(int index) {
    if (widget.onSelectTab != null) {
      widget.onSelectTab!(index);
    } else if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  // ===============================
  // MỞ MÀN HÌNH TIN NHẮN
  // ===============================

  void _openMessages() {
    if (widget.page == 'Messages') {
      return;
    }

    if (widget.onSelectTab != null) {
      widget.onSelectTab!(1);
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => NovaExtraScreen(
          page: 'Messages',
          studentId: widget.studentId,
          onSelectTab: widget.onSelectTab,
        ),
      ),
    );
  }

  // ===============================
  // BUILD UI
  // ===============================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,

      // APP BAR
      appBar: AppBar(
        backgroundColor: _navy,
        foregroundColor: Colors.white,
        title: Text(widget.page),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => _toTab(0),
        ),
      ),

      // BODY
      body: _section.isEmpty
          ? _semester()
          : _section == 'exams'
          ? ExamScheduleView(studentId: widget.studentId)
          : _section == 'marks'
          ? FutureBuilder<List<Map<String, dynamic>>>(
              future: _future,
              builder: (context, snapshot) {
                if (!snapshot.hasData && !snapshot.hasError) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Không tải được bảng điểm: ${snapshot.error}',
                          style: const TextStyle(color: Colors.white70),
                        ),
                        TextButton(
                          onPressed: _reload,
                          child: const Text('Thử lại'),
                        ),
                      ],
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: _reload,
                  child: MarkReportView(
                    key: ValueKey(_future),
                    marks: snapshot.data ?? [],
                    onCourseSelected: _openCourse,
                  ),
                );
              },
            )
          : _section == 'attendance'
          ? FutureBuilder<List<Map<String, dynamic>>>(
              future: _future,
              builder: (context, snapshot) {
                if (!snapshot.hasData && !snapshot.hasError) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Không tải được điểm danh: ${snapshot.error}',
                          style: const TextStyle(color: Colors.white70),
                        ),
                        TextButton(
                          onPressed: _reload,
                          child: const Text('Thử lại'),
                        ),
                      ],
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: _reload,
                  child: AttendanceReportView(
                    key: ValueKey(_future),
                    rows: snapshot.data ?? [],
                    onCourseSelected: _openCourse,
                  ),
                );
              },
            )
          : Column(
              children: [
                // THANH TÌM KIẾM
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: TextField(
                    style: const TextStyle(color: Colors.white),
                    onChanged: (value) {
                      setState(() {
                        _query = value.trim().toLowerCase();
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Tìm kiếm...',
                      hintStyle: const TextStyle(color: Colors.white54),
                      prefixIcon: const Icon(
                        Icons.search,
                        color: Colors.white54,
                      ),
                      filled: true,
                      fillColor: _panel,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),

                // DANH SÁCH DỮ LIỆU
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _reload,
                    child: FutureBuilder<List<Map<String, dynamic>>>(
                      future: _future,
                      builder: (context, snapshot) {
                        // ĐANG TẢI
                        if (snapshot.connectionState != ConnectionState.done) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        // BACKEND BÁO LỖI
                        if (snapshot.hasError) {
                          return ListView(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  children: [
                                    const Icon(
                                      Icons.error_outline,
                                      color: Colors.orange,
                                      size: 40,
                                    ),
                                    const SizedBox(height: 12),
                                    const Text(
                                      'Không tải được dữ liệu từ Backend',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      '${snapshot.error}',
                                      style: const TextStyle(
                                        color: Colors.white70,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    TextButton(
                                      onPressed: _reload,
                                      child: const Text('Thử lại'),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        }

                        // LỌC DỮ LIỆU THEO TỪ KHÓA
                        final items = (snapshot.data ?? []).where((row) {
                          return row.values
                              .join(' ')
                              .toLowerCase()
                              .contains(_query);
                        }).toList();

                        // DANH SÁCH RỖNG
                        if (items.isEmpty) {
                          return ListView(
                            children: const [
                              SizedBox(height: 100),
                              Icon(
                                Icons.inbox_outlined,
                                color: Colors.white70,
                                size: 50,
                              ),
                              SizedBox(height: 14),
                              Center(
                                child: Text(
                                  'Chưa có dữ liệu trong hệ thống',
                                  style: TextStyle(color: Colors.white70),
                                ),
                              ),
                            ],
                          );
                        }

                        // HIỂN THỊ DANH SÁCH
                        return ListView.builder(
                          itemCount: items.length,
                          itemBuilder: (context, index) {
                            final row = items[index];

                            final title = switch (_section) {
                              'notifications' => row['Title'],
                              'messages' => row['Subject'],
                              'applications' => row['Title'],
                              'exams' => row['SubjectCode'],
                              'attendance' => row['SubjectCode'],
                              'marks' =>
                                row['SubjectName'] ?? row['SubjectCode'],
                              'fees' => row['FeeName'],
                              'contacts' => row['Department'],
                              'reviews' => 'Đánh giá ${row['Rating']}/5',
                              _ => 'Thông tin',
                            };

                            return Card(
                              color: _panel,
                              margin: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 5,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ListTile(
                                leading: const Icon(
                                  Icons.article_outlined,
                                  color: _orange,
                                ),
                                title: Text(
                                  '$title',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text(
                                  row.entries
                                      .where(
                                        (entry) =>
                                            entry.key != 'Id' &&
                                            entry.value != null,
                                      )
                                      .map(
                                        (entry) =>
                                            '${entry.key}: ${entry.value}',
                                      )
                                      .join('\n'),
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    height: 1.4,
                                  ),
                                ),
                                isThreeLine: true,
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),

      // ===============================
      // NÚT GỬI ĐƠN / ĐÁNH GIÁ
      // ===============================
      floatingActionButton: _section == 'applications' || _section == 'reviews'
          ? FloatingActionButton.extended(
              backgroundColor: _orange,
              foregroundColor: Colors.black,
              onPressed: _createRecord,
              icon: const Icon(Icons.add),
              label: Text(_section == 'reviews' ? 'Đánh giá' : 'Gửi đơn'),
            )
          : null,

      // ===============================
      // BOTTOM NAVIGATION
      // ===============================
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          height: 62,
          color: _navy,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _tab(Icons.home, widget.page != 'Messages', () => _toTab(0)),
              _tab(Icons.chat_bubble, widget.page == 'Messages', _openMessages),
              _tab(Icons.person, false, () => _toTab(2)),
            ],
          ),
        ),
      ),
    );
  }

  // ===============================
  // BOTTOM NAV ITEM
  // ===============================

  Widget _tab(IconData icon, bool active, VoidCallback onTap) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(icon, color: active ? _orange : Colors.white60, size: 28),
    );
  }

  // ===============================
  // MÀN HÌNH LỊCH THEO KỲ
  // ===============================

  Widget _semester() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'Lịch học theo kỳ: sử dụng mục '
          'Weekly timetable để xem lịch thật từ Backend. '
          'Chưa có API lịch tổng hợp theo kỳ.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white70),
        ),
      ),
    );
  }

  // ===============================
  // TẠO ĐƠN / ĐÁNH GIÁ DỊCH VỤ
  // ===============================

  Future<void> _createRecord() async {
    final formKey = GlobalKey<FormState>();

    final titleController = TextEditingController();

    final contentController = TextEditingController();

    int rating = 5;

    final bool isReview = _section == 'reviews';

    try {
      // HIỂN THỊ FORM
      final bool? ok = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (dialogContext, setDialogState) {
              return AlertDialog(
                title: Text(isReview ? 'Đánh giá dịch vụ' : 'Gửi đơn mới'),

                // FORM NHẬP DỮ LIỆU
                content: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // CHỌN SỐ SAO
                        if (isReview)
                          DropdownButtonFormField<int>(
                            initialValue: rating,
                            decoration: const InputDecoration(
                              labelText: 'Đánh giá',
                            ),
                            items: [1, 2, 3, 4, 5]
                                .map(
                                  (value) => DropdownMenuItem<int>(
                                    value: value,
                                    child: Text('$value sao'),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              setDialogState(() {
                                rating = value ?? 5;
                              });
                            },
                          ),

                        // TIÊU ĐỀ ĐƠN
                        if (!isReview)
                          TextFormField(
                            controller: titleController,
                            maxLength: 250,
                            decoration: const InputDecoration(
                              labelText: 'Tiêu đề',
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Nhập tiêu đề';
                              }
                              return null;
                            },
                          ),

                        // NỘI DUNG / NHẬN XÉT
                        TextFormField(
                          controller: contentController,
                          maxLength: 2000,
                          maxLines: 3,
                          decoration: InputDecoration(
                            labelText: isReview ? 'Nhận xét' : 'Nội dung',
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Vui lòng nhập nội dung';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                // NÚT THAO TÁC
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(dialogContext, false);
                    },
                    child: const Text('Hủy'),
                  ),
                  FilledButton(
                    onPressed: () {
                      if (formKey.currentState!.validate()) {
                        Navigator.pop(dialogContext, true);
                      }
                    },
                    child: const Text('Gửi'),
                  ),
                ],
              );
            },
          );
        },
      );

      // NGƯỜI DÙNG HỦY
      if (ok != true) {
        return;
      }

      // ===============================
      // GỬI API LƯU DATABASE
      // ===============================

      if (isReview) {
        await PortalApi.submit(widget.studentId, _section, {
          'rating': rating,
          'comment': contentController.text.trim(),
        });
      } else {
        await PortalApi.submit(widget.studentId, _section, {
          'title': titleController.text.trim(),
          'content': contentController.text.trim(),
        });
      }

      if (!mounted) {
        return;
      }

      // THÔNG BÁO THÀNH CÔNG
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Đã lưu vào SQL Server')));

      // TẢI LẠI DANH SÁCH
      await _reload();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Không lưu được: $e')));
      }
    } finally {
      // GIẢI PHÓNG CONTROLLER
      titleController.dispose();
      contentController.dispose();
    }
  }
}
