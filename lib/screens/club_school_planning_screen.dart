import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/schedule_provider.dart';
import '../models/session_schedule_model.dart';

class ClubSchoolPlanningScreen extends StatefulWidget {
  const ClubSchoolPlanningScreen({super.key});

  @override
  State<ClubSchoolPlanningScreen> createState() => _ClubSchoolPlanningScreenState();
}

class _ClubSchoolPlanningScreenState extends State<ClubSchoolPlanningScreen> {
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
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => provider.loadWeeklySchedule(),
          ),
        ],
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(Colors.white.withOpacity(0.08)),
                    dataRowMinHeight: 70,
                    columns: List.generate(
                      7,
                      (i) => DataColumn(
                        label: Text(
                          _getDayName(i + 1),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    rows: _buildRows(schedule),
                  ),
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // TODO: Ouvrir modal de création de session
        },
        icon: const Icon(Icons.add),
        label: const Text('Nouvelle séance'),
      ),
    );
  }

  String _getDayName(int day) {
    const days = ['Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche'];
    return days[day - 1];
  }

  List<DataRow> _buildRows(Map<int, List<SessionSchedule>> schedule) {
    final rows = <DataRow>[];
    // Créneaux horaires de 8h à 18h
    for (int hour = 8; hour <= 18; hour++) {
      final cells = <DataCell>[];
      for (int day = 1; day <= 7; day++) {
        final daySessions = schedule[day] ?? [];
        final hourSessions = daySessions.where((s) => s.timeSlot.start.hour == hour).toList();

        if (hourSessions.isEmpty) {
          cells.add(const DataCell(SizedBox(height: 60)));
        } else {
          cells.add(
            DataCell(
              Column(
                mainAxisSize: MainAxisSize.min,
                children: hourSessions.map((s) => _buildSessionCard(s)).toList(),
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
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Cours ${session.courseId.substring(0, 8)}...", // À remplacer par titre réel via join
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
          Text(
            '${session.timeSlot.start.format(context)} - ${session.timeSlot.end.format(context)}',
            style: TextStyle(color: Colors.white.withOpacity(0.9)),
          ),
          if (session.roomName != null) Text('📍 ${session.roomName}'),
          if (session.coachId != null) Text('👨‍🏫 ${session.coachId}'),
        ],
      ),
    );
  }
}