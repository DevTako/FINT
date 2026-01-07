// Datos de prueba para la aplicación
final List<Map<String, dynamic>> recentTransactions = [
  {
    'id': 1,
    'description': 'Supermercado',
    'category': 'Alimentos',
    'amount': '125.50',
    'date': '15/11/2024',
    'type': 'expense',
  },
  {
    'id': 2,
    'description': 'Gasolina',
    'category': 'Transporte',
    'amount': '45.00',
    'date': '14/11/2024',
    'type': 'expense',
  },
  {
    'id': 3,
    'description': 'Salario',
    'category': 'Ingreso',
    'amount': '2500.00',
    'date': '10/11/2024',
    'type': 'income',
  },
  {
    'id': 4,
    'description': 'Luz y Agua',
    'category': 'Servicios',
    'amount': '120.00',
    'date': '05/11/2024',
    'type': 'expense',
  },
  {
    'id': 5,
    'description': 'Cine',
    'category': 'Entretenimiento',
    'amount': '65.00',
    'date': '02/11/2024',
    'type': 'expense',
  },
  {
    'id': 6,
    'description': 'Ropa',
    'category': 'Vestimenta',
    'amount': '89.99',
    'date': '01/11/2024',
    'type': 'expense',
  },
];

final List<Map<String, dynamic>> budgetCategories = [
  {
    'category': 'Alimentos',
    'budget': 500.0,
    'spent': 425.50,
  },
  {
    'category': 'Transporte',
    'budget': 200.0,
    'spent': 145.00,
  },
  {
    'category': 'Vivienda',
    'budget': 800.0,
    'spent': 800.0,
  },
  {
    'category': 'Servicios',
    'budget': 150.0,
    'spent': 120.0,
  },
  {
    'category': 'Entretenimiento',
    'budget': 100.0,
    'spent': 65.0,
  },
];

final Map<String, double> categoryTotals = {
  'Alimentos': 425.50,
  'Transporte': 145.00,
  'Vivienda': 800.00,
  'Servicios': 120.00,
  'Entretenimiento': 65.00,
  'Salud': 89.50,
  'Educación': 200.00,
};