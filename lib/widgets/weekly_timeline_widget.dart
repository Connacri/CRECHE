import 'package:flutter/material.dart';
import '../models/session_schedule_model.dart';
import '../models/course_model_complete.dart';
import '../models/child_model_complete.dart';
import 'glass_card.dart';

class WeeklyTimeline extends StatelessWidget {
  final Map<DateTime, List<SessionSchedule>> schedulesByDate;
  final Map<String, CourseModel> coursesById;
  final Map<String, ChildModel> childrenById;
  final Function(SessionSchedule) onSessionTap;

  const WeeklyTimeline({
    super.key,
    required this.schedulesByDate,
    required this.coursesById,
    required this.childrenById,
    required this.onSessionTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      itemCount: schedulesByDate.length,
      itemBuilder: (context, index) {
        final date = schedulesByDate.keys.elementAt(index);
        final sessions = schedulesByDate[date]!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                _formatDate(date),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            ...sessions.map((session) {
              final course = coursesById[session.courseId];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: GlassCard(
                  onTap: () => onSessionTap(session),
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      _buildTimeColumn(session),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(course?.title ?? 'Session', style: const TextStyle(fontWeight: FontWeight.bold)),
                            Text(session.timeSlot.displayTime, style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7))),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right, size: 16, color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
                    ],
                  ),
                ),
              );
            }),
          ],
        );
      },
    );
  }

  Widget _buildTimeColumn(SessionSchedule session) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(session.timeSlot.displayTime.split(' - ').first, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blue)),
    );
  }

  String _formatDate(DateTime date) {
    final days = ['Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche'];
    final months = ['Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Juin', 'Juil', 'Août', 'Sep', 'Oct', 'Nov', 'Déc'];
    return '${days[date.weekday - 1]} ${date.day} ${months[date.month - 1]}';
  }
}
