import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/course_provider_complete.dart';
import '../providers/auth_provider_v2.dart';
import '../models/course_model_complete.dart';
import '../screens/create_course_screen.dart';
import 'glass_card.dart';

class MyCoursesPage extends StatefulWidget {
  const MyCoursesPage({super.key});

  @override
  State<MyCoursesPage> createState() => _MyCoursesPageState();
}

class _MyCoursesPageState extends State<MyCoursesPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProviderV2>();
      if (auth.currentUser != null) {
        context.read<CourseProvider>().subscribeToUserCourses(auth.currentUser!.uid);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CourseProvider>();
    final courses = provider.userCourses;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Gestion des Cours', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    Text('${courses.length} cours au total', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
                IconButton.filled(
                  icon: const Icon(Icons.add),
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateCourseScreen())),
                ),
              ],
            ),
          ),
          if (provider.isLoading && courses.isEmpty)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (courses.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.school_outlined, size: 64, color: Colors.grey[300]),
                    const SizedBox(height: 16),
                    const Text("Aucun cours créé pour le moment.", style: TextStyle(color: Colors.grey)),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateCourseScreen())),
                      child: const Text('Créer mon premier cours'),
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                itemCount: courses.length,
                itemBuilder: (context, index) {
                  final course = courses[index];
                  return _CourseItem(course: course);
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _CourseItem extends StatelessWidget {
  final CourseModel course;
  const _CourseItem({required this.course});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (course.images.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      course.images.first.supabaseUrl ?? '',
                      width: 70,
                      height: 70,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildPlaceholder(),
                    ),
                  )
                else
                  _buildPlaceholder(),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(course.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 4),
                      _buildInfoChip(Icons.category_outlined, course.category.displayName),
                      const SizedBox(height: 4),
                      _buildInfoChip(Icons.people_outline, '${course.currentStudents} / ${course.maxStudents} inscrits'),
                    ],
                  ),
                ),
                Column(
                  children: [
                    const Text('Actif', style: TextStyle(fontSize: 10, color: Colors.grey)),
                    Switch.adaptive(
                      value: course.isActive,
                      activeColor: Colors.green,
                      onChanged: (val) {
                        context.read<CourseProvider>().updateCourse(courseId: course.id, isActive: val);
                      },
                    ),
                  ],
                ),
              ],
            ),
            const Divider(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${course.price?.toStringAsFixed(0) ?? "0"} DA',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blue),
                ),
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CreateCourseScreen(courseToEdit: course))),
                      icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                      tooltip: 'Modifier',
                    ),
                    IconButton(
                      onPressed: () => _confirmDelete(context),
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      tooltip: 'Supprimer',
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
      child: const Icon(Icons.school, size: 30, color: Colors.grey),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.grey),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le cours ?'),
        content: Text('Cette action supprimera définitivement "${course.title}".'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () {
              context.read<CourseProvider>().deleteCourse(course.id);
              Navigator.pop(context);
            },
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}
