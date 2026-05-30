import 'package:flutter/material.dart';
import '../models/app_models.dart';
import '../theme/app_theme.dart';

class StoryDetailScreen extends StatelessWidget {
  final Story story;

  const StoryDetailScreen({super.key, required this.story});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(story.title, style: const TextStyle(fontWeight: FontWeight.bold)),
              background: Image.asset(story.coverImage, fit: BoxFit.cover),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const CircleAvatar(
                        backgroundColor: AppColors.softBlue,
                        child: Icon(Icons.person, color: Colors.white),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Écrit par', style: TextStyle(fontSize: 12, color: AppColors.textLight)),
                          Text(story.author, style: const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const Spacer(),
                      IconButton(onPressed: () {}, icon: const Icon(Icons.share_outlined)),
                    ],
                  ),
                  const SizedBox(height: 30),
                  Text(
                    story.content,
                    style: const TextStyle(fontSize: 18, height: 1.6),
                  ),
                  const SizedBox(height: 50),
                  Center(
                    child: ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.favorite),
                      label: const Text('J\'ai adoré cette histoire !'),
                    ),
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
