import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/auth_provider_v2.dart';
import '../services/club_service.dart';
import '../widgets/glass_card.dart';

class ClubCoachesScreen extends StatefulWidget {
  const ClubCoachesScreen({super.key});

  @override
  State<ClubCoachesScreen> createState() => _ClubCoachesScreenState();
}

class _ClubCoachesScreenState extends State<ClubCoachesScreen> {
  final ClubService _clubService = ClubService();
  List<Map<String, dynamic>> _coaches = [];
  List<Map<String, dynamic>> _courses = [];
  Map<String, List<Map<String, dynamic>>> _coachCourses = {};
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final auth = context.read<AuthProviderV2>();
      final userId = auth.currentUser!.uid;

      final courses = await _clubService.getClubCourses(userId);
      final courseIds = courses.map((c) => c['id'] as String).toList();

      final coachingHistory = await _clubService.getClubCoachingHistory(courseIds);

      final coachIds = coachingHistory
          .map((ch) => ch['coach_id'] as String)
          .toSet()
          .toList();

      Map<String, Map<String, dynamic>> coachData = {};
      if (coachIds.isNotEmpty) {
        final coachesRes = await _clubService.getCoachesDetails(coachIds);
        for (final c in coachesRes) {
          coachData[c['id'] as String] = c;
        }
      }

      final coachMap = <String, Map<String, dynamic>>{};
      final coachCoursesMap = <String, List<Map<String, dynamic>>>{};
      for (final ch in coachingHistory) {
        final cid = ch['coach_id'] as String;
        if (!coachMap.containsKey(cid)) {
          coachMap[cid] = Map<String, dynamic>.from(coachData[cid] ?? {});
        }
        coachCoursesMap.putIfAbsent(cid, () => []);
        final courseInfo = ch['course'] as Map<String, dynamic>?;
        if (courseInfo != null) {
          coachCoursesMap[cid]!.add({
            'course_id': ch['course_id'],
            'title': courseInfo['title'] ?? 'Cours',
            'role': ch['role'] ?? 'assistant',
          });
        }
      }

      setState(() {
        _coaches = coachMap.entries.map((e) => {'id': e.key, ...e.value}).toList();
        _courses = courses;
        _coachCourses = coachCoursesMap;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _showAddCoachDialog() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => _AddCoachDialog(courses: _courses, clubService: _clubService),
    );
    if (result != null && mounted) {
      try {
        await _clubService.assignCoachToCourse(
          courseId: result['course_id'],
          coachId: result['coach_id'],
          role: result['role'],
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Coach ajouté au cours')),
          );
          _loadData();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
        }
      }
    }
  }

  Future<void> _removeCoach(String coachId, String courseId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Retirer le coach ?'),
        content: const Text('Cette action retire le coach de ce cours.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Retirer'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      try {
        await _clubService.removeCoachFromCourse(coachId, courseId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Coach retiré du cours')),
          );
          _loadData();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Coaches du club'),
        actions: [
          IconButton(icon: const Icon(Icons.person_add), onPressed: _showAddCoachDialog, tooltip: 'Ajouter un coach'),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          Text('Erreur: $_error', textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _loadData, child: const Text('Réessayer')),
        ]),
      );
    }
    if (_coaches.isEmpty) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text('Aucun coach associé', style: TextStyle(fontSize: 16, color: Colors.grey[600])),
          const SizedBox(height: 8),
          ElevatedButton.icon(onPressed: _showAddCoachDialog, icon: const Icon(Icons.person_add), label: const Text('Ajouter un coach')),
        ]),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _coaches.length,
        itemBuilder: (context, index) {
          final coach = _coaches[index];
          return _CoachCard(
            coach: coach,
            courses: _coachCourses[coach['id']] ?? [],
            onRemove: (courseId) => _removeCoach(coach['id'], courseId),
          );
        },
      ),
    );
  }
}

class _CoachCard extends StatelessWidget {
  final Map<String, dynamic> coach;
  final List<Map<String, dynamic>> courses;
  final Function(String courseId) onRemove;

