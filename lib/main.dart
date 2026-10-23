import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'screens.dart';
import 'store_api.dart';

const supabaseUrl = String.fromEnvironment(
  'SUPABASE_URL',
  defaultValue: 'https://dsvtddkfgkszwjfhgavo.supabase.co',
);
const supabasePublishableKey = String.fromEnvironment(
  'SUPABASE_PUBLISHABLE_KEY',
  defaultValue: 'sb_publishable_Q3ajjZiPhk3ZFHmTyqnuyQ_S-f2JOcu',
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
      url: supabaseUrl, publishableKey: supabasePublishableKey);
  final api = AjiStoreApi(Supabase.instance.client);
  await api.initialize();
  runApp(AjiomartApp(api: api));
}

class StoreScope extends InheritedNotifier<AjiStoreApi> {
  const StoreScope({super.key, required super.notifier, required super.child});

  static AjiStoreApi of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<StoreScope>();
    assert(scope != null, 'StoreScope is missing above this widget.');
    return scope!.notifier!;
  }
}

class AjiomartApp extends StatelessWidget {
  const AjiomartApp({super.key, required this.api});

  final AjiStoreApi api;

  @override
  Widget build(BuildContext context) {
    const wine = Color(0xFF8D344B);
    return StoreScope(
      notifier: api,
      child: MaterialApp(
        title: 'Ajiomart',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
              seedColor: wine, surface: const Color(0xFFFCF9F6)),
          scaffoldBackgroundColor: const Color(0xFFFCF9F6),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFFFCF9F6),
            foregroundColor: Color(0xFF271C1D),
            centerTitle: false,
            surfaceTintColor: Colors.transparent,
          ),
          cardTheme: CardTheme(
            color: Colors.white,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFE8DFD9))),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFE8DFD9))),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: wine, width: 1.5)),
          ),
          filledButtonTheme: FilledButtonThemeData(
            style: FilledButton.styleFrom(
              backgroundColor: wine,
              foregroundColor: Colors.white,
              minimumSize: const Size(0, 50),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              textStyle: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          outlinedButtonTheme: OutlinedButtonThemeData(
            style: OutlinedButton.styleFrom(
              foregroundColor: wine,
              minimumSize: const Size(0, 48),
              side: const BorderSide(color: Color(0xFFD9BBC2)),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
          ),
          textTheme: const TextTheme(
            headlineLarge: TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w700,
                height: 1.1,
                color: Color(0xFF271C1D),
                letterSpacing: -1.1),
            headlineMedium: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                height: 1.12,
                color: Color(0xFF271C1D),
                letterSpacing: -0.5),
            titleLarge: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w700,
                color: Color(0xFF271C1D)),
            bodyMedium:
                TextStyle(fontSize: 14, height: 1.5, color: Color(0xFF65585A)),
          ),
        ),
        home: const ShopShell(),
        onGenerateRoute: (settings) {
          late final Widget page;
          switch (settings.name) {
            case '/product':
              page =
                  ProductDetailScreen(productId: settings.arguments as String);
            case '/auth':
              page = const AuthScreen();
            case '/checkout':
              page = const CheckoutScreen();
            case '/orders':
              page = const OrderHistoryScreen();
            case '/admin':
              page = const AdminScreen();
            case '/privacy':
              page = const PrivacyScreen();
            case '/shop':
              page = const ShopShell(initialTab: 1);
            case '/wishlist':
              page = const ShopShell(initialTab: 2);
            case '/cart':
              page = const ShopShell(initialTab: 3);
            case '/account':
              page = const ShopShell(initialTab: 4);
            default:
              page = const ShopShell();
          }
          return MaterialPageRoute<void>(
              builder: (_) => page, settings: settings);
        },
        builder: (context, child) =>
            StoreScope(notifier: api, child: child ?? const SizedBox.shrink()),
      ),
    );
  }
}
