import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider_v2.dart';
import '../services/finance_service.dart';
import '../widgets/glass_card.dart';

class ClubFinanceScreen extends StatefulWidget {
  const ClubFinanceScreen({super.key});

  @override
  State<ClubFinanceScreen> createState() => _ClubFinanceScreenState();
}

class _ClubFinanceScreenState extends State<ClubFinanceScreen> {
  final _financeService = FinanceService();
  Map<String, dynamic>? _summary;
  List<Map<String, dynamic>> _recentInvoices = [];
  List<Map<String, dynamic>> _expenses = [];
  List<Map<String, dynamic>> _inventory = [];
  Map<String, dynamic>? _subStatus;

  bool _isLoading = true;
  int _selectedYear = DateTime.now().year;
  String _tab = 'overview';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final auth = context.read<AuthProviderV2>();
      final userId = auth.currentUser?.uid;

      if (userId == null) {
        throw Exception('Utilisateur non connecté');
      }

      final results = await Future.wait([
        _financeService.getFinancialSummary(userId, _selectedYear),
        _financeService.getRecentInvoices(userId),
        _financeService.getClubExpenses(userId),
        _financeService.getInventoryItems(userId),
        _financeService.getSubscriptionStatus(userId),
      ]);

      if (mounted) {
        setState(() {
          _summary = results[0] as Map<String, dynamic>;
          _recentInvoices = results[1] as List<Map<String, dynamic>>;
          _expenses = results[2] as List<Map<String, dynamic>>;
          _inventory = results[3] as List<Map<String, dynamic>>;
          _subStatus = results[4] as Map<String, dynamic>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  String _fmt(num? value) {
    if (value == null) return '0 DA';
    return "${NumberFormat('#,##0', 'fr_FR').format(value)} DA";
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'draft': return 'Brouillon';
      case 'sent': return 'Envoyée';
      case 'pending': return 'En attente';
      case 'partial': return 'Partielle';
      case 'paid': return 'Payée';
      case 'overdue': return 'En retard';
      case 'cancelled': return 'Annulée';
      default: return status;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'paid': return Colors.green;
      case 'partial': return Colors.orange;
      case 'overdue': return Colors.red;
      case 'sent': return Colors.blue;
      case 'pending': return Colors.amber;
      case 'draft': return Colors.grey;
      case 'cancelled': return Colors.blueGrey;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Finance & Gestion'),
        actions: [
          IconButton(icon: const Icon(Icons.add_shopping_cart), onPressed: _showAddExpenseDialog, tooltip: 'Ajouter une dépense'),
          IconButton(icon: const Icon(Icons.inventory), onPressed: _showAddInventoryDialog, tooltip: 'Ajouter au stock'),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(),
    );
  }

  Widget _buildBody() {
    return Column(
      children: [
        _buildTabs(),
        Expanded(
          child: _getContentForTab(),
        ),
      ],
    );
  }

  Widget _getContentForTab() {
    switch (_tab) {
      case 'overview': return _buildOverview();
      case 'invoices': return _buildInvoicesList();
      case 'expenses': return _buildExpensesList();
      case 'inventory': return _buildInventoryList();
      case 'subscriptions': return _buildSubscriptionsOverview();
      default: return _buildOverview();
    }
  }

  Widget _buildTabs() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _tabButton('Vue d\'ensemble', 'overview'),
          _tabButton('Factures', 'invoices'),
          _tabButton('Dépenses', 'expenses'),
          _tabButton('Stock', 'inventory'),
          _tabButton('Abonnements', 'subscriptions'),
        ],
      ),
    );
  }

  Widget _tabButton(String label, String value) {
    final isSelected = _tab == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => setState(() => _tab = value),
      ),
    );
  }

  Widget _buildOverview() {
    if (_summary == null) return const Center(child: Text('Aucune donnée'));

    final monthlyData = (_summary!['monthly'] as List?)?.map((m) => BarData(
      month: m['month'],
      revenue: (m['revenue'] as num).toDouble(),
      expenses: (m['expenses'] as num).toDouble(),
    )).toList() ?? [];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildStatCard('Revenu Total', _summary!['total_revenue'], Colors.green),
        const SizedBox(height: 12),
        _buildStatCard('Dépenses Totales', _summary!['total_expenses'], Colors.red),
        const SizedBox(height: 12),
        _buildStatCard('Bénéfice Net', _summary!['net_profit'], Colors.blue),
        const SizedBox(height: 24),
        if (monthlyData.isNotEmpty) ...[
          const Text('Performance Mensuelle', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: CustomPaint(
              painter: _EnhancedBarChartPainter(data: monthlyData),
              size: Size.infinite,
            ),
          ),
          const SizedBox(height: 32),
        ],
        const Text('Aperçu Abonnements', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 12),
        _buildSubStats(),
      ],
    );
  }

  Widget _buildSubStats() {
    if (_subStatus == null) return const SizedBox.shrink();
    return Row(
      children: [
        Expanded(child: _miniStat('Actifs', '${_subStatus!['total_active_members'] ?? 0}', Colors.green)),
        const SizedBox(width: 8),
        Expanded(child: _miniStat('Expirent soon', '${_subStatus!['expiring_soon'] ?? 0}', Colors.orange)),
      ],
    );
  }

  Widget _miniStat(String label, String val, Color color) {
    return GlassCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Text(val, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          Text(label, style: const TextStyle(fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, dynamic value, Color color) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(_fmt(value as num?), style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 18)),
        ],
      ),
    );
  }

  Widget _buildInvoicesList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _recentInvoices.length,
      itemBuilder: (context, i) => _buildInvoiceCard(_recentInvoices[i]),
    );
  }

  Widget _buildInvoiceCard(Map<String, dynamic> inv) {
    final status = inv['status'] ?? 'pending';
    final color = _statusColor(status);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(Icons.receipt_long, color: color),
        title: Text(inv['invoice_number'] ?? 'Sans numéro'),
        subtitle: Text('Total: ${_fmt(inv['total_amount'])}'),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
          child: Text(_statusLabel(status), style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
        ),
      ),
    );
  }

  Widget _buildExpensesList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _expenses.length,
      itemBuilder: (context, i) => _buildExpenseCard(_expenses[i]),
    );
  }

  Widget _buildExpenseCard(Map<String, dynamic> exp) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const Icon(Icons.remove_circle, color: Colors.red),
        title: Text(exp['title'] ?? 'Sans titre'),
        subtitle: Text('${exp['category']} • ${exp['date']}'),
        trailing: Text(_fmt(exp['amount']), style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildInventoryList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _inventory.length,
      itemBuilder: (context, i) {
        final item = _inventory[i];
        final stock = item['quantity_in_stock'] ?? 0;
        final alert = item['min_quantity_alert'] ?? 5;
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: const Icon(Icons.inventory_2),
            title: Text(item['name'] ?? ''),
            subtitle: Text('Prix vente: ${_fmt(item['sale_price'])}'),
            onTap: () => _showUpdateStockDialog(item),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('$stock', style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: stock <= alert ? Colors.red : Colors.green,
                )),
                const Text('en stock', style: TextStyle(fontSize: 10)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSubscriptionsOverview() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.card_membership, size: 64, color: Colors.blue),
          const SizedBox(height: 16),
          Text('${_subStatus?['total_active_members'] ?? 0} abonnés actifs', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('CA Abonnements: ${_fmt(_subStatus?['total_revenue_members'])}'),
        ],
      ),
    );
  }

  void _showAddExpenseDialog() {
    final titleController = TextEditingController();
    final amountController = TextEditingController();
    String category = 'equipment';
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Nouvelle dépense'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Titre')),
              TextField(controller: amountController, decoration: const InputDecoration(labelText: 'Montant (DA)'), keyboardType: TextInputType.number),
              DropdownButtonFormField<String>(
                value: category,
                items: [
                  'equipment', 'venue', 'staff', 'transport', 'marketing', 'utilities', 'other'
                ].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (v) => setDialogState(() => category = v!),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
            ElevatedButton(
              onPressed: isSaving ? null : () async {
                if (titleController.text.isEmpty || amountController.text.isEmpty) return;
                setDialogState(() => isSaving = true);
                final auth = context.read<AuthProviderV2>();
                await _financeService.createExpense({
                  'club_id': auth.currentUser!.uid,
                  'title': titleController.text,
                  'amount': double.parse(amountController.text),
                  'category': category,
                  'created_by': auth.currentUser!.uid,
                });
                if (context.mounted) {
                  Navigator.pop(context);
                  _loadData();
                }
              },
              child: const Text('Enregistrer'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddInventoryDialog() {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    final qtyController = TextEditingController();
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Nouvel article en stock'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Nom de l\'article')),
              TextField(controller: priceController, decoration: const InputDecoration(labelText: 'Prix de vente'), keyboardType: TextInputType.number),
              TextField(controller: qtyController, decoration: const InputDecoration(labelText: 'Quantité initiale'), keyboardType: TextInputType.number),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
            ElevatedButton(
              onPressed: isSaving ? null : () async {
                if (nameController.text.isEmpty) return;
                setDialogState(() => isSaving = true);
                final auth = context.read<AuthProviderV2>();
                await _financeService.createInventoryItem({
                  'club_id': auth.currentUser!.uid,
                  'name': nameController.text,
                  'sale_price': double.tryParse(priceController.text) ?? 0,
                  'quantity_in_stock': int.tryParse(qtyController.text) ?? 0,
                });
                if (context.mounted) {
                  Navigator.pop(context);
                  _loadData();
                }
              },
              child: const Text('Enregistrer'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddInvoiceDialog() {
    final amountController = TextEditingController();
    String type = 'subscription';
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Nouvelle facture'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: amountController, decoration: const InputDecoration(labelText: 'Montant Total (DA)'), keyboardType: TextInputType.number),
              DropdownButtonFormField<String>(
                value: type,
                items: [
                  'subscription', 'session', 'event', 'custom'
                ].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                onChanged: (v) => setDialogState(() => type = v!),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
            ElevatedButton(
              onPressed: isSaving ? null : () async {
                if (amountController.text.isEmpty) return;
                setDialogState(() => isSaving = true);
                final auth = context.read<AuthProviderV2>();
                await _financeService.createInvoice({
                  'club_id': auth.currentUser!.uid,
                  'total_amount': double.parse(amountController.text),
                  'type': type,
                  'status': 'pending',
                  'created_by': auth.currentUser!.uid,
                });
                if (context.mounted) {
                  Navigator.pop(context);
                  _loadData();
                }
              },
              child: const Text('Générer'),
            ),
          ],
        ),
      ),
    );
  }

  void _showUpdateStockDialog(Map<String, dynamic> item) {
    final qtyController = TextEditingController();
    String type = 'sale';
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Mouvement de stock: ${item['name']}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: type,
                items: [
                  DropdownMenuItem(value: 'sale', child: Text('Vente (-)')),
                  DropdownMenuItem(value: 'stock_in', child: Text('Réapprovisionnement (+)')),
                  DropdownMenuItem(value: 'adjustment', child: Text('Ajustement (+/-)')),
                ],
                onChanged: (v) => setDialogState(() => type = v!),
              ),
              TextField(
                controller: qtyController,
                decoration: const InputDecoration(labelText: 'Quantité'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
            ElevatedButton(
              onPressed: isSaving ? null : () async {
                if (qtyController.text.isEmpty) return;
                setDialogState(() => isSaving = true);
                final auth = context.read<AuthProviderV2>();
                await _financeService.updateInventoryStock(
                  item['id'],
                  auth.currentUser!.uid,
                  int.parse(qtyController.text),
                  type,
                );
                if (context.mounted) {
                  Navigator.pop(context);
                  _loadData();
                }
              },
              child: const Text('Confirmer'),
            ),
          ],
        ),
      ),
    );
  }
}

