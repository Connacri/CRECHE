import 'package:flutter/material.dart';
import '../models/session_schedule_model.dart';
import '../models/course_model_complete.dart';

class AddSessionDialog extends StatefulWidget {
  final List<CourseModel> courses;
  final List<Map<String, dynamic>> coaches;
  final DayOfWeek? initialDay;
  final TimeSlot? initialTimeSlot;
  final SessionSchedule? sessionToEdit;

  const AddSessionDialog({
    super.key,
    required this.courses,
    required this.coaches,
    this.initialDay,
    this.initialTimeSlot,
    this.sessionToEdit,
  });

  @override
  State<AddSessionDialog> createState() => _AddSessionDialogState();
}

class _AddSessionDialogState extends State<AddSessionDialog> {
  final _formKey = GlobalKey<FormState>();
  late String _selectedCourseId;
  late DayOfWeek _selectedDay;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  String? _selectedCoachId;
  final _roomController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final edit = widget.sessionToEdit;
    _selectedCourseId = edit?.courseId ?? (widget.courses.isNotEmpty ? widget.courses.first.id : '');
    _selectedDay = edit?.dayOfWeek ?? widget.initialDay ?? DayOfWeek.monday;

    if (edit != null) {
      _startTime = TimeOfDay.fromDateTime(edit.timeSlot.startTime);
      _endTime = TimeOfDay.fromDateTime(edit.timeSlot.endTime);
      _selectedCoachId = edit.coachId;
      _roomController.text = edit.roomName ?? '';
    } else {
      _startTime = widget.initialTimeSlot != null
          ? TimeOfDay.fromDateTime(widget.initialTimeSlot!.startTime)
          : const TimeOfDay(hour: 9, minute: 0);
      _endTime = widget.initialTimeSlot != null
          ? TimeOfDay.fromDateTime(widget.initialTimeSlot!.endTime)
          : const TimeOfDay(hour: 10, minute: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.sessionToEdit == null ? 'Nouvelle Session' : 'Modifier Session'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: _selectedCourseId,
                decoration: const InputDecoration(labelText: 'Cours'),
                items: widget.courses.map((c) => DropdownMenuItem(
                  value: c.id,
                  child: Text(c.title),
                )).toList(),
                onChanged: (val) => setState(() => _selectedCourseId = val!),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<DayOfWeek>(
                value: _selectedDay,
                decoration: const InputDecoration(labelText: 'Jour'),
                items: DayOfWeek.values.map((d) => DropdownMenuItem(
                  value: d,
                  child: Text(d.displayName),
                )).toList(),
                onChanged: (val) => setState(() => _selectedDay = val!),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ListTile(
                      title: const Text('Début'),
                      subtitle: Text(_startTime.format(context)),
                      onTap: () async {
                        final time = await showTimePicker(context: context, initialTime: _startTime);
                        if (time != null) setState(() => _startTime = time);
                      },
                    ),
                  ),
                  Expanded(
                    child: ListTile(
                      title: const Text('Fin'),
                      subtitle: Text(_endTime.format(context)),
                      onTap: () async {
                        final time = await showTimePicker(context: context, initialTime: _endTime);
                        if (time != null) setState(() => _endTime = time);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String?>(
                value: _selectedCoachId,
                decoration: const InputDecoration(labelText: 'Coach'),
                items: [
                  const DropdownMenuItem<String?>(value: null, child: Text('Aucun coach')),
                  ...widget.coaches.map((c) => DropdownMenuItem<String?>(
                    value: c['id'],
                    child: Text(c['name'] ?? 'Inconnu'),
                  )),
                ],
                onChanged: (val) => setState(() => _selectedCoachId = val),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _roomController,
                decoration: const InputDecoration(labelText: 'Salle / Lieu', hintText: 'ex: Salle 101'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
        if (widget.sessionToEdit != null)
          TextButton(
            onPressed: () => Navigator.pop(context, 'delete'),
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final now = DateTime.now();
              final start = DateTime(now.year, now.month, now.day, _startTime.hour, _startTime.minute);
              final end = DateTime(now.year, now.month, now.day, _endTime.hour, _endTime.minute);

              final session = SessionSchedule(
                id: widget.sessionToEdit?.id ?? '',
                courseId: _selectedCourseId,
                enrollmentId: '', // Non utilisé pour les templates d'horaires
                dayOfWeek: _selectedDay,
                timeSlot: TimeSlot(startTime: start, endTime: end),
                startDate: DateTime.now(), // Devrait être lié à la saison du cours
                endDate: DateTime.now().add(const Duration(days: 90)),
                currentEnrollment: 0,
                maxCapacity: 20,
                coachId: _selectedCoachId,
                roomName: _roomController.text,
              );
              Navigator.pop(context, session);
            }
          },
          child: const Text('Enregistrer'),
        ),
      ],
    );
  }
}
