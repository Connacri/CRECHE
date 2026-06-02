import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../dependences/calendar_timeline/calendar_timeline.dart';
import '../providers/auth_provider_v2.dart';
import '../models/course_model_complete.dart';
import '../models/enrollment_model_complete.dart';
import '../models/session_schedule_model.dart';
import '../models/user_model.dart';
import '../models/child_model_complete.dart';
import '../models/daily_activity_model.dart';
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
    // ✅ ÉCOUTE RÉACTIVE DES PROVIDERS
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
        padding: const EdgeInsets.symmetric(vertical: 8),
        borderRadius: BorderRadius.circular(30),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(0, Icons.home_rounded, 'Accueil'),
            _buildNavItem(1, Icons.calendar_today_rounded, 'Planning'),
            _buildNavItem(2, Icons.child_care_rounded, 'Enfants'),
            _buildNavItem(3, Icons.search_rounded, 'Cours'),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _selectedIndex == index;
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: () => setState(() => _selectedIndex = index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _getSelectedPage() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    
    switch (_selectedIndex) {
      case 0: return const _HomePage();
      case 1: return const _PlanningPage();
      case 2: return const _ChildrenPage();
      case 3: return const _CoursesPage();
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
                radius: 28, 
                backgroundImage: avatarUrl != null ? CachedNetworkImageProvider(avatarUrl) : null,
                child: avatarUrl == null ? const Icon(Icons.person) : null,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Bonjour, $userName', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                  const Text('Votre espace de sérénité'),
                ],
              ),
            ),
            IconButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen())),
              icon: const Icon(Icons.settings_outlined),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Mes enfants', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
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
    return Selector<ChildEnrollmentProvider, int>(
      selector: (_, provider) => provider.enrollments.length,
      builder: (context, enrollmentCount, _) {
        return Row(
          children: [
            Expanded(child: _buildStatCard(context, 'Présences', '18/20', Icons.check_circle_outline, Colors.green)),
            const SizedBox(width: 16),
            Expanded(child: _buildStatCard(context, 'Cours Actifs', '$enrollmentCount', Icons.book_outlined, Colors.blue)),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(BuildContext context, String title, String value, IconData icon, Color color) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          Text(title, style: const TextStyle(fontSize: 12)),
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
        const Text('Planning hebdomadaire', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 16),
        GlassCard(
          padding: const EdgeInsets.all(8),
          child: CalendarTimeline(
            initialDate: _selectedDate,
            firstDate: DateTime.now().subtract(const Duration(days: 30)),
            lastDate: DateTime.now().add(const Duration(days: 30)),
            onDateSelected: (date) {
              setState(() => _selectedDate = date);
              final authProvider = context.read<AuthProviderV2>();
              final uid = authProvider.userData?['id'] ?? '';
              context.read<ChildEnrollmentProvider>().loadDailyActivities(uid, date);
            },
            leftMargin: 20,
            monthColor: Theme.of(context).colorScheme.onSurfaceVariant,
            dayColor: Theme.of(context).colorScheme.onSurfaceVariant,
            activeDayColor: Colors.white,
            activeBackgroundDayColor: Theme.of(context).colorScheme.primary,
            locale: 'fr',
          ),
        ),
        const SizedBox(height: 16),
        _buildDaySessions(),
        const SizedBox(height: 16),
        _buildDailyActivities(),
      ],
    );
  }

  Widget _buildDaySessions() {
    return Consumer2<ChildEnrollmentProvider, CourseProvider>(
      builder: (context, provider, courseProvider, _) {
        final sessions = provider.getSchedulesForDate(_selectedDate);
        if (sessions.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Text('Aucune activité prévue pour cette date'),
            ),
          );
        }

        return Column(
          children: sessions.map((session) {
            final course = courseProvider.courses.firstWhere(
              (c) => c.id == session.courseId,
              orElse: () => CourseModel.mock(),
            );

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GlassCard(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.access_time, size: 16, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 12),
                    Text(
                      session.timeSlot.displayTime,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(course.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                          if (session.location != null)
                            Text(
                              session.location!,
                              style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                            ),
                        ],
                      ),
                    ),
                    _buildBadge(context, session.isCancelled ? 'Annulé' : 'Confirmé', isCancelled: session.isCancelled),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildDailyActivities() {
    return Consumer<ChildEnrollmentProvider>(
      builder: (context, provider, _) {
        if (provider.dailyActivities.isEmpty) return const SizedBox();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Activités & Tâches', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            ...provider.dailyActivities.map((activity) {
              final child = provider.children.firstWhere((c) => c.id == activity.childId, orElse: () => ChildModel.mock());
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: GlassCard(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      _getActivityIcon(activity.type),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(activity.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                            Text('Pour ${child.firstName}', style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                            if (activity.description != null)
                              Text(activity.description!, style: const TextStyle(fontSize: 13)),
                          ],
                        ),
                      ),
                      if (activity.status == 'completed')
                        const Icon(Icons.check_circle, color: Colors.green)
                      else
                        const Icon(Icons.pending_actions, color: Colors.orange),
                    ],
                  ),
                ),
              );
            }).toList(),
          ],
        );
      },
    );
  }

  Widget _getActivityIcon(ActivityType type) {
    IconData icon;
    Color color;
    switch (type) {
      case ActivityType.meal: icon = Icons.restaurant; color = Colors.orange; break;
      case ActivityType.activity: icon = Icons.brush; color = Colors.green; break;
      case ActivityType.task: icon = Icons.assignment; color = Colors.blue; break;
      case ActivityType.nap: icon = Icons.king_bed; color = Colors.purple; break;
      case ActivityType.other: icon = Icons.star; color = Colors.amber; break;
    }
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
      child: Icon(icon, color: color),
    );
  }

  Widget _buildBadge(BuildContext context, String text, {bool isCancelled = false}) {
    final color = isCancelled ? Colors.red : Colors.green;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
      child: Text(text, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold)),
    );
  }
}

