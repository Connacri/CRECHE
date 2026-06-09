import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/course_provider_complete.dart';
import '../providers/child_enrollment_provider.dart';
import '../models/course_model_complete.dart';
import '../models/enrollment_model_complete.dart';
import '../models/child_model_complete.dart';
import 'glass_card.dart';

class AttendanceManagementPage extends StatefulWidget {
  const AttendanceManagementPage({super.key});

  @override
  State<AttendanceManagementPage> createState() => _AttendanceManagementPageState();
}

class _AttendanceManagementPageState extends State<AttendanceManagementPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  CourseModel? _selectedCourse;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    final courseProvider = context.watch<CourseProvider>();
    final allCourses = courseProvider.userCourses;
    final currentCourses = allCourses.where((c) => c.isActive).toList();
    final pastCourses = allCourses.where((c) => !c.isActive).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Présences'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Cours Actuels'),
            Tab(text: 'Archives'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAttendanceView(currentCourses),
          _buildAttendanceView(pastCourses),
        ],
      ),
    );
  }

  Widget _buildAttendanceView(List<CourseModel> courses) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              DropdownButtonFormField<CourseModel>(
                initialValue: courses.contains(_selectedCourse) ? _selectedCourse : null,
                items: courses.map((c) => DropdownMenuItem(value: c, child: Text(c.title))).toList(),
                onChanged: (val) => setState(() => _selectedCourse = val),
                decoration: const InputDecoration(labelText: 'Choisir un cours', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              ListTile(
                title: const Text('Date de la séance'),
                subtitle: Text('${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}'),
                trailing: const Icon(Icons.calendar_today),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey[300]!)),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime.now().subtract(const Duration(days: 365)),
                    lastDate: DateTime.now().add(const Duration(days: 7)),
                  );
                  if (date != null) setState(() => _selectedDate = date);
                },
              ),
            ],
          ),
        ),
        if (_selectedCourse == null)
          const Expanded(child: Center(child: Text('Sélectionnez un cours pour commencer.')))
        else
          Expanded(child: _AttendanceList(courseId: _selectedCourse!.id, date: _selectedDate)),
      ],
    );
  }
}

class _AttendanceList extends StatelessWidget {
  final String courseId;
  final DateTime date;
  const _AttendanceList({required this.courseId, required this.date});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ChildEnrollmentProvider>();
    final enrolledItems = provider.ownerEnrollmentsDetailed.where((e) {
      if (e['enrollment'] == null) return false;
      try {
        final enrollment = EnrollmentModel.fromSupabase(e['enrollment']);
        return enrollment.courseId == courseId && enrollment.status == EnrollmentStatus.approved;
      } catch (_) {
        return false;
      }
    }).toList();

    if (enrolledItems.isEmpty) return const Center(child: Text('Aucun inscrit actif.'));

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: enrolledItems.length,
      itemBuilder: (context, index) {
        final item = enrolledItems[index];
        if (item['enrollment'] == null || item['child'] == null) {
          return const SizedBox.shrink();
        }

        try {
          final child = ChildModel.fromSupabase(item['child']);
          final enrollment = EnrollmentModel.fromSupabase(item['enrollment']);

          final dateOnly = DateTime(date.year, date.month, date.day);
          final bool isPresent = enrollment.attendanceHistory.any((r) =>
            r.date.year == dateOnly.year && r.date.month == dateOnly.month && r.date.day == dateOnly.day && r.isPresent);

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            child: GlassCard(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundImage: child.photoUrl != null ? NetworkImage(child.photoUrl!) : null,
                    child: child.photoUrl == null ? Text(child.firstName[0]) : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(child.fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text('Taux de présence: ${enrollment.attendanceRate.toStringAsFixed(1)}%', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                      ],
                    ),
                  ),
                  Transform.scale(
                    scale: 1.2,
                    child: Checkbox(
                      value: isPresent,
                      activeColor: Colors.green,
                      onChanged: (val) {
                        _toggleAttendance(context, provider, enrollment, dateOnly, val ?? false);
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        } catch (e) {
          return const SizedBox.shrink();
        }
      },
    );
  }

  void _toggleAttendance(BuildContext context, ChildEnrollmentProvider provider, EnrollmentModel enrollment, DateTime date, bool present) async {
    final List<AttendanceRecord> newHistory = List<AttendanceRecord>.from(enrollment.attendanceHistory);
    newHistory.removeWhere((r) => r.date.year == date.year && r.date.month == date.month && r.date.day == date.day);
    newHistory.add(AttendanceRecord(date: date, isPresent: present));

    await provider.updateEnrollment(
      enrollmentId: enrollment.id,
      attendanceHistory: newHistory.map((r) => r.toMap()).toList(),
    );
  }
}
