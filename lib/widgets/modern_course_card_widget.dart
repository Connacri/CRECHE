import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../models/course_model_complete.dart';
import '../services/auth_service.dart';
import '../providers/auth_provider_v2.dart';

class CourseCard extends StatefulWidget {
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

  @override
  State<CourseCard> createState() => _CourseCardState();
}

class _CourseCardState extends State<CourseCard> {
  String? _creatorName;
  bool _isLoadingCreator = true;

  @override
  void initState() {
    super.initState();
    _loadCreatorInfo();
  }

  Future<void> _loadCreatorInfo() async {
    try {
      final authService = AuthService();
      final userData = await authService.getUserData(widget.course.createdBy);
      if (mounted) {
        setState(() {
          _creatorName = userData?['name'];
          _isLoadingCreator = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingCreator = false;
        });
      }
    }
  }

  String get _levelLabel {
    final min = widget.course.minAge;
    final max = widget.course.maxAge;
    final level = widget.course.level;

    String label = '';
    if (level != null) {
      label += '${level.displayName} • ';
    }

    if (min != null && max != null) {
      label += '$min – $max ans';
    } else if (min != null) {
      label += 'Dès $min ans';
    } else if (label.isEmpty) {
      label = widget.course.category.displayName;
    } else {
      label = label.substring(0, label.length - 3); // Remove trailing bullet
    }

    return label;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final authProvider = context.watch<AuthProviderV2>();
    final isParent = authProvider.userRole == 'parent';
    final isDisabled = !widget.course.isActive && isParent;

    return ColorFiltered(
      colorFilter: isDisabled
          ? const ColorFilter.mode(Colors.grey, BlendMode.saturation)
          : const ColorFilter.mode(Colors.transparent, BlendMode.multiply),
      child: Opacity(
        opacity: isDisabled ? 0.6 : 1.0,
        child: Container(
          height: 160, // Minimalist: Lower height
          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: isDisabled ? null : widget.onTap,
              child: Row(
                children: [
                  // ── IMAGE ──────────────────────────────
                  SizedBox(
                    width: 120,
                    child: _ImageHeader(
                      imageUrl: widget.course.images.isNotEmpty
                          ? widget.course.images.first.supabaseUrl
                          : null,
                      isFavorited: widget.isFavorited,
                      onFavorite: widget.onFavorite,
                      rating: widget.rating,
                      primary: cs.primary,
                      category: widget.course.category.displayName,
                    ),
                  ),

                  // ── CONTENT ────────────────────────────
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Creator (Indispensable)
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _isLoadingCreator ? "..." : "Organisé par : ${_creatorName ?? 'Club'}".toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 8, 
                                    color: cs.primary, 
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.5,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (isDisabled)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    "INDISPONIBLE",
                                    style: TextStyle(color: Colors.red, fontSize: 7, fontWeight: FontWeight.bold),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          // Title
                          Text(
                            widget.course.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 2),
                          // Description (Minimalist: Show description in black for white card)
                          Text(
                            widget.course.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.black87,
                              fontSize: 10,
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(height: 4),
                          // Location & Age
                          Row(
                            children: [
                              Icon(Icons.location_on, size: 10, color: Colors.grey[400]),
                              const SizedBox(width: 2),
                              Expanded(
                                child: Text(
                                  widget.course.location.city ?? widget.course.location.address,
                                  style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _levelLabel,
                                style: TextStyle(
                                  color: cs.secondary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                          
                          const Spacer(),
                          
                          // Bottom Row: Price & Spots
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${(widget.course.price ?? 0).toStringAsFixed(0)} ${widget.course.metadata?['currency'] ?? "DA"}',
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 14,
                                      color: cs.onSurface,
                                    ),
                                  ),
                                  Text(
                                    widget.course.pricingType.displayName,
                                    style: const TextStyle(fontSize: 8, color: Colors.grey),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: (widget.course.availableSpots < 5 ? Colors.orange : Colors.green).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '${widget.course.availableSpots} places',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: widget.course.availableSpots < 5 ? Colors.orange : Colors.green,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          // Enrolled Children (Minimalist version - just dots or small text if needed, but let's keep it simple)
                          if (widget.enrolledChildren.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              '${widget.enrolledChildren.length} enfant(s) inscrit(s)',
                              style: TextStyle(fontSize: 8, color: cs.primary, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
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
  final String category;

  const _ImageHeader({
    required this.imageUrl,
    required this.isFavorited,
    required this.onFavorite,
    required this.rating,
    required this.primary,
    required this.category,
  });

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
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.1),
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.3),
                ],
              ),
            ),
          ),
        ),
        // Category Badge on top of image
        Positioned(
          top: 10,
          left: 10,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              category,
              style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        // Rating
        if (rating != null)
          Positioned(
            top: 10,
            right: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.star_rounded, color: Colors.amber, size: 12),
                  const SizedBox(width: 2),
                  Text(rating!.toStringAsFixed(1),
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
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
                  size: 16),
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
        child: Icon(Icons.image_outlined, color: primary.withValues(alpha: 0.2), size: 40));
  }
}




class ChildChip extends StatelessWidget {
  final String name;
  final Color primary;
  const ChildChip({super.key, required this.name, required this.primary});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: primary.withValues(alpha: 0.1)),
      ),
      child: Text(name,
          style: TextStyle(
              fontSize: 9, fontWeight: FontWeight.w700, color: primary)),
    );
  }
}
