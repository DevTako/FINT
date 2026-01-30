import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'main.dart';

class HomeScreen extends StatefulWidget {
  final String token;
  
  const HomeScreen({super.key, required this.token});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  double _balance = 0.0;
  double _income = 0.0;
  double _expenses = 0.0;
  List<Map<String, dynamic>> recentTransactions = [];
  List<Map<String, dynamic>> budgetCategories = [];
  late VoidCallback _themeListener;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _themeListener = () {
      if (mounted) {
        setState(() {}); // Rebuild when theme changes
      }
    };
    ThemeController.mode.addListener(_themeListener);
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      // Conectar al servidor real con el token real
      final response = await http.get(
        Uri.parse('http://localhost:3000/api/financial-data'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );
      
      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        
        if (result['success']) {
          final data = result['data'];
          setState(() {
            _balance = (data['balance'] ?? 0.0).toDouble();
            _income = (data['income'] ?? 0.0).toDouble();
            _expenses = (data['expenses'] ?? 0.0).toDouble();
            
            // Procesar transacciones de la base de datos
            recentTransactions = List<Map<String, dynamic>>.from(
              data['transactions']?.map((t) => {
                'id': t['id'],
                'description': t['descripcion'],
                'category': t['categoria'],
                'amount': t['monto'].toString(),
                'date': t['fecha_transaccion'],
                'type': t['tipo'] == 'ingreso' ? 'income' : 'expense',
                'note': t['nota'] ?? '',
              }) ?? []
            );
            
            // Procesar presupuestos de la base de datos
            budgetCategories = List<Map<String, dynamic>>.from(
              data['budgets']?.map((b) => {
                'id': b['id'],
                'category': b['categoria'],
                'budget': b['monto_limite'],
                'spent': b['monto_actual'],
                'percentage': b['porcentaje_usado'],
              }) ?? []
            );
            
            _isLoading = false;
          });
        } else {
          throw Exception(result['message'] ?? 'Error del servidor');
        }
      } else {
        throw Exception('Error HTTP: ${response.statusCode}');
      }
    } catch (e) {
      // Si hay error, NO sobreescribir con datos demo (para evitar confusión)
      // Solo salimos de loading y mostramos el error.
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error cargando datos: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    ThemeController.mode.removeListener(_themeListener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Scaffold(
      body: Column(
        children: [
          Container(
            height: 100,
            padding: const EdgeInsets.symmetric(horizontal: 56.7), // 1.5cm = 56.7px at 96dpi
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              border: Border(
                bottom: BorderSide(
                  color: theme.dividerColor.withOpacity(0.2),
                  width: 0.5,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: Icon(
                    isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                    size: 20,
                  ),
                  onPressed: () {
                    ThemeController.toggle();
                    setState(() {}); // Trigger rebuild to update logo
                  },
                ),
                Container(
                  height: 80,
                  child: Center(
                    child: Text(
                      'FINT',
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.person_outline, size: 20),
                  onPressed: () {
                    _showProfileDialog();
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: _selectedIndex == 0
                ? _buildDashboard()
                : _selectedIndex == 1
                    ? _buildReports()
                    : _buildProfile(),
          ),
        ],
      ),
      floatingActionButton: _selectedIndex == 0
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton(
                  heroTag: "ai_assistant",
                  onPressed: () {
                    _showAIAssistantDialog();
                  },
                  child: Icon(
                    isDark ? Icons.smart_toy_outlined : Icons.smart_toy,
                  ),
                ),
                const SizedBox(height: 16),
                FloatingActionButton(
                  heroTag: "add_transaction",
                  onPressed: () {
                    _showAddTransactionDialog();
                  },
                  child: const Icon(Icons.add),
                ),
              ],
            )
          : null,
    );
  }

  // ============ DASHBOARD ============
  Widget _buildDashboard() {
    final theme = Theme.of(context);
    final available = _income - _expenses;
    final recentItems = recentTransactions.take(4).toList();

    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Resumen mensual',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Presupuesto total',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '\$${_balance.toStringAsFixed(2)}',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontSize: 30,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _summaryTile(
                          title: 'Gastos del mes',
                          value: _expenses,
                          icon: Icons.arrow_downward_rounded,
                          color: Colors.redAccent,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _summaryTile(
                          title: 'Saldo disponible',
                          value: available,
                          icon: Icons.account_balance_wallet_outlined,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Carrusel de transacciones con filtros
          _buildTransactionsCarousel(),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Gastos recientes',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _selectedIndex = 1;
                  });
                },
                child: const Text('Ver todo'),
              ),
            ],
          ),
          Card(
            child: recentItems.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(32),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.receipt_long_outlined,
                            size: 48,
                            color: theme.colorScheme.onSurface.withOpacity(0.3),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No hay transacciones registradas',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Agrega tu primera transacción usando el botón +',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(0.4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: recentItems.length,
                    separatorBuilder: (_, __) => Divider(
                      height: 1,
                      thickness: 0.6,
                      color: theme.dividerColor.withOpacity(0.12),
                    ),
                    itemBuilder: (context, index) {
                      final transaction = recentItems[index];
                      return _buildTransactionItem(transaction);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionsCarousel() {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Transacciones del mes',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          height: 280,
          child: PageView.builder(
            itemCount: 3,
            controller: PageController(viewportFraction: 0.9),
            onPageChanged: (index) {
              setState(() {});
            },
            itemBuilder: (context, pageIndex) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 8),
                child: Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header del carrusel
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _getCarouselTitle(pageIndex),
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: _getCarouselColor(pageIndex),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: _getCarouselColor(pageIndex).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                _getCarouselCount(pageIndex),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: _getCarouselColor(pageIndex),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        // Lista de transacciones filtradas
                        Expanded(
                          child: ListView.builder(
                            itemCount: _getFilteredTransactions(pageIndex).length,
                            itemBuilder: (context, index) {
                              final transaction = _getFilteredTransactions(pageIndex)[index];
                              final isIncome = transaction['type'] == 'income';
                              final accent = isIncome ? Colors.green : Colors.redAccent;
                              
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: accent.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: accent.withOpacity(0.2),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 16,
                                        backgroundColor: accent.withOpacity(0.16),
                                        child: Icon(
                                          isIncome 
                                              ? Icons.arrow_upward_rounded 
                                              : Icons.arrow_downward_rounded,
                                          color: accent,
                                          size: 18,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              transaction['description'],
                                              style: theme.textTheme.bodyMedium?.copyWith(
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              '${transaction['category']} • ${transaction['date']}',
                                              style: theme.textTheme.bodySmall?.copyWith(
                                                color: theme.colorScheme.onSurface.withOpacity(0.6),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Text(
                                        '\$${transaction['amount']}',
                                        style: theme.textTheme.bodyMedium?.copyWith(
                                          fontWeight: FontWeight.w700,
                                          color: accent,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        
                        // Indicador de página
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(3, (index) {
                            return Container(
                              width: 8,
                              height: 8,
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: pageIndex == index
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.onSurface.withOpacity(0.3),
                              ),
                            );
                          }),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
  
  String _getCarouselTitle(int index) {
    switch (index) {
      case 0:
        return '💰 Ingresos';
      case 1:
        return '💸 Egresos';
      case 2:
        return '📊 Todas';
      default:
        return 'Transacciones';
    }
  }
  
  Color _getCarouselColor(int index) {
    switch (index) {
      case 0:
        return Colors.green;
      case 1:
        return Colors.redAccent;
      case 2:
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
  
  String _getCarouselCount(int index) {
    final transactions = _getFilteredTransactions(index);
    final total = transactions.fold<double>(
      0.0, 
      (sum, t) => sum + (double.tryParse(t['amount'].toString()) ?? 0.0)
    );
    return '${transactions.length} • \$${total.toStringAsFixed(0)}';
  }
  
  List<Map<String, dynamic>> _getFilteredTransactions(int index) {
    switch (index) {
      case 0:
        // Solo ingresos
        return recentTransactions.where((t) => t['type'] == 'income').toList();
      case 1:
        // Solo egresos
        return recentTransactions.where((t) => t['type'] == 'expense').toList();
      case 2:
      default:
        // Todas las transacciones
        return recentTransactions;
    }
  }

  Widget _summaryTile({
    required String title,
    required double value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w300,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '\$${value.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfile() {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Perfil',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 34,
                    backgroundColor: theme.colorScheme.primary.withOpacity(0.15),
                    child: Icon(
                      Icons.person_outline,
                      color: theme.colorScheme.primary,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Usuario ACOSENAR',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'demo@acosenar.coop',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w300,
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: _showProfileDialog,
                      child: const Text('Ver detalles'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============ TRANSACCIONES ============
  Widget _buildTransactions() {
    final theme = Theme.of(context);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Todas las transacciones',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  _showAddTransactionDialog();
                },
                icon: const Icon(Icons.add),
                label: const Text('Agregar'),
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: recentTransactions.length,
            itemBuilder: (context, index) {
              final transaction = recentTransactions[index];
              final isIncome = transaction['type'] == 'income';
              final accent = isIncome ? Colors.green : Colors.redAccent;
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  leading: CircleAvatar(
                    backgroundColor: accent.withOpacity(0.16),
                    child: Icon(
                      isIncome
                          ? Icons.arrow_upward_rounded
                          : Icons.arrow_downward_rounded,
                      color: accent,
                    ),
                  ),
                  title: Text(
                    transaction['description'],
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  subtitle: Text(
                    '${transaction['category']} • ${transaction['date']}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w300,
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                  trailing: Text(
                    '\$${transaction['amount']}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: accent,
                    ),
                  ),
                  onTap: () {
                    _showTransactionDetails(transaction);
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ============ PRESUPUESTO ============
  Widget _buildBudget() {
    final theme = Theme.of(context);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Presupuesto mensual',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: budgetCategories.length,
            itemBuilder: (context, index) {
              final category = budgetCategories[index];
              final percentage = category['spent'] / category['budget'];
              final color = _getCategoryColor(category['category']);
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  leading: CircleAvatar(
                    backgroundColor: color.withOpacity(0.18),
                    child: Icon(
                      _getCategoryIcon(category['category']),
                      color: color,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    category['category'],
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      Text(
                        'Gastado: \$${category['spent']} de \$${category['budget']}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w300,
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: percentage,
                          minHeight: 6,
                          backgroundColor:
                              theme.colorScheme.primary.withOpacity(0.12),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            percentage > 0.8
                                ? Colors.red
                                : percentage > 0.6
                                    ? Colors.orange
                                    : theme.colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  trailing: Text(
                    '${(percentage * 100).toStringAsFixed(0)}%',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: percentage > 0.8
                          ? Colors.red
                          : percentage > 0.6
                              ? Colors.orange
                              : theme.colorScheme.primary,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            onPressed: () {
              _showCreateBudgetDialog();
            },
            icon: const Icon(Icons.auto_awesome),
            label: const Text('Generar Presupuesto Automático con IA'),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ============ REPORTES ============
  Widget _buildReports() {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Estadísticas',
            style: theme.textTheme.titleMedium?.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Resumen financiero',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Ingresos del mes',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontSize: 13,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                      Text(
                        '\$${_income.toStringAsFixed(2)}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Gastos del mes',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontSize: 13,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                      Text(
                        '\$${_expenses.toStringAsFixed(2)}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: Colors.redAccent,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Balance del mes',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontSize: 13,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                      Text(
                        '\$${_balance.toStringAsFixed(2)}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: _balance >= 0 ? theme.colorScheme.primary : Colors.redAccent,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Categoría',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontSize: 13,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                      Text(
                        'Total gastado',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontSize: 13,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Divider(color: theme.dividerColor.withOpacity(0.2)),
                  const SizedBox(height: 8),
                  ..._getCategoryTotals().entries.map(
                    (entry) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(entry.key),
                          Text(
                            '\$${entry.value.toStringAsFixed(2)}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============ WIDGETS AUXILIARES ============

  Map<String, double> _getCategoryTotals() {
    final Map<String, double> totals = {};
    
    for (final transaction in recentTransactions) {
      if (transaction['type'] == 'expense') {
        final category = transaction['category'] as String;
        final amount = double.tryParse(transaction['amount'].toString()) ?? 0.0;
        totals[category] = (totals[category] ?? 0.0) + amount.abs();
      }
    }
    
    return totals;
  }

  Widget _buildMiniCard(String title, double amount, IconData icon, Color color) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 8),
        Text(
          '\$$amount',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w300,
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionItem(Map<String, dynamic> transaction) {
    final theme = Theme.of(context);
    final isIncome = transaction['type'] == 'income';
    final accent = isIncome ? Colors.green : Colors.redAccent;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: CircleAvatar(
        backgroundColor: accent.withOpacity(0.16),
        child: Icon(
          isIncome ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
          color: accent,
        ),
      ),
      title: Text(
        transaction['description'],
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        '${transaction['category']} • ${transaction['date']}',
        style: theme.textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.w300,
          color: theme.colorScheme.onSurface.withOpacity(0.6),
        ),
      ),
      trailing: Text(
        '\$${transaction['amount']}',
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: accent,
        ),
      ),
    );
  }

  Widget _buildBudgetItem(Map<String, dynamic> category) {
    final percentage = category['spent'] / category['budget'];
    final theme = Theme.of(context);
    final color = _getCategoryColor(category['category']);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                category['category'],
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '\$${category['spent']} / \$${category['budget']}',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w300,
                  color: percentage > 0.8
                      ? Colors.red
                      : percentage > 0.6
                          ? Colors.orange
                          : color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: percentage,
              minHeight: 6,
              backgroundColor: theme.colorScheme.primary.withOpacity(0.12),
              valueColor: AlwaysStoppedAnimation<Color>(
                percentage > 0.8
                    ? Colors.red
                    : percentage > 0.6
                        ? Colors.orange
                        : theme.colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Alimentos':
        return Colors.red;
      case 'Transporte':
        return Colors.blue;
      case 'Vivienda':
        return Colors.purple;
      case 'Servicios':
        return Colors.orange;
      case 'Entretenimiento':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Alimentos':
        return Icons.fastfood;
      case 'Transporte':
        return Icons.directions_car;
      case 'Vivienda':
        return Icons.home;
      case 'Servicios':
        return Icons.electrical_services;
      case 'Entretenimiento':
        return Icons.movie;
      default:
        return Icons.category;
    }
  }

  // ============ DIALOGOS ============
  void _showAddTransactionDialog() {
    final TextEditingController descriptionController = TextEditingController();
    final TextEditingController amountController = TextEditingController();
    final TextEditingController customCategoryController = TextEditingController();
    String selectedCategory = 'Alimentos';
    String transactionType = 'Egreso'; // 'Ingreso' o 'Egreso'
    bool isCustomCategory = false;

    showDialog(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              title: Text(
                'Nueva transacción',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Selección de tipo de transacción
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                transactionType = 'Ingreso';
                                selectedCategory = 'Salario'; // Categoría por defecto para ingresos
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: transactionType == 'Ingreso' 
                                    ? Colors.green.withOpacity(0.1)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: transactionType == 'Ingreso' 
                                      ? Colors.green
                                      : theme.dividerColor.withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.arrow_upward_rounded,
                                    color: transactionType == 'Ingreso' ? Colors.green : Colors.grey,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Ingreso',
                                    style: TextStyle(
                                      color: transactionType == 'Ingreso' ? Colors.green : Colors.grey,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                transactionType = 'Egreso';
                                selectedCategory = 'Alimentos'; // Categoría por defecto para egresos
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: transactionType == 'Egreso' 
                                    ? Colors.red.withOpacity(0.1)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: transactionType == 'Egreso' 
                                      ? Colors.red
                                      : theme.dividerColor.withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.arrow_downward_rounded,
                                    color: transactionType == 'Egreso' ? Colors.red : Colors.grey,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Egreso',
                                    style: TextStyle(
                                      color: transactionType == 'Egreso' ? Colors.red : Colors.grey,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: descriptionController,
                      decoration: InputDecoration(
                        labelText: transactionType == 'Ingreso' ? 'Descripción del ingreso' : 'Descripción del gasto',
                        hintText: transactionType == 'Ingreso' ? 'Ej: Salario mensual, Venta, etc.' : 'Ej: Supermercado, Transporte, etc.',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: amountController,
                      decoration: InputDecoration(
                        labelText: 'Monto',
                        prefixText: '\$ ',
                        hintText: '0.00',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField(
                      items: transactionType == 'Ingreso'
                          ? ['Salario', 'Ventas', 'Inversiones', 'Otros']
                              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                              .toList()
                          : ['Alimentos', 'Transporte', 'Vivienda', 'Servicios', 'Otros']
                              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                              .toList(),
                      decoration: InputDecoration(
                        labelText: 'Categoría',
                        hintText: transactionType == 'Ingreso' ? 'Selecciona tipo de ingreso' : 'Selecciona tipo de gasto',
                      ),
                      value: selectedCategory,
                      onChanged: (value) {
                        setState(() {
                          selectedCategory = value!;
                          isCustomCategory = value == 'Otros';
                        });
                      },
                    ),
                    if (isCustomCategory) ...[
                      const SizedBox(height: 16),
                      TextField(
                        controller: customCategoryController,
                        decoration: InputDecoration(
                          labelText: transactionType == 'Ingreso' 
                              ? 'Describe el tipo de ingreso'
                              : 'Describe el tipo de gasto',
                          hintText: transactionType == 'Ingreso' 
                              ? 'Ej: Freelance, Regalo, etc.'
                              : 'Ej: Mantenimiento, Gastos médicos, etc.',
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    // Validar campos
                    if (descriptionController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Por favor ingresa una descripción'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }
                    
                    if (amountController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Por favor ingresa un monto'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }
                    
                    final amount = double.tryParse(amountController.text);
                    if (amount == null || amount <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Por favor ingresa un monto válido'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }
                    
                    if (isCustomCategory && customCategoryController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Por favor ingresa un nombre para la categoría personalizada'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }
                    
                    // Mostrar indicador de carga
                    Navigator.pop(context);
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (context) => const AlertDialog(
                        content: Row(
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(width: 20),
                            Text('Guardando transacción...'),
                          ],
                        ),
                      ),
                    );
                    
                    try {
                      // Preparar datos para enviar al backend
                      final transactionData = {
                        'descripcion': descriptionController.text.trim(),
                        'monto': amount.toString(),
                        'tipo': transactionType.toLowerCase() == 'ingreso' ? 'ingreso' : 'gasto',
                        'categoria': isCustomCategory ? customCategoryController.text.trim() : selectedCategory,
                        'fecha_transaccion': DateTime.now().toIso8601String().split('T')[0],
                        'nota': '', // Campo opcional
                      };
                      
                      // Enviar al backend
                      final response = await http.post(
                        Uri.parse('http://localhost:3000/api/transaction'),
                        headers: {
                          'Content-Type': 'application/json',
                          'Authorization': 'Bearer ${widget.token}',
                        },
                        body: json.encode(transactionData),
                      );
                      
                      Navigator.pop(context); // Cerrar diálogo de carga
                      
                      if (response.statusCode == 200) {
                        final result = json.decode(response.body);
                        if (result['success']) {
                          // Recargar datos para mostrar la nueva transacción
                          await _loadUserData();
                          
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                '✅ ${transactionType} "${isCustomCategory ? customCategoryController.text : selectedCategory}" de \$${amount.toStringAsFixed(2)} guardado exitosamente'
                              ),
                              backgroundColor: transactionType == 'Ingreso' ? Colors.green : Colors.orange,
                              duration: const Duration(seconds: 3),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('❌ Error: ${result['message'] ?? 'Error desconocido'}'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('❌ Error del servidor: ${response.statusCode}'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    } catch (e) {
                      Navigator.pop(context); // Cerrar diálogo de carga
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('❌ Error de conexión: ${e.toString()}'),
                          backgroundColor: Colors.red,
                          duration: const Duration(seconds: 4),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: transactionType == 'Ingreso' ? Colors.green : Colors.red,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Guardar ${transactionType.toLowerCase()}',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showTransactionDetails(Map<String, dynamic> transaction) {
    showDialog(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Text(
            transaction['description'],
            style: theme.textTheme.titleMedium?.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Categoría: ${transaction['category']}',
                style: theme.textTheme.bodySmall,
              ),
              Text(
                'Fecha: ${transaction['date']}',
                style: theme.textTheme.bodySmall,
              ),
              Text(
                'Monto: \$${transaction['amount']}',
                style: theme.textTheme.bodySmall,
              ),
              Text(
                'Tipo: ${transaction['type'] == 'income' ? 'Ingreso' : 'Gasto'}',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }

  void _showAlertDialog() {
    showDialog(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded,
                  color: theme.colorScheme.primary),
              const SizedBox(width: 10),
              Text(
                'Alertas del sistema',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('• Presupuesto de Alimentos al 85%',
                  style: theme.textTheme.bodySmall),
              Text('• Gasto inusual en Transporte',
                  style: theme.textTheme.bodySmall),
              Text('• Ahorro mensual cumplido',
                  style: theme.textTheme.bodySmall),
              Text('• Pago de servicios próximo',
                  style: theme.textTheme.bodySmall),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }

  void _showProfileDialog() {
    showDialog(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Text(
            'Perfil de usuario',
            style: theme.textTheme.titleMedium?.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: theme.colorScheme.primary.withOpacity(0.12),
                child: Icon(
                  Icons.person_outline,
                  size: 40,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Usuario ACOSENAR',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                'demo@acosenar.coop',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w300,
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Cooperativa de Servicios Navieros',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w300,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Proyecto Universitario - Versión Demo',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w300,
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamedAndRemoveUntil(
                      context, '/login', (route) => false);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Cerrar sesión'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }

  void _showCreateBudgetDialog() {
    showDialog(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Row(
            children: [
              Icon(Icons.auto_awesome_outlined,
                  color: theme.colorScheme.primary),
              const SizedBox(width: 10),
              Text(
                'IA · Presupuesto automático',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('La IA ha analizado tus gastos históricos',
                  style: theme.textTheme.bodySmall),
              const SizedBox(height: 10),
              Text('📊 Resultados del análisis:',
                  style: theme.textTheme.bodySmall),
              Text('• Tendencia de gastos estable',
                  style: theme.textTheme.bodySmall),
              Text('• Puedes ahorrar 15% más',
                  style: theme.textTheme.bodySmall),
              Text('• Recomendación: Reducir gastos discrecionales',
                  style: theme.textTheme.bodySmall),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('¡Presupuesto generado con IA!'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Aplicar Presupuesto'),
            ),
          ],
        );
      },
    );
  }

  void _showAIAssistantDialog() {
    final theme = Theme.of(context);
    final TextEditingController _questionController = TextEditingController();
    bool _isLoading = false;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Row(
                children: [
                  Icon(
                    Icons.smart_toy,
                    color: theme.colorScheme.primary,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Asistente Financiero IA',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Haz preguntas sobre tus finanzas y recibe recomendaciones personalizadas',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w300,
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _questionController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Ej: ¿Cómo puedo ahorrar para comprar un auto en 12 meses?',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: theme.colorScheme.surface,
                      ),
                    ),
                    if (_isLoading) ...[
                      const SizedBox(height: 16),
                      const Center(child: CircularProgressIndicator()),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: _isLoading ? null : () async {
                    if (_questionController.text.trim().isEmpty) return;
                    
                    setState(() => _isLoading = true);
                    
                    try {
                      final response = await _getFinancialAdvice(_questionController.text);
                      Navigator.of(context).pop();
                      _showAIResponseDialog(response);
                    } catch (e) {
                      setState(() => _isLoading = false);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error: ${e.toString()}'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  child: const Text('Consultar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showAIResponseDialog(String response) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                color: theme.colorScheme.primary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Recomendación IA',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Text(
                response,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w300,
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cerrar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _showAIAssistantDialog();
              },
              child: const Text('Otra pregunta'),
            ),
          ],
        );
      },
    );
  }

  Future<String> _getFinancialAdvice(String question) async {
    // Simular procesamiento de IA
    await Future.delayed(Duration(seconds: 2));
    
    // Convertir pregunta a minúsculas para análisis
    final questionLower = question.toLowerCase().trim();
    
    // SALUDOS Y CONVERSACIÓN BÁSICA
    if (questionLower.contains('hola') || questionLower.contains('buenos') || questionLower.contains('hey')) {
      return "👋 **¡Hola! Soy tu asistente financiero personal**\n\n"
          "Estoy aquí para ayudarte a alcanzar tus metas financieras. Puedes preguntarme sobre:\n\n"
          "💰 **Ahorro e Inversión:**\n"
          "- \"¿Cómo puedo ahorrar para un auto?\"\n"
          "- \"Quiero comprar una casa, ¿qué necesito?\"\n"
          "- \"¿Cómo empezar a invertir?\"\n\n"
          "📊 **Gastos y Presupuesto:**\n"
          "- \"¿Cómo optimizar mis gastos?\"\n"
          "- \"Ayúdame a crear un presupuesto\"\n"
          "- \"¿Dónde estoy gastando más dinero?\"\n\n"
          "🎯 **Metas Financieras:**\n"
          "- \"¿Cómo alcanzar la libertad financiera?\"\n"
          "- \"Quiero ser millonario, ¿qué hago?\"\n"
          "- \"¿Cómo prepararme para la jubilación?\"\n\n"
          "📈 **Análisis Personalizado:**\n"
          "- \"¿Estoy bien financieramente?\"\n"
          "- \"¿Cómo mejorar mi situación actual?\"\n"
          "- \"Recomiéndame un plan de acción\"\n\n"
          "**Tu situación actual:**\n"
          "- Balance: \$${_balance.toStringAsFixed(2)}\n"
          "- Ingresos: \$${_income.toStringAsFixed(2)}/mes\n"
          "- Gastos: \$${_expenses.toStringAsFixed(2)}/mes\n"
          "- Ahorro disponible: \$${(_income - _expenses).toStringAsFixed(2)}/mes\n\n"
          "¿Cuál es tu meta financiera principal? 🚀";
    }
    
    // AHORRO PARA AUTO
    if (questionLower.contains('auto') || questionLower.contains('coche') || questionLower.contains('carro')) {
      final precioAuto = 15000.0; // Precio estimado
      final mesesAhorro = 24.0; // 2 años
      final ahorroMensualNecesario = precioAuto / mesesAhorro;
      final ahorroActual = _income - _expenses;
      
      final planAccion = ahorroActual >= ahorroMensualNecesario ? 
          "1. **Ahorro automático:** Configura transferencia de \$${ahorroMensualNecesario.toStringAsFixed(2)} a cuenta de ahorros\n"
          "2. **Cuenta específica:** Abre una cuenta separada solo para el auto\n"
          "3. **Inversión extra:** Considera fondo de bajo riesgo para ganar intereses\n"
          "4. **Seguimiento:** Revisa tu progreso mensualmente\n\n"
          "**📈 PROYECCIONES:**\n"
          "- En 6 meses habrás ahorrado: \$${(ahorroMensualNecesario * 6).toStringAsFixed(2)}\n"
          "- En 1 año: \$${(ahorroMensualNecesario * 12).toStringAsFixed(2)}\n"
          "- ¡En ${mesesAhorro.toInt()} meses tendrás tu auto! 🎉" :
          "1. **Reduce gastos:** Necesitas ahorrar \$${(ahorroMensualNecesario - ahorroActual).toStringAsFixed(2)} adicionales por mes\n"
          "2. **Aumenta ingresos:** Busca trabajo extra o freelancing\n"
          "3. **Plazo extendido:** Considera 3 años en lugar de 2\n"
          "4. **Auto más económico:** Busca opciones entre \$8,000-\$12,000\n\n"
          "**📊 ALTERNATIVAS:**\n"
          "- Con 3 años de plazo: \$${(precioAuto / 36).toStringAsFixed(2)}/mes\n"
          "- Auto económico (\$10,000): \$${(10000 / 24).toStringAsFixed(2)}/mes\n"
          "- Combinando ambas: \$${(10000 / 36).toStringAsFixed(2)}/mes\n\n"
          "💡 **Consejo:** Empieza con lo que puedas, ¡cada peso cuenta!";
      
      return "🚗 **PLAN DE AHORRO PARA COMPRA DE AUTO**\n\n"
          "**📋 META: Comprar tu auto propio**\n"
          "- Precio estimado del auto: \$${precioAuto.toStringAsFixed(2)}\n"
          "- Plazo recomendado: ${mesesAhorro.toInt()} meses (2 años)\n\n"
          "**💰 ANÁLISIS DE TU CAPACIDAD:**\n"
          "- Tu ahorro mensual actual: \$${ahorroActual.toStringAsFixed(2)}\n"
          "- Ahorro necesario mensual: \$${ahorroMensualNecesario.toStringAsFixed(2)}/mes\n"
          "- ${ahorroActual >= ahorroMensualNecesario ? '✅ ¡Puedes lograrlo!' : '⚠️ Necesitas ajustar tus gastos'}\n\n"
          "**🎯 PLAN DE ACCIÓN:**\n"
          "$planAccion";
    }
    
    // RESPUESTA POR DEFECTO - AYUDA GENERAL
    return "🤖 **ASESOR FINANCIERO INTELIGENTE**\n\n"
        "¡Hola! Soy tu asistente financiero personal y estoy aquí para ayudarte a alcanzar tus metas.\n\n"
        "**💬 PREGUNTAS QUE PUEDO RESPONDER:**\n\n"
        "🚗 **COMPRAS IMPORTANTES:**\n"
        "- \"¿Cómo puedo ahorrar para un auto?\"\n"
        "- \"Quiero comprar una casa, ¿qué necesito?\"\n"
        "- \"¿Cuánto necesito para una moto?\"\n\n"
        "💰 **AHORRO E INVERSIÓN:**\n"
        "- \"¿Cómo empezar a invertir?\"\n"
        "- \"¿Dónde puedo ahorrar mi dinero?\"\n"
        "- \"¿Cómo hacer crecer mi patrimonio?\"\n\n"
        "📊 **PRESUPUESTO Y GASTOS:**\n"
        "- \"¿Cómo optimizar mis gastos?\"\n"
        "- \"Ayúdame a crear un presupuesto\"\n"
        "- \"¿Por qué no me alcanza el dinero?\"\n\n"
        "🎯 **METAS FINANCIERAS:**\n"
        "- \"¿Cómo alcanzar la libertad financiera?\"\n"
        "- \"Quiero ser millonario, ¿qué hago?\"\n"
        "- \"¿Cómo prepararme para la jubilación?\"\n\n"
        "📈 **ANÁLISIS PERSONAL:**\n"
        "- \"¿Cómo estoy financieramente?\"\n"
        "- \"¿Estoy bien ahorrando?\"\n"
        "- \"¿Cómo puedo mejorar mi situación?\"\n\n"
        "**🔢 TU SITUACIÓN ACTUAL:**\n"
        "- Balance: \$${_balance.toStringAsFixed(2)}\n"
        "- Ingresos: \$${_income.toStringAsFixed(2)}/mes\n"
        "- Gastos: \$${_expenses.toStringAsFixed(2)}/mes\n"
        "- Ahorro disponible: \$${(_income - _expenses).toStringAsFixed(2)}/mes\n\n"
        "**🎪 SIMPLEMENTE PREGUNTA:**\n"
        "Escribe cualquier pregunta sobre tus finanzas y te daré recomendaciones personalizadas con cálculos, planes de acción y proyecciones basadas en tus datos reales.\n\n"
        "¿Cuál es tu meta financiera principal? 🚀\n\n"
        "*Ejemplos:*\n"
        "- *\"¿Cómo puedo ahorrar para un auto de \$15,000?\"*\n"
        "- *\"Quiero comprar una casa en 5 años, ¿qué hago?\"*\n"
        "- *\"¿Estoy ahorrando lo suficiente?\"*";
  }
}