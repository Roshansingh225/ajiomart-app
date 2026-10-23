import 'dart:async';

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
  runApp(AjiomartApp(api: api));
  unawaited(api.initialize());
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
        builder: (context, child) => StoreScope(
          notifier: api,
          child: Stack(
            fit: StackFit.expand,
            children: [
              child ?? const SizedBox.shrink(),
              const _StartupLoadingGate(),
            ],
          ),
        ),
      ),
    );
  }
}

class _StartupLoadingGate extends StatelessWidget {
  const _StartupLoadingGate();

  @override
  Widget build(BuildContext context) {
    final api = StoreScope.of(context);
    return api.initializationComplete
        ? const SizedBox.shrink()
        : const Positioned.fill(child: _StartupLoadingScreen());
  }
}

class _StartupLoadingScreen extends StatefulWidget {
  const _StartupLoadingScreen();

  @override
  State<_StartupLoadingScreen> createState() => _StartupLoadingScreenState();
}

class _StartupLoadingScreenState extends State<_StartupLoadingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _logoScale;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
    _logoScale = Tween<double>(begin: .96, end: 1.04).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Material(
        color: const Color(0xFFFCF9F6),
        child: Stack(
          fit: StackFit.expand,
          children: [
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0, -.15),
                  radius: .9,
                  colors: [Colors.white, Color(0xFFFCF9F6)],
                ),
              ),
            ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox.square(
                    dimension: 116,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        const CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Color(0xFF8D344B),
                          backgroundColor: Color(0xFFEADDE0),
                        ),
                        ScaleTransition(
                          scale: _logoScale,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(17),
                            child: Image.asset(
                              'assets/images/ajiomart-logo.png',
                              width: 76,
                              height: 76,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 26),
                  const Text(
                    'AJIOMART',
                    style: TextStyle(
                      color: Color(0xFF271C1D),
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 3.1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Getting your store ready',
                    style: TextStyle(
                      color: Color(0xFF76696A),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 22),
                  const SizedBox(
                    width: 136,
                    child: ClipRRect(
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                      child: LinearProgressIndicator(
                        minHeight: 3,
                        color: Color(0xFF8D344B),
                        backgroundColor: Color(0xFFEADDE0),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Positioned(
              left: 0,
              right: 0,
              bottom: 30,
              child: Text(
                'CURATED FOR YOUR EVERYDAY',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF9A8587),
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.8,
                ),
              ),
            ),
          ],
        ),
      );
}
