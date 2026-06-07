import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/auth_provider_v2.dart';
import '../services/event_service.dart';
import '../widgets/glass_card.dart';
import 'create_event_screen.dart';
import 'event_detail_screen.dart';

class ClubEventsScreen extends StatefulWidget {
  const ClubEventsScreen({super.key});

  @override
  State<ClubEventsScreen> createState() => _ClubEventsScreenState();
}

class _ClubEventsScreenState extends State<ClubEventsScreen> {
  final EventService _eventService = EventService();
  List<Map<String, dynamic>> _events = [];
  bool _isLoading = true;
  String? _error;
  String _filter = 'all';
  StreamSubscription? _eventsSubscription;

  @override
  void initState() {
    super.initState();
    _initRealtime();
  }

  void _initRealtime() {
    final auth = context.read<AuthProviderV2>();
    final userId = auth.currentUser!.uid;

    _eventsSubscription?.cancel();
    _eventsSubscription = _eventService.getClubEventsStream(userId).listen((data) {
      if (mounted) {
        setState(() {
          _events = data;
          _isLoading = false;
        });
      }
    }, onError: (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _eventsSubscription?.cancel();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filteredEvents {
    if (_filter == 'all') return _events;
    final now = DateTime.now();
    return _events.where((e) {
      final start = DateTime.parse(e['start_date']);
      final end = DateTime.parse(e['end_date']);
      if (_filter == 'upcoming') return start.isAfter(now);
      if (_filter == 'ongoing') return start.isBefore(now) && end.isAfter(now);
      if (_filter == 'past') return end.isBefore(now);
      return true;
    }).toList();
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'competition': return Colors.red;
      case 'stage': return Colors.blue;
      case 'porte_ouverte': return Colors.green;
      case 'reunion': return Colors.orange;
      case 'examen': return Colors.purple;
      case 'tournoi': return Colors.amber;
      case 'gala': return Colors.pink;
      default: return Colors.grey;
    }
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'competition': return 'Compétition';
      case 'stage': return 'Stage';
      case 'porte_ouverte': return 'Portes ouvertes';
      case 'reunion': return 'Réunion';
      case 'examen': return 'Examen';
      case 'tournoi': return 'Tournoi';
      case 'gala': return 'Gala';
      default: return 'Autre';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Événements du club'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              await Navigator.push<bool>(
                context,
                MaterialPageRoute(builder: (_) => const CreateEventScreen()),
              );
              // Pas besoin de recharger manuellement car Realtime s'en charge
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterBar(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    final filters = ['all', 'upcoming', 'ongoing', 'past'];
    final labels = ['Tous', 'À venir', 'En cours', 'Passés'];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(filters.length, (i) {
            final isSelected = _filter == filters[i];
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(labels[i]),
                selected: isSelected,
                onSelected: (_) => setState(() => _filter = filters[i]),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('Erreur: $_error'),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _initRealtime, child: const Text('Réessayer')),
          ],
        ),
      );
    }
    final events = _filteredEvents;
    if (events.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.event_busy, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text('Aucun événement', style: TextStyle(fontSize: 16, color: Colors.grey[600])),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () async {
                await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(builder: (_) => const CreateEventScreen()),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Créer un événement'),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () async => _initRealtime(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: events.length,
        itemBuilder: (context, index) {
          final event = events[index];
          return _EventCard(
            event: event,
            typeColor: _typeColor(event['type']),
            typeLabel: _typeLabel(event['type']),
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EventDetailScreen(eventId: event['id']),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  final Map<String, dynamic> event;
  final Color typeColor;
  final String typeLabel;
  final VoidCallback onTap;

  const _EventCard({
    required this.event,
    required this.typeColor,
    required this.typeLabel,
    required this.onTap,
  });

  String _formatDate(String iso) {
    final dt = DateTime.parse(iso);
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'draft': return 'Brouillon';
      case 'published': return 'Publié';
      case 'registration_open': return 'Inscriptions ouvertes';
      case 'ongoing': return 'En cours';
      case 'completed': return 'Terminé';
      case 'cancelled': return 'Annulé';
      default: return status;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'draft': return Colors.grey;
      case 'published': return Colors.blue;
      case 'registration_open': return Colors.green;
      case 'ongoing': return Colors.orange;
      case 'completed': return Colors.teal;
      case 'cancelled': return Colors.red;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final startDate = _formatDate(event['start_date']);
    final endDate = _formatDate(event['end_date']);
    final status = event['status'] ?? 'draft';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: GlassCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: typeColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: typeColor.withValues(alpha: 0.3)),
                    ),
                    child: Text(typeLabel, style: TextStyle(fontSize: 11, color: typeColor, fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _statusColor(status).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(_statusLabel(status), style: TextStyle(fontSize: 11, color: _statusColor(status))),
                  ),
                  const Spacer(),
                  if (event['is_paid'] == true && event['price'] != null)
                    Text('${event['price']} DA', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                ],
              ),
              const SizedBox(height: 12),
              Text(event['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              if (event['description'] != null && (event['description'] as String).isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  event['description'],
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 14, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text('$startDate - $endDate', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                  if (event['current_participants'] != null) ...[
                    const SizedBox(width: 16),
                    Icon(Icons.people, size: 14, color: Colors.grey[500]),
                    const SizedBox(width: 4),
                    Text(
                      '${event['current_participants']}/${event['max_participants'] ?? '∞'}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
