import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/schedule_provider.dart';
import '../models/session_schedule_model.dart';
// import 'package:calendar_timeline/calendar_timeline.dart'; // déjà présent dans le projet

class SchoolPlanningScreen extends StatefulWidget {
  const SchoolPlanningScreen({super.key});

  @override
  State<SchoolPlanningScreen> createState() => _SchoolPlanningScreenState();
}

class _SchoolPlanningScreenState extends State<SchoolPlanningScreen> {
  @override
  void initState() {
    super.initState();
    context.read<ScheduleProvider>().loadWeeklySchedule();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ScheduleProvider>();
    final schedule = provider.weeklySchedule;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Planning Club & School'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () { /* Modal de filtre coach / cours */ },
          ),
        ],
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 900;
                return SingleChildScrollView(
                  scrollDirection: isWide ? Axis.horizontal : Axis.vertical,
                  child: SingleChildScrollView(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      child: DataTable(
                        headingRowColor: WidgetStateProperty.all(Colors.white.withValues(alpha: 0.1)),
                        dataRowColor: WidgetStateProperty.all(Colors.white.withValues(alpha: 0.05)),
                        border: TableBorder.all(
                          color: Colors.white.withValues(alpha: 0.2),
                          width: 1,
                        ),
                        columns: DayOfWeek.values.map(
                          (day) => DataColumn(
                            label: Text(
                              day.displayName,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ).toList(),
                        rows: _buildScheduleRows(schedule, isWide),
                      ),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () { /* Modal création de session */ },
        icon: const Icon(Icons.add),
        label: const Text('Nouvelle séance'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
    );
  }

  List<DataRow> _buildScheduleRows(Map<DayOfWeek, List<SessionSchedule>> schedule, bool isWide) {
    // Exemple simplifié : une ligne par créneau horaire fixe (8h-18h)
    // Vous pouvez améliorer avec une vraie grille temporelle
    final rows = <DataRow>[];
    final hours = List.generate(11, (i) => 8 + i); // 8h à 18h

    for (int h in hours) {
      final cells = <DataCell>[];
      for (var d in DayOfWeek.values) {
        final daySessions = schedule[d] ?? [];
        final slotSessions = daySessions.where((s) => s.timeSlot.start.hour == h).toList();

        if (slotSessions.isEmpty) {
          cells.add(const DataCell(SizedBox(height: 60)));
        } else {
          cells.add(
            DataCell(
              Column(
                mainAxisSize: MainAxisSize.min,
                children: slotSessions.map((session) => _buildSessionCard(session)).toList(),
              ),
            ),
          );
        }
      }
      rows.add(DataRow(cells: cells));
    }
    return rows;
  }

  Widget _buildSessionCard(SessionSchedule session) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1), // Glassmorphism
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            session.courseId, // Remplacer par titre du cours via join si besoin
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
          Text(
            '${session.timeSlot.start.format(context)} - ${session.timeSlot.end.format(context)}',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.8)),
          ),
          if (session.roomName != null) Text('Salle: ${session.roomName}'),
          if (session.coachId != null) Text('Coach: ${session.coachId}'),
        ],
      ),
    );
  }
}