import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:readmore/readmore.dart';

import '../models/course_model_complete.dart';
import '../providers/auth_provider_v2.dart';
import '../providers/child_enrollment_provider.dart';
import '../services/auth_service.dart';
import '../widgets/glass_card.dart';
import '../widgets/modern_course_card_widget.dart';

class CourseDetailsScreen extends StatefulWidget {
  final CourseModel course;
  final List<String> enrolledChildren;

  const CourseDetailsScreen({
    super.key,
    required this.course,
    this.enrolledChildren = const [],
  });

  @override
  State<CourseDetailsScreen> createState() => _CourseDetailsScreenState();
}

class _CourseDetailsScreenState extends State<CourseDetailsScreen> {
  late CourseModel _course;
  String? _creatorName;
  String? _coachName;
  bool _isLoadingCreator = true;
  bool _isLoadingCoach = false;

  @override
  void initState() {
    super.initState();
    _course = widget.course;
    _loadCreatorInfo();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadEnrollmentData();
    });
  }

  Future<void> _loadCreatorInfo() async {
    try {
      final authService = AuthService();
      final userData = await authService.getUserData(_course.createdBy);
      if (mounted) {
        setState(() {
          _creatorName = userData?['name'] ?? 'Créateur inconnu';
          _isLoadingCreator = false;
        });
      }
      
      if (_course.coachId != null && _course.coachId!.isNotEmpty && _course.coachId != _course.createdBy) {
        _loadCoachInfo();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _creatorName = 'Erreur chargement';
          _isLoadingCreator = false;
        });
      }
    }
  }

  Future<void> _loadCoachInfo() async {
    if (mounted) setState(() => _isLoadingCoach = true);
    try {
      final authService = AuthService();
      final userData = await authService.getUserData(_course.coachId!);
      if (mounted) {
        setState(() {
          _coachName = userData?['name'];
          _isLoadingCoach = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingCoach = false);
    }
  }

  Future<void> _loadEnrollmentData() async {
    final authProvider = context.read<AuthProviderV2>();
    final userId = authProvider.userData?['id'];
    if (userId != null && authProvider.userRole == 'parent') {
      final childProvider = context.read<ChildEnrollmentProvider>();
      await Future.wait([
        childProvider.loadChildren(userId),
        childProvider.loadEnrollments(userId),
      ]);
    }
  }

  String _getDayName(int? day) {
    switch (day) {
      case 1: return 'Lundi';
      case 2: return 'Mardi';
      case 3: return 'Mercredi';
      case 4: return 'Jeudi';
      case 5: return 'Vendredi';
      case 6: return 'Samedi';
      case 7: return 'Dimanche';
      default: return 'Non défini';
    }
  }

  void _handleEnrollment() {
    final authProvider = context.read<AuthProviderV2>();
    final userId = authProvider.userData?['id'] ?? '';

    if (userId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez vous connecter pour vous inscrire')),
      );
      return;
    }

    if (authProvider.userRole != 'parent') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seuls les parents peuvent inscrire des enfants')),
      );
      return;
    }

    if (!_course.hasAvailableSpots()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ce cours est complet')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _EnrollmentBottomSheet(
        course: _course,
        parentId: userId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.3),
            shape: BoxShape.circle,
          ),
          child: const BackButton(color: Colors.white),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.share, color: Colors.white),
              onPressed: () {},
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: _course.images.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: _course.images.first.supabaseUrl ?? '',
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(color: Colors.grey[300]),
                  errorWidget: (context, url, error) => Image.asset('assets/images/meditation_bg.jpg', fit: BoxFit.cover),
                )
              : Image.asset('assets/images/meditation_bg.jpg', fit: BoxFit.cover),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.3),
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.7),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Column(
                children: [
                  const SizedBox(height: 200), // Push content down to show background
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: GlassCard(
                      color: Colors.black45,
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildBadge(_course.category.displayName, color: Colors.white70),
                              if (_course.minAge != null)
                                _buildBadge(
                                  '${_course.minAge}${_course.maxAge != null ? "-${_course.maxAge}" : "+"} ans',
                                  color: Colors.blueAccent,
                                ),
                              _buildBadge(
                                '${_course.availableSpots} places',
                                color: _course.availableSpots < 5 ? Colors.orange : Colors.green,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _course.title,
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.business_outlined, size: 16, color: Colors.white70),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  _isLoadingCreator ? 'Chargement...' : 'Organisé par : $_creatorName',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.white70,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (_course.coachId != null && (_isLoadingCoach || _coachName != null)) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.person_outline, size: 16, color: Colors.white70),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    _isLoadingCoach ? 'Chargement coach...' : 'Coach : $_coachName',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.white70,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                          const SizedBox(height: 16),
                          _buildInfoRow(Icons.location_on_outlined, _course.location.address),
                          const SizedBox(height: 12),
                          _buildInfoRow(
                            Icons.calendar_month_outlined,
                            'Saison : ${_course.season.displayName} (${DateFormat('dd/MM').format(_course.seasonStartDate)} au ${DateFormat('dd/MM').format(_course.seasonEndDate)})',
                          ),
                          if (_course.hasWeeklySchedule) ...[
                            const SizedBox(height: 12),
                            _buildInfoRow(
                              Icons.access_time_outlined,
                              '${_getDayName(_course.dayOfWeek)} : ${_course.startTime?.format(context)} - ${_course.endTime?.format(context)}',
                            ),
                          ],
                          if (_course.roomId != null && _course.roomId!.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            _buildInfoRow(Icons.meeting_room_outlined, 'Salle : ${_course.roomId}'),
                          ],
                          const SizedBox(height: 24),
                          const Text(
                            'Description',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          ReadMoreText(
                            _course.description,
                            trimLines: 3,
                            colorClickableText: Colors.blueAccent,
                            trimMode: TrimMode.Line,
                            trimCollapsedText: '... Voir plus',
                            trimExpandedText: ' Voir moins',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white),
                            moreStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blueAccent),
                            lessStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blueAccent),
                          ),
                          if (_course.tags.isNotEmpty) ...[
                            const SizedBox(height: 24),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _course.tags.map((tag) => Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white10,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.white24),
                                ),
                                child: Text(
                                  '#$tag',
                                  style: const TextStyle(color: Colors.white70, fontSize: 10),
                                ),
                              )).toList(),
                            ),
                          ],
                          const SizedBox(height: 24),
                          // Enfants inscrits (Compact Row)
                          if (widget.enrolledChildren.isNotEmpty) ...[
                            const Text(
                              'Inscriptions actives :',
                              style: TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              height: 24,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: widget.enrolledChildren.length,
                                separatorBuilder: (_, __) => const SizedBox(width: 8),
                                itemBuilder: (context, index) => ChildChip(
                                  name: widget.enrolledChildren[index],
                                  primary: cs.inversePrimary,
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Tarif',
                                      style: TextStyle(fontSize: 12, color: Colors.white70),
                                    ),
                                    Text(
                                      '${_course.price?.toStringAsFixed(0) ?? "0"} ${_course.metadata?['currency'] ?? "DA"} / ${_course.pricingType.displayName.toLowerCase()}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 20,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              FilledButton(
                                onPressed: _handleEnrollment,
                                style: FilledButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                                  backgroundColor: cs.primary,
                                ),
                                child: const Text('S\'inscrire', style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.white70),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white70),
          ),
        ),
      ],
    );
  }

  Widget _buildBadge(String text, {Color? color}) {
    final colorScheme = Theme.of(context).colorScheme;
    final badgeColor = color ?? colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: badgeColor,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _EnrollmentBottomSheet extends StatefulWidget {
  final CourseModel course;
  final String parentId;

  const _EnrollmentBottomSheet({
    required this.course,
    required this.parentId,
  });

  @override
  State<_EnrollmentBottomSheet> createState() => _EnrollmentBottomSheetState();
}

class _EnrollmentBottomSheetState extends State<_EnrollmentBottomSheet> {
  final List<String> _selectedChildIds = [];
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    final childProvider = context.watch<ChildEnrollmentProvider>();
    final children = childProvider.children;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Inscription au cours',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          Text(
            widget.course.title,
            style: TextStyle(color: Theme.of(context).colorScheme.primary),
          ),
          const SizedBox(height: 24),
          const Text(
            'Sélectionnez les enfants à inscrire :',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          if (children.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Column(
                  children: [
                    const Text('Aucun enfant enregistré.'),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () {
                        // Naviguer vers l'ajout d'enfant (via dashboard par ex)
                        Navigator.pop(context);
                      },
                      child: const Text('Ajouter un enfant dans votre profil'),
                    ),
                  ],
                ),
              ),
            )
          else
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.4),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: children.length,
                itemBuilder: (context, index) {
                  final child = children[index];
                  final isEnrolled = childProvider.isChildEnrolledInCourse(child.id, widget.course.id);
                  final isSelected = _selectedChildIds.contains(child.id);

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: InkWell(
                      onTap: isEnrolled ? null : () {
                        setState(() {
                          if (isSelected) {
                            _selectedChildIds.remove(child.id);
                          } else {
                            _selectedChildIds.add(child.id);
                          }
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isSelected ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.05) : Colors.transparent,
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color: isSelected 
                                ? Theme.of(context).colorScheme.primary 
                                : Colors.grey.withValues(alpha: 0.2),
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Row(
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
                                  Text(child.fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
                                  Text('${child.age} ans • ${child.schoolGrade ?? "Niveau non précisé"}', style: const TextStyle(fontSize: 12)),
                                ],
                              ),
                            ),
                            if (isEnrolled)
                              const Icon(Icons.check_circle, color: Colors.green)
                            else if (isSelected)
                              Icon(Icons.check_box, color: Theme.of(context).colorScheme.primary)
                            else
                              const Icon(Icons.check_box_outline_blank, color: Colors.grey),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: (_selectedChildIds.isEmpty || _isSubmitting) ? null : _submitEnrollment,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              ),
              child: _isSubmitting 
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Confirmer l\'inscription'),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Future<void> _submitEnrollment() async {
    setState(() => _isSubmitting = true);
    
    final childProvider = context.read<ChildEnrollmentProvider>();
    bool allSuccess = true;

    for (final childId in _selectedChildIds) {
      final success = await childProvider.createEnrollment(
        courseId: widget.course.id,
        childId: childId,
        parentId: widget.parentId,
        totalAmount: widget.course.price,
      );
      if (!success) allSuccess = false;
    }

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (allSuccess) {
        Navigator.pop(context);
        _showSuccessDialog();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(childProvider.error ?? 'Une ou plusieurs inscriptions ont échoué')),
        );
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Félicitations !'),
        content: const Text('L\'inscription a été envoyée avec succès. Elle est en attente de validation par le responsable (club ou coach).'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
