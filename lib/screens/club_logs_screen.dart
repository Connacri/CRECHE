import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider_v2.dart';
import '../services/activity_service.dart';
import '../widgets/glass_card.dart';

class ClubLogsScreen extends StatefulWidget {
  const ClubLogsScreen({super.key});

  @override
  State<ClubLogsScreen> createState() => _ClubLogsScreenState();
}

class _ClubLogsScreenState extends State<ClubLogsScreen> {
  final _activityService = ActivityService();
  List<Map<String, dynamic>> _activities = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadActivities();
  }

  Future<void> _loadActivities() async {
    setState(() => _isLoading = true);
    try {
      final auth = context.read<AuthProviderV2>();
      final userId = auth.currentUser?.uid;
      if (userId != null) {
        final logs = await _activityService.getRecentActivities(userId);
        setState(() {
          _activities = logs;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors du chargement des logs: $e')),
        );
      }
    }
  }

  IconData _getIcon(String iconName) {
    switch (iconName) {
      case 'people': return Icons.people;
      case 'people_outline': return Icons.people_outline;
      case 'event': return Icons.event;
      case 'account_balance': return Icons.account_balance;
      default: return Icons.history;
    }
  }

  Color _getColor(String type) {
    switch (type) {
      case 'member': return Colors.blue;
      case 'coach': return Colors.indigo;
      case 'event': return Colors.purple;
      case 'finance': return Colors.green;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Journal d\'activité'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadActivities,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _activities.isEmpty
              ? const Center(child: Text('Aucune activité récente'))
              : RefreshIndicator(
                  onRefresh: _loadActivities,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _activities.length,
                    itemBuilder: (context, index) {
                      final log = _activities[index];
                      final date = DateTime.tryParse(log['date']) ?? DateTime.now();
                      final color = _getColor(log['type']);

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: GlassCard(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(_getIcon(log['icon']), color: color, size: 24),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      log['title'],
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                    Text(
                                      log['subtitle'],
                                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      DateFormat('dd/MM/yyyy HH:mm').format(date),
                                      style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
