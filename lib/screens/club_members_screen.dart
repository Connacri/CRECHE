import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/auth_provider_v2.dart';
import '../services/club_service.dart';
import '../widgets/glass_card.dart';

class ClubMembersScreen extends StatefulWidget {
  const ClubMembersScreen({super.key});

  @override
  State<ClubMembersScreen> createState() => _ClubMembersScreenState();
}

class _ClubMembersScreenState extends State<ClubMembersScreen> {
  final ClubService _clubService = ClubService();
  List<Map<String, dynamic>> _members = [];
  bool _isLoading = true;
  String? _error;
  String _filter = 'all';
  StreamSubscription? _membersSubscription;

  @override
  void initState() {
    super.initState();
    _initRealtime();
  }

  void _initRealtime() {
    final auth = context.read<AuthProviderV2>();
    final clubId = auth.currentUser!.uid;

    _membersSubscription?.cancel();
    _membersSubscription = _clubService.getClubMembersStream(clubId).listen((data) async {
       // Since the stream only returns 'members' table, and we need user details,
       // in a real app we might use a more complex stream or join in a view.
       // For this expert fix, we'll fetch full details when the list changes.
       try {
         final fullDetails = await _clubService.getClubMembers(clubId);
         if (mounted) {
           setState(() {
             _members = fullDetails;
             _isLoading = false;
           });
         }
       } catch (e) {
          if (mounted) setState(() => _error = e.toString());
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
    _membersSubscription?.cancel();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filteredMembers {
    if (_filter == 'all') return _members;
    return _members.where((m) => m['status'] == _filter).toList();
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'active': return 'Actif';
      case 'inactive': return 'Inactif';
      case 'pending': return 'En attente';
      case 'suspended': return 'Suspendu';
      default: return status;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'active': return Colors.green;
      case 'inactive': return Colors.grey;
      case 'pending': return Colors.orange;
      case 'suspended': return Colors.red;
      default: return Colors.grey;
    }
  }

  String _membershipTypeLabel(String type) {
    switch (type) {
      case 'standard': return 'Standard';
      case 'premium': return 'Premium';
      case 'vip': return 'VIP';
      case 'trial': return 'Essai';
      default: return type;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Adhérents du club'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: _showAddMemberDialog,
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
    final filters = ['all', 'active', 'pending', 'inactive'];
    final labels = ['Tous', 'Actifs', 'En attente', 'Inactifs'];
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
    final members = _filteredMembers;
    if (members.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text('Aucun adhérent', style: TextStyle(fontSize: 16, color: Colors.grey[600])),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () async => _initRealtime(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: members.length,
        itemBuilder: (context, index) {
          final member = members[index];
          final user = member['user'] as Map<String, dynamic>?;
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
                        radius: 24,
                        backgroundImage: user != null && user['profile_images'] is Map
                            ? (user['profile_images']['profileImageSupabase'] != null
                                ? CachedNetworkImageProvider(user['profile_images']['profileImageSupabase'])
                                : null)
                            : null,
                        child: user != null && user['name'] != null
                            ? Text(user['name'][0].toUpperCase())
                            : const Icon(Icons.person),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(user?['name'] ?? 'Inconnu', style: const TextStyle(fontWeight: FontWeight.bold)),
                            if (member['membership_number'] != null)
                              Text('N° ${member['membership_number']}', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _statusColor(member['status']).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _statusLabel(member['status']),
                          style: TextStyle(fontSize: 11, color: _statusColor(member['status']), fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _chip(Icons.card_membership, _membershipTypeLabel(member['membership_type'] ?? 'standard')),
                      const SizedBox(width: 8),
                      if (member['end_date'] != null)
                        _chip(Icons.event, 'Fin: ${member['end_date']}'),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _chip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.grey[600]),
          const SizedBox(width: 4),
          Text(text, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
        ],
      ),
    );
  }

  void _showAddMemberDialog() {
    List<Map<String, dynamic>> searchResults = [];
    bool isSearching = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Ajouter un adhérent'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  decoration: const InputDecoration(
                    hintText: 'Rechercher par nom ou email...',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (v) async {
                    if (v.length < 3) return;
                    setDialogState(() => isSearching = true);
                    final results = await _clubService.searchUsers(v);
                    setDialogState(() {
                      searchResults = results;
                      isSearching = false;
                    });
                  },
                ),
                const SizedBox(height: 16),
                if (isSearching)
                  const Center(child: CircularProgressIndicator())
                else
                  Flexible(
                    child: Material(
                      color: Colors.transparent,
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: searchResults.length,
                        itemBuilder: (context, i) {
                          final user = searchResults[i];
                          return ListTile(
                            title: Text(user['name'] ?? ''),
                            subtitle: Text(user['email'] ?? ''),
                            trailing: IconButton(
                              icon: const Icon(Icons.add_circle, color: Colors.green),
                              onPressed: () async {
                                final auth = context.read<AuthProviderV2>();
                                await _clubService.addMember(
                                  clubId: auth.currentUser!.uid,
                                  userId: user['id'],
                                );
                                if (context.mounted) {
                                  Navigator.pop(context);
                                }
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Fermer')),
          ],
        ),
      ),
    );
  }
}
