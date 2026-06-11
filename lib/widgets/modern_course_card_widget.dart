import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/course_model_complete.dart';
import '../services/auth_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SIGNATURE DU WIDGET — Breaking change volontaire vs l'ancienne version
//
//  Ajouts requis vs l'ancienne signature :
//    • onFavorite   (VoidCallback, required)
//    • isFavorited  (bool, default false)
//    • rating       (double?, default null  → badge caché si absent)
// ─────────────────────────────────────────────────────────────────────────────
class CourseCard extends StatelessWidget {
  final CourseModel course;
  final VoidCallback onTap;
  final VoidCallback onFavorite;
  final bool isFavorited;
  final List<String> enrolledChildren;
  final double? rating;

  const CourseCard({
    super.key,
    required this.course,
    required this.onTap,
    required this.onFavorite,
    this.isFavorited = false,
    this.enrolledChildren = const [],
    this.rating,
  });

  // Dérivé du modèle : préférence tranche d'âge > catégorie
  String get _levelLabel {
    final min = course.minAge;
    final max = course.maxAge;
    if (min != null && max != null) return '$min – $max ans';
    if (min != null) return 'Dès $min ans';
    return course.category.displayName;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.09),
            blurRadius: 24,
            spreadRadius: 0,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── ZONE IMAGE ──────────────────────────────────────────────
              _ImageHeader(
                imageUrl: course.images.isNotEmpty
                    ? course.images.first.supabaseUrl
                    : null,
                isFavorited: isFavorited,
                onFavorite: onFavorite,
                rating: rating,
                primary: cs.primary,
              ),

              // ── ZONE CONTENU ────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Titre (orange bold)
                    Text(
                      course.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: cs.primary,
                        height: 1.2,
                      ),
                    ),

                    const SizedBox(height: 4),

                    // Niveau / tranche d'âge (gris, comme "Beginner")
                    Text(
                      _levelLabel,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Description (2 lignes)
                    SizedBox(
                      height: 32, // Hauteur fixe pour éviter les variations
                      child: Text(
                        course.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                          height: 1.3,
                        ),
                      ),
                    ),

                    // Chips enfants inscrits (si présents)
                    if (enrolledChildren.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: enrolledChildren
                            .map((n) => _ChildChip(name: n, primary: cs.primary))
                            .toList(),
                      ),
                    ],

                    const SizedBox(height: 16),

                    // ── LIGNE PRIX + BOUTON CTA ──────────────────────────
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${(course.price ?? 0).toStringAsFixed(0)} DA',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  color: cs.onSurface,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          height: 36,
                          child: FilledButton(
                            onPressed: onTap,
                            style: FilledButton.styleFrom(
                              backgroundColor: cs.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(50),
                              ),
                            ),
                            child: const Text(
                              "S'inscrire",
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),
                  ],
                ),
              ),

              // ── SÉPARATEUR ──────────────────────────────────────────────
              Divider(
                height: 1,
                thickness: 1,
                color: cs.outlineVariant.withValues(alpha: 0.35),
              ),

              // ── SECTION AUTEUR ───────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: _AuthorRow(
                  course: course,
                  primary: cs.primary,
                  theme: theme,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// IMAGE HEADER  (image + bouton favori + badge rating)
// ─────────────────────────────────────────────────────────────────────────────
class _ImageHeader extends StatelessWidget {
  final String? imageUrl;
  final bool isFavorited;
  final VoidCallback onFavorite;
  final double? rating;
  final Color primary;

