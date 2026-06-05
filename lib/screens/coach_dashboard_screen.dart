import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/course_model_complete.dart';
import '../models/enrollment_model_complete.dart';
import '../models/child_model_complete.dart';
import '../models/user_model.dart';
import '../models/session_schedule_model.dart';
import '../providers/course_provider_complete.dart';
import '../providers/child_enrollment_provider.dart';
import '../providers/auth_provider_v2.dart';
import '../widgets/glass_card.dart';
import '../widgets/interactive_weekly_timetable.dart';
import '../services/club_service.dart';
import 'create_course_screen.dart';
import 'profile_screen.dart';
import 'associate_to_school_screen.dart';

class CoachDashboardScreen extends StatefulWidget {
  const CoachDashboardScreen({super.key});

  @override
  State<CoachDashboardScreen> createState() => _CoachDashboardScreenState();
}

class _CoachDashboardScreenState extends State<CoachDashboardScreen> {
  int _selectedIndex = 0;
  final ClubService _clubService = ClubService();
  Map<String, String> _clubNames = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProviderV2>();
      if (auth.currentUser != null) {
        context.read<CourseProvider>().loadUserCourses(auth.currentUser!.uid);
        context.read<ChildEnrollmentProvider>().loadOwnerEnrollments(auth.currentUser!.uid);
        _loadClubs();
      }
    });
  }

  Future<void> _loadClubs() async {
    try {
      final clubs = await _clubService.getAvailableClubs();
      setState(() {
        _clubNames = {for (var c in clubs) c.uid: c.name};
      });
    } catch (e) {
      print('Error loading clubs: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildPage(),
      bottomNavigationBar: _buildBottomNav(),
      floatingActionButton: _selectedIndex == 0 ? FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const CreateCourseScreen()),
        ),
        child: const Icon(Icons.add),
      ) : null,
    );
  }

  Widget _buildPage() {
    switch (_selectedIndex) {
      case 0: return _buildDashboard();
      case 1: return const _EnrollmentsPage();
      case 2: return const _ClubTimetablePage();
      case 3: return const ProfileScreen();
      default: return const SizedBox.shrink();
    }
  }

  Widget _buildDashboard() {
    final auth = context.watch<AuthProviderV2>();
    final user = auth.userData != null ? UserModel.fromSupabase(auth.userData!) : null;

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 120,
          flexibleSpace: FlexibleSpaceBar(
            title: Text('Salut, ${user?.name ?? "Coach"}',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            background: Container(color: Theme.of(context).colorScheme.primary),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(24),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              const Text('Mes Cours', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 16),
              _buildCourseList(),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildCourseList() {
    return Consumer<CourseProvider>(
      builder: (context, provider, _) {
        final userCourses = provider.userCourses;
        if (userCourses.isEmpty) return const Text('Aucun cours programmé');
        return Column(
          children: userCourses.map((course) {
            final clubName = _clubNames[course.clubId] ?? "Indépendant";
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: GlassCard(
                padding: const EdgeInsets.all(8),
                child: ListTile(
                  title: Text(course.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${course.category.displayName} • ${course.currentStudents}/${course.maxStudents} élèves'),
                      Text('Club: $clubName', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
                      Text('Lieu: ${course.location.address}', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.business, color: Colors.green, size: 20),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => AssociateToSchoolScreen(course: course)),
                          ).then((_) => _loadClubs());
                        },
                        tooltip: 'Associer à un club',
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => CreateCourseScreen(courseToEdit: course)),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                        onPressed: () => _confirmDelete(context, course),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, CourseModel course) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Supprimer le cours'),
        content: Text('Voulez-vous vraiment supprimer "${course.title}" ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Annuler')),
          TextButton(
            onPressed: () async {
              final success = await context.read<CourseProvider>().deleteCourse(course.id);
              if (mounted) {
                Navigator.pop(dialogContext);
                if (!success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Erreur lors de la suppression')),
                  );
                }
              }
            },
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    final childProvider = context.watch<ChildEnrollmentProvider>();
    final pendingCount = childProvider.ownerEnrollmentsDetailed
        .where((e) => e['enrollment']['status'] == 'pending').length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: GlassCard(
        opacity: 0.8,
        borderRadius: BorderRadius.circular(30),
        child: BottomNavigationBar(
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.transparent,
          currentIndex: _selectedIndex,
          onTap: (i) => setState(() => _selectedIndex = i),
          selectedItemColor: Theme.of(context).colorScheme.primary,
          unselectedItemColor: Theme.of(context).colorScheme.onSurfaceVariant,
          items: [
            const BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded), label: 'Dashboard'),
            BottomNavigationBarItem(
              icon: Badge(
                label: Text('$pendingCount'),
                isLabelVisible: pendingCount > 0,
                child: const Icon(Icons.people_alt_rounded),
              ), 
              label: 'Inscriptions',
            ),
            const BottomNavigationBarItem(icon: Icon(Icons.calendar_month), label: 'Clubs'),
            const BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Profil'),
          ],
        ),
      ),
    );
  }
}

class _EnrollmentsPage extends StatelessWidget {
  const _EnrollmentsPage();

  @override
  Widget build(BuildContext context) {
    final childProvider = context.watch<ChildEnrollmentProvider>();
    final enrollments = childProvider.ownerEnrollmentsDetailed;

    if (enrollments.isEmpty) {
      return const Scaffold(
        body: Center(child: Text('Aucune inscription pour le moment.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Gestion des inscriptions')),
      body: ListView.builder(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
        itemCount: enrollments.length,
        itemBuilder: (context, index) {
          final item = enrollments[index];
          final enrollmentJson = item['enrollment'] as Map<String, dynamic>;
          final childJson = (item["child"] as Map<String, dynamic>?) ?? ChildModel.mock().toSupabase();
          final courseJson = item['course'] as Map<String, dynamic>;

          final enrollment = EnrollmentModel.fromSupabase(enrollmentJson);
          final child = ChildModel.fromSupabase(childJson);
          final course = CourseModel.fromSupabase(courseJson);

          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: GlassCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundImage: child.photoUrl != null ? CachedNetworkImageProvider(child.photoUrl!) : null,
                        child: child.photoUrl == null ? Text(child.firstName[0]) : null,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(child.fullName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            Text('S\'inscrit à : ${course.title}', style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.primary)),
                          ],
                        ),
                      ),
                      _buildStatusBadge(enrollment.status),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Inscrit le ${_formatDate(enrollment.enrolledAt)}', style: const TextStyle(fontSize: 11, color: Colors.black54)),
                      Row(
                        children: [
                          TextButton.icon(
                            onPressed: () => _showDetails(context, child, enrollment),
                            icon: const Icon(Icons.visibility, size: 16),
                            label: const Text('Détails', style: TextStyle(fontSize: 12)),
                          ),
                          if (enrollment.status == EnrollmentStatus.pending) ...[
                            IconButton(
                              icon: const Icon(Icons.check_circle, color: Colors.green),
                              onPressed: () => _updateStatus(context, enrollment.id, EnrollmentStatus.approved),
                              tooltip: 'Approuver',
                            ),
                            IconButton(
                              icon: const Icon(Icons.cancel, color: Colors.red),
                              onPressed: () => _updateStatus(context, enrollment.id, EnrollmentStatus.rejected),
                              tooltip: 'Refuser',
                            ),
                          ] else if (enrollment.status == EnrollmentStatus.approved) ...[
                            if (enrollment.paymentStatus != PaymentStatus.paid)
                              TextButton.icon(
                                onPressed: () => _confirmPayment(context, enrollment.id),
                                icon: const Icon(Icons.payments, size: 16, color: Colors.green),
                                label: const Text('Confirm. Paiement', style: TextStyle(fontSize: 12, color: Colors.green)),
                              ),
                             TextButton.icon(
                              onPressed: () => _updateStatus(context, enrollment.id, EnrollmentStatus.cancelled),
                              icon: const Icon(Icons.remove_circle_outline, size: 16, color: Colors.grey),
                              label: const Text('Annuler', style: TextStyle(fontSize: 12, color: Colors.grey)),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showDetails(BuildContext context, ChildModel child, EnrollmentModel enrollment) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => GlassCard(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[400], borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 24),
              Row(
                children: [
                  CircleAvatar(radius: 30, backgroundImage: child.photoUrl != null ? CachedNetworkImageProvider(child.photoUrl!) : null),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(child.fullName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                      Text('Âge: ${child.age} ans'),
                    ],
                  ),
                ],
              ),
              const Divider(height: 32),
              const Text('Informations Médicales', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              Text('Allergies: ${child.medicalInfo.allergies.isEmpty ? "Aucune" : child.medicalInfo.allergies.join(", ")}'),
              Text('Médicaments: ${child.medicalInfo.medications.isEmpty ? "Aucun" : child.medicalInfo.medications.join(", ")}'),
              Text('Note: ${child.medicalInfo.additionalNotes ?? "N/A"}'),
              const Divider(height: 32),
              const Text('Documents', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              if (child.birthCertificateUrl != null)
                TextButton.icon(onPressed: () {}, icon: const Icon(Icons.file_present), label: const Text('Acte de naissance')),
              if (child.medicalCertificateUrl != null)
                TextButton.icon(onPressed: () {}, icon: const Icon(Icons.file_present), label: const Text('Certificat médical')),
              if (child.birthCertificateUrl == null && child.medicalCertificateUrl == null)
                const Text('Aucun document fourni', style: TextStyle(fontStyle: FontStyle.italic)),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmPayment(BuildContext context, String enrollmentId) async {
    final provider = context.read<ChildEnrollmentProvider>();
    final success = await provider.updateEnrollment(
      enrollmentId: enrollmentId,
      status: EnrollmentStatus.completed,
      paymentStatus: PaymentStatus.paid,
    );
    if (success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Paiement confirmé et inscription finalisée !')));
    }
  }

  void _updateStatus(BuildContext context, String enrollmentId, EnrollmentStatus status) async {
    final provider = context.read<ChildEnrollmentProvider>();
    final success = await provider.updateEnrollment(enrollmentId: enrollmentId, status: status);
    
    if (success && context.mounted) {
      final auth = context.read<AuthProviderV2>();
      context.read<CourseProvider>().loadUserCourses(auth.currentUser!.uid);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Statut mis à jour : ${status.displayName}')));
    }
  }

  Widget _buildStatusBadge(EnrollmentStatus status) {
    Color color;
    switch (status) {
      case EnrollmentStatus.approved: color = Colors.green; break;
      case EnrollmentStatus.pending: color = Colors.orange; break;
      case EnrollmentStatus.rejected: color = Colors.red; break;
      case EnrollmentStatus.cancelled: color = Colors.grey; break;
      case EnrollmentStatus.completed: color = Colors.blue; break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10), border: Border.all(color: color.withValues(alpha: 0.2))),
      child: Text(status.displayName, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold)),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _ClubTimetablePage extends StatefulWidget {
  const _ClubTimetablePage();

  @override
  State<_ClubTimetablePage> createState() => _ClubTimetablePageState();
}

class _ClubTimetablePageState extends State<_ClubTimetablePage> {
  UserModel? _selectedClub;
  List<UserModel> _clubs = [];
  List<SessionSchedule> _schedules = [];
  List<CourseModel> _allCourses = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    try {
      final clubService = ClubService();
      _clubs = await clubService.getAvailableClubs();
      if (_clubs.isNotEmpty) {
        _selectedClub = _clubs.first;
        await _loadSchedules(_selectedClub!.uid);
      }
    } catch (e) {
      print('Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadSchedules(String clubId) async {
    // This is a bit complex as we need ALL schedules for this club from ALL coaches
    // For now, let us fetch the schedules for this school_id from session_schedules table
    final clubService = ClubService();
    // We might need a new method in ClubService or SchoolService to fetch all schedules for a school
    // Let's use Supabase directly or assume it's available
    final response = await clubService.adminClient
        .from('session_schedules')
        .select('*, courses(*)')
        .eq('school_id', clubId);

    final List<dynamic> data = response;
    setState(() {
      _schedules = data.map((json) => SessionSchedule.fromSupabase(json)).toList();
      _allCourses = data.map((json) => CourseModel.fromSupabase(json['courses'])).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Disponibilité des Clubs')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: DropdownButtonFormField<UserModel>(
              value: _selectedClub,
              items: _clubs.map((c) => DropdownMenuItem(value: c, child: Text(c.name))).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() => _selectedClub = val);
                  _loadSchedules(val.uid);
                }
              },
              decoration: const InputDecoration(labelText: 'Sélectionner un Club'),
            ),
          ),
          if (_isLoading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else
            Expanded(
              child: InteractiveWeeklyTimetable(
                schedules: _schedules,
                courses: _allCourses,
                onEmptySlotTap: (day, slot) {},
                onSessionTap: (session) {},
              ),
            ),
        ],
      ),
    );
  }
}
