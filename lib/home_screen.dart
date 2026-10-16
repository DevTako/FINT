import 'package:flutter/material.dart';
import 'services/api_service.dart';
import 'core/utils/currency_formatter.dart';
import 'skia/painters/gauge_painter.dart';
import 'main.dart';

class HomeScreen extends StatefulWidget {
  final String token;
  const HomeScreen({super.key, required this.token});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  bool _isLoading = true;

  double _balance = 0.0;
  double _income = 0.0;
  double _expenses = 0.0;

  String _currentCurrency = 'VES';
  Map<String, dynamic> _exchangeRates = {};

  List<Map<String, dynamic>> _transactions = [];
  List<Map<String, dynamic>> _budgets = [];

  // Datos de perfil de usuario
  String _userName = 'Cargando...';
  String _userEmail = 'Cargando...';
  String _userPhone = '';
  String _userHousingZone = '';
  String _userRegisterDate = '';

  late AnimationController _chartAnimController;

  @override
  void initState() {
    super.initState();
    _chartAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _loadData();
    _loadExchangeRates();
  }

  @override
  void dispose() {
    _chartAnimController.dispose();
    super.dispose();
  }

  double _toDouble(dynamic val) {
    if (val == null) return 0.0;
    if (val is num) return val.toDouble();
    if (val is String) return double.tryParse(val) ?? 0.0;
    return 0.0;
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiService.getFinancialData(widget.token);

      if (response['success'] == true && response['data'] != null) {
        final data = response['data'];
        setState(() {
          _balance = _toDouble(data['balance']);
          _income = _toDouble(data['income']);
          _expenses = _toDouble(data['expenses']);

          _transactions = List<Map<String, dynamic>>.from(
            (data['transactions'] as List?)?.map((t) => {
              'id': t['id'],
              'description': t['descripcion'] ?? '',
              'category': t['categoria'] ?? 'General',
              'amount': _toDouble(t['monto'] ?? t['amount']),
              'date': t['fecha_transaccion']?.toString().split('T')[0] ?? '',
              'type': t['tipo'] == 'ingreso' ? 'income' : 'expense',
              'note': t['nota'] ?? '',
            }) ?? []
          );

          _budgets = List<Map<String, dynamic>>.from(
            (data['budgets'] as List?)?.map((b) => {
              'id': b['id'],
              'category': b['categoria'] ?? 'General',
              'budget': _toDouble(b['monto_limite']),
              'spent': _toDouble(b['monto_actual']),
              'percentage': _toDouble(b['porcentaje_usado']),
            }) ?? []
          );

          final user = data['user'] ?? {};
          _userName = user['nombre'] ?? '';
          _userEmail = user['correo'] ?? '';
          _userPhone = user['telefono'] ?? '';
          _userHousingZone = user['zona_vivienda'] ?? '';
          _userRegisterDate = user['fecha_registro']?.toString().split('T')[0] ?? '';
        });
        _chartAnimController.forward(from: 0.0);
      } else {
        _loadDemoData();
      }
    } catch (e) {
      _loadDemoData();
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _loadDemoData() {
    setState(() {
      _balance = 14250.00;
      _income = 25000.00;
      _expenses = 10750.00;
      _transactions = [
        {'id': 1, 'description': 'Salario Mensual', 'category': 'Salario', 'amount': 25000.0, 'date': '2026-01-15', 'type': 'income', 'note': ''},
        {'id': 2, 'description': 'Supermercado', 'category': 'Alimentos', 'amount': 3500.0, 'date': '2026-01-20', 'type': 'expense', 'note': ''},
        {'id': 3, 'description': 'Gasolina', 'category': 'Transporte', 'amount': 1200.0, 'date': '2026-01-22', 'type': 'expense', 'note': ''},
        {'id': 4, 'description': 'Renta Depa', 'category': 'Vivienda', 'amount': 6050.0, 'date': '2026-01-25', 'type': 'expense', 'note': ''},
      ];
      _budgets = [
        {'id': 1, 'category': 'Alimentos', 'budget': 5000.0, 'spent': 3500.0, 'percentage': 70.0},
        {'id': 2, 'category': 'Transporte', 'budget': 2000.0, 'spent': 1200.0, 'percentage': 60.0},
        {'id': 3, 'category': 'Vivienda', 'budget': 7000.0, 'spent': 6050.0, 'percentage': 86.4},
      ];
      _userName = 'Usuario FINT Demo';
      _userEmail = 'demo@fint.co';
      _userPhone = '+58 412 1234567';
      _userHousingZone = 'Distrito Capital, Caracas';
      _userRegisterDate = '2026-08-17';
      _isLoading = false;
    });
    _chartAnimController.forward(from: 0.0);
  }

  Future<void> _loadExchangeRates() async {
    try {
      // Siempre anclamos la tabla de conversión a base USD
      final response = await ApiService.getExchangeRates('USD');
      if (response['success'] == true && response['rates'] != null) {
        final rates = Map<String, dynamic>.from(response['rates']);

        // Sincronizar tasa de Venezuela con la oficial del BCV
        try {
          final veRes = await ApiService.getVenezuelaRates();
          final bcvRate = _toDouble(veRes['data']?['bcv']?['usd']);
          if (bcvRate > 0) {
            rates['VES'] = bcvRate;
          }
        } catch (_) {}

        if (mounted) {
          setState(() {
            _exchangeRates = rates;
          });
        }
      }
    } catch (e) {
      // Las tasas se cargarán en el próximo intento
    }
  }

  double _convert(double amount, {String? targetCurrency}) {
    final target = targetCurrency ?? _currentCurrency;
    if (target == 'USD') return amount;
    final rate = _toDouble(_exchangeRates[target]);
    if (rate <= 0) return amount;
    return amount * rate;
  }

  Widget _responsive(Widget child) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('FINT', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2)),
        actions: [
          // Botón Tasas Oficiales BCV + Binance
          IconButton(
            icon: const Icon(Icons.price_change_outlined),
            tooltip: 'Tasas Venezuela (BCV & Binance)',
            onPressed: _showVenezuelaRatesDialog,
          ),
          // Botón Conversor / Calculadora de Divisas
          IconButton(
            icon: const Icon(Icons.calculate_outlined),
            tooltip: 'Calculadora Cambiaria',
            onPressed: _showCurrencyCalculatorDialog,
          ),
          IconButton(
            icon: Icon(ThemeController.mode.value == ThemeMode.dark ? Icons.light_mode : Icons.dark_mode),
            onPressed: () {
              ThemeController.toggle();
              setState(() {});
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : IndexedStack(
              index: _selectedIndex,
              children: [
                _buildHomeTab(theme),
                _buildBudgetsTab(theme),
                _buildProfileTab(theme),
              ],
            ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Inicio'),
          NavigationDestination(icon: Icon(Icons.account_balance_wallet_outlined), selectedIcon: Icon(Icons.account_balance_wallet), label: 'Presupuesto'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Perfil'),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCurrencyCalculatorDialog,
        icon: const Icon(Icons.calculate_outlined),
        label: const Text('Calculadora Cambiaria'),
      ),
    );
  }

  // ================= 1. TAB INICIO =================
  Widget _buildHomeTab(ThemeData theme) {
    final vesRate = _toDouble(_exchangeRates['VES']);
    final rateToUse = vesRate > 0 ? vesRate : 879.12;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: _responsive(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Card Balance
            Card(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E3A5F), Color(0xFF2A5CAA)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Balance Total',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '1 USD = ${CurrencyFormatter.formatNumber(rateToUse)} Bs.',
                            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      CurrencyFormatter.formatVes(_balance),
                      style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.public, color: Colors.white70, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          'Ref. Internacional: \$ ${CurrencyFormatter.formatNumber(_balance / rateToUse)} USD',
                          style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.arrow_upward, color: Color(0xFF10B981), size: 16),
                                  SizedBox(width: 4),
                                  Text('Ingresos', style: TextStyle(color: Colors.white70, fontSize: 12)),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                CurrencyFormatter.formatVes(_income),
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                            ],
                          ),
                        ),
                        Container(height: 30, width: 1, color: Colors.white24),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.arrow_downward, color: Colors.redAccent, size: 16),
                                  SizedBox(width: 4),
                                  Text('Gastos', style: TextStyle(color: Colors.white70, fontSize: 12)),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                CurrencyFormatter.formatVes(_expenses),
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Transacciones Recientes
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Transacciones Recientes', style: theme.textTheme.titleMedium),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: _showAddTransactionDialog,
                ),
              ],
            ),
            const SizedBox(height: 8),

            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _transactions.length,
              itemBuilder: (context, index) {
                final t = _transactions[index];
                final isIncome = t['type'] == 'income';
                final color = isIncome ? Colors.green : Colors.redAccent;

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: color.withOpacity(0.15),
                      child: Icon(isIncome ? Icons.arrow_upward : Icons.arrow_downward, color: color),
                    ),
                    title: Text(t['description'], style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text('${t['category']} • ${t['date']}'),
                    trailing: Text(
                      CurrencyFormatter.formatVes(t['amount']),
                      style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 15),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }



  // ================= 3. TAB PRESUPUESTO =================
  Widget _buildBudgetsTab(ThemeData theme) {
    final symbol = CurrencyFormatter.symbolFor(_currentCurrency);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: _responsive(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Mis Presupuestos', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                ElevatedButton.icon(
                  onPressed: _showCreateBudgetDialog,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Nuevo'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_budgets.isEmpty) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.account_balance_wallet_outlined, size: 48, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        Text('No tienes presupuestos creados', style: theme.textTheme.titleMedium),
                        const SizedBox(height: 4),
                        Text('Crea un presupuesto para controlar tus gastos por categoría', style: theme.textTheme.bodySmall),
                      ],
                    ),
                  ),
                ),
              ),
            ] else ...[
              ..._budgets.map((b) {
                final pct = (b['percentage'] as double) / 100.0;
                final spentConverted = _convert(b['spent']);
                final budgetConverted = _convert(b['budget']);

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 16,
                                  backgroundColor: theme.colorScheme.primary.withOpacity(0.12),
                                  child: Icon(Icons.category_outlined, size: 16, color: theme.colorScheme.primary),
                                ),
                                const SizedBox(width: 8),
                                Text(b['category'], style: theme.textTheme.titleMedium),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: (pct > 0.85 ? Colors.red : (pct > 0.6 ? Colors.amber : Colors.green)).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '${(pct * 100).toStringAsFixed(0)}%',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: pct > 0.85 ? Colors.redAccent : (pct > 0.6 ? Colors.amber.shade800 : Colors.green),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 90,
                          child: Center(
                            child: CustomPaint(
                              size: const Size(180, 90),
                              painter: GaugePainter(percentage: pct),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Gastado: ${CurrencyFormatter.format(spentConverted, currencySymbol: symbol, currencyCode: _currentCurrency)} de ${CurrencyFormatter.format(budgetConverted, currencySymbol: symbol, currencyCode: _currentCurrency)}',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ],
          ],
        ),
      ),
    );
  }

  // ================= 4. TAB PERFIL =================
  Widget _buildProfileTab(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: _responsive(
        Column(
          children: [
            const SizedBox(height: 24),
            // Header: Avatar y Nombre/Correo
            CircleAvatar(
              radius: 48,
              backgroundColor: theme.colorScheme.primary.withOpacity(0.12),
              child: Icon(Icons.person, size: 48, color: theme.colorScheme.primary),
            ),
            const SizedBox(height: 16),
            Text(
              _userName,
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              _userEmail,
              style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),

            // Card 1: Información de Vivienda y Teléfono
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: theme.colorScheme.outline.withOpacity(0.15)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Contacto y Ubicación',
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const Divider(height: 24),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.phone_outlined, color: theme.colorScheme.primary),
                      title: const Text('Teléfono', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      subtitle: Text(
                        _userPhone.isNotEmpty ? _userPhone : 'No especificado',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.home_work_outlined, color: theme.colorScheme.primary),
                      title: const Text('Zona de Vivienda', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      subtitle: Text(
                        _userHousingZone.isNotEmpty ? _userHousingZone : 'No especificada',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Card 2: Información de Utilidad (Estadísticas básicas)
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: theme.colorScheme.outline.withOpacity(0.15)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Información de Utilidad',
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const Divider(height: 24),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.calendar_today_outlined, color: theme.colorScheme.primary),
                      title: const Text('Miembro desde', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      subtitle: Text(
                        _userRegisterDate.isNotEmpty ? _userRegisterDate : 'N/D',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.account_balance_wallet_outlined, color: theme.colorScheme.primary),
                      title: const Text('Presupuestos Activos', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      subtitle: Text(
                        '${_budgets.length}',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.receipt_long_outlined, color: theme.colorScheme.primary),
                      title: const Text('Transacciones Recientes', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      subtitle: Text(
                        '${_transactions.length}',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),

            // Botones de Acción
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _showEditProfileDialog,
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Editar Perfil'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.pushReplacementNamed(context, '/'),
                icon: const Icon(Icons.logout_outlined),
                label: const Text('Cerrar Sesión'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
            const SizedBox(height: 24),
            TextButton.icon(
              onPressed: _showDeleteAccountConfirmDialog,
              icon: const Icon(Icons.delete_forever_outlined, color: Colors.redAccent),
              label: const Text(
                'Eliminar Cuenta Permanentemente',
                style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _showEditProfileDialog() {
    final nameCtrl = TextEditingController(text: _userName);
    final emailCtrl = TextEditingController(text: _userEmail);
    final phoneCtrl = TextEditingController(text: _userPhone);
    final zoneCtrl = TextEditingController(text: _userHousingZone);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.edit_note, color: Colors.blueAccent),
              SizedBox(width: 10),
              Text('Editar Perfil'),
            ],
          ),
          content: SizedBox(
            width: 380,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Nombre Completo'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: emailCtrl,
                    decoration: const InputDecoration(labelText: 'Correo Electrónico'),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: phoneCtrl,
                    decoration: const InputDecoration(labelText: 'Teléfono / Móvil'),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: zoneCtrl,
                    decoration: const InputDecoration(labelText: 'Zona de Vivienda'),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = nameCtrl.text.trim();
                final email = emailCtrl.text.trim();
                final phone = phoneCtrl.text.trim();
                final zone = zoneCtrl.text.trim();

                if (name.isEmpty || email.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Nombre y correo son requeridos')),
                  );
                  return;
                }

                final res = await ApiService.updateProfile(
                  token: widget.token,
                  name: name,
                  email: email,
                  phone: phone,
                  housingZone: zone,
                );

                if (!context.mounted) return;
                Navigator.pop(context);

                if (res['success'] == true) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Perfil actualizado exitosamente')),
                  );
                  _loadData();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(res['message'] ?? 'Error al actualizar perfil')),
                  );
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteAccountConfirmDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
              SizedBox(width: 10),
              Text('Eliminar Cuenta'),
            ],
          ),
          content: const Text(
            '¿Estás seguro de que deseas eliminar permanentemente tu cuenta? '
            'Esta acción borrará todas tus transacciones, presupuestos, configuraciones y '
            'no se puede deshacer.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                final res = await ApiService.deleteAccount(widget.token);

                if (!context.mounted) return;
                Navigator.pop(context);

                if (res['success'] == true) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Cuenta eliminada exitosamente')),
                  );
                  Navigator.pushReplacementNamed(context, '/');
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(res['message'] ?? 'Error al eliminar cuenta')),
                  );
                }
              },
              child: const Text('Eliminar Permanentemente'),
            ),
          ],
        );
      },
    );
  }



  // ================= MODAL CALCULADORA CAMBIARIA (APIs BCV, BINANCE Y MERCADO) =================
  void _showCurrencyCalculatorDialog() {
    final amountCtrl = TextEditingController(text: '1');
    // Configuración Divisas Venezuela (BCV vs Binance)
    String foreignCurrency = 'USD'; // 'USD', 'EUR', 'USDT', 'USDC'
    bool isForeignToVes = true; // true: Divisa -> VES, false: VES -> Divisa

    showDialog(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        return FutureBuilder<Map<String, dynamic>>(
          future: ApiService.getVenezuelaRates(),
          builder: (context, snapshot) {
            final isLoadingVe = snapshot.connectionState == ConnectionState.waiting;
            final data = snapshot.data?['data'];
            final bcv = data?['bcv'] ?? {};
            final binance = data?['binance'] ?? {};
            final spread = data?['spread'] ?? {};

            final double bcvUsd = _toDouble(bcv['usd']) > 0 ? _toDouble(bcv['usd']) : 36.50;
            final double bcvEur = _toDouble(bcv['eur']) > 0 ? _toDouble(bcv['eur']) : (bcvUsd * 1.08);
            final double binanceUsdt = _toDouble(binance['usdt']) > 0 ? _toDouble(binance['usdt']) : 40.50;
            final double binanceUsdc = _toDouble(binance['usdc']) > 0 ? _toDouble(binance['usdc']) : 40.50;
            final double spreadPct = _toDouble(spread['percentage']);

            return StatefulBuilder(
              builder: (context, setDialogState) {
                final double inputAmount = double.tryParse(amountCtrl.text.replaceAll(',', '.')) ?? 0.0;

                return AlertDialog(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  title: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.calculate, color: theme.colorScheme.primary, size: 24),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Calculadora Cambiaria',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'Cotizaciones en vivo de BCV, Binance y APIs',
                              style: TextStyle(fontSize: 11, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  content: SizedBox(
                    width: 480,
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isLoadingVe)
                            const Padding(
                              padding: EdgeInsets.all(24.0),
                              child: Center(child: CircularProgressIndicator()),
                            )
                          else ...[
                            // Selector de dirección de conversión
                              Row(
                                children: [
                                  Expanded(
                                    child: ChoiceChip(
                                      label: const Text('💵 Divisa ➔ Bs.'),
                                      selected: isForeignToVes,
                                      onSelected: (val) {
                                        setDialogState(() {
                                          isForeignToVes = true;
                                        });
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: ChoiceChip(
                                      label: const Text('🇻🇪 Bs. ➔ Divisa'),
                                      selected: !isForeignToVes,
                                      onSelected: (val) {
                                        setDialogState(() {
                                          isForeignToVes = false;
                                        });
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              // Campo de entrada de monto y divisa
                              Row(
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: TextField(
                                      controller: amountCtrl,
                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                      decoration: InputDecoration(
                                        labelText: isForeignToVes ? 'Monto en Divisa' : 'Monto en Bolívares (VES)',
                                        prefixText: isForeignToVes ? '\$ ' : 'Bs. ',
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                      ),
                                      onChanged: (_) => setDialogState(() {}),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    flex: 2,
                                    child: DropdownButtonFormField<String>(
                                      value: foreignCurrency,
                                      decoration: InputDecoration(
                                        labelText: 'Moneda',
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                      ),
                                      items: const [
                                        DropdownMenuItem(value: 'USD', child: Text('🇺🇸 USD')),
                                        DropdownMenuItem(value: 'EUR', child: Text('🇪🇺 EUR')),
                                        DropdownMenuItem(value: 'USDT', child: Text('🟡 USDT')),
                                        DropdownMenuItem(value: 'USDC', child: Text('🔵 USDC')),
                                      ],
                                      onChanged: (val) {
                                        if (val != null) setDialogState(() => foreignCurrency = val);
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // Cálculos comparativos entre tasas
                              Builder(builder: (context) {
                                double rateBcv = foreignCurrency == 'EUR' ? bcvEur : bcvUsd;
                                double rateBinance = foreignCurrency == 'USDC' ? binanceUsdc : binanceUsdt;

                                double resultBcv = isForeignToVes ? (inputAmount * rateBcv) : (rateBcv > 0 ? inputAmount / rateBcv : 0.0);
                                double resultBinance = isForeignToVes ? (inputAmount * rateBinance) : (rateBinance > 0 ? inputAmount / rateBinance : 0.0);

                                double diff = (resultBinance - resultBcv).abs();

                                return Column(
                                  children: [
                                    // Tarjeta BCV Oficial
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.withOpacity(0.08),
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(color: Colors.blue.withOpacity(0.3)),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  const Text('🏛️', style: TextStyle(fontSize: 16)),
                                                  const SizedBox(width: 6),
                                                  Text(
                                                    'Tasa Oficial BCV ($foreignCurrency)',
                                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                '1 $foreignCurrency = ${CurrencyFormatter.formatNumber(rateBcv)} Bs.',
                                                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                              ),
                                            ],
                                          ),
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.end,
                                            children: [
                                              Text(
                                                isForeignToVes
                                                    ? '${CurrencyFormatter.formatNumber(resultBcv)} Bs.'
                                                    : '${CurrencyFormatter.formatNumber(resultBcv)} $foreignCurrency',
                                                style: const TextStyle(
                                                  fontSize: 17,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.blue,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                inputAmount == 1.0
                                                    ? 'Tasa exacta'
                                                    : 'Total por ${CurrencyFormatter.formatNumber(inputAmount)} $foreignCurrency',
                                                style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 10),

                                    // Tarjeta Binance P2P
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.amber.withOpacity(0.08),
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(color: Colors.amber.withOpacity(0.3)),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  const Text('🟡', style: TextStyle(fontSize: 16)),
                                                  const SizedBox(width: 6),
                                                  Text(
                                                    'Binance P2P ($foreignCurrency)',
                                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                '1 $foreignCurrency = ${CurrencyFormatter.formatNumber(rateBinance)} Bs.',
                                                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                              ),
                                            ],
                                          ),
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.end,
                                            children: [
                                              Text(
                                                isForeignToVes
                                                    ? '${CurrencyFormatter.formatNumber(resultBinance)} Bs.'
                                                    : '${CurrencyFormatter.formatNumber(resultBinance)} $foreignCurrency',
                                                style: TextStyle(
                                                  fontSize: 17,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.amber.shade800,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                inputAmount == 1.0
                                                    ? 'Tasa exacta'
                                                    : 'Total por ${CurrencyFormatter.formatNumber(inputAmount)} $foreignCurrency',
                                                style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 12),

                                    // Brecha y comparativa
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.primary.withOpacity(0.06),
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(Icons.compare_arrows, color: theme.colorScheme.primary, size: 20),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  isForeignToVes
                                                      ? (inputAmount == 1.0
                                                          ? 'Diferencia de mercado: +${CurrencyFormatter.formatNumber(diff)} Bs. / $foreignCurrency'
                                                          : 'Diferencia a favor en Binance: +${CurrencyFormatter.formatNumber(diff)} Bs.')
                                                      : 'Diferencia de compra: ${CurrencyFormatter.formatNumber(diff)} $foreignCurrency',
                                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  'Brecha cambiaria del mercado: : ${spreadPct > 0 ? '+${CurrencyFormatter.formatNumber(spreadPct)}%' : '${CurrencyFormatter.formatNumber(spreadPct)}%'}',
                                                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                );
                              }),
                            ],
                        ],
                      ),
                    ),
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
          },
        );
      },
    );
  }

  // ================= MODAL MONITOR DE TASAS VENEZUELA (BCV Y BINANCE) =================
  void _showVenezuelaRatesDialog() {
    showDialog(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        return FutureBuilder<Map<String, dynamic>>(
          future: ApiService.getVenezuelaRates(),
          builder: (context, snapshot) {
            final isLoading = snapshot.connectionState == ConnectionState.waiting;
            final data = snapshot.data?['data'];
            final bcv = data?['bcv'] ?? {};
            final binance = data?['binance'] ?? {};
            final spread = data?['spread'] ?? {};

            final double bcvUsd = _toDouble(bcv['usd']);
            final double bcvEur = _toDouble(bcv['eur']);
            final double binanceUsdt = _toDouble(binance['usdt']);
            final double binanceUsdc = _toDouble(binance['usdc']);
            final double spreadPct = _toDouble(spread['percentage']);
            final double diffVes = _toDouble(spread['diff_ves']);

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Row(
                children: [
                  Icon(Icons.account_balance, color: Colors.blueAccent),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Tasas Venezuela (BCV & Binance)',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 440,
                child: isLoading
                    ? const SizedBox(
                        height: 200,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 16),
                              Text('Obteniendo tasas del BCV y Binance...'),
                            ],
                          ),
                        ),
                      )
                    : SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Tarjeta BCV Oficial
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.blue.withOpacity(0.25)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Row(
                                    children: [
                                      Text('🏛️', style: TextStyle(fontSize: 20)),
                                      SizedBox(width: 8),
                                      Text(
                                        'Banco Central de Venezuela (BCV)',
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text('Dólar Oficial (USD):', style: TextStyle(fontSize: 13)),
                                      Text(
                                        'Bs. ${CurrencyFormatter.formatNumber(bcvUsd, decimals: 2)}',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.blueAccent),
                                      ),
                                    ],
                                  ),
                                  if (bcvEur > 0) ...[
                                    const SizedBox(height: 4),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text('Euro Oficial (EUR):', style: TextStyle(fontSize: 13)),
                                        Text(
                                          'Bs. ${CurrencyFormatter.formatNumber(bcvEur, decimals: 2)}',
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                        ),
                                      ],
                                    ),
                                  ],
                                  if (bcv['date'] != null) ...[
                                    const SizedBox(height: 6),
                                    Text(
                                      'Publicación: ${bcv['date']}',
                                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Tarjeta Binance P2P / Spot
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.amber.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.amber.withOpacity(0.25)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Row(
                                    children: [
                                      Text('🟡', style: TextStyle(fontSize: 20)),
                                      SizedBox(width: 8),
                                      Text(
                                        'Binance P2P / Cripto (VES)',
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text('Tasa USDT / VES:', style: TextStyle(fontSize: 13)),
                                      Text(
                                        'Bs. ${CurrencyFormatter.formatNumber(binanceUsdt, decimals: 2)}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          color: Colors.amber.shade800,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text('Tasa USDC / VES:', style: TextStyle(fontSize: 13)),
                                      Text(
                                        'Bs. ${CurrencyFormatter.formatNumber(binanceUsdc, decimals: 2)}',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Tarjeta de Brecha Cambiaria
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surface,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.grey.withOpacity(0.2)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.compare_arrows, color: Colors.indigoAccent),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Brecha Cambiaria (Binance vs BCV):',
                                          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                        ),
                                        Text(
                                          '+${CurrencyFormatter.formatNumber(spreadPct)}% (Dif: Bs. ${CurrencyFormatter.formatNumber(diffVes)})',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                            color: spreadPct > 10 ? Colors.redAccent : Colors.orange,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
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
      },
    );
  }

  // ================= DIÁLOGO CREAR PRESUPUESTO PERSONALIZADO =================
  void _showCreateBudgetDialog() {
    final amountCtrl = TextEditingController();
    String category = 'Alimentos';
    String period = 'mensual';

    final categories = ['Alimentos', 'Transporte', 'Vivienda', 'Servicios', 'Entretenimiento', 'Otros'];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Row(
                children: [
                  Icon(Icons.add_chart, color: Colors.blueAccent),
                  SizedBox(width: 10),
                  Text('Nuevo Presupuesto'),
                ],
              ),
              content: SizedBox(
                width: 380,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      value: category,
                      decoration: const InputDecoration(labelText: 'Categoría'),
                      items: categories
                          .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setDialogState(() => category = val);
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: amountCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Monto Límite'),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: period,
                      decoration: const InputDecoration(labelText: 'Periodo'),
                      items: const [
                        DropdownMenuItem(value: 'semanal', child: Text('Semanal')),
                        DropdownMenuItem(value: 'mensual', child: Text('Mensual')),
                        DropdownMenuItem(value: 'anual', child: Text('Anual')),
                      ],
                      onChanged: (val) {
                        if (val != null) setDialogState(() => period = val);
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
                ElevatedButton(
                  onPressed: () async {
                    final amount = double.tryParse(amountCtrl.text);
                    if (amount == null || amount <= 0) return;

                    // Agregar a la lista local de presupuestos
                    setState(() {
                      _budgets.add({
                        'id': DateTime.now().millisecondsSinceEpoch,
                        'category': category,
                        'budget': amount,
                        'spent': 0.0,
                        'percentage': 0.0,
                      });
                    });

                    // Guardar en backend
                    await ApiService.createBudget(
                      token: widget.token,
                      category: category,
                      limitAmount: amount,
                      period: period,
                    );

                    if (!context.mounted) return;
                    Navigator.pop(context);
                  },
                  child: const Text('Crear Presupuesto'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ================= DIÁLOGO AGREGAR TRANSACCIÓN =================
  void _showAddTransactionDialog() {
    final descCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    String type = 'gasto';
    String category = 'Alimentos';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final amount = double.tryParse(amountCtrl.text) ?? 0.0;

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text('Nueva Transacción'),
              content: SizedBox(
                width: 380,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'ingreso', label: Text('Ingreso')),
                        ButtonSegment(value: 'gasto', label: Text('Gasto')),
                      ],
                      selected: {type},
                      onSelectionChanged: (val) {
                        setDialogState(() {
                          type = val.first;
                          category = type == 'ingreso' ? 'Salario' : 'Alimentos';
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Descripción')),
                    const SizedBox(height: 12),
                    TextField(
                      controller: amountCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Monto en Bolívares (Bs.)',
                        prefixText: 'Bs. ',
                      ),
                      onChanged: (_) => setDialogState(() {}),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: category,
                      decoration: const InputDecoration(labelText: 'Categoría'),
                      items: (type == 'ingreso'
                              ? ['Salario', 'Freelance', 'Inversiones', 'Otros Ingresos']
                              : ['Alimentos', 'Transporte', 'Vivienda', 'Servicios', 'Salud', 'Educación', 'Entretenimiento', 'Compras', 'Ahorro', 'Impuestos', 'Otros Gastos'])
                          .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setDialogState(() => category = val);
                      },
                    ),
                    if (amount > 0) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue.withOpacity(0.2)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.public, size: 18, color: Colors.blueAccent),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                () {
                                  final bcvRate = _toDouble(_exchangeRates['VES']);
                                  final refUsd = bcvRate > 0 ? (amount / bcvRate) : 0.0;
                                  return 'Ref. Internacional: \$ ${CurrencyFormatter.formatNumber(refUsd, decimals: 2)} USD';
                                }(),
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.blueAccent),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
                ElevatedButton(
                  onPressed: () async {
                    if (descCtrl.text.isEmpty || amount <= 0) return;

                    await ApiService.addTransaction(
                      token: widget.token,
                      description: descCtrl.text,
                      amount: amount,
                      type: type,
                      category: category,
                    );

                    if (!context.mounted) return;
                    Navigator.pop(context);
                    _loadData();
                  },
                  child: const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}