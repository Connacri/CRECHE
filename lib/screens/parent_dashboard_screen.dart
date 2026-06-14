import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../dependences/calendar_timeline/calendar_timeline.dart';
import '../providers/auth_provider_v2.dart';
import '../models/course_model_complete.dart';
import '../models/enrollment_model_complete.dart';
import '../models/child_model_complete.dart';

import '../providers/child_enrollment_provider.dart';
import '../providers/course_provider_complete.dart';
import '../widgets/modern_course_card_widget.dart';
import '../widgets/glass_card.dart';
import '../widgets/child_profile_dialog.dart';
import '../widgets/child_form_dialog.dart';
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
                const Text('Bonjour,', style: TextStyle(color: Colors.white, fontSize: 14)),
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
                  builder: (context) => ChildFormDialog(parentId: parentId),
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
                              builder: (context) => ChildProfileDialog(childId: child.id),
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

class _CoursesPage extends StatelessWidget {
  const _CoursesPage();

  @override
  Widget build(BuildContext context) {
    return Consumer2<CourseProvider, ChildEnrollmentProvider>(
      builder: (context, courseProvider, childProvider, _) {
        final courses = courseProvider.courses;
        final children = childProvider.children;

        return ListView.separated(
          padding: const EdgeInsets.all(24),
          itemCount: courses.length,
          separatorBuilder: (_, __) => const SizedBox(height: 20),
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
                Navigator.push(context, MaterialPageRoute(builder: (_) => CourseDetailsScreen(course: course, enrolledChildren: enrolledChildrenNames,)));
              }, onFavorite: () {  },
            );
          },
        );
      },
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

  Widget _buildChildBillingCard(
      BuildContext context, ChildEnrollmentProvider provider, ChildModel child) {
    final enrollments = provider.getEnrollmentsForChild(child.id);
    final totalDue = provider.getTotalDueForChild(child.id);
    final nextRenewal = provider.getNextRenewalDateForChild(child.id);
    // ✅ FIX : utilise CourseProvider (déjà chargé dans initState du dashboard)
    final courseProvider = context.read<CourseProvider>();

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header enfant ──────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundImage: child.photoUrl != null
                      ? CachedNetworkImageProvider(child.photoUrl!)
                      : null,
                  child: child.photoUrl == null
                      ? Text(child.firstName[0],
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(child.fullName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text(
                        '${enrollments.length} inscription${enrollments.length > 1 ? "s" : ""}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                totalDue > 0
                    ? Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                  ),
                  child: Text('${totalDue.toStringAsFixed(0)} DA dû',
                      style: const TextStyle(
                          color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12)),
                )
                    : Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle, color: Colors.green, size: 14),
                      SizedBox(width: 4),
                      Text('À jour',
                          style: TextStyle(
                              color: Colors.green,
                              fontSize: 12,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // ── Cards d'inscriptions ───────────────────────
          GlassCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                if (enrollments.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: Text('Aucune inscription active.',
                          style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
                    ),
                  )
                else
                  ...enrollments.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final e = entry.value;
                    // ✅ FIX : lookup via CourseProvider
                    final course = courseProvider.courses.firstWhere(
                          (c) => c.id == e.courseId,
                      orElse: CourseModel.mock,
                    );
                    return Column(
                      children: [
                        if (idx > 0)
                          const Divider(height: 28, thickness: 0.5),
                        _buildEnrollmentRow(context, e, course, child),
                      ],
                    );
                  }),
                if (nextRenewal != null) ...[
                  const Divider(height: 24, thickness: 0.5),
                  Row(
                    children: [
                      Icon(Icons.event_repeat, size: 16, color: Colors.blue[400]),
                      const SizedBox(width: 6),
                      const Expanded(
                        child: Text(
                          'Prochain renouvellement',
                          style: TextStyle(fontSize: 13),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        DateFormat('dd/MM/yyyy').format(nextRenewal),
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.blue),
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

  Widget _buildEnrollmentRow(
      BuildContext context, EnrollmentModel enrollment, CourseModel course, ChildModel child) {
    final colorScheme = Theme.of(context).colorScheme;
    final isPaid = enrollment.paymentStatus == PaymentStatus.paid;
    final isPartial = enrollment.paymentStatus == PaymentStatus.partial;
    final total = enrollment.totalAmount ?? 0;
    final paid = enrollment.paidAmount ?? 0;
    final progress = total > 0 ? (paid / total).clamp(0.0, 1.0) : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Titre du cours + badge statut ──────────────
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.school_outlined,
                  color: colorScheme.onPrimaryContainer, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    course.title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    course.category.displayName,
                    style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _buildStatusBadge(enrollment.status),
          ],
        ),
        const SizedBox(height: 12),
        // ── Barre de progression paiement ──────────────
        if (total > 0) ...[
          Row(
            children: [
              Expanded(
                child: Text(
                  isPaid
                      ? 'Payé intégralement'
                      : isPartial
                      ? 'Paiement partiel'
                      : 'En attente de paiement',
                  style: TextStyle(
                    fontSize: 12,
                    color: isPaid
                        ? Colors.green
                        : isPartial
                        ? Colors.orange
                        : Colors.red[400],
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${paid.toStringAsFixed(0)} / ${total.toStringAsFixed(0)} DA',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation<Color>(
                isPaid
                    ? Colors.green
                    : isPartial
                    ? Colors.orange
                    : Colors.red.withValues(alpha: 0.5),
              ),
              minHeight: 7,
            ),
          ),
        ],
        // ── Action paiement ────────────────────────────
        if (enrollment.status == EnrollmentStatus.approved && !isPaid) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showPaymentQR(context, enrollment, child),
              icon: const Icon(Icons.qr_code, size: 18),
              label: const Text('Payer maintenant',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 11),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ] else if (isPaid) ...[
          const SizedBox(height: 10),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.verified, color: Colors.green, size: 16),
              SizedBox(width: 4),
              Text('Adhérent confirmé',
                  style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                      fontSize: 12)),
            ],
          ),
        ],
      ],
    );
  }

  void _showPaymentQR(BuildContext context, EnrollmentModel enrollment, ChildModel child) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Paiement par QR Code'),
        content: SizedBox(
          width: 300,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Scannez ce code pour effectuer le paiement de votre inscription.'),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: QrImageView(
                  data: jsonEncode({
                    'type': 'enrollment_payment',
                    'id': enrollment.id,
                    'child_name': child.firstName,
                    'amount': enrollment.totalAmount ?? 0.0,
                  }),
                  version: QrVersions.auto,
                  size: 200.0,
                  eyeStyle: const QrEyeStyle(
                    eyeShape: QrEyeShape.square,
                    color: Colors.black,
                  ),
                  dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: Colors.black,
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
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Fermer')),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(EnrollmentStatus status) {
    final Color color;
    switch (status) {
      case EnrollmentStatus.approved:  color = Colors.green;  break;
      case EnrollmentStatus.pending:   color = Colors.orange; break;
      case EnrollmentStatus.rejected:  color = Colors.red;    break;
      case EnrollmentStatus.cancelled: color = Colors.grey;   break;
      case EnrollmentStatus.completed: color = Colors.blue;   break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        status.displayName,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
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



