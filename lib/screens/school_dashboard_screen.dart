import "package:mobile_scanner/mobile_scanner.dart";
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider_v2.dart';
import '../providers/course_provider_complete.dart';
import '../models/user_model.dart';
import '../models/course_model_complete.dart';
import '../models/session_schedule_model.dart';
import '../widgets/glass_card.dart';
import '../widgets/interactive_weekly_timetable.dart';
import '../widgets/add_session_dialog.dart';
import 'profile_screen.dart';

class SchoolDashboard extends StatefulWidget {
  const SchoolDashboard({super.key});

  @override
  State<SchoolDashboard> createState() => _SchoolDashboardState();
}

class _SchoolDashboardState extends State<SchoolDashboard> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildPage(),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildPage() {
    switch (_selectedIndex) {
      case 0: return const _OverviewPage();
      case 1: return const _PlanningManagementPage();
      case 2: return const ProfileScreen();
      default: return const _OverviewPage();
    }
  }

  Widget _buildBottomNav() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: GlassCard(
        opacity: 0.8,
        borderRadius: BorderRadius.circular(30),
        child: BottomNavigationBar(
          elevation: 0,
          backgroundColor: Colors.transparent,
          currentIndex: _selectedIndex,
          onTap: (i) => setState(() => _selectedIndex = i),
          selectedItemColor: Theme.of(context).colorScheme.primary,
          unselectedItemColor: Theme.of(context).colorScheme.onSurfaceVariant,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded), label: 'Aperçu'),
            BottomNavigationBarItem(icon: Icon(Icons.calendar_month), label: 'Planning'),
            BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Profil'),
          ],
        ),
      ),
    );
  }
}

class _OverviewPage extends StatelessWidget {
  const _OverviewPage();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProviderV2>();
    final user = auth.userData != null ? UserModel.fromSupabase(auth.userData!) : null;

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 120,
          flexibleSpace: FlexibleSpaceBar(
            title: Text('Tableau de Bord', style: TextStyle(color: Theme.of(context).colorScheme.onPrimary, fontWeight: FontWeight.bold)),
            background: Container(color: Theme.of(context).colorScheme.primary),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(24),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              Text('Bienvenue, ${user?.name ?? "Club"}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              _buildStatsGrid(context),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsGrid(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      children: [
        _buildStatCard(context, 'Membres', '124', Icons.people, Colors.blue),
        _buildStatCard(context, 'Cours Actifs', '12', Icons.school, Colors.green),
        _buildStatCard(context, 'Sessions/Jour', '8', Icons.timer, Colors.orange),
        _buildStatCard(context, 'Revenus', '450k', Icons.payments, Colors.purple),
      ],
    );
  }

  Widget _buildStatCard(BuildContext context, String title, String value, IconData icon, Color color) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }
}

class _PlanningManagementPage extends StatefulWidget {
  const _PlanningManagementPage();

  @override
  State<_PlanningManagementPage> createState() => _PlanningManagementPageState();
}

class _PlanningManagementPageState extends State<_PlanningManagementPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final auth = context.read<AuthProviderV2>();
        final provider = context.read<CourseProvider>();
        provider.loadOwnerSchedules(auth.currentUser!.uid);
        provider.loadCoaches();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CourseProvider>();
    final schedules = provider.schedules;
    final courses = provider.userCourses;
    final coaches = provider.coaches;

    final Map<String, String> coachesNames = {
      for (var c in coaches) c.uid: c.name
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Planning & Horaires', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                onPressed: () => _showAddScheduleDialog(context, courses, coaches),
              ),
            ],
          ),
        ),
        if (provider.isLoading)
          const Expanded(child: Center(child: CircularProgressIndicator()))
        else if (courses.isEmpty)
          const Expanded(child: Center(child: Text("Créez d'abord un cours pour pouvoir planifier des horaires.")))
        else
          Expanded(
            child: InteractiveWeeklyTimetable(
              schedules: schedules,
              courses: courses,
              coachesNames: coachesNames,
              onEmptySlotTap: (day, slot) => _showAddScheduleDialog(context, courses, coaches, initialDay: day, initialTimeSlot: slot),
              onSessionTap: (session) => _showAddScheduleDialog(context, courses, coaches, sessionToEdit: session),
            ),
          ),
      ],
    );
  }

  void _showAddScheduleDialog(BuildContext context, List<CourseModel> courses, List<UserModel> coaches, {DayOfWeek? initialDay, TimeSlot? initialTimeSlot, SessionSchedule? sessionToEdit}) {
    showDialog(
      context: context,
      builder: (context) => AddSessionDialog(
        courses: courses,
        coaches: coaches,
        initialDay: initialDay,
        initialTimeSlot: initialTimeSlot,
        sessionToEdit: sessionToEdit,
      ),
    );

    if (result != null) {
      if (result == 'delete' && sessionToEdit != null) {
        await provider.deleteSchedule(sessionToEdit.id);
      } else if (result is SessionSchedule) {
        if (sessionToEdit != null) {
          await provider.updateSchedule(sessionToEdit.id, result.toSupabase());
          // Rafraîchir
          if (context.mounted) {
            final auth = context.read<AuthProviderV2>();
            provider.loadOwnerSchedules(auth.currentUser!.uid);
          }
        } else {
          await provider.createSchedule(result);
        }
      }
    }
  }
}

