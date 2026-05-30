import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/course_model_complete.dart';
import '../providers/course_provider_complete.dart';
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Colors.white),
        actions: [
          IconButton(icon: const Icon(Icons.share, color: Colors.white), onPressed: () {}),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: _course.images.isNotEmpty
              ? CachedNetworkImage(imageUrl: _course.images.first.supabaseUrl ?? '', fit: BoxFit.cover)
              : Image.asset('assets/images/meditation_bg.jpg', fit: BoxFit.cover),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black.withValues(alpha: 0.3), Colors.transparent, Colors.black.withValues(alpha: 0.5)],
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
                        _buildBadge(_course.category.name),
                        const SizedBox(height: 8),
                        Text(_course.title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            const Icon(Icons.location_on_outlined, size: 16),
                            const SizedBox(width: 4),
                            Expanded(child: Text(_course.location.address, style: Theme.of(context).textTheme.bodySmall)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(_course.description, style: Theme.of(context).textTheme.bodyMedium, maxLines: 4, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Prix', style: TextStyle(fontSize: 12)),
                                Text('${_course.price?.toStringAsFixed(2) ?? "0.00"} €', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                              ],
                            ),
                            FilledButton(
                              onPressed: () {},
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

  Widget _buildBadge(String text) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(color: colorScheme.primary.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)),
      child: Text(text, style: TextStyle(color: colorScheme.primary, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}
