import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/school_slot_model.dart';
import '../models/session_schedule_model.dart';
import '../providers/school_provider.dart';
import '../providers/auth_provider_v2.dart';
import '../widgets/glass_card.dart';

class SchoolSlotsManagementScreen extends StatefulWidget {
  const SchoolSlotsManagementScreen({super.key});

  @override
  State<SchoolSlotsManagementScreen> createState() => _SchoolSlotsManagementScreenState();
}

class _SchoolSlotsManagementScreenState extends State<SchoolSlotsManagementScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = context.read<AuthProviderV2>().currentUser?.uid;
      if (userId != null) {
        context.read<SchoolProvider>().loadSchoolSlots(userId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes Horaires Disponibles'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddSlotDialog,
          ),
        ],
      ),
      body: Consumer<SchoolProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final slots = provider.currentSchoolSlots;
          if (slots.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Aucun créneau défini.'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _showAddSlotDialog,
                    child: const Text('Ajouter mon premier créneau'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: slots.length,
            itemBuilder: (context, index) {
              final slot = slots[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: GlassCard(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              slot.dayOfWeek.displayName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              slot.timeSlot.displayTime,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            if (slot.isOccupied)
                              const Padding(
                                padding: EdgeInsets.only(top: 4),
                                child: Text(
                                  'Occupé',
                                  style: TextStyle(
                                    color: Colors.orange,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: slot.isOccupied
                          ? null
                          : () => _confirmDelete(slot),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _confirmDelete(SchoolSlotModel slot) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer ce créneau ?'),
        content: const Text('Cette action est irréversible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              context.read<SchoolProvider>().deleteSlot(slot.id, slot.schoolId);
              Navigator.pop(context);
            },
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showAddSlotDialog() {
    DayOfWeek selectedDay = DayOfWeek.monday;
    TimeOfDay startTime = const TimeOfDay(hour: 9, minute: 0);
    TimeOfDay endTime = const TimeOfDay(hour: 10, minute: 0);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Ajouter un créneau'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<DayOfWeek>(
                initialValue: selectedDay,
                items: DayOfWeek.values.map((day) => DropdownMenuItem(
                  value: day,
                  child: Text(day.displayName),
                )).toList(),
                onChanged: (val) {
                  if (val != null) setDialogState(() => selectedDay = val);
                },
                decoration: const InputDecoration(labelText: 'Jour'),
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('Début'),
                subtitle: Text(startTime.format(context)),
                trailing: const Icon(Icons.access_time),
                onTap: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: startTime,
                  );
                  if (picked != null) setDialogState(() => startTime = picked);
                },
              ),
              ListTile(
                title: const Text('Fin'),
                subtitle: Text(endTime.format(context)),
                trailing: const Icon(Icons.access_time),
                onTap: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: endTime,
                  );
                  if (picked != null) setDialogState(() => endTime = picked);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                final now = DateTime.now();
                final start = DateTime(now.year, now.month, now.day, startTime.hour, startTime.minute);
                final end = DateTime(now.year, now.month, now.day, endTime.hour, endTime.minute);

                final userId = context.read<AuthProviderV2>().currentUser?.uid;
                if (userId != null) {
                  final newSlot = SchoolSlotModel(
                    id: '',
                    schoolId: userId,
                    dayOfWeek: selectedDay,
                    timeSlot: TimeSlot(startTime: start, endTime: end),
                    createdAt: DateTime.now(),
                    updatedAt: DateTime.now(),
                  );
                  context.read<SchoolProvider>().addSlot(newSlot);
                }
                Navigator.pop(context);
              },
              child: const Text('Ajouter'),
            ),
          ],
        ),
      ),
    );
  }
}
