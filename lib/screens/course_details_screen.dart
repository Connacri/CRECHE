import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/course_model_complete.dart';
import '../providers/auth_provider_v2.dart';
import '../providers/child_enrollment_provider.dart';
import '../widgets/glass_card.dart';

class CourseDetailsScreen extends StatefulWidget {
  final CourseModel course;

  const CourseDetailsScreen({
    super.key,
    required this.course,
  });

  @override
  State<CourseDetailsScreen> createState() => _CourseDetailsScreenState();
}

class _CourseDetailsScreenState extends State<CourseDetailsScreen> {
  late CourseModel _course;

  @override
  void initState() {
    super.initState();
    _course = widget.course;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadEnrollmentData();
    });
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
            child: Column(
              children: [
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: GlassCard(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildBadge(_course.category.displayName),
                            _buildBadge(
                              '${_course.availableSpots} places restantes',
                              color: _course.availableSpots < 5 ? Colors.orange : Colors.green,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
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
                            const Icon(Icons.location_on_outlined, size: 16, color: Colors.white70),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                _course.location.address,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white70),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            const Icon(Icons.calendar_month_outlined, size: 16, color: Colors.white70),
                            const SizedBox(width: 4),
                            Text(
                              'Saison : ${_course.season.displayName}',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white70),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _course.description,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white),
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Tarif',
                                  style: TextStyle(fontSize: 12, color: Colors.white70),
                                ),
                                Text(
                                  '${_course.price?.toStringAsFixed(0) ?? "0"} DA',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 22,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                            FilledButton(
                              onPressed: _handleEnrollment,
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                              ),
                              child: const Text('S\'inscrire'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
