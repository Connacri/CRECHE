import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/course_model_complete.dart';
import '../services/auth_service.dart';

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
      height: 165, // Fixed height to ensure stability and alignment
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Row(
            children: [
              // ── ZONE IMAGE (Partie Gauche) ──────────────────────────────
              SizedBox(
                width: 130,
                child: _ImageHeader(
                  imageUrl: course.images.isNotEmpty ? course.images.first.supabaseUrl : null,
                  isFavorited: isFavorited,
                  onFavorite: onFavorite,
                  rating: rating,
                  primary: cs.primary,
                ),
              ),

              // ── ZONE CONTENU (Partie Droite) ────────────────────────────
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Titre & Badge Niveau
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              course.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        _levelLabel,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: cs.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                      
                      const SizedBox(height: 8),
                      
                      // Description (Flexible but constrained)
                      Expanded(
                        child: Text(
                          course.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                            fontSize: 11,
                            height: 1.3,
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 8),

                      // Enfants inscrits (Compact Row)
                      if (enrolledChildren.isNotEmpty) ...[
                        SizedBox(
                          height: 18,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: enrolledChildren.length,
                            separatorBuilder: (_, __) => const SizedBox(width: 4),
                            itemBuilder: (context, index) => _ChildChip(
                              name: enrolledChildren[index],
                              primary: cs.primary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],

                      // Prix + CTA
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${(course.price ?? 0).toStringAsFixed(0)} DA',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w900,
                                fontSize: 15,
                                color: cs.onSurface,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            height: 32,
                            child: FilledButton(
                              onPressed: onTap,
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 14),
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                backgroundColor: cs.primary,
                              ),
                              child: const Text(
                                "S'inscrire", 
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)
                              ),
                            ),
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
      ),
    );
  }
}

class _ImageHeader extends StatelessWidget {
  final String? imageUrl;
  final bool isFavorited;
  final VoidCallback onFavorite;
  final double? rating;
  final Color primary;

  const _ImageHeader({required this.imageUrl, required this.isFavorited, required this.onFavorite, required this.rating, required this.primary});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Stack(
      children: [
        Positioned.fill(
          child: ClipRRect(
            child: _buildImage(cs),
          ),
        ),
        // Gradient overlay for better text contrast
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.1),
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.2),
                ],
              ),
            ),
          ),
        ),
        // Rating
        if (rating != null)
          Positioned(
            top: 10,
            left: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min, // Fix: Use min size to avoid overflow
                children: [
                  const Icon(Icons.star_rounded, color: Colors.amber, size: 12),
                  const SizedBox(width: 2),
                  Text(
                    rating!.toStringAsFixed(1), 
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)
                  ),
                ],
              ),
            ),
          ),
        // Favorite
        Positioned(
          bottom: 10,
          right: 10,
          child: GestureDetector(
            onTap: onFavorite,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: Colors.black12, blurRadius: 4, offset: const Offset(0, 2)),
                ],
              ),
              child: Icon(
                isFavorited ? Icons.favorite_rounded : Icons.favorite_border_rounded, 
                color: isFavorited ? Colors.red : Colors.grey.shade600, 
                size: 16
              ),
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
        errorWidget: (c, u, e) => Container(
          color: cs.surfaceContainerHighest,
          child: const Icon(Icons.broken_image_outlined, size: 30),
        ),
      );
    }
    return Container(
      color: primary.withValues(alpha: 0.05), 
      child: Icon(Icons.image_outlined, color: primary.withValues(alpha: 0.2), size: 40)
    );
  }
}

class _ChildChip extends StatelessWidget {
  final String name;
  final Color primary;
  const _ChildChip({required this.name, required this.primary});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.08), 
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: primary.withValues(alpha: 0.1)),
      ),
      child: Text(
        name, 
        style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: primary)
      ),
    );
  }
}
