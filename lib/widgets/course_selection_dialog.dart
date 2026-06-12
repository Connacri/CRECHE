import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/child_model_complete.dart';
import '../providers/child_enrollment_provider.dart';
import '../providers/course_provider_complete.dart';
import '../providers/auth_provider_v2.dart';

class CourseSelectionDialog extends StatefulWidget {
  final ChildModel child;
  const CourseSelectionDialog({super.key, required this.child});

  @override
  State<CourseSelectionDialog> createState() => _CourseSelectionDialogState();
}

class _CourseSelectionDialogState extends State<CourseSelectionDialog> {
  final List<String> _selectedCourseIds = [];
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    final courseProvider = context.watch<CourseProvider>();
    final childProvider = context.watch<ChildEnrollmentProvider>();
    final courses = courseProvider.courses;

    return AlertDialog(
      title: Text('Inscrire ${widget.child.firstName}'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: courses.length,
          itemBuilder: (context, i) {
            final course = courses[i];
            final isEnrolled = childProvider.isChildEnrolledInCourse(widget.child.id, course.id);
            final isSelected = _selectedCourseIds.contains(course.id);

            return CheckboxListTile(
              title: Text(course.title),
              subtitle: Text('${course.price?.toStringAsFixed(0) ?? "0"} DA'),
              value: isEnrolled || isSelected,
              onChanged: isEnrolled ? null : (val) {
                setState(() {
                  if (val == true) {
                    _selectedCourseIds.add(course.id);
                  } else {
                    _selectedCourseIds.remove(course.id);
                  }
                });
              },
            );
          },
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
        ElevatedButton(
          onPressed: (_selectedCourseIds.isEmpty || _isSubmitting) ? null : _submit,
          child: _isSubmitting
            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
            : const Text('Confirmer'),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    setState(() => _isSubmitting = true);
    final provider = context.read<ChildEnrollmentProvider>();
    final courseProvider = context.read<CourseProvider>();

    final authProvider = context.read<AuthProviderV2>();
    final parentId = authProvider.userData?['id'] ?? '';

    bool allSuccess = true;
    for (final courseId in _selectedCourseIds) {
      final course = courseProvider.courses.firstWhere((c) => c.id == courseId);
      final success = await provider.createEnrollment(
        courseId: courseId,
        childId: widget.child.id,
        parentId: parentId,
        totalAmount: course.price,
      );
      if (!success) allSuccess = false;
    }

    if (mounted) {
      setState(() => _isSubmitting = false);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(allSuccess ? 'Inscriptions réussies' : 'Certaines inscriptions ont échoué')),
      );
    }
  }
}
