import 'package:flutter/material.dart';
import '../services/event_service.dart';
import '../widgets/glass_card.dart';
import 'create_event_screen.dart';

class EventDetailScreen extends StatefulWidget {
  final String eventId;
  const EventDetailScreen({super.key, required this.eventId});

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  final _eventService = EventService();
  Map<String, dynamic>? _event;
  List<Map<String, dynamic>> _registrations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final event = await _eventService.getEvent(widget.eventId);
      final registrations = await _eventService.getEventRegistrations(widget.eventId);
      setState(() {
        _event = event;
        _registrations = registrations;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
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

  Future<void> _updateStatus(String newStatus) async {
    try {
      await _eventService.updateEvent(widget.eventId, {'status': newStatus});
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Statut: ${_statusLabel(newStatus)}')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
    }
  }

  Future<void> _deleteEvent() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer l\'événement ?'),
        content: const Text('Cette action est irréversible.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        await _eventService.deleteEvent(widget.eventId);
        if (mounted) Navigator.pop(context);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_event == null) return const Scaffold(body: Center(child: Text('Événement introuvable')));

    final event = _event!;

    return Scaffold(
      appBar: AppBar(
        title: Text(event['title'] ?? ''),
        actions: [
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'edit') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => CreateEventScreen(existingEvent: event)),
                ).then((_) => _load());
              } else if (v == 'delete') {
                _deleteEvent();
              }
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(value: 'edit', child: ListTile(leading: Icon(Icons.edit), title: Text('Modifier'))),
              const PopupMenuItem(value: 'delete', child: ListTile(leading: Icon(Icons.delete, color: Colors.red), title: Text('Supprimer', style: TextStyle(color: Colors.red)))),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          GlassCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _typeColor(event['type']).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: _typeColor(event['type']).withValues(alpha: 0.3)),
                      ),
                      child: Text(_typeLabel(event['type']), style: TextStyle(color: _typeColor(event['type']), fontWeight: FontWeight.w600, fontSize: 12)),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _statusColor(event['status']).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(_statusLabel(event['status']), style: TextStyle(color: _statusColor(event['status']), fontSize: 12)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (event['description'] != null && (event['description'] as String).isNotEmpty) ...[
                  Text(event['description'], style: TextStyle(color: Colors.grey[700], height: 1.5)),
                  const SizedBox(height: 16),
                ],
                _infoRow(Icons.calendar_today, 'Du ${_fmt(event['start_date'])} au ${_fmt(event['end_date'])}'),
                if (event['registration_deadline'] != null)
                  _infoRow(Icons.schedule, 'Inscription avant le ${_fmt(event['registration_deadline'])}'),
                _infoRow(Icons.people, 'Participants: ${event['current_participants'] ?? 0}/${event['max_participants'] ?? '∞'}'),
                if (event['is_paid'] == true) ...[
                  if (event['price'] != null) _infoRow(Icons.money, 'Prix: ${event['price']} DA'),
                  if (event['member_price'] != null) _infoRow(Icons.card_membership, 'Adhérent: ${event['member_price']} DA'),
                ],
                if (event['requires_medical_cert'] == true)
                  _infoRow(Icons.medical_services, 'Certificat médical requis'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              if (event['status'] == 'draft')
                Expanded(child: ElevatedButton(onPressed: () => _updateStatus('published'), child: const Text('Publier')))
              else if (event['status'] == 'published')
                Expanded(child: ElevatedButton(onPressed: () => _updateStatus('registration_open'), child: const Text('Ouvrir les inscriptions')))
              else if (event['status'] == 'registration_open')
                Expanded(child: ElevatedButton(onPressed: () => _updateStatus('ongoing'), child: const Text('Démarrer l\'événement')))
              else if (event['status'] == 'ongoing')
                Expanded(child: ElevatedButton(onPressed: () => _updateStatus('completed'), child: const Text('Terminer'))),
            ],
          ),
          const SizedBox(height: 24),
          Text('Inscriptions (${_registrations.length})', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          if (_registrations.isEmpty)
            Center(child: Padding(
              padding: const EdgeInsets.all(32),
              child: Text('Aucune inscription', style: TextStyle(color: Colors.grey[500])),
            ))
          else
            ..._registrations.map((reg) => _RegistrationTile(
              registration: reg,
              onUpdateStatus: (status) async {
                await _eventService.updateRegistrationStatus(reg['id'], status);
                _load();
              },
            )),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: TextStyle(color: Colors.grey[700]))),
        ],
      ),
    );
  }

  String _fmt(dynamic iso) {
    if (iso == null) return '';
    final dt = DateTime.parse(iso as String);
    return '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

class _RegistrationTile extends StatelessWidget {
  final Map<String, dynamic> registration;
  final Function(String) onUpdateStatus;

  const _RegistrationTile({required this.registration, required this.onUpdateStatus});

  @override
  Widget build(BuildContext context) {
    final registrant = registration['registrant'] as Map<String, dynamic>?;
    final name = registrant?['name'] ?? 'Inconnu';
    final email = registrant?['email'] ?? '';
    final status = registration['status'] ?? 'pending';

    Color sColor;
    String sLabel;
    switch (status) {
      case 'pending': sColor = Colors.orange; sLabel = 'En attente'; break;
      case 'confirmed': sColor = Colors.green; sLabel = 'Confirmé'; break;
      case 'waitlisted': sColor = Colors.blue; sLabel = 'Liste d\'attente'; break;
      case 'cancelled': sColor = Colors.red; sLabel = 'Annulé'; break;
      case 'attended': sColor = Colors.teal; sLabel = 'Présent'; break;
      case 'no_show': sColor = Colors.grey; sLabel = 'Absent'; break;
      default: sColor = Colors.grey; sLabel = status; break;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GlassCard(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?'),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                  if (email.isNotEmpty) Text(email, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: sColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(sLabel, style: TextStyle(fontSize: 11, color: sColor, fontWeight: FontWeight.w600)),
            ),
            if (status == 'pending') ...[
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.check_circle, color: Colors.green, size: 20),
                onPressed: () => onUpdateStatus('confirmed'),
                tooltip: 'Confirmer',
              ),
              IconButton(
                icon: const Icon(Icons.cancel, color: Colors.red, size: 20),
                onPressed: () => onUpdateStatus('cancelled'),
                tooltip: 'Refuser',
              ),
            ],
            if (status == 'confirmed') ...[
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.check, color: Colors.teal, size: 20),
                onPressed: () => onUpdateStatus('attended'),
                tooltip: 'Marquer présent',
              ),
            ],
          ],
        ),
      ),
    );
  }
}