  const _ImageHeader({
    required this.imageUrl,
    required this.isFavorited,
    required this.onFavorite,
    required this.rating,
    required this.primary,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Stack(
      children: [
        // Image principale (ratio 4:3 comme dans le design de référence)
        AspectRatio(
          aspectRatio: 4 / 3,
          child: _buildImage(cs),
        ),

        // Gradient bas pour lisibilité du badge
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0.5, 1.0],
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.20),
                ],
              ),
            ),
          ),
        ),

        // ❤️ Bouton favori (cercle blanc, coin haut-droit)
        Positioned(
          top: 12,
          right: 12,
          child: GestureDetector(
            onTap: onFavorite,
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.14),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  transitionBuilder: (child, anim) => ScaleTransition(
                    scale: anim,
                    child: child,
                  ),
                  child: Icon(
                    isFavorited
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    key: ValueKey(isFavorited),
                    color:
                    isFavorited ? Colors.red.shade400 : Colors.grey.shade400,
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
        ),

        // ⭐ Badge rating (pilule blanche, coin bas-gauche)
        if (rating != null)
          Positioned(
            bottom: 12,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    rating!.toStringAsFixed(1),
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text('⭐', style: TextStyle(fontSize: 12)),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildImage(ColorScheme cs) {
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: imageUrl!,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          color: primary.withValues(alpha: 0.08),
          child: const Center(
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
        errorWidget: (context, url, error) => Container(
          color: cs.surfaceContainerHighest,
          child: Icon(
            Icons.broken_image_outlined,
            color: cs.onSurfaceVariant,
            size: 48,
          ),
        ),
      );
    }

    // Fallback : fond coloré avec icône centrée
    return Container(
      color: primary.withValues(alpha: 0.08),
      child: Icon(
        Icons.image_outlined,
        color: primary.withValues(alpha: 0.30),
        size: 56,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SECTION AUTEUR  (avatar initiales + nom + handle)
// ─────────────────────────────────────────────────────────────────────────────
class _AuthorRow extends StatefulWidget {
  final CourseModel course;
  final Color primary;
  final ThemeData theme;

  const _AuthorRow({
    required this.course,
    required this.primary,
    required this.theme,
  });

  @override
  State<_AuthorRow> createState() => _AuthorRowState();
}

class _AuthorRowState extends State<_AuthorRow> {
  final AuthService _authService = AuthService();
  late Future<Map<String, String>> _instructorData;

  @override
  void initState() {
    super.initState();
    _instructorData = _fetchData();
  }

  @override
  void didUpdateWidget(_AuthorRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.course.createdBy != widget.course.createdBy || 
        oldWidget.course.clubId != widget.course.clubId) {
      _instructorData = _fetchData();
    }
  }

  Future<Map<String, String>> _fetchData() async {
    String coachName = '';
    String clubName = '';

    // Fetch Coach
    final coachData = await _authService.getUserData(widget.course.createdBy);
    if (coachData != null) {
      coachName = coachData['name'] ?? coachData['displayName'] ?? '';
    }

    // Fetch Club if exists
    if (widget.course.clubId != null && widget.course.clubId!.isNotEmpty) {
      final clubData = await _authService.getUserData(widget.course.clubId!);
      if (clubData != null) {
        clubName = clubData['name'] ?? clubData['displayName'] ?? '';
      }
    }

    return {
      'coach': coachName.isEmpty ? 'Instructeur' : coachName,
      'club': clubName,
    };
  }

  String _getInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : 'I';
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, String>>(
      future: _instructorData,
      builder: (context, snapshot) {
        final data = snapshot.data ?? {'coach': '...', 'club': ''};
        final coach = data['coach']!;
        final club = data['club']!;

        final String displayName = club.isNotEmpty 
            ? (coach != 'Instructeur' ? '$coach • $club' : club)
            : coach;

        final String handle = '@${displayName.toLowerCase().trim().replaceAll(RegExp(r'\s+'), '_').replaceAll(RegExp(r'[^a-z0-9_]'), '')}';

        return Row(
          children: [
            // Avatar initiales
            CircleAvatar(
              radius: 20,
              backgroundColor: widget.primary.withValues(alpha: 0.12),
              child: Text(
                _getInitials(coach != '...' ? coach : 'I'),
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: widget.primary,
                ),
              ),
            ),

            const SizedBox(width: 10),

            // Nom + handle (Expanded pour éviter l'overflow horizontal)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: widget.theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    handle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: widget.theme.textTheme.labelSmall?.copyWith(
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CHIP ENFANT INSCRIT
// ─────────────────────────────────────────────────────────────────────────────
class _ChildChip extends StatelessWidget {
  final String name;
  final Color primary;

  const _ChildChip({required this.name, required this.primary});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: primary.withValues(alpha: 0.2)),
      ),
      child: Text(
        name,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: primary,
        ),
      ),
    );
  }
}