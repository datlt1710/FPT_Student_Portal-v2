import 'package:flutter/material.dart';

import '../services/auth_api.dart';

/// Loads identity from the authenticated API, once per mounted widget.
class StudentInfoBuilder extends StatefulWidget {
  const StudentInfoBuilder({
    super.key,
    required this.builder,
    this.loadStudent = AuthApi.currentStudent,
  });
  final Widget Function(BuildContext, Map<String, dynamic>) builder;
  final Future<Map<String, dynamic>> Function() loadStudent;

  @override
  State<StudentInfoBuilder> createState() => _StudentInfoBuilderState();
}

class _StudentInfoBuilderState extends State<StudentInfoBuilder> {
  late Future<Map<String, dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.loadStudent();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<Map<String, dynamic>>(
    future: _future,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return TextButton.icon(
          onPressed: () {
            final request = widget.loadStudent();
            setState(() {
              _future = request;
            });
          },
          icon: const Icon(Icons.refresh),
          label: const Text('Cannot load student. Retry'),
        );
      }
      if (!snapshot.hasData) {
        return const Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        );
      }
      return widget.builder(context, snapshot.data!);
    },
  );
}
