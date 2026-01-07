import 'package:flutter/material.dart';
import 'data.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  double _balance = 12540.50;
  double _income = 18500.00;
  double _expenses = 5959.50;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ACOSENAR Finanzas'),
        backgroundColor: const Color(0xFF0066CC),
        elevation: 4,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              _showAlertDialog();
            },
          ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              _showProfileDialog();
            },
          ),
        ],
      ),
      body: _selectedIndex == 0
          ? _buildDashboard()
          : _selectedIndex == 1
              ? _buildTransactions()
              : _selectedIndex == 2
                  ? _buildBudget()
                  : _buildReports(),
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton.extended(
              onPressed: () {
                _showAddTransactionDialog();
              },
              icon: const Icon(Icons.add),
              label: const Text('Nuevo Gasto'),
              backgroundColor: const Color(0xFF0066CC),
            )
          : null,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: 'Transacciones',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet),
            label: 'Presupuesto',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Reportes',
          ),
        ],
      ),
    );
  }

  // ============ DASHBOARD ============
  Widget _buildDashboard() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Tarjeta de Balance
          Card(
            elevation: 5,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Text(
                    'Balance Total',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '\$$_balance',
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0066CC),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildMiniCard('Ingresos', _income, Icons.arrow_upward, Colors.green),
                      _buildMiniCard('Gastos', _expenses, Icons.arrow_downward, Colors.red),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Transacciones Recientes
          Card(
            elevation: 5,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Transacciones Recientes',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...recentTransactions.take(3).map((transaction) =>
                      _buildTransactionItem(transaction)),
                  const SizedBox(height: 10),
                  Center(
                    child: TextButton(
                      onPressed: () {
                        setState(() {
                          _selectedIndex = 1;
                        });
                      },
                      child: const Text('Ver todas las transacciones'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Presupuesto
          Card(
            elevation: 5,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Presupuesto del Mes',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...budgetCategories.map((category) =>
                      _buildBudgetItem(category)),
                  const SizedBox(height: 10),
                  Center(
                    child: TextButton(
                      onPressed: () {
                        setState(() {
                          _selectedIndex = 2;
                        });
                      },
                      child: const Text('Gestionar presupuesto'),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Alertas
          Card(
            elevation: 5,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.warning, color: Colors.orange),
                      SizedBox(width: 10),
                      Text(
                        'Alertas Activas',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    '• Presupuesto de Alimentos al 85%',
                    style: TextStyle(color: Colors.orange),
                  ),
                  const Text(
                    '• Gasto inusual en Transporte',
                    style: TextStyle(color: Colors.orange),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () {
                      _showAlertDialog();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                    ),
                    child: const Text('Ver todas las alertas'),
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
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Todas las Transacciones',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  _showAddTransactionDialog();
                },
                icon: const Icon(Icons.add),
                label: const Text('Agregar'),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: recentTransactions.length,
            itemBuilder: (context, index) {
              final transaction = recentTransactions[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: transaction['type'] == 'income'
                        ? Colors.green.withOpacity(0.2)
                        : Colors.red.withOpacity(0.2),
                    child: Icon(
                      transaction['type'] == 'income'
                          ? Icons.arrow_upward
                          : Icons.arrow_downward,
                      color: transaction['type'] == 'income'
                          ? Colors.green
                          : Colors.red,
                    ),
                  ),
                  title: Text(transaction['description']),
                  subtitle: Text(
                      '${transaction['category']} • ${transaction['date']}'),
                  trailing: Text(
                    '\$${transaction['amount']}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: transaction['type'] == 'income'
                          ? Colors.green
                          : Colors.red,
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
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: const Text(
            'Presupuesto Mensual',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: budgetCategories.length,
            itemBuilder: (context, index) {
              final category = budgetCategories[index];
              final percentage = category['spent'] / category['budget'];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _getCategoryColor(category['category']),
                    child: Icon(
                      _getCategoryIcon(category['category']),
                      color: Colors.white,
                    ),
                  ),
                  title: Text(category['category']),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          'Gastado: \$${category['spent']} de \$${category['budget']}'),
                      const SizedBox(height: 5),
                      LinearProgressIndicator(
                        value: percentage,
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          percentage > 0.8
                              ? Colors.red
                              : percentage > 0.6
                                  ? Colors.orange
                                  : Colors.green,
                        ),
                      ),
                    ],
                  ),
                  trailing: Text(
                    '${(percentage * 100).toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: percentage > 0.8
                          ? Colors.red
                          : percentage > 0.6
                              ? Colors.orange
                              : Colors.green,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(20),
          child: ElevatedButton.icon(
            onPressed: () {
              _showCreateBudgetDialog();
            },
            icon: const Icon(Icons.auto_awesome),
            label: const Text('Generar Presupuesto Automático con IA'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0066CC),
              minimumSize: const Size(double.infinity, 50),
            ),
          ),
        ),
      ],
    );
  }

  // ============ REPORTES ============
  Widget _buildReports() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Card(
            elevation: 5,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Text(
                    'Resumen Financiero',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Categoría'),
                      Text('Total Gastado'),
                    ],
                  ),
                  const Divider(),
                  ...categoryTotals.entries.map((entry) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 5),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(entry.key),
                            Text(
                              '\$${entry.value}',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      )),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Card(
            elevation: 5,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Text(
                    'Recomendaciones de IA',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildRecommendationCard(
                    'Reducir gastos en Transporte',
                    'Has gastado 40% más que el mes pasado en transporte',
                    Icons.directions_car,
                  ),
                  _buildRecommendationCard(
                    'Aumentar ahorro mensual',
                    'Puedes ahorrar \$200 más este mes',
                    Icons.savings,
                  ),
                  _buildRecommendationCard(
                    'Presupuesto de Alimentos alto',
                    'Considera reducir compras innecesarias',
                    Icons.fastfood,
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
  Widget _buildMiniCard(String title, double amount, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color),
        const SizedBox(height: 5),
        Text(
          '\$$amount',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionItem(Map<String, dynamic> transaction) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: transaction['type'] == 'income'
            ? Colors.green.withOpacity(0.2)
            : Colors.red.withOpacity(0.2),
        child: Icon(
          transaction['type'] == 'income' ? Icons.arrow_upward : Icons.arrow_downward,
          color: transaction['type'] == 'income' ? Colors.green : Colors.red,
        ),
      ),
      title: Text(transaction['description']),
      subtitle: Text('${transaction['category']} • ${transaction['date']}'),
      trailing: Text(
        '\$${transaction['amount']}',
        style: TextStyle(
          color: transaction['type'] == 'income' ? Colors.green : Colors.red,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildBudgetItem(Map<String, dynamic> category) {
    final percentage = category['spent'] / category['budget'];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(category['category']),
              Text(
                '\$${category['spent']} / \$${category['budget']}',
                style: TextStyle(
                  color: percentage > 0.8 ? Colors.red : Colors.green,
                ),
              ),
            ],
          ),
          LinearProgressIndicator(
            value: percentage,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(
              percentage > 0.8
                  ? Colors.red
                  : percentage > 0.6
                      ? Colors.orange
                      : Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationCard(String title, String desc, IconData icon) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      color: Colors.blue[50],
      child: ListTile(
        leading: Icon(icon, color: Colors.blue),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(desc),
        trailing: const Icon(Icons.arrow_forward),
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
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Nueva Transacción'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: const InputDecoration(labelText: 'Descripción'),
              ),
              TextField(
                decoration: const InputDecoration(labelText: 'Monto'),
                keyboardType: TextInputType.number,
              ),
              DropdownButtonFormField(
                items: ['Alimentos', 'Transporte', 'Vivienda', 'Servicios']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                decoration: const InputDecoration(labelText: 'Categoría'),
                onChanged: (value) {},
              ),
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
                    content: Text('Transacción agregada exitosamente'),
                  ),
                );
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }

  void _showTransactionDetails(Map<String, dynamic> transaction) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(transaction['description']),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Categoría: ${transaction['category']}'),
              Text('Fecha: ${transaction['date']}'),
              Text('Monto: \$${transaction['amount']}'),
              Text('Tipo: ${transaction['type'] == 'income' ? 'Ingreso' : 'Gasto'}'),
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
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning, color: Colors.orange),
              SizedBox(width: 10),
              Text('Alertas del Sistema'),
            ],
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('• ⚠️ Presupuesto de Alimentos al 85%'),
              Text('• ⚠️ Gasto inusual en Transporte'),
              Text('• ✅ Ahorro mensual cumplido'),
              Text('• ℹ️ Pago de servicios próximo'),
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
        return AlertDialog(
          title: const Text('Perfil de Usuario'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircleAvatar(
                radius: 40,
                child: Icon(Icons.person, size: 40),
              ),
              const SizedBox(height: 10),
              const Text('Usuario ACOSENAR',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const Text('demo@acosenar.coop'),
              const SizedBox(height: 20),
              const Text('Cooperativa de Servicios Navieros'),
              const SizedBox(height: 10),
              const Text('Proyecto Universitario - Versión Demo'),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamedAndRemoveUntil(
                      context, '/login', (route) => false);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                ),
                child: const Text('Cerrar Sesión'),
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
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.auto_awesome, color: Colors.purple),
              SizedBox(width: 10),
              Text('IA - Presupuesto Automático'),
            ],
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('La IA ha analizado tus gastos históricos'),
              SizedBox(height: 10),
              Text('📊 Resultados del análisis:'),
              Text('• Tendencia de gastos estable'),
              Text('• Puedes ahorrar 15% más'),
              Text('• Recomendación: Reducir gastos discrecionales'),
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
                backgroundColor: Colors.purple,
              ),
              child: const Text('Aplicar Presupuesto'),
            ),
          ],
        );
      },
    );
  }
}