import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import "package:qr_flutter/qr_flutter.dart";

import 'package:image_cropper/image_cropper.dart';

import '../../dependences/calendar_timeline/calendar_timeline.dart';
import '../providers/auth_provider_v2.dart';
import '../models/course_model_complete.dart';
import '../models/enrollment_model_complete.dart';
import '../models/child_model_complete.dart';

import '../providers/child_enrollment_provider.dart';
import '../providers/course_provider_complete.dart';
import '../services/hybrid_image_picker.dart';
import '../widgets/modern_course_card_widget.dart';
import '../widgets/glass_card.dart';
import 'profile_screen.dart';
import 'course_details_screen.dart';

class ParentDashboard extends StatefulWidget {
  const ParentDashboard({super.key});

  @override
  State<ParentDashboard> createState() => _ParentDashboardState();
}

class _ParentDashboardState extends State<ParentDashboard> {
  int _selectedIndex = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final authProvider = context.read<AuthProviderV2>();
      if (authProvider.userData != null) {
        final uid = authProvider.userData!['id'];
        final childProvider = context.read<ChildEnrollmentProvider>();
        childProvider.subscribeToParentData(uid);
        await Future.wait([
          childProvider.loadChildren(uid),
          childProvider.loadEnrollments(uid),
          childProvider.loadAllSchedulesForParent(uid),
          childProvider.loadDailyActivities(uid, DateTime.now()),
          context.read<CourseProvider>().loadCourses(),
        ]);
      }
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProviderV2>();
    final childProvider = context.watch<ChildEnrollmentProvider>();
    
    final isGlobalLoading = auth.isLoading || childProvider.isLoading;

    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/meditation_bg.jpg',
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: Container(color: Colors.white.withValues(alpha: 0.1)),
          ),
          SafeArea(
            bottom: false,
            child: (isGlobalLoading && _isLoading) 
                ? const Center(child: CircularProgressIndicator()) 
                : _getSelectedPage(),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: GlassCard(
        opacity: 0.8,
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (i) => setState(() => _selectedIndex = i),
          backgroundColor: Colors.transparent,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: Theme.of(context).colorScheme.primary,
          unselectedItemColor: Colors.grey,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Accueil'),
            BottomNavigationBarItem(icon: Icon(Icons.school_outlined), activeIcon: Icon(Icons.school), label: 'Cours'),
            BottomNavigationBarItem(icon: Icon(Icons.receipt_long_outlined), activeIcon: Icon(Icons.receipt_long), label: 'Factures'),
            BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profil'),
          ],
        ),
      ),
    );
  }

  Widget _getSelectedPage() {
    switch (_selectedIndex) {
      case 0: return const _HomePage();
      case 1: return const _CoursesPage();
      case 2: return const _BillingPage();
      case 3: return const ProfileScreen();
      default: return const _HomePage();
    }
  }
}

class _HomePage extends StatelessWidget {
  const _HomePage();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const _UserHeader(),
        const SizedBox(height: 32),
        const _QuickChildren(),
        const SizedBox(height: 32),
        const _StatCards(),
        const SizedBox(height: 32),
        const _GeofencingSection(),
        const SizedBox(height: 32),
        const _ChildrenTimelines(),
        const SizedBox(height: 32),
        const _CalendarSection(),
        const SizedBox(height: 100),
      ],
    );
  }
}

class _UserHeader extends StatelessWidget {
  const _UserHeader();

  @override
  Widget build(BuildContext context) {
    return Selector<AuthProviderV2, (String, String?)>(
      selector: (_, auth) => (
        auth.userData?['name'] ?? 'Parent',
        auth.userData?['profile_images']?['profileImageSupabase'] ?? 
        auth.userData?['profile_images']?['profile']
      ),
      builder: (context, data, _) {
        final userName = data.$1;
        final avatarUrl = data.$2;
        
        return Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen())),
              child: CircleAvatar(
                key: ValueKey(avatarUrl ?? 'no-avatar'),
                radius: 24,
                backgroundImage: avatarUrl != null ? CachedNetworkImageProvider(avatarUrl) : null,
                child: avatarUrl == null ? const Icon(Icons.person) : null,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Bonjour,', style: TextStyle(color: Colors.grey, fontSize: 14)),
                Text(userName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              ],
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.notifications_outlined),
              onPressed: () {},
            ),
          ],
        );
      },
    );
  }
}

