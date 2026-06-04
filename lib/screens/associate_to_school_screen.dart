import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/course_model_complete.dart';
import '../models/school_slot_model.dart';
import '../models/user_model.dart';
import '../providers/school_provider.dart';
import '../providers/auth_provider_v2.dart';
import '../widgets/glass_card.dart';

class AssociateToSchoolScreen extends StatefulWidget {
  final CourseModel course;

  const AssociateToSchoolScreen({super.key, required this.course});

  @override
  State<AssociateToSchoolScreen> createState() => _AssociateToSchoolScreenState();
}

class _AssociateToSchoolScreenState extends State<AssociateToSchoolScreen> {
  UserModel? selectedSchool;
  SchoolSlotModel? selectedSlot;
  List<SchoolSlotModel> availableSlots = [];
  bool isLoadingSlots = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SchoolProvider>().loadSchools();
    });
  }

  Future<void> _onSchoolSelected(UserModel? school) async {
    if (school == null) return;
    setState(() {
      selectedSchool = school;
      selectedSlot = null;
      isLoadingSlots = true;
    });

    final slots = await context.read<SchoolProvider>().getAvailableSlots(school.uid);

    setState(() {
      availableSlots = slots;
      isLoadingSlots = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Associer à un Club'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Associer le cours "$widget.course.title" à un établissement partenaire.',
              style: const TextStyle(fontSize: 16),
            ),
          ),

          // Sélection de l'école
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Consumer<SchoolProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading && provider.schools.isEmpty) {
                  return const CircularProgressIndicator();
                }

                return DropdownButtonFormField<UserModel>(
                  value: selectedSchool,
                  hint: const Text('Choisir un club / école'),
                  items: provider.schools.map((school) => DropdownMenuItem(
                    value: school,
                    child: Text(school.name),
                  )).toList(),
                  onChanged: _onSchoolSelected,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.business),
                    border: OutlineInputBorder(),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 24),

          if (selectedSchool != null) ...[
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'Créneaux disponibles dans cet établissement :',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 8),

            if (isLoadingSlots)
              const Center(child: CircularProgressIndicator())
            else if (availableSlots.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('Aucun créneau disponible pour le moment.'),
              )
            else
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: availableSlots.length,
                  itemBuilder: (context, index) {
                    final slot = availableSlots[index];
                    final isSelected = selectedSlot?.id == slot.id;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: InkWell(
                        onTap: () => setState(() => selectedSlot = slot),
                        child: GlassCard(
                          padding: const EdgeInsets.all(16),
                          color: isSelected
                            ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
                            : null,
                          border: isSelected
                            ? Border.all(color: Theme.of(context).colorScheme.primary, width: 2)
                            : null,
                          child: Row(
                            children: [
                              Icon(
                                isSelected ? Icons.check_circle : Icons.circle_outlined,
                                color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey,
                              ),
                              const SizedBox(width: 16),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    slot.dayOfWeek.displayName,
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  Text(slot.timeSlot.displayTime),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],

          if (selectedSlot != null)
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveAssociation,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Confirmer l\'association'),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _saveAssociation() async {
    if (selectedSchool == null || selectedSlot == null) return;

    final success = await context.read<SchoolProvider>().associateCourseToSlot(
      courseId: widget.course.id,
      schoolId: selectedSchool!.uid,
      slot: selectedSlot!,
      startDate: widget.course.seasonStartDate,
      endDate: widget.course.seasonEndDate,
      coachId: context.read<AuthProviderV2>().currentUser?.uid,
    );

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Association réussie !')),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur lors de l\'association')),
        );
      }
    }
  }
}
