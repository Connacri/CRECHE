import 'package:flutter/material.dart';
import '../models/session_schedule_model.dart';
import '../models/course_model_complete.dart';
import '../models/user_model.dart';
import '../providers/course_provider_complete.dart';
import 'package:provider/provider.dart';

class AddSessionDialog extends StatefulWidget {
  final List<CourseModel> courses;
  final List<UserModel> coaches;
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
  String? _roomName;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.sessionToEdit != null) {
      _selectedCourseId = widget.sessionToEdit!.courseId;
      _selectedDay = widget.sessionToEdit!.dayOfWeek;
      _startTime = TimeOfDay.fromDateTime(widget.sessionToEdit!.timeSlot.startTime);
      _endTime = TimeOfDay.fromDateTime(widget.sessionToEdit!.timeSlot.endTime);
      _selectedCoachId = widget.sessionToEdit!.coachId;
      _roomName = widget.sessionToEdit!.roomName;
    } else {
      _selectedCourseId = widget.courses.isNotEmpty ? widget.courses.first.id : "";
      _selectedDay = widget.initialDay ?? DayOfWeek.monday;
      _startTime = widget.initialTimeSlot != null
          ? TimeOfDay.fromDateTime(widget.initialTimeSlot!.startTime)
          : const TimeOfDay(hour: 9, minute: 0);
      _endTime = widget.initialTimeSlot != null
          ? TimeOfDay.fromDateTime(widget.initialTimeSlot!.endTime)
          : const TimeOfDay(hour: 10, minute: 0);
    }
  }

  Future<void> _selectTime(bool isStart) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _endTime,
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  void _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day, _startTime.hour, _startTime.minute);
    final end = DateTime(now.year, now.month, now.day, _endTime.hour, _endTime.minute);

    final schedule = SessionSchedule(
      id: widget.sessionToEdit?.id ?? "",
      courseId: _selectedCourseId,
      enrollmentId: "",
      dayOfWeek: _selectedDay,
      timeSlot: TimeSlot(startTime: start, endTime: end),
      startDate: DateTime(2024, 1, 1),
      endDate: DateTime(2025, 1, 1),
      currentEnrollment: 0,
      maxCapacity: 30,
      coachId: _selectedCoachId,
      roomName: _roomName,
    );

    final provider = context.read<CourseProvider>();
    bool success;
    if (widget.sessionToEdit != null) {
      success = await provider.updateSchedule(schedule.id, schedule.toSupabase());
    } else {
      success = await provider.createSchedule(schedule);
    }

    if (mounted) {
      setState(() => _isSaving = false);
      if (success) {
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erreur lors de la sauvegarde')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.sessionToEdit != null ? 'Modifier la session' : 'Nouvelle session'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: _selectedCourseId,
                items: widget.courses.map((c) => DropdownMenuItem(value: c.id, child: Text(c.title))).toList(),
                onChanged: (val) => setState(() => _selectedCourseId = val!),
                decoration: const InputDecoration(labelText: 'Cours'),
              ),
              DropdownButtonFormField<DayOfWeek>(
                initialValue: _selectedDay,
                items: DayOfWeek.values.map((d) => DropdownMenuItem(value: d, child: Text(d.displayName))).toList(),
                onChanged: (val) => setState(() => _selectedDay = val!),
                decoration: const InputDecoration(labelText: 'Jour'),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ListTile(
                      title: const Text('Début'),
                      subtitle: Text(_startTime.format(context)),
                      onTap: () => _selectTime(true),
                    ),
                  ),
                  Expanded(
                    child: ListTile(
                      title: const Text('Fin'),
                      subtitle: Text(_endTime.format(context)),
                      onTap: () => _selectTime(false),
                    ),
                  ),
                ],
              ),
              DropdownButtonFormField<String?>(
                initialValue: _selectedCoachId,
                items: [
                  const DropdownMenuItem(value: null, child: Text('Non assigné')),
                  ...widget.coaches.map((c) => DropdownMenuItem(value: c.uid, child: Text(c.name))),
                ],
                onChanged: (val) => setState(() => _selectedCoachId = val),
                decoration: const InputDecoration(labelText: 'Coach'),
              ),
              TextFormField(
                initialValue: _roomName,
                decoration: const InputDecoration(labelText: 'Salle / Endroit'),
                onChanged: (val) => _roomName = val,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
        ElevatedButton(
          onPressed: _isSaving ? null : _save,
          child: _isSaving ? const CircularProgressIndicator() : const Text('Enregistrer'),
        ),
      ],
    );
  }
}