class _QuickChildren extends StatelessWidget {
  const _QuickChildren();

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProviderV2>();
    final parentId = auth.userData?['id'] ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Mes Enfants', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            TextButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => _ChildFormDialog(parentId: parentId),
                );
              },
              child: const Text('Ajouter'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 90,
          child: Selector<ChildEnrollmentProvider, List<ChildModel>>(
            selector: (_, provider) => provider.children,
            builder: (context, children, _) {
              if (children.isEmpty) return const Text('Aucun enfant enregistré');
              return ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: children.length,
                itemBuilder: (context, index) {
                  final child = children[index];
                  return Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: Column(
                      children: [
                        InkWell(
                          onTap: () {
                            showDialog(
                              context: context,
                              useSafeArea: false,
                              builder: (context) => _ChildProfileDialog(childId: child.id),
                            );
                          },
                          child: CircleAvatar(
                            key: ValueKey(child.photoUrl ?? child.id),
                            radius: 30,
                            backgroundImage: child.photoUrl != null ? CachedNetworkImageProvider(child.photoUrl!) : null,
                            child: child.photoUrl == null ? Text(child.firstName[0]) : null,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(child.firstName, style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _StatCards extends StatelessWidget {
  const _StatCards();

  @override
  Widget build(BuildContext context) {
    return Consumer<ChildEnrollmentProvider>(
      builder: (context, provider, _) {
        final enrollments = provider.enrollments;
        final activeEnrollments = enrollments.where((e) => e.status == EnrollmentStatus.approved).length;

        int totalSessions = 0;
        int attendedSessions = 0;

        for (var e in enrollments) {
          totalSessions += e.attendanceHistory.length;
          attendedSessions += e.attendanceCount;
        }

        final attendanceRate = totalSessions > 0 ? (attendedSessions / totalSessions * 100) : 0.0;

        return Row(
          children: [
            Expanded(
              child: _StatCard(
                title: 'Inscriptions',
                value: activeEnrollments.toString(),
                subtitle: 'Cours actifs',
                icon: Icons.school,
                color: Colors.blue,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _StatCard(
                title: 'Assiduité',
                value: '${attendanceRate.toStringAsFixed(0)}%',
                subtitle: 'Taux moyen',
                icon: Icons.check_circle,
                color: Colors.green,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
          Text(subtitle, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        ],
      ),
    );
  }
}

class _CalendarSection extends StatefulWidget {
  const _CalendarSection();

  @override
  State<_CalendarSection> createState() => _CalendarSectionState();
}

class _CalendarSectionState extends State<_CalendarSection> {
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Planning', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 16),
        GlassCard(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              CalendarTimeline(
                initialDate: _selectedDate,
                firstDate: DateTime.now().subtract(const Duration(days: 30)),
                lastDate: DateTime.now().add(const Duration(days: 30)),
                onDateSelected: (date) => setState(() => _selectedDate = date),
                leftMargin: 20,
                monthColor: Colors.blueGrey,
                dayColor: Colors.teal[200],
                activeDayColor: Colors.white,
                activeBackgroundDayColor: Theme.of(context).colorScheme.primary,
                dotColor: const Color(0xFF333A47),
                locale: Localizations.localeOf(context).languageCode,
              ),
              const SizedBox(height: 20),
              Consumer<ChildEnrollmentProvider>(
                builder: (context, provider, _) {
                  final schedules = provider.getSchedulesForDate(_selectedDate);
                  if (schedules.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(20),
                      child: Text('Aucun cours prévu ce jour'),
                    );
                  }
                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: schedules.length,
                    itemBuilder: (context, i) {
                      final schedule = schedules[i];
                      return ListTile(
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              schedule.timeSlot.displayTime,
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
                            ),
                          ),
                        ),
                        title: Text('Cours #${schedule.courseId.substring(0, 5)}'),
                        subtitle: Text(schedule.location ?? 'Salle non définie'),
                        trailing: const Icon(Icons.chevron_right, size: 16),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ChildProfileDialog extends StatelessWidget {
  final String childId;

  const _ChildProfileDialog({required this.childId});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Consumer<ChildEnrollmentProvider>(
      builder: (context, provider, _) {
        final childIndex = provider.children.indexWhere((c) => c.id == childId);
        if (childIndex == -1) return const SizedBox();
        final child = provider.children[childIndex];
        
        final enrollments = provider.getEnrollmentsForChild(child.id);
        final courses = context.read<CourseProvider>().courses;

        return Dialog.fullscreen(
          child: Scaffold(
            body: SafeArea(child: CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: 300,
                  pinned: true,
                  flexibleSpace: FlexibleSpaceBar(
                    title: Text('${child.firstName} ${child.lastName}',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    background: child.photoUrl != null
                        ? CachedNetworkImage(imageUrl: child.photoUrl!, fit: BoxFit.cover)
                        : Container(
                            color: colorScheme.primary,
                            child: Center(child: Text(child.firstName[0],
                              style: const TextStyle(fontSize: 80, color: Colors.white))),
                          ),
                  ),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.white),
                      onPressed: () => _showEditDialog(context, child),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.white),
                      onPressed: () => _confirmDelete(context, child),
                    ),
                  ],
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Informations Personnelles',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        _buildInfoRow(context, Icons.cake, 'Date de naissance', _formatDate(child.dateOfBirth)),
                        _buildInfoRow(context, Icons.bloodtype, 'Groupe Sanguin', child.medicalInfo.bloodType ?? 'Non spécifié'),
                        _buildInfoRow(context, Icons.medical_services, 'Allergies', child.medicalInfo.allergies.isEmpty ? 'Aucune' : child.medicalInfo.allergies.join(", ")),
                        
                        const SizedBox(height: 32),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Inscriptions',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            ElevatedButton.icon(
                              onPressed: () => _showCourseSelectionDialog(context, child),
                              icon: const Icon(Icons.add),
                              label: const Text('Inscrire'),
                            ),
                          ],
                        ),
                        if (enrollments.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 20),
                            child: Center(child: Text('Aucune inscription active')),
                          ),
                      ],
                    ),
                  ),
                ),
                if (enrollments.isNotEmpty)
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final enrollment = enrollments[index];
                        final course = courses.firstWhere((c) => c.id == enrollment.courseId,
                          orElse: () => CourseModel(
                            id: '',
                            title: 'Cours inconnu',
                            description: '',
                            category: CourseCategory.other,
                            season: CourseSeason.yearRound,
                            seasonStartDate: DateTime.now(),
                            seasonEndDate: DateTime.now(),
                            location: CourseLocation(latitude: 0.0, longitude: 0.0, address: ''),
                            images: [],
                            createdBy: '',
                            createdAt: DateTime.now(),
                            updatedAt: DateTime.now(),
                          ));

                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          child: GlassCard(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 50,
                                      height: 50,
                                      decoration: BoxDecoration(
                                        color: colorScheme.primaryContainer,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(Icons.class_, color: colorScheme.onPrimaryContainer),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Text(course.title,
                                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                              ),
                                              _buildBadge(context, enrollment.status.displayName, enrollment.status),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Row(
                                                children: [
                                                  Icon(Icons.calendar_today, size: 14, color: colorScheme.onSurfaceVariant),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    'Inscrit le ${_formatDate(enrollment.enrolledAt)}',
                                                    style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                                                  ),
                                                ],
                                              ),
                                              if (enrollment.status == EnrollmentStatus.pending || enrollment.status == EnrollmentStatus.approved)
                                                TextButton(
                                                  onPressed: () => _confirmCancelEnrollment(context, enrollment.id, course.title),
                                                  style: TextButton.styleFrom(
                                                    foregroundColor: Colors.red,
                                                    padding: EdgeInsets.zero,
                                                    minimumSize: const Size(0, 30),
                                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                  ),
                                                  child: const Text("Annuler", style: TextStyle(fontSize: 12)),
                                                ),
                                            ],
                                          ),
                                          if (enrollment.status == EnrollmentStatus.approved) ...[
                                            const Divider(),
                                            const SizedBox(height: 4),
                                            if (enrollment.paymentStatus == PaymentStatus.paid)
                                              const Row(
                                                children: [
                                                  Icon(Icons.verified, color: Colors.green, size: 20),
                                                  SizedBox(width: 8),
                                                  Text("Adhérent confirmé",
                                                    style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 13)),
                                                ],
                                              )
                                            else
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  const Text("Paiement requis",
                                                    style: TextStyle(color: Colors.orange, fontWeight: FontWeight.w500, fontSize: 13)),
                                                  ElevatedButton.icon(
                                                    onPressed: () => _showPaymentQR(context, enrollment),
                                                    icon: const Icon(Icons.qr_code, size: 18),
                                                    label: const Text("Payer", style: TextStyle(fontSize: 12)),
                                                    style: ElevatedButton.styleFrom(
                                                      backgroundColor: Colors.orange,
                                                      foregroundColor: Colors.white,
                                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                                                      minimumSize: const Size(0, 32),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      childCount: enrollments.length,
                    ),
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: 50)),
              ],
            )),
          ),
        );
      },
    );
  }

  void _showPaymentQR(BuildContext context, EnrollmentModel enrollment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Paiement par QR Code"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Veuillez présenter ce code au club pour valider votre paiement."),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: QrImageView(
                data: enrollment.id,
                version: QrVersions.auto,
                size: 200.0,
              ),
            ),
            const SizedBox(height: 12),
            Text("${enrollment.totalAmount?.toStringAsFixed(0) ?? "0"} DA",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Fermer")),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context, ChildModel child) {
    showDialog(
      context: context,
      builder: (context) => _ChildFormDialog(child: child, parentId: child.parentId),
    );
  }

  void _confirmDelete(BuildContext context, ChildModel child) {
    showDialog(
      context: context,
      builder: (confirmContext) => AlertDialog(
        title: const Text('Supprimer le profil'),
        content: Text('Voulez-vous vraiment supprimer le profil de ${child.firstName} ? Cette action est irréversible.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(confirmContext), child: const Text('Annuler')),
          TextButton(
            onPressed: () async {
              final provider = confirmContext.read<ChildEnrollmentProvider>();
              await provider.deleteChild(child.id);
              if (confirmContext.mounted) {
                Navigator.pop(confirmContext); // Close alert
                Navigator.pop(context); // Close profile dialog
              }
            },
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _confirmCancelEnrollment(BuildContext context, String enrollmentId, String courseTitle) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Annuler l'inscription"),
        content: Text("Voulez-vous vraiment annuler l'inscription au cours $courseTitle ?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Retour')),
          TextButton(
            onPressed: () async {
              await context.read<ChildEnrollmentProvider>().cancelEnrollment(enrollmentId);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text("Confirmer l'annulation", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, IconData icon, String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color ?? Colors.grey[600]),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(BuildContext context, String text, EnrollmentStatus status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getStatusColor(status).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(color: _getStatusColor(status), fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  Color _getStatusColor(EnrollmentStatus status) {
    switch (status) {
      case EnrollmentStatus.approved: return Colors.green;
      case EnrollmentStatus.pending: return Colors.orange;
      case EnrollmentStatus.rejected: return Colors.red;
      case EnrollmentStatus.cancelled: return Colors.grey;
      case EnrollmentStatus.completed: return Colors.blue;
    }
  }

  String _formatDate(DateTime date) => '${date.day}/${date.month}/${date.year}';
}

class _CoursesPage extends StatelessWidget {
  const _CoursesPage();

  @override
  Widget build(BuildContext context) {
    return Consumer2<CourseProvider, ChildEnrollmentProvider>(
      builder: (context, courseProvider, childProvider, _) {
        final courses = courseProvider.courses;
        final children = childProvider.children;

        return GridView.builder(
          padding: const EdgeInsets.all(24),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, crossAxisSpacing: 16, mainAxisSpacing: 16, childAspectRatio: 0.75
          ),
          itemCount: courses.length,
          itemBuilder: (context, i) {
            final course = courses[i];
            
            final enrolledChildrenNames = children
                .where((child) => childProvider.isChildEnrolledInCourse(child.id, course.id))
                .map((child) => child.firstName)
                .toList();

            return CourseCard(
              course: course,
              enrolledChildren: enrolledChildrenNames,
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => CourseDetailsScreen(course: course)));
              },
            );
          },
        );
      },
    );
  }
}

class _ChildFormDialog extends StatefulWidget {
  final ChildModel? child;
  final String parentId;

  const _ChildFormDialog({this.child, required this.parentId});

  @override
  State<_ChildFormDialog> createState() => _ChildFormDialogState();
}

class _ChildFormDialogState extends State<_ChildFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _schoolGradeController;
  DateTime? _dateOfBirth;
  ChildGender _gender = ChildGender.other;
  File? _photo;
  File? _birthCertificate;
  File? _medicalCertificate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController(text: widget.child?.firstName);
    _lastNameController = TextEditingController(text: widget.child?.lastName);
    _schoolGradeController = TextEditingController(text: widget.child?.schoolGrade);
    _dateOfBirth = widget.child?.dateOfBirth;
    _gender = widget.child?.gender ?? ChildGender.other;
  }

  Future<void> _pickImage() async {
    final image = await HybridImagePickerService.pickImage(context: context, crop: true, aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1));
    if (image != null) {
      setState(() => _photo = image);
    }
  }

  Future<void> _pickBirthCertificate() async {
    final file = await HybridImagePickerService.pickDocument(context: context);
    if (file != null) setState(() => _birthCertificate = file);
  }

  Future<void> _pickMedicalCertificate() async {
    final file = await HybridImagePickerService.pickDocument(context: context);
    if (file != null) setState(() => _medicalCertificate = file);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || (_dateOfBirth == null && widget.child == null)) {
      if (_dateOfBirth == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Veuillez sélectionner une date de naissance')),
        );
      }
      return;
    }

    setState(() => _isLoading = true);
    final provider = context.read<ChildEnrollmentProvider>();

    bool success;
    if (widget.child == null) {
      success = await provider.addChild(
        parentId: widget.parentId,
        firstName: _firstNameController.text,
        lastName: _lastNameController.text,
        dateOfBirth: _dateOfBirth!,
        gender: _gender,
        photoFile: _photo,
        birthCertificateFile: _birthCertificate,
        medicalCertificateFile: _medicalCertificate,
        schoolGrade: _schoolGradeController.text,
      );
    } else {
      success = await provider.updateChild(parentId: widget.parentId,
        childId: widget.child!.id,
        firstName: _firstNameController.text,
        lastName: _lastNameController.text,
        dateOfBirth: _dateOfBirth,
        gender: _gender,
        newPhoto: _photo,
        newBirthCertificate: _birthCertificate,
        newMedicalCertificate: _medicalCertificate,
        schoolGrade: _schoolGradeController.text,
      );
    }

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(provider.error ?? 'Une erreur est survenue')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.child == null ? 'Ajouter un enfant' : 'Modifier l\'enfant'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: CircleAvatar(
                  radius: 40,
                  backgroundImage: _photo != null 
                      ? FileImage(_photo!) 
                      : (widget.child?.photoUrl != null ? CachedNetworkImageProvider(widget.child!.photoUrl!) : null) as ImageProvider?,
                  child: _photo == null && widget.child?.photoUrl == null ? const Icon(Icons.camera_alt, size: 30) : null,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _firstNameController,
                decoration: const InputDecoration(labelText: 'Prénom'),
                validator: (v) => v!.isEmpty ? 'Requis' : null,
              ),
              TextFormField(
                controller: _lastNameController,
                decoration: const InputDecoration(labelText: 'Nom'),
                validator: (v) => v!.isEmpty ? 'Requis' : null,
              ),
              const SizedBox(height: 16),
              ListTile(
                title: Text(_dateOfBirth == null 
                    ? 'Date de naissance' 
                    : 'Né(e) le: ${_dateOfBirth!.day}/${_dateOfBirth!.month}/${_dateOfBirth!.year}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _dateOfBirth ?? DateTime.now().subtract(const Duration(days: 365 * 3)),
                    firstDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) setState(() => _dateOfBirth = date);
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<ChildGender>(
                initialValue: _gender,
                decoration: const InputDecoration(labelText: 'Genre'),
                items: ChildGender.values.map((g) => DropdownMenuItem(
                  value: g,
                  child: Text(g == ChildGender.male ? 'Garçon' : g == ChildGender.female ? 'Fille' : 'Autre'),
                )).toList(),
                onChanged: (v) => setState(() => _gender = v!),
              ),
              TextFormField(
                controller: _schoolGradeController,
                decoration: const InputDecoration(labelText: 'Niveau scolaire (ex: Petite Section)'),
              ),
              const SizedBox(height: 16),
              _buildDocumentPicker(
                label: "Extrait de naissance",
                file: _birthCertificate,
                currentUrl: widget.child?.birthCertificateUrl,
                onTap: _pickBirthCertificate,
              ),
              const SizedBox(height: 8),
              _buildDocumentPicker(
                label: "Certificat médical",
                file: _medicalCertificate,
                currentUrl: widget.child?.medicalCertificateUrl,
                onTap: _pickMedicalCertificate,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("Annuler")),
        ElevatedButton(
          onPressed: _isLoading ? null : _save,
          child: _isLoading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text("Enregistrer"),
        ),
      ],
    );
  }

  Widget _buildDocumentPicker({
    required String label,
    File? file,
    String? currentUrl,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(file != null || currentUrl != null ? Icons.check_circle : Icons.upload_file,
                 color: file != null || currentUrl != null ? Colors.green : Colors.grey),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  Text(file != null ? file.path.split("/").last : (currentUrl != null ? "Déjà téléchargé" : "Facultatif"),
                       style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BillingPage extends StatelessWidget {
  const _BillingPage();

  @override
  Widget build(BuildContext context) {
    return Consumer<ChildEnrollmentProvider>(
      builder: (context, provider, _) {
        final children = provider.children;
        final totalDue = provider.getTotalDueAllChildren();

        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              'Mes Factures',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Suivez vos paiements et renouvellements',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),

            GlassCard(
              color: Theme.of(context).colorScheme.primary,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Text(
                      'Total dû (tous enfants)',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${totalDue.toStringAsFixed(0)} DA',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            if (children.isEmpty)
              const Center(child: Text('Aucun enfant enregistré.'))
            else
              ...children.map((child) => _buildChildBillingCard(context, provider, child)),

            const SizedBox(height: 100),
          ],
        );
      },
    );
  }

  Widget _buildChildBillingCard(BuildContext context, ChildEnrollmentProvider provider, ChildModel child) {
    final enrollments = provider.getEnrollmentsForChild(child.id);
    final totalDue = provider.getTotalDueForChild(child.id);
    final nextRenewal = provider.getNextRenewalDateForChild(child.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundImage: child.photoUrl != null ? CachedNetworkImageProvider(child.photoUrl!) : null,
                child: child.photoUrl == null ? Text(child.firstName[0]) : null,
              ),
              const SizedBox(width: 12),
              Text(
                child.fullName,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const Spacer(),
              if (totalDue > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${totalDue.toStringAsFixed(0)} DA dû',
                    style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                )
              else
                const Icon(Icons.check_circle, color: Colors.green, size: 20),
            ],
          ),
          const SizedBox(height: 12),
          GlassCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                if (enrollments.isEmpty)
                  const Text('Aucune inscription active.')
                else
                  ...enrollments.map((e) => _buildEnrollmentRow(context, e)),

                if (nextRenewal != null) ...[
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Prochain renouvellement', style: TextStyle(fontSize: 13)),
                      Text(
                        DateFormat('dd/MM/yyyy').format(nextRenewal),
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnrollmentRow(BuildContext context, EnrollmentModel enrollment) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Cours #${enrollment.courseId.substring(0, 5)}', style: const TextStyle(fontWeight: FontWeight.w500)),
                    Text(
                      'Statut: ${enrollment.paymentStatus.displayName}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${enrollment.totalAmount?.toStringAsFixed(0) ?? "0"} DA',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  if (enrollment.remainingAmount > 0)
                    Text(
                      '-${enrollment.paidAmount?.toStringAsFixed(0) ?? "0"} payé',
                      style: const TextStyle(fontSize: 11, color: Colors.green),
                    ),
                ],
              ),
            ],
          ),
          if (enrollment.status == EnrollmentStatus.approved && enrollment.paymentStatus != PaymentStatus.paid) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showPaymentQR(context, enrollment),
                    icon: const Icon(Icons.qr_code, size: 18),
                    label: const Text('Payer maintenant', style: TextStyle(fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
              ],
            ),
          ] else if (enrollment.status == EnrollmentStatus.completed && enrollment.paymentStatus == PaymentStatus.paid) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.verified, color: Colors.green, size: 16),
                const SizedBox(width: 4),
                const Text("Adhérent confirmé", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
              ],
            ),
          ]
        ],
      ),
    );
  }

  void _showPaymentQR(BuildContext context, EnrollmentModel enrollment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Paiement par QR Code'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Scannez ce code pour effectuer le paiement de votre inscription.'),
            const SizedBox(height: 20),
            Image.asset(
              'assets/qrcode/qr.jpg',
              width: 200,
              height: 200,
              errorBuilder: (context, error, stackTrace) => Container(
                width: 200,
                height: 200,
                color: Colors.grey[200],
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.qr_code, size: 50, color: Colors.grey),
                    Text('QR Code non disponible', style: TextStyle(fontSize: 12)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text('Montant: ${enrollment.totalAmount?.toStringAsFixed(0) ?? "0"} DA', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 12),
            const Text("Une fois le paiement effectué, le coach confirmera votre statut d'adhérent.",
              textAlign: TextAlign.center, style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Fermer')),
        ],
      ),
    );
  }
}