class _PlanningPage extends StatelessWidget {
  const _PlanningPage();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const _CalendarSection(),
        const SizedBox(height: 100),
      ],
    );
  }
}

class _ChildrenPage extends StatelessWidget {
  const _ChildrenPage();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Consumer<ChildEnrollmentProvider>(
          builder: (context, provider, _) {
            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
              itemCount: provider.children.length,
              itemBuilder: (context, i) {
                final child = provider.children[i];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: GlassCard(
                    padding: const EdgeInsets.all(8),
                    child: ListTile(
                      leading: CircleAvatar(
                        key: ValueKey(child.photoUrl ?? child.id),
                        backgroundImage: child.photoUrl != null ? CachedNetworkImageProvider(child.photoUrl!) : null,
                        child: child.photoUrl == null ? Text(child.firstName[0]) : null,
                      ),
                      title: Text(child.fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('${child.age} ans • ${child.schoolGrade ?? "Niveau non précisé"}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined),
                            onPressed: () => _showChildDialog(context, child: child),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                            onPressed: () => _confirmDeleteChild(context, child),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
        Positioned(
          bottom: 100,
          right: 24,
          child: FloatingActionButton.extended(
            onPressed: () => _showChildDialog(context),
            icon: const Icon(Icons.add),
            label: const Text('Ajouter un enfant'),
          ),
        ),
      ],
    );
  }

  void _showChildDialog(BuildContext context, {ChildModel? child}) {
    final authProvider = context.read<AuthProviderV2>();
    final uid = authProvider.userData?['id'] ?? '';
    showDialog(
      context: context,
      builder: (context) => _ChildFormDialog(
        child: child,
        parentId: uid,
      ),
    );
  }

  void _confirmDeleteChild(BuildContext context, ChildModel child) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer l\'enfant'),
        content: Text('Êtes-vous sûr de vouloir supprimer ${child.firstName} ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          TextButton(
            onPressed: () async {
              await context.read<ChildEnrollmentProvider>().deleteChild(child.id);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
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
        if (childIndex == -1) return const SizedBox(); // Handle deleted
        final child = provider.children[childIndex];
        
        final enrollments = provider.getEnrollmentsForChild(child.id);
        final courses = context.read<CourseProvider>().courses;

        return Dialog.fullscreen(
          child: Scaffold(
            body: CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: 300,
                  pinned: true,
                  leading: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
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
                    const SizedBox(width: 8),
                  ],
                  flexibleSpace: FlexibleSpaceBar(
                    title: Text(
                      child.firstName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        shadows: [Shadow(blurRadius: 10, color: Colors.black)],
                      ),
                    ),
                    background: Hero(
                      tag: 'child-photo-${child.id}',
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          if (child.photoUrl != null)
                            CachedNetworkImage(
                              imageUrl: child.photoUrl!,
                              fit: BoxFit.cover,
                            )
                          else
                            Container(
                              color: colorScheme.primaryContainer,
                              child: Icon(Icons.child_care, size: 100, color: colorScheme.onPrimaryContainer),
                            ),
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.black.withValues(alpha: 0.3),
                                  Colors.transparent,
                                  Colors.black.withValues(alpha: 0.5),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Informations personnelles', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        _buildInfoRow(context, Icons.person_outline, 'Nom complet', child.fullName),
                        _buildInfoRow(context, Icons.cake_outlined, 'Âge', '${child.age} ans'),
                        _buildInfoRow(context, Icons.school_outlined, 'Niveau', child.schoolGrade ?? 'Non précisé'),
                        _buildInfoRow(context, Icons.wc_outlined, 'Genre', child.gender == ChildGender.male ? 'Garçon' : child.gender == ChildGender.female ? 'Fille' : 'Autre'),
                        
                        if (child.medicalInfo.allergies.isNotEmpty || child.medicalInfo.additionalNotes != null) ...[
                          const SizedBox(height: 32),
                          Text('Santé & Médical', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 16),
                          if (child.medicalInfo.allergies.isNotEmpty)
                            _buildInfoRow(context, Icons.warning_amber_rounded, 'Allergies', child.medicalInfo.allergies.join(', '), color: Colors.red),
                          if (child.medicalInfo.additionalNotes != null)
                            _buildInfoRow(context, Icons.note_alt_outlined, 'Notes', child.medicalInfo.additionalNotes!),
                        ],

                        const SizedBox(height: 32),
                        Text('Timeline des cours', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
                if (enrollments.isEmpty)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24),
                      child: Text('Aucun cours inscrit pour le moment.'),
                    ),
                  )
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final enrollment = enrollments[index];
                        final course = courses.firstWhere((c) => c.id == enrollment.courseId, orElse: () => CourseModel.mock());
                        final isLast = index == enrollments.length - 1;

                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: IntrinsicHeight(
                            child: Row(
                              children: [
                                Column(
                                  children: [
                                    Container(
                                      width: 12,
                                      height: 12,
                                      decoration: BoxDecoration(
                                        color: _getStatusColor(enrollment.status),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    if (!isLast)
                                      Expanded(
                                        child: Container(
                                          width: 2,
                                          color: colorScheme.outlineVariant,
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.only(bottom: 24),
                                    child: GlassCard(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                course.title,
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                              ),
                                              _buildBadge(context, enrollment.status.displayName, enrollment.status),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            course.category.displayName,
                                            style: TextStyle(fontSize: 12, color: colorScheme.primary),
                                          ),
                                          const SizedBox(height: 8),
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
                                        ],
                                      ),
                                    ),
                                  ),
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
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(BuildContext context, IconData icon, String label, String value, {Color? color}) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color ?? colorScheme.primary),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
              Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(BuildContext context, String text, EnrollmentStatus status) {
    final color = _getStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold),
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showEditDialog(BuildContext context, ChildModel child) {
    final authProvider = context.read<AuthProviderV2>();
    final uid = authProvider.userData?['id'] ?? '';
    showDialog(
      context: context,
      builder: (context) => _ChildFormDialog(
        child: child,
        parentId: uid,
      ),
    );
  }

  void _confirmDelete(BuildContext context, ChildModel child) {
    showDialog(
      context: context,
      builder: (confirmContext) => AlertDialog(
        title: const Text('Supprimer l\'enfant'),
        content: Text('Êtes-vous sûr de vouloir supprimer ${child.firstName} ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(confirmContext), child: const Text('Annuler')),
          TextButton(
            onPressed: () async {
              await context.read<ChildEnrollmentProvider>().deleteChild(child.id);
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
}

class _CoursesPage extends StatelessWidget {
  const _CoursesPage();

  @override
  Widget build(BuildContext context) {
    return Consumer<CourseProvider>(
      builder: (context, provider, _) {
        return GridView.builder(
          padding: const EdgeInsets.all(24),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, crossAxisSpacing: 16, mainAxisSpacing: 16, childAspectRatio: 0.8
          ),
          itemCount: provider.courses.length,
          itemBuilder: (context, i) => CourseCard(course: provider.courses[i], onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => CourseDetailsScreen(course: provider.courses[i])));
          }),
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
    final image = await HybridImagePickerService.pickProfileImage(context: context);
    if (image != null) {
      setState(() => _photo = image);
    }
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
        photo: _photo,
        schoolGrade: _schoolGradeController.text,
      );
    } else {
      success = await provider.updateChild(
        childId: widget.child!.id,
        firstName: _firstNameController.text,
        lastName: _lastNameController.text,
        dateOfBirth: _dateOfBirth,
        gender: _gender,
        newPhoto: _photo,
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
                value: _gender,
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
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
        ElevatedButton(
          onPressed: _isLoading ? null : _save,
          child: _isLoading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Enregistrer'),
        ),
      ],
    );
  }
}