class _DashboardOverview extends StatelessWidget {
  const _DashboardOverview();


  @override
  Widget build(BuildContext context) {
    final courses = context.watch<CourseProvider>().userCourses;
    final enrollmentProvider = context.watch<ChildEnrollmentProvider>();
    final enrollments = enrollmentProvider.ownerEnrollmentsDetailed;
    final memberCount = enrollmentProvider.memberCount;
    final graphData = enrollmentProvider.monthlyEnrollmentStats;

    final pendingEnrollments = enrollments.where((e) {
      final enrollment = EnrollmentModel.fromSupabase(e['enrollment']);
      return enrollment.status == EnrollmentStatus.pending;
    }).length;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          children: [
            Expanded(child: _StatCard('Cours actifs', courses.where((c) => c.isActive).length.toString(), Icons.school, Colors.blue)),
            const SizedBox(width: 12),
            Expanded(child: _StatCard('Inscriptions', enrollments.length.toString(), Icons.people, Colors.green)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _StatCard('En attente', pendingEnrollments.toString(), Icons.hourglass_empty, Colors.orange)),
            const SizedBox(width: 12),
            Expanded(child: _StatCard('Adhérents', memberCount.toString(), Icons.card_membership, Colors.purple)),
          ],
        ),
        const SizedBox(height: 24),
        Text('Inscriptions mensuelles', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        GlassCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              SizedBox(
                height: 150,
                width: double.infinity,
                child: CustomPaint(
                  painter: _TrendChartPainter(data: graphData),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(width: 12, height: 12, decoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle)),
                  const SizedBox(width: 8),
                  const Text('Inscriptions', style: TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text('Actions rapides', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        InkWell(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateCourseScreen())),
          borderRadius: BorderRadius.circular(16),
          child: GlassCard(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.add_circle, color: Colors.blue, size: 28)),
                const SizedBox(width: 16),
                const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Créer un cours', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), Text('Ajouter un nouveau cours au catalogue', style: TextStyle(fontSize: 13, color: Colors.grey))])),
                const Icon(Icons.arrow_forward_ios, size: 16),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _StatCard(this.label, this.value, this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [Icon(icon, size: 18, color: color), const Spacer(), Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color))]),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        ],
      ),
    );
  }
}