  const _CoachCard({required this.coach, required this.courses, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final profileImages = coach['profile_images'];
    final photoUrl = profileImages is Map ? profileImages['profileImageSupabase'] as String? : null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundImage: photoUrl != null ? CachedNetworkImageProvider(photoUrl) : null,
                  child: photoUrl == null
                      ? Text((coach['name'] as String? ?? '?')[0].toUpperCase(), style: const TextStyle(fontSize: 22))
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(coach['name'] ?? 'Coach', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      if (coach['email'] != null) Text(coach['email'], style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                      if (coach['phone_number'] != null) Text(coach['phone_number'], style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text('${courses.length} cours', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onPrimaryContainer)),
                ),
              ],
            ),
            if (courses.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 8),
              Text('Cours assignés:', style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              ...courses.map((c) => Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  children: [
                    Icon(Icons.sports_kabaddi, size: 16, color: Colors.grey[500]),
                    const SizedBox(width: 8),
                    Expanded(child: Text(c['title'] ?? '', style: const TextStyle(fontSize: 14))),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: c['role'] == 'head' ? Colors.amber.withValues(alpha: 0.1) : Colors.blue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(c['role'] == 'head' ? 'Principal' : 'Assistant', style: TextStyle(fontSize: 10, color: c['role'] == 'head' ? Colors.amber.shade800 : Colors.blue.shade700)),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => onRemove(c['course_id']),
                      child: Icon(Icons.remove_circle_outline, size: 18, color: Colors.red[400]),
                    ),
                  ],
                ),
              )),
            ],
          ],
        ),
      ),
    );
  }
}

class _AddCoachDialog extends StatefulWidget {
  final List<Map<String, dynamic>> courses;
  final ClubService clubService;
  const _AddCoachDialog({required this.courses, required this.clubService});

  @override
  State<_AddCoachDialog> createState() => _AddCoachDialogState();
}

class _AddCoachDialogState extends State<_AddCoachDialog> {
  final _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;
  Map<String, dynamic>? _selectedCoach;
  String? _selectedCourseId;
  String _selectedRole = 'assistant';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchCoaches() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;
    setState(() => _isSearching = true);
    try {
      final results = await widget.clubService.searchCoaches(query);
      setState(() => _searchResults = results);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
    } finally {
      setState(() => _isSearching = false);
    }
  }

  void _submit() {
    if (_selectedCoach == null || _selectedCourseId == null) return;
    Navigator.pop(context, {
      'coach_id': _selectedCoach!['id'],
      'course_id': _selectedCourseId,
      'role': _selectedRole,
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Ajouter un coach'),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  labelText: 'Rechercher un coach',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(icon: const Icon(Icons.clear), onPressed: () { _searchController.clear(); setState(() => _searchResults = []); })
                      : null,
                ),
                onChanged: (_) => _searchCoaches(),
              ),
              if (_isSearching) const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator())),
              if (_searchResults.isNotEmpty && !_isSearching) ...[
                const SizedBox(height: 12),
                Text('Résultats:', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey[700])),
                const SizedBox(height: 8),
                Material(
                  color: Colors.transparent,
                  child: Column(
                    children: _searchResults.map((coach) => ListTile(
                      dense: true,
                      selected: _selectedCoach?['id'] == coach['id'],
                      leading: CircleAvatar(radius: 18, child: Text((coach['name'] as String? ?? '?')[0].toUpperCase())),
                      title: Text(coach['name'] ?? ''),
                      subtitle: Text(coach['email'] ?? ''),
                      onTap: () => setState(() => _selectedCoach = coach),
                    )).toList(),
                  ),
                ),
              ],
              if (_selectedCoach != null) ...[
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _selectedCourseId,
                  decoration: const InputDecoration(labelText: 'Assigner au cours'),
                  items: widget.courses.map((c) => DropdownMenuItem(value: c['id'] as String, child: Text(c['title'] ?? ''))).toList(),
                  onChanged: (v) => setState(() => _selectedCourseId = v),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _selectedRole,
                  decoration: const InputDecoration(labelText: 'Rôle'),
                  items: const [
                    DropdownMenuItem(value: 'assistant', child: Text('Assistant')),
                    DropdownMenuItem(value: 'head', child: Text('Coach principal')),
                  ],
                  onChanged: (v) => setState(() => _selectedRole = v!),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
        FilledButton(onPressed: (_selectedCoach != null && _selectedCourseId != null) ? _submit : null, child: const Text('Ajouter')),
      ],
    );
  }
}
