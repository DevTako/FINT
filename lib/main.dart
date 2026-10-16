import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'login_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const FintApp());
}

class ThemeController {
  ThemeController._();

  static final ValueNotifier<ThemeMode> mode = ValueNotifier<ThemeMode>(ThemeMode.dark);

  static void toggle() {
    mode.value = mode.value == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
  }
}

class CurrencyController {
  CurrencyController._();

  static final ValueNotifier<String> selectedCurrency = ValueNotifier<String>('USD');

  static void setCurrency(String code) {
    selectedCurrency.value = code;
  }
}

class FintApp extends StatelessWidget {
  const FintApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeController.mode,
      builder: (context, themeMode, _) {
        return MaterialApp(
          title: 'FINT',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeMode,
          routes: {
            '/': (context) => const LoginScreen(),
          },
        );
      },
    );
  }
}
