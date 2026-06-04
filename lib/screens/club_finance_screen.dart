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

      // Parallélisation des requêtes pour de meilleures performances
      final results = await Future.wait([
        _financeService.getFinancialSummary(userId, _selectedYear),
        _financeService.getRecentInvoices(userId),
        _financeService.getClubExpenses(userId),
      ]);

      if (mounted) {
        setState(() {
          _summary = results[0] as Map<String, dynamic>;
          _recentInvoices = results[1] as List<Map<String, dynamic>>;
          _expenses = results[2] as List<Map<String, dynamic>>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.redAccent,
          ),
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
        title: const Text('Finances du Club'),
        elevation: 0,
        actions: [
          _buildYearPicker(),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                children: [
                  if (_summary != null) _buildSummaryCards(),
                  const SizedBox(height: 24),
                  _buildTabBar(),
                  const SizedBox(height: 16),
                  _buildTabContent(),
                ],
              ),
            ),
    );
  }

  Widget _buildYearPicker() {
    return PopupMenuButton<int>(
      initialValue: _selectedYear,
      onSelected: (year) {
        setState(() {
          _selectedYear = year;
        });
        _loadData();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Text('$_selectedYear', style: const TextStyle(fontWeight: FontWeight.bold)),
            const Icon(Icons.arrow_drop_down),
          ],
        ),
      ),
      itemBuilder: (ctx) => List.generate(5, (i) {
        final year = DateTime.now().year - i;
        return PopupMenuItem(
          value: year,
          child: Text(year.toString()),
        );
      }),
    );
  }

  Widget _buildTabContent() {
    if (_tab == 'overview') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMonthlyChart(),
          const SizedBox(height: 24),
          Text(
            'Dépenses par catégorie',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _buildExpenseByCategories(),
        ],
      );
    } else if (_tab == 'invoices') {
      return _recentInvoices.isEmpty
          ? _buildEmptyState('Aucune facture trouvée')
          : Column(children: _recentInvoices.map((inv) => _buildInvoiceCard(inv)).toList());
    } else {
      return _expenses.isEmpty
          ? _buildEmptyState('Aucune dépense enregistrée')
          : Column(children: _expenses.map((exp) => _buildExpenseCard(exp)).toList());
    }
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48.0),
        child: Column(
          children: [
            Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(message, style: TextStyle(color: Colors.grey[500])),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards() {
    final totalRevenue = _summary?['total_revenue']?.toDouble() ?? 0.0;
    final totalExpenses = _summary?['total_expenses']?.toDouble() ?? 0.0;
    final netProfit = _summary?['net_profit']?.toDouble() ?? 0.0;
    final pendingAmount = _summary?['pending_amount']?.toDouble() ?? 0.0;

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _metricCard('Revenus', _fmt(totalRevenue), Colors.green, Icons.trending_up)),
            const SizedBox(width: 12),
            Expanded(child: _metricCard('Dépenses', _fmt(totalExpenses), Colors.red, Icons.trending_down)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _metricCard('Bénéfice net', _fmt(netProfit), Colors.blue, Icons.account_balance)),
            const SizedBox(width: 12),
            Expanded(child: _metricCard('En attente', _fmt(pendingAmount), Colors.orange, Icons.hourglass_empty)),
          ],
        ),
      ],
    );
  }

  Widget _metricCard(String label, String value, Color color, IconData icon) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 8),
              Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w500)),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          _tabButton('Vue d\'ensemble', 'overview'),
          _tabButton('Factures', 'invoices'),
          _tabButton('Dépenses', 'expenses'),
        ],
      ),
    );
  }

  Widget _tabButton(String label, String tab) {
    final isSelected = _tab == tab;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _tab = tab),
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Theme.of(context).colorScheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected ? [BoxShadow(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3), blurRadius: 4, offset: const Offset(0, 2))] : [],
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMonthlyChart() {
    final monthlyData = _summary?['monthly'] as List?;
    if (monthlyData == null || monthlyData.isEmpty) {
      return const SizedBox.shrink();
    }

    final List<BarData> bars = monthlyData.map((m) {
      return BarData(
        month: m['month'] as int,
        revenue: (m['revenue'] as num?)?.toDouble() ?? 0,
        expenses: (m['expenses'] as num?)?.toDouble() ?? 0,
      );
    }).toList();

    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Performance Mensuelle', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              Row(
                children: [
                  _legendItem('Revenus', Colors.green),
                  const SizedBox(width: 8),
                  _legendItem('Dépenses', Colors.red),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 180,
            width: double.infinity,
            child: CustomPaint(
              painter: _EnhancedBarChartPainter(data: bars),
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendItem(String label, Color color) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }

  Widget _buildExpenseByCategories() {
    final catData = _summary?['expense_by_cat'] as Map<String, dynamic>?;
    if (catData == null || catData.isEmpty) {
      return const Text('Aucune donnée de catégorie');
    }

    final totalExpenses = (_summary!['total_expenses'] as num?)?.toDouble() ?? 1.0;
    
    return Column(
      children: catData.entries.map((e) => _buildCategoryBar(e.key, (e.value as num).toDouble(), totalExpenses)).toList(),
    );
  }

  Widget _buildCategoryBar(String category, double amount, double total) {
    final labels = {
      'equipment': 'Équipement', 'venue': 'Lieu', 'staff': 'Personnel',
      'transport': 'Transport', 'marketing': 'Marketing', 'utilities': 'Services',
      'license_fees': 'Licences', 'maintenance': 'Entretien', 'medical': 'Médical', 'other': 'Autre',
    };
    
    final percentage = total > 0 ? (amount / total) : 0.0;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(labels[category] ?? category, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
              Text(_fmt(amount), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 6),
          Stack(
            children: [
              Container(
                height: 8,
                width: double.infinity,
                decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(4)),
              ),
              FractionallySizedBox(
                widthFactor: percentage.clamp(0.0, 1.0),
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [Colors.red[300]!, Colors.red[700]!]),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInvoiceCard(Map<String, dynamic> inv) {
    final total = (inv['total_amount'] as num?)?.toDouble() ?? 0.0;
    final paid = (inv['paid_amount'] as num?)?.toDouble() ?? 0.0;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.description_outlined, color: Colors.blue, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(inv['invoice_number'] ?? 'Sans numéro', style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text(
                        inv['created_at'] != null ? DateFormat('dd/MM/yyyy').format(DateTime.parse(inv['created_at'])) : '',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                _buildStatusChip(inv['status'] ?? 'draft'),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _infoColumn('Montant total', _fmt(total)),
                _infoColumn('Montant payé', _fmt(paid), color: Colors.green),
                _infoColumn('Reste', _fmt(total - paid), color: Colors.orange),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    final color = _statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        _statusLabel(status),
        style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _infoColumn(String label, String value, {Color? color}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[500])),
        Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  Widget _buildExpenseCard(Map<String, dynamic> exp) {
    final labels = {
      'equipment': 'Équipement', 'venue': 'Lieu', 'staff': 'Personnel',
      'transport': 'Transport', 'marketing': 'Marketing', 'utilities': 'Services',
      'license_fees': 'Licences', 'maintenance': 'Entretien', 'medical': 'Médical', 'other': 'Autre',
    };
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              height: 40,
              width: 40,
              decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.remove_circle_outline, color: Colors.red, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(exp['description'] ?? 'Sans description', style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(
                    '${labels[exp['category']] ?? exp['category']} • ${exp['date'] ?? ''}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            Text(_fmt((exp['amount'] as num?)?.toDouble()), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
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

    final paintRevenue = Paint()..color = Colors.green.withValues(alpha: 0.8);
    final paintExpenses = Paint()..color = Colors.red.withValues(alpha: 0.8);
    final paintGrid = Paint()..color = Colors.grey.withValues(alpha: 0.1)..strokeWidth = 1;

    // Calcul du maximum pour l'échelle
    double maxVal = 0;
    for (var d in data) {
      if (d.revenue > maxVal) maxVal = d.revenue;
      if (d.expenses > maxVal) maxVal = d.expenses;
    }
    if (maxVal == 0) maxVal = 1000;
    maxVal *= 1.2; // Ajout d'une marge en haut

    // Dessin des lignes de grille horizontales
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
      // On cherche la donnée pour ce mois (1-12)
      final monthIndex = i + 1;
      final d = data.firstWhere((element) => element.month == monthIndex, 
          orElse: () => BarData(month: monthIndex, revenue: 0, expenses: 0));

      final xBase = i * barGroupWidth + (barGroupWidth - (barWidth * 2 + spacing)) / 2;

      // Dessin du Revenue
      if (d.revenue > 0) {
        final h = (d.revenue / maxVal) * size.height;
        final rect = RRect.fromRectAndCorners(
          Rect.fromLTWH(xBase, size.height - h, barWidth, h),
          topLeft: const Radius.circular(4),
          topRight: const Radius.circular(4),
        );
        canvas.drawRRect(rect, paintRevenue);
      }

      // Dessin des Dépenses
      if (d.expenses > 0) {
        final h = (d.expenses / maxVal) * size.height;
        final rect = RRect.fromRectAndCorners(
          Rect.fromLTWH(xBase + barWidth + spacing, size.height - h, barWidth, h),
          topLeft: const Radius.circular(4),
          topRight: const Radius.circular(4),
        );
        canvas.drawRRect(rect, paintExpenses);
      }

      // Label du mois
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
