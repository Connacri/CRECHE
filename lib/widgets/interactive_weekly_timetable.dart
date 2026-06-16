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
                    ..._buildAllSessions(context),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildAllSessions(BuildContext context) {
    final widgets = <Widget>[];

    for (var day in DayOfWeek.values) {
      final daySessions = schedules.where((s) => s.dayOfWeek == day).toList();
      if (daySessions.isEmpty) continue;

      // Tri par heure de début
      daySessions.sort((a, b) {
        final startA = a.timeSlot.start.hour * 60 + a.timeSlot.start.minute;
        final startB = b.timeSlot.start.hour * 60 + b.timeSlot.start.minute;
        return startA.compareTo(startB);
      });

      // Attribution des colonnes (Greedy)
      List<List<SessionSchedule>> columns = [];
      Map<String, int> sessionToCol = {};

      for (var session in daySessions) {
        int assignedCol = -1;
        for (int i = 0; i < columns.length; i++) {
          if (!columns[i].any((s) => s.overlapsInTime(session))) {
            assignedCol = i;
            break;
          }
        }
        if (assignedCol == -1) {
          assignedCol = columns.length;
          columns.add([session]);
        } else {
          columns[assignedCol].add(session);
        }
        sessionToCol[session.id] = assignedCol;
      }

      // Calcul de la largeur pour chaque session
      for (var session in daySessions) {
        final colIndex = sessionToCol[session.id]!;
        
        // Version simplifiée : si plusieurs sessions, on divise par le nombre total de colonnes créées pour ce jour
        final usedColsInOverlap = columns.length; 

        widgets.add(_buildSessionWidget(context, session, day.index, colIndex, usedColsInOverlap));
      }
    }
    return widgets;
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
                  start: TimeOfDay(hour: hour, minute: 0),
                  end: TimeOfDay(hour: hour + 1, minute: 0),
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

  Widget _buildSessionWidget(BuildContext context, SessionSchedule session, int dayIndex, int colIndex, int totalCols) {
    final startHour = session.timeSlot.start.hour;
    final startMinute = session.timeSlot.start.minute;
    final durationHours = session.timeSlot.duration.inMinutes / 60.0;

    // Calcul de la position
    final top = (startHour - 8 + (startMinute / 60.0)) * 100;
    final height = durationHours * 100;
    
    final dayColumnWidth = 740 / 7;
    final sessionWidth = dayColumnWidth / totalCols;
    final left = 60 + (dayIndex * dayColumnWidth) + (colIndex * sessionWidth);

    final course = courses.firstWhere((c) => c.id == session.courseId, orElse: () => CourseModel.mock());
    final displayTitle = session.courseTitle ?? course.title;
    final coachName = coachesNames[session.coachId] ?? 'Coach non assigné';

    return Positioned(
      top: top,
      left: left,
      width: sessionWidth,
      height: height,
      child: Padding(
        padding: const EdgeInsets.all(1.0),
        child: GlassCard(
          onTap: () => onSessionTap(session),
          opacity: 0.8,
          padding: const EdgeInsets.all(4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                displayTitle,
                style: TextStyle(
                  fontWeight: FontWeight.bold, 
                  fontSize: totalCols > 1 ? 9 : 11,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (height > 40) ...[
                const Spacer(),
                Text(
                  coachName,
                  style: const TextStyle(fontSize: 8),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  session.timeSlot.displayTime,
                  style: const TextStyle(fontSize: 8),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