class BarData {
  final int month;
  final double revenue;
  final double expenses;
  BarData({required this.month, required this.revenue, required this.expenses});
}

class _EnhancedBarChartPainter extends CustomPainter {
  final List<BarData> data;
  _EnhancedBarChartPainter({required this.data});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final paintRevenue = Paint()..color = Colors.green.withOpacity(0.8);
    final paintExpenses = Paint()..color = Colors.red.withOpacity(0.8);
    final paintGrid = Paint()..color = Colors.grey.withOpacity(0.1)..strokeWidth = 1;

    double maxVal = 0;
    for (var d in data) {
      if (d.revenue > maxVal) maxVal = d.revenue;
      if (d.expenses > maxVal) maxVal = d.expenses;
    }
    if (maxVal == 0) maxVal = 1000;
    maxVal *= 1.2;

    const gridLines = 4;
    for (int i = 0; i <= gridLines; i++) {
      final y = size.height - (i * size.height / gridLines);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paintGrid);
    }

    final barGroupWidth = size.width / 12;
    final barWidth = barGroupWidth * 0.35;
    final spacing = barGroupWidth * 0.1;
    final months = ['J', 'F', 'M', 'A', 'M', 'J', 'J', 'A', 'S', 'O', 'N', 'D'];

    for (int i = 0; i < 12; i++) {
      final monthIndex = i + 1;
      final d = data.firstWhere((element) => element.month == monthIndex, 
          orElse: () => BarData(month: monthIndex, revenue: 0, expenses: 0));

      final xBase = i * barGroupWidth + (barGroupWidth - (barWidth * 2 + spacing)) / 2;

      if (d.revenue > 0) {
        final h = (d.revenue / maxVal) * size.height;
        final rect = RRect.fromRectAndCorners(
          Rect.fromLTWH(xBase, size.height - h, barWidth, h),
          topLeft: const Radius.circular(4),
          topRight: const Radius.circular(4),
        );
        canvas.drawRRect(rect, paintRevenue);
      }

      if (d.expenses > 0) {
        final h = (d.expenses / maxVal) * size.height;
        final rect = RRect.fromRectAndCorners(
          Rect.fromLTWH(xBase + barWidth + spacing, size.height - h, barWidth, h),
          topLeft: const Radius.circular(4),
          topRight: const Radius.circular(4),
        );
        canvas.drawRRect(rect, paintExpenses);
      }

      final textPainter = TextPainter(
        text: TextSpan(text: months[i], style: TextStyle(color: Colors.grey[600], fontSize: 10, fontWeight: FontWeight.bold)),
        textDirection: ui.TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(xBase + barWidth - textPainter.width/2 + spacing/2, size.height + 8));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