class _EnrollmentsPage extends StatelessWidget {
  const _EnrollmentsPage();
  @override
  Widget build(BuildContext context) {
    final enrollments = context.watch<ChildEnrollmentProvider>().ownerEnrollmentsDetailed;
    final provider = context.read<ChildEnrollmentProvider>();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Inscriptions", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              IconButton(
                icon: const Icon(Icons.qr_code_scanner),
                onPressed: () => _openScanner(context, provider),
                tooltip: "Scanner un QR Code de paiement",
              ),
            ],
          ),
        ),
        if (enrollments.isEmpty)
          const Expanded(child: Center(child: Text("Aucune inscription.")))
        else
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              itemCount: enrollments.length,
              itemBuilder: (context, index) {
                final item = enrollments[index];
                final enrollment = EnrollmentModel.fromSupabase(item['enrollment']);
                final child = ChildModel.fromSupabase(item['child']);
                final course = CourseModel.fromSupabase(item['course']);

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
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('${child.firstName} ${child.lastName}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                  Text(course.title, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                                ],
                              ),
                            ),
                            _buildStatusChip(enrollment.status),
                          ],
                        ),
                        if (enrollment.status == EnrollmentStatus.pending) ...[
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: SizedBox(
                                  height: 36,
                                  child: ElevatedButton.icon(
                                    onPressed: () => _updateStatus(context, provider, enrollment.id, 'approved'),
                                    icon: const Icon(Icons.check, size: 18),
                                    label: const Text('Approuver', style: TextStyle(fontSize: 12)),
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: SizedBox(
                                  height: 36,
                                  child: OutlinedButton.icon(
                                    onPressed: () => _rejectDialog(context, provider, enrollment.id),
                                    icon: const Icon(Icons.close, size: 18),
                                    label: const Text('Refuser', style: TextStyle(fontSize: 12)),
                                    style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ] else if (enrollment.status == EnrollmentStatus.approved && enrollment.paymentStatus != PaymentStatus.paid) ...[
                          const Divider(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text("En attente de paiement", style: TextStyle(fontSize: 12, color: Colors.orange)),
                              ElevatedButton(
                                onPressed: () => _confirmPaymentFromQR(context, provider, enrollment.id),
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white, minimumSize: const Size(0, 32)),
                                child: const Text("Valider manuellement", style: TextStyle(fontSize: 11)),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  void _openScanner(BuildContext context, ChildEnrollmentProvider provider) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => Scaffold(
      appBar: AppBar(title: const Text("Scanner Paiement")),
      body: MobileScanner(
        onDetect: (capture) {
          final List<Barcode> barcodes = capture.barcodes;
          if (barcodes.isNotEmpty) {
            final String? code = barcodes.first.rawValue;
            if (code != null) {
              Navigator.pop(context);
              _confirmPaymentFromQR(context, provider, code);
            }
          }
        },
      ),
    )));
  }

  void _confirmPaymentFromQR(BuildContext context, ChildEnrollmentProvider provider, String enrollmentId) async {
    final success = await provider.updateEnrollment(
      enrollmentId: enrollmentId,
      paymentStatus: PaymentStatus.paid,
      paidAmount: 0 // Mock amount for now
    );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(success ? "Paiement validé avec succès" : "Erreur lors de la validation"))
      );
    }
  }

  void _updateStatus(BuildContext context, ChildEnrollmentProvider provider, String enrollmentId, String status) async {
    final enrollmentStatus = status == 'approved'
        ? EnrollmentStatus.approved
        : status == 'rejected'
            ? EnrollmentStatus.rejected
            : EnrollmentStatus.cancelled;
    try {
      await provider.updateEnrollment(enrollmentId: enrollmentId, status: enrollmentStatus);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(status == 'approved' ? 'Inscription approuvée' : 'Inscription mise à jour')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
    }
  }

  void _rejectDialog(BuildContext context, ChildEnrollmentProvider provider, String enrollmentId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Refuser l\'inscription'),
        content: const Text('Êtes-vous sûr de vouloir refuser cette inscription ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _updateStatus(context, provider, enrollmentId, 'rejected');
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Refuser'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(EnrollmentStatus status) {
    Color color;
    String text;
    switch (status) {
      case EnrollmentStatus.approved: color = Colors.green; text = 'Approuvé'; break;
      case EnrollmentStatus.pending: color = Colors.orange; text = 'En attente'; break;
      case EnrollmentStatus.rejected: color = Colors.red; text = 'Refusé'; break;
      case EnrollmentStatus.cancelled: color = Colors.grey; text = 'Annulé'; break;
      case EnrollmentStatus.completed: color = Colors.blue; text = 'Terminé'; break;
    }
    return Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: color)), child: Text(text, style: TextStyle(color: color, fontSize: 10)));
  }
}
class _TrendChartPainter extends CustomPainter {
  final List<Map<String, dynamic>> data;
  _TrendChartPainter({required this.data});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final paintLine = Paint()
      ..color = Colors.blue
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final paintPoint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.fill;

    final paintGrid = Paint()
      ..color = Colors.grey.withValues(alpha: 0.1)
      ..strokeWidth = 1;

    double maxVal = 0;
    for (var d in data) {
      if ((d['count'] as int).toDouble() > maxVal) maxVal = (d['count'] as int).toDouble();
    }
    if (maxVal == 0) maxVal = 5;
    maxVal *= 1.2;

    // Grid
    for (int i = 0; i <= 4; i++) {
      final y = size.height - (i * size.height / 4);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paintGrid);
    }

    final xStep = size.width / (data.length > 1 ? data.length - 1 : 1);
    final path = Path();

    for (int i = 0; i < data.length; i++) {
      final val = (data[i]['count'] as int).toDouble();
      final x = i * xStep;
      final y = size.height - (val / maxVal) * size.height;

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paintLine);

    for (int i = 0; i < data.length; i++) {
      final val = (data[i]['count'] as int).toDouble();
      final x = i * xStep;
      final y = size.height - (val / maxVal) * size.height;
      canvas.drawCircle(Offset(x, y), 4, paintPoint);

      // Label (Month)
      final monthStr = data[i]['month'].split('-')[1];
      final textPainter = TextPainter(
        text: TextSpan(
          text: monthStr,
          style: const TextStyle(color: Colors.grey, fontSize: 10),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(x - textPainter.width / 2, size.height + 8));
    }
  }
}
