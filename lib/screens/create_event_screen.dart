import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider_v2.dart';
import '../services/event_service.dart';

class CreateEventScreen extends StatefulWidget {
  final Map<String, dynamic>? existingEvent;
  const CreateEventScreen({super.key, this.existingEvent});

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _priceController = TextEditingController();
  final _memberPriceController = TextEditingController();
  final _maxParticipantsController = TextEditingController();
  final _eventService = EventService();
  bool _isSaving = false;

  String _type = 'competition';
  bool _isPublic = true;
  bool _isPaid = false;
  bool _requiresMedicalCert = false;
  DateTime? _startDate;
  DateTime? _endDate;
  DateTime? _registrationDeadline;

  final Map<String, String> _types = {
    'competition': 'Compétition',
    'stage': 'Stage intensif',
    'porte_ouverte': 'Portes ouvertes',
    'reunion': 'Réunion parents-coachs',
    'examen': 'Examen / Passage de grade',
    'tournoi': 'Tournoi',
    'gala': 'Gala',
    'autre': 'Autre',
  };

  @override
  void initState() {
    super.initState();
    if (widget.existingEvent != null) {
      final e = widget.existingEvent!;
      _titleController.text = e['title'] ?? '';
      _descController.text = e['description'] ?? '';
      _type = e['type'] ?? 'competition';
      _isPublic = e['is_public'] ?? true;
      _isPaid = e['is_paid'] ?? false;
      _requiresMedicalCert = e['requires_medical_cert'] ?? false;
      _priceController.text = e['price']?.toString() ?? '';
      _memberPriceController.text = e['member_price']?.toString() ?? '';
      _maxParticipantsController.text = e['max_participants']?.toString() ?? '';
      if (e['start_date'] != null) _startDate = DateTime.parse(e['start_date']);
      if (e['end_date'] != null) _endDate = DateTime.parse(e['end_date']);
      if (e['registration_deadline'] != null) _registrationDeadline = DateTime.parse(e['registration_deadline']);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _priceController.dispose();
    _memberPriceController.dispose();
    _maxParticipantsController.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isStart, required bool isDeadline}) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: isStart ? (_startDate ?? now) : (_endDate ?? now.add(const Duration(days: 30))),
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 365 * 2)),
    );
    if (!mounted) return;
    if (date != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(now),
      );
      if (time != null) {
        final dt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
        setState(() {
          if (isDeadline) {
            _registrationDeadline = dt;
          } else if (isStart) {
            _startDate = dt;
          } else {
            _endDate = dt;
          }
        });
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner les dates')),
      );
      return;
    }
    if (_endDate!.isBefore(_startDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La date de fin doit être après la date de début')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final auth = context.read<AuthProviderV2>();
      final userId = auth.currentUser!.uid;
      final data = {
        'club_id': userId,
        'title': _titleController.text.trim(),
        'description': _descController.text.trim(),
        'type': _type,
        'is_public': _isPublic,
        'is_paid': _isPaid,
        'requires_medical_cert': _requiresMedicalCert,
        'start_date': _startDate!.toIso8601String(),
        'end_date': _endDate!.toIso8601String(),
        'registration_deadline': _registrationDeadline?.toIso8601String(),
        'price': _isPaid && _priceController.text.isNotEmpty ? double.parse(_priceController.text) : null,
        'member_price': _isPaid && _memberPriceController.text.isNotEmpty ? double.parse(_memberPriceController.text) : null,
        'max_participants': _maxParticipantsController.text.isNotEmpty ? int.parse(_maxParticipantsController.text) : null,
        'status': 'draft',
        'created_by': userId,
      };

      if (widget.existingEvent != null) {
        await _eventService.updateEvent(widget.existingEvent!['id'], data);
      } else {
        await _eventService.createEvent(data);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.existingEvent != null ? 'Événement mis à jour' : 'Événement créé')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingEvent != null ? 'Modifier l\'événement' : 'Nouvel événement'),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _save,
            child: _isSaving
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Enregistrer'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Titre *', icon: Icon(Icons.event)),
              validator: (v) => v!.trim().length < 3 ? 'Minimum 3 caractères' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descController,
              decoration: const InputDecoration(labelText: 'Description', icon: Icon(Icons.description)),
              maxLines: 4,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _type,
              decoration: const InputDecoration(labelText: 'Type *', icon: Icon(Icons.category)),
              items: _types.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
              onChanged: (v) => setState(() => _type = v!),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _DateField(
                    label: 'Début *',
                    value: _startDate,
                    onTap: () => _pickDate(isStart: true, isDeadline: false),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _DateField(
                    label: 'Fin *',
                    value: _endDate,
                    onTap: () => _pickDate(isStart: false, isDeadline: false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: () => _pickDate(isStart: false, isDeadline: true),
              child: InputDecorator(
                decoration: const InputDecoration(labelText: 'Date limite d\'inscription', icon: Icon(Icons.schedule)),
                child: Text(
                  _registrationDeadline != null
                      ? '${_registrationDeadline!.day}/${_registrationDeadline!.month}/${_registrationDeadline!.year}'
                      : 'Non définie',
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _maxParticipantsController,
              decoration: const InputDecoration(labelText: 'Nombre max de participants', icon: Icon(Icons.people)),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 24),
            Text('Options', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            SwitchListTile(
              title: const Text('Événement public'),
              subtitle: const Text('Visible par tous les utilisateurs'),
              value: _isPublic,
              onChanged: (v) => setState(() => _isPublic = v),
            ),
            SwitchListTile(
              title: const Text('Événement payant'),
              subtitle: const Text('Les participants doivent payer'),
              value: _isPaid,
              onChanged: (v) => setState(() => _isPaid = v),
            ),
            if (_isPaid) ...[
              const SizedBox(height: 8),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(labelText: 'Prix standard (DA)', icon: Icon(Icons.money)),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _memberPriceController,
                decoration: const InputDecoration(labelText: 'Prix adhérent (DA)', icon: Icon(Icons.card_membership)),
                keyboardType: TextInputType.number,
              ),
            ],
            SwitchListTile(
              title: const Text('Certificat médical requis'),
              value: _requiresMedicalCert,
              onChanged: (v) => setState(() => _requiresMedicalCert = v),
            ),
          ],
        ),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  final String label;
  final DateTime? value;
  final VoidCallback onTap;

  const _DateField({required this.label, required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(labelText: label, icon: const Icon(Icons.calendar_today)),
        child: Text(
          value != null ? '${value!.day}/${value!.month}/${value!.year} ${value!.hour}:${value!.minute.toString().padLeft(2, '0')}' : 'Choisir',
        ),
      ),
    );
  }
}