class _GeofencingSection extends StatelessWidget {
  const _GeofencingSection();

  @override
  Widget build(BuildContext context) {
    return Consumer<ChildEnrollmentProvider>(
      builder: (context, provider, _) {
        final children = provider.children;
        if (children.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Transport & Geofencing', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 16),
            ...children.map((child) {
              final loc = provider.getChildLocation(child.id);
              if (loc == null || loc['is_in_transport'] != true) return const SizedBox.shrink();

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                child: GlassCard(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      const Icon(Icons.directions_bus, color: Colors.orange),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${child.firstName} est dans le transport', style: const TextStyle(fontWeight: FontWeight.bold)),
                            Text('Vitesse: ${loc['speed']?.toStringAsFixed(1)} km/h • Zone: Centre-Ville', style: const TextStyle(fontSize: 12)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text('Sécurisé', style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
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
}

class _ChildrenTimelines extends StatelessWidget {
  const _ChildrenTimelines();

  @override
  Widget build(BuildContext context) {
    return Consumer<ChildEnrollmentProvider>(
      builder: (context, provider, _) {
        final children = provider.children;
        if (children.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Activités du jour', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: children.length,
                itemBuilder: (context, index) {
                  final child = children[index];
                  final activities = provider.getActivitiesForChild(child.id);

                  return Container(
                    width: 280,
                    margin: const EdgeInsets.only(right: 16),
                    child: GlassCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 14,
                                backgroundImage: child.photoUrl != null ? CachedNetworkImageProvider(child.photoUrl!) : null,
                                child: child.photoUrl == null ? Text(child.firstName[0]) : null,
                              ),
                              const SizedBox(width: 8),
                              Text(child.firstName, style: const TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const Divider(),
                          Expanded(
                            child: activities.isEmpty
                              ? const Center(child: Text('Aucune activité notée', style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic)))
                              : ListView.builder(
                                  itemCount: activities.length,
                                  itemBuilder: (context, i) {
                                    final act = activities[i];
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 4),
                                      child: Row(
                                        children: [
                                          Icon(Icons.circle, size: 8, color: Theme.of(context).colorScheme.primary),
                                          const SizedBox(width: 8),
                                          Expanded(child: Text(act.title, style: const TextStyle(fontSize: 12))),
                                          Text(act.status, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

void _showCourseSelectionDialog(BuildContext context, ChildModel child) {
  showDialog(
    context: context,
    builder: (context) => _CourseSelectionDialog(child: child),
  );
}

class _CourseSelectionDialog extends StatefulWidget {
  final ChildModel child;
  const _CourseSelectionDialog({required this.child});

  @override
  State<_CourseSelectionDialog> createState() => _CourseSelectionDialogState();
}

class _CourseSelectionDialogState extends State<_CourseSelectionDialog> {
  final List<String> _selectedCourseIds = [];
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    final courseProvider = context.watch<CourseProvider>();
    final childProvider = context.watch<ChildEnrollmentProvider>();
    final courses = courseProvider.courses;

    return AlertDialog(
      title: Text('Inscrire ${widget.child.firstName}'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: courses.length,
          itemBuilder: (context, i) {
            final course = courses[i];
            final isEnrolled = childProvider.isChildEnrolledInCourse(widget.child.id, course.id);
            final isSelected = _selectedCourseIds.contains(course.id);

            return CheckboxListTile(
              title: Text(course.title),
              subtitle: Text('${course.price?.toStringAsFixed(0) ?? "0"} DA'),
              value: isEnrolled || isSelected,
              onChanged: isEnrolled ? null : (val) {
                setState(() {
                  if (val == true) {
                    _selectedCourseIds.add(course.id);
                  } else {
                    _selectedCourseIds.remove(course.id);
                  }
                });
              },
            );
          },
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
        ElevatedButton(
          onPressed: (_selectedCourseIds.isEmpty || _isSubmitting) ? null : _submit,
          child: _isSubmitting
            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
            : const Text('Confirmer'),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    setState(() => _isSubmitting = true);
    final provider = context.read<ChildEnrollmentProvider>();
    final courseProvider = context.read<CourseProvider>();

    final authProvider = context.read<AuthProviderV2>();
    final parentId = authProvider.userData?['id'] ?? '';

    bool allSuccess = true;
    for (final courseId in _selectedCourseIds) {
      final course = courseProvider.courses.firstWhere((c) => c.id == courseId);
      final success = await provider.createEnrollment(
        courseId: courseId,
        childId: widget.child.id,
        parentId: parentId,
        totalAmount: course.price,
      );
      if (!success) allSuccess = false;
    }

    if (mounted) {
      setState(() => _isSubmitting = false);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(allSuccess ? 'Inscriptions réussies' : 'Certaines inscriptions ont échoué')),
      );
    }
  }
}
