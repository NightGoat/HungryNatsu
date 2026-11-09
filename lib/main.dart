import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'data/food_repository.dart';
import 'ui/home_page.dart';
import 'ui/auth_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const url = String.fromEnvironment('SUPABASE_URL');
  const anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  final FoodRepository repository;
  if (url.isNotEmpty && anonKey.isNotEmpty) {
    await Supabase.initialize(url: url, publishableKey: anonKey);
    repository = SupabaseFoodRepository(Supabase.instance.client);
  } else {
    repository = LocalFoodRepository(await SharedPreferences.getInstance());
  }
  runApp(
    HungryNatsuApp(
      repository: repository,
      online: url.isNotEmpty && anonKey.isNotEmpty,
      preferences: await SharedPreferences.getInstance(),
    ),
  );
}

class HungryNatsuApp extends StatefulWidget {
  const HungryNatsuApp({
    super.key,
    required this.repository,
    required this.online,
    required this.preferences,
  });
  final FoodRepository repository;
  final bool online;
  final SharedPreferences preferences;

  @override
  State<HungryNatsuApp> createState() => _HungryNatsuAppState();
}

class _HungryNatsuAppState extends State<HungryNatsuApp> {
  String? _language;
  bool _signedIn = false;
  late final StreamSubscription<AuthState>? _authSubscription;

  @override
  void initState() {
    super.initState();
    _language = widget.preferences.getString('language_v1');
    if (widget.online) {
      final client = Supabase.instance.client;
      _signedIn =
          client.auth.currentUser != null &&
          client.auth.currentUser?.isAnonymous != true;
      _authSubscription = client.auth.onAuthStateChange.listen((_) {
        if (mounted) {
          setState(() {
            _signedIn =
                client.auth.currentUser != null &&
                client.auth.currentUser?.isAnonymous != true;
          });
        }
      });
    } else {
      _authSubscription = null;
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  Future<void> _setLanguage(String language) async {
    setState(() => _language = language);
    await widget.preferences.setString('language_v1', language);
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Hungry Natsu',
    debugShowCheckedModeBanner: false,
    locale: _language == null ? null : Locale(_language!),
    supportedLocales: const [Locale('en'), Locale('ru')],
    localeResolutionCallback: (deviceLocale, supportedLocales) =>
        Locale(_language ?? (deviceLocale?.languageCode == 'ru' ? 'ru' : 'en')),
    localizationsDelegates: const [
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFFB85D3B),
        surface: const Color(0xFFFFFCF7),
      ),
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xFFFAF5EB),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFFAF5EB),
        foregroundColor: Color(0xFF32271F),
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFFFFFCF7),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFFFFCF7),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE7D9C9)),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    ),
    home: widget.online && !_signedIn
        ? const AuthPage()
        : HomePage(
            key: ValueKey(
              widget.online
                  ? Supabase.instance.client.auth.currentUser?.id
                  : 'local',
            ),
            repository: widget.repository,
            online: widget.online,
            onLanguageChanged: _setLanguage,
          ),
  );
}
