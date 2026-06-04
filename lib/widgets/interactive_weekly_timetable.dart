import 'package:flutter/material.dart';
import '../models/session_schedule_model.dart';
import '../models/course_model_complete.dart';
import 'glass_card.dart';

class InteractiveWeeklyTimetable extends StatelessWidget {
  final List<SessionSchedule> schedules;
  final List<CourseModel> courses;
  final Function(DayOfWeek day, TimeSlot slot) onEmptySlotTap;
  final Function(SessionSchedule session) onSessionTap;
  final Map<String, String> coachesNames;

  const InteractiveWeeklyTimetable({
    super.key,
    required this.schedules,
    required this.courses,
    required this.onEmptySlotTap,
    required this.onSessionTap,
    this.coachesNames = const {},
  });

  @override
  Widget build(BuildContext context) {
    final days = DayOfWeek.values;
    // On définit des tranches horaires de 1h de 8h à 20h
    final hours = List.generate(13, (index) => 8 + index);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: 800, // Largeur fixe pour le défilement horizontal
        child: Column(
          children: [
            // Header: Jours
            Row(
              children: [
                const SizedBox(width: 60), // Espace pour l'heure
                ...days.map((day) => Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    alignment: Alignment.center,
                    child: Text(
                      day.displayName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                )),
              ],
            ),
            // Grille
            Expanded(
              child: SingleChildScrollView(
                child: Stack(
                  children: [
                    // Lignes d'heures
                    Column(
                      children: hours.map((hour) => _buildHourRow(context, hour)).toList(),
                    ),
                    // Sessions positionnées
                    ...schedules.map((session) => _buildSessionWidget(context, session)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHourRow(BuildContext context, int hour) {
    final timeStr = '${hour.toString().padLeft(2, "0")}:00';
    return SizedBox(
      height: 100, // Hauteur par heure
      child: Row(
        children: [
          Container(
            width: 60,
            alignment: Alignment.topCenter,
            padding: const EdgeInsets.only(top: 8),
            child: Text(timeStr, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          ),
          ...DayOfWeek.values.map((day) => Expanded(
            child: GestureDetector(
              onTap: () => onEmptySlotTap(
                day,
                TimeSlot(
                  startTime: DateTime(2024, 1, 1, hour, 0),
                  endTime: DateTime(2024, 1, 1, hour + 1, 0),
                )
              ),
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.withValues(alpha: 0.2), width: 0.5),
                ),
              ),
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildSessionWidget(BuildContext context, SessionSchedule session) {
    final dayIndex = session.dayOfWeek.index;
    final startHour = session.timeSlot.startTime.hour;
    final startMinute = session.timeSlot.startTime.minute;
    final durationHours = session.timeSlot.duration.inMinutes / 60.0;

    // Calcul de la position
    // L'heure 8 est à top: 0
    final top = (startHour - 8 + (startMinute / 60.0)) * 100;
    final height = durationHours * 100;
    final left = 60 + (dayIndex * (740 / 7)); // 740 = 800 - 60
    final width = 740 / 7;

    final course = courses.firstWhere((c) => c.id == session.courseId, orElse: () => CourseModel.mock());
    final coachName = coachesNames[session.coachId] ?? 'Coach non assigné';

    return Positioned(
      top: top,
      left: left,
      width: width,
      height: height,
      child: Padding(
        padding: const EdgeInsets.all(2.0),
        child: GlassCard(
          onTap: () => onSessionTap(session),
          opacity: 0.7,
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                course.title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),
              Text(
                coachName,
                style: const TextStyle(fontSize: 9),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                session.timeSlot.displayTime,
                style: const TextStyle(fontSize: 9),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
