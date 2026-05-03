import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'dart:ui' show PlatformDispatcher;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:home_widget/home_widget.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:record/record.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class AppFirebaseService {
  AppFirebaseService._();

  static final FirebaseAnalytics analytics = FirebaseAnalytics.instance;
  static final FirebaseAnalyticsObserver analyticsObserver =
      FirebaseAnalyticsObserver(analytics: analytics);
  static final FirebaseRemoteConfig remoteConfig =
      FirebaseRemoteConfig.instance;

  static Future<void> initialize() async {
    await _initializeRemoteConfig();
    await setAnalyticsUser(FirebaseAuth.instance.currentUser);
  }

  static Future<void> _initializeRemoteConfig() async {
    try {
      await remoteConfig.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(minutes: 1),
          minimumFetchInterval: const Duration(hours: 1),
        ),
      );

      await remoteConfig.setDefaults(const <String, Object>{
        'app_title': 'My Notes',
        'home_banner_text': '',
        'enable_voice_note_fab': true,
        'enable_pdf_export': true,
      });

      await remoteConfig.fetchAndActivate();
    } catch (error, stack) {
      await recordNonFatal(
        error,
        stack,
        reason: 'Remote Config initialization failed',
      );
    }
  }

  static String get appTitle {
    final String value = remoteConfig.getString('app_title').trim();
    return value.isEmpty ? 'My Notes' : value;
  }

  static String get homeBannerText =>
      remoteConfig.getString('home_banner_text').trim();

  static bool get enableVoiceNoteFab =>
      remoteConfig.getBool('enable_voice_note_fab');

  static bool get enablePdfExport => remoteConfig.getBool('enable_pdf_export');

  static Future<void> setAnalyticsUser(User? user) async {
    try {
      await analytics.setUserId(id: user?.uid);

      final String? email = user?.email;
      if (email != null && email.contains('@')) {
        await analytics.setUserProperty(
          name: 'email_domain',
          value: email.split('@').last,
        );
      }
    } catch (error, stack) {
      await recordNonFatal(error, stack, reason: 'Analytics setUserId failed');
    }
  }

  static Future<void> clearAnalyticsUser() async {
    try {
      await analytics.setUserId(id: null);
    } catch (error, stack) {
      await recordNonFatal(
        error,
        stack,
        reason: 'Analytics clearUserId failed',
      );
    }
  }

  static Future<void> logEvent(
    String name, {
    Map<String, Object?> parameters = const <String, Object?>{},
  }) async {
    final Map<String, Object> sanitizedParameters = <String, Object>{};

    parameters.forEach((String key, Object? value) {
      if (value == null) {
        return;
      }
      if (value is String || value is num) {
        sanitizedParameters[key] = value;
        return;
      }
      if (value is bool) {
        sanitizedParameters[key] = value ? 1 : 0;
        return;
      }
      sanitizedParameters[key] = value.toString();
    });

    try {
      await analytics.logEvent(name: name, parameters: sanitizedParameters);
    } catch (error, stack) {
      await recordNonFatal(
        error,
        stack,
        reason: 'Analytics logEvent failed: $name',
      );
    }
  }

  static Future<void> recordNonFatal(
    Object error,
    StackTrace stack, {
    String? reason,
  }) async {
    // Error reporting is intentionally disabled here.
    await Future<void>.value();
  }
}

enum AppPalette {
  emerald,
  ocean,
  sunset,
  rose,
  amber,
  violet,
  teal,
  slate,
  coral,
  indigo,
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await AppFirebaseService.initialize();

  runZonedGuarded(
    () {
      runApp(const KeepNotesApp());
    },
    (Object error, StackTrace stack) {},
  );
}

class KeepNotesApp extends StatefulWidget {
  const KeepNotesApp({super.key});

  @override
  State<KeepNotesApp> createState() => _KeepNotesAppState();
}

class _KeepNotesAppState extends State<KeepNotesApp> {
  static const String _themeModeKey = 'app_theme_mode_v1';
  static const String _paletteKey = 'app_palette_v1';
  static const String _pinKey = 'app_pin_v1';
  static const String _localeKey = 'app_locale_v1';

  ThemeMode _themeMode = ThemeMode.system;
  AppPalette _palette = AppPalette.emerald;
  Locale _locale = const Locale('en');
  String? _pinCode;
  bool _locked = false;

  @override
  void initState() {
    super.initState();
    _loadAppSettings();
  }

  Future<void> _loadAppSettings() async {
    await _loadThemeMode();
    await _loadPalette();
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    _pinCode = prefs.getString(_pinKey);
    final String? localeCode = prefs.getString(_localeKey);
    if (localeCode != null && localeCode.isNotEmpty) {
      _locale = Locale(_normalizeLocaleCode(localeCode));
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _locked = _pinCode != null;
    });
  }

  Future<void> _loadThemeMode() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString(_themeModeKey);
    if (raw == null) {
      return;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _themeMode = _themeModeFromStorage(raw);
    });
  }

  Future<void> _setThemeMode(ThemeMode mode) async {
    setState(() {
      _themeMode = mode;
    });

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeModeKey, _themeModeToStorage(mode));
  }

  Future<void> _loadPalette() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString(_paletteKey);
    if (raw == null) {
      return;
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _palette = _paletteFromStorage(raw);
    });
  }

  Future<void> _setPalette(AppPalette palette) async {
    setState(() {
      _palette = palette;
    });

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_paletteKey, _paletteToStorage(palette));
  }

  Future<void> _setPin(String pin) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pinKey, pin);
    if (!mounted) {
      return;
    }
    setState(() {
      _pinCode = pin;
      _locked = false;
    });
  }

  Future<void> _removePin() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pinKey);
    if (!mounted) {
      return;
    }
    setState(() {
      _pinCode = null;
      _locked = false;
    });
  }

  void _unlockWithPin(String pin) {
    if (_pinCode != null && _pinCode == pin) {
      setState(() {
        _locked = false;
      });
    }
  }

  Future<void> _showPinSetupDialog(BuildContext context) async {
    final String languageCode = _locale.languageCode;
    String s(String key) => AppStrings.of(languageCode, key);
    final TextEditingController pinController = TextEditingController();
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    await showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(_pinCode == null ? s('set_pin') : s('change_pin')),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: pinController,
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 6,
              decoration: InputDecoration(labelText: s('enter_pin_4_6')),
              validator: (String? value) {
                if (value == null || value.length < 4 || value.length > 6) {
                  return s('pin_must_4_6');
                }
                if (!RegExp(r'^\\d+$').hasMatch(value)) {
                  return s('numbers_only');
                }
                return null;
              },
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(s('cancel')),
            ),
            FilledButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  _setPin(pinController.text);
                  Navigator.of(dialogContext).pop();
                }
              },
              child: Text(s('save')),
            ),
          ],
        );
      },
    );
  }

  Future<void> _requestLockNow() async {
    if (_pinCode == null) {
      return;
    }
    setState(() {
      _locked = true;
    });
  }

  Future<void> _setLocale(Locale locale) async {
    final String normalizedCode = _normalizeLocaleCode(locale.languageCode);
    setState(() {
      _locale = Locale(normalizedCode);
    });
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localeKey, normalizedCode);
  }

  String _normalizeLocaleCode(String localeCode) {
    if (localeCode == 'hi') {
      // Migrate previous Hindi setting to Bangla option.
      return 'bn';
    }
    return localeCode;
  }

  String _themeModeToStorage(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return 'system';
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
    }
  }

  ThemeMode _themeModeFromStorage(String value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
        return ThemeMode.system;
      default:
        return ThemeMode.system;
    }
  }

  String _paletteToStorage(AppPalette palette) {
    return palette.name;
  }

  AppPalette _paletteFromStorage(String value) {
    return AppPalette.values.firstWhere(
      (AppPalette palette) => palette.name == value,
      orElse: () => AppPalette.emerald,
    );
  }

  Color _paletteSeedColor(AppPalette palette) {
    switch (palette) {
      case AppPalette.emerald:
        return const Color(0xFF1F7A5A);
      case AppPalette.ocean:
        return const Color(0xFF1572D3);
      case AppPalette.sunset:
        return const Color(0xFFE56A2E);
      case AppPalette.rose:
        return const Color(0xFFD94A8A);
      case AppPalette.amber:
        return const Color(0xFFB58300);
      case AppPalette.violet:
        return const Color(0xFF6D4ACF);
      case AppPalette.teal:
        return const Color(0xFF008E91);
      case AppPalette.slate:
        return const Color(0xFF4B5D7A);
      case AppPalette.coral:
        return const Color(0xFFD55D5D);
      case AppPalette.indigo:
        return const Color(0xFF4057D6);
    }
  }

  ThemeData _buildLightTheme(Color seedColor) {
    final ColorScheme colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.light,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: const Color(0xFFF4F6FA),
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFFF4F6FA),
        foregroundColor: colorScheme.onSurface,
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      cardColor: colorScheme.surface,
      cardTheme: CardThemeData(
        color: colorScheme.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      dialogTheme: DialogThemeData(
        elevation: 0,
        backgroundColor: colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      popupMenuTheme: PopupMenuThemeData(
        elevation: 0,
        color: colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: const StadiumBorder(),
        side: BorderSide.none,
        labelStyle: TextStyle(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
        selectedColor: colorScheme.primaryContainer,
        backgroundColor: colorScheme.surfaceContainerLow,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colorScheme.surface,
        indicatorColor: colorScheme.secondaryContainer,
        elevation: 0,
        labelTextStyle: const WidgetStatePropertyAll(
          TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }

  ThemeData _buildAmoledTheme(Color seedColor) {
    final ColorScheme seeded = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.dark,
    );
    final ColorScheme colorScheme = seeded.copyWith(
      surface: const Color(0xFF14161B),
      onSurface: const Color(0xFFE8EAED),
      surfaceContainerLowest: const Color(0xFF0B0D11),
      surfaceContainerLow: const Color(0xFF11141A),
      surfaceContainer: const Color(0xFF171B22),
      surfaceContainerHigh: const Color(0xFF1F242C),
      surfaceContainerHighest: const Color(0xFF2B3038),
      outlineVariant: const Color(0xFF4E5561),
      primary: const Color(0xFFAEC5F5),
      onPrimary: const Color(0xFF101826),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: const Color(0xFF14161B),
      canvasColor: const Color(0xFF14161B),
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFF14161B),
        foregroundColor: colorScheme.onSurface,
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      cardColor: const Color(0xFF0B0D11),
      cardTheme: CardThemeData(
        color: const Color(0xFF0B0D11),
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF141414),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      dialogTheme: DialogThemeData(
        elevation: 0,
        backgroundColor: const Color(0xFF171B22),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      popupMenuTheme: PopupMenuThemeData(
        elevation: 0,
        color: const Color(0xFF171B22),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: const StadiumBorder(),
        side: BorderSide.none,
        labelStyle: TextStyle(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
        selectedColor: colorScheme.primary.withValues(alpha: 0.32),
        backgroundColor: colorScheme.surfaceContainerHigh,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: const Color(0xFF14161B),
        indicatorColor: colorScheme.secondaryContainer,
        elevation: 0,
        labelTextStyle: const WidgetStatePropertyAll(
          TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: const Color(0xFFAEC5F5),
        foregroundColor: const Color(0xFF1B2433),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color seedColor = _paletteSeedColor(_palette);
    return MaterialApp(
      title: AppFirebaseService.appTitle,
      debugShowCheckedModeBanner: false,
      navigatorObservers: <NavigatorObserver>[
        AppFirebaseService.analyticsObserver,
      ],
      locale: _locale,
      supportedLocales: const <Locale>[Locale('en'), Locale('bn')],
      localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      themeMode: _themeMode,
      theme: _buildLightTheme(seedColor),
      darkTheme: _buildAmoledTheme(seedColor),
      home: AuthGate(
        child: _locked
            ? PinUnlockPage(
                onUnlock: _unlockWithPin,
                localeCode: _locale.languageCode,
              )
            : NotesHomePage(
                selectedThemeMode: _themeMode,
                onThemeModeChanged: _setThemeMode,
                selectedPalette: _palette,
                onPaletteChanged: _setPalette,
                onSetPinRequested: _showPinSetupDialog,
                onRemovePinRequested: _removePin,
                onLockNowRequested: _requestLockNow,
                hasPin: _pinCode != null,
                selectedLocale: _locale,
                onLocaleChanged: _setLocale,
              ),
      ),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (BuildContext context, AsyncSnapshot<User?> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData) {
          return child;
        }

        return const LoginPage();
      },
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _isLogin = true;
  bool _isLoading = false;
  String? _errorText;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final String email = _emailController.text.trim();
    final String password = _passwordController.text.trim();
    final String confirmPassword = _confirmPasswordController.text.trim();

    final RegExp emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

    if (email.isEmpty) {
      setState(() {
        _errorText = 'Email is required.';
      });
      return;
    }

    if (!emailRegex.hasMatch(email)) {
      setState(() {
        _errorText = 'Please enter a valid email address.';
      });
      return;
    }

    if (password.length < 6) {
      setState(() {
        _errorText = 'Password must be at least 6 characters.';
      });
      return;
    }

    if (!_isLogin && confirmPassword != password) {
      setState(() {
        _errorText = 'Confirm password does not match.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    try {
      if (_isLogin) {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      } else {
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
      }

      await AppFirebaseService.setAnalyticsUser(
        FirebaseAuth.instance.currentUser,
      );
      await AppFirebaseService.logEvent(
        _isLogin ? 'login_success' : 'sign_up_success',
        parameters: <String, Object?>{'method': 'email'},
      );
    } on FirebaseAuthException catch (e, stack) {
      await AppFirebaseService.recordNonFatal(
        e,
        stack,
        reason: _isLogin ? 'Login failed' : 'Sign up failed',
      );
      setState(() {
        _errorText = e.message ?? 'Authentication failed.';
      });
    } catch (error, stack) {
      await AppFirebaseService.recordNonFatal(
        error,
        stack,
        reason: 'Unexpected authentication error',
      );
      setState(() {
        _errorText = 'Something went wrong. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  InputDecoration _loginInputDecoration(
    Color inputFill,
    BorderSide inputBorder,
    Color primary,
  ) {
    return InputDecoration(
      isDense: true,
      filled: true,
      fillColor: inputFill,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      border: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(14)),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: const BorderRadius.all(Radius.circular(14)),
        borderSide: BorderSide(color: primary),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: const BorderRadius.all(Radius.circular(14)),
        borderSide: inputBorder,
      ),
    );
  }

  Widget _requiredLabel(String text, Color textColor, Color errorColor) {
    return Text.rich(
      TextSpan(
        children: <InlineSpan>[
          TextSpan(
            text: text,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w600,
              fontSize: 17,
            ),
          ),
          TextSpan(
            text: ' *',
            style: TextStyle(
              color: errorColor,
              fontWeight: FontWeight.w600,
              fontSize: 17,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final bool isDark = theme.brightness == Brightness.dark;
    final Color panelBackground = theme.cardColor;
    final Color inputFill =
        theme.inputDecorationTheme.fillColor ??
        (isDark ? const Color(0xFF141414) : Colors.white);
    final BorderSide inputBorder = BorderSide(
      color: colorScheme.outlineVariant,
    );

    return Scaffold(
      backgroundColor: isDark ? Colors.black : colorScheme.surface,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[
              colorScheme.primary.withValues(alpha: isDark ? 0.22 : 0.08),
              isDark ? Colors.black : colorScheme.surface,
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: colorScheme.primary,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: <BoxShadow>[
                            BoxShadow(
                              color: colorScheme.primary.withValues(
                                alpha: 0.26,
                              ),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.edit_rounded,
                          color: colorScheme.onPrimary,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        AppFirebaseService.appTitle,
                        style: TextStyle(
                          fontSize: 44,
                          height: 1,
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.8,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Card(
                    elevation: 0,
                    color: panelBackground,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(22),
                      side: BorderSide(color: colorScheme.outlineVariant),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          _requiredLabel(
                            'Email',
                            colorScheme.onSurface,
                            colorScheme.error,
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: _loginInputDecoration(
                              inputFill,
                              inputBorder,
                              colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 14),
                          _requiredLabel(
                            'Password',
                            colorScheme.onSurface,
                            colorScheme.error,
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _passwordController,
                            obscureText: true,
                            decoration: _loginInputDecoration(
                              inputFill,
                              inputBorder,
                              colorScheme.primary,
                            ),
                          ),
                          if (_isLogin)
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: _isLoading
                                    ? null
                                    : () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute<void>(
                                            builder: (BuildContext context) =>
                                                const ResetPasswordPage(),
                                          ),
                                        );
                                      },
                                child: Text(
                                  'Forgot password?',
                                  style: TextStyle(color: colorScheme.primary),
                                ),
                              ),
                            ),
                          if (!_isLogin) ...<Widget>[
                            const SizedBox(height: 14),
                            TextField(
                              controller: _confirmPasswordController,
                              obscureText: true,
                              decoration: _loginInputDecoration(
                                inputFill,
                                inputBorder,
                                colorScheme.primary,
                              ).copyWith(labelText: 'Confirm Password'),
                            ),
                          ],
                          const SizedBox(height: 8),
                          if (_errorText != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Text(
                                _errorText!,
                                style: TextStyle(color: colorScheme.error),
                              ),
                            ),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              onPressed: _isLoading ? null : _submit,
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 18,
                                      width: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Text(_isLogin ? 'Sign in' : 'Sign up'),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Center(
                            child: GestureDetector(
                              onTap: _isLoading
                                  ? null
                                  : () {
                                      setState(() {
                                        _isLogin = !_isLogin;
                                        _errorText = null;
                                        _confirmPasswordController.clear();
                                      });
                                    },
                              child: RichText(
                                text: TextSpan(
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: colorScheme.onSurface,
                                  ),
                                  children: <InlineSpan>[
                                    TextSpan(
                                      text: _isLogin
                                          ? "Don't have an account? "
                                          : 'Already have an account? ',
                                    ),
                                    TextSpan(
                                      text: _isLogin ? 'Sign up' : 'Sign in',
                                      style: TextStyle(
                                        color: colorScheme.primary,
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
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;
  String? _errorText;
  String? _successText;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendResetLink() async {
    final String email = _emailController.text.trim();
    final RegExp emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

    if (email.isEmpty) {
      setState(() {
        _errorText = 'Email is required.';
        _successText = null;
      });
      return;
    }

    if (!emailRegex.hasMatch(email)) {
      setState(() {
        _errorText = 'Please enter a valid email address.';
        _successText = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorText = null;
      _successText = null;
    });

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      await AppFirebaseService.logEvent(
        'password_reset_requested',
        parameters: <String, Object?>{
          'email_domain': email.contains('@')
              ? email.split('@').last
              : 'unknown',
        },
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _successText = 'Password reset email sent successfully.';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password reset email sent.')),
      );
    } on FirebaseAuthException catch (e, stack) {
      await AppFirebaseService.recordNonFatal(
        e,
        stack,
        reason: 'Password reset failed',
      );
      if (!mounted) {
        return;
      }
      setState(() {
        if (e.code == 'invalid-email') {
          _errorText = 'Please enter a valid email address.';
        } else {
          _errorText = e.message ?? 'Failed to send reset email.';
        }
      });
    } catch (error, stack) {
      await AppFirebaseService.recordNonFatal(
        error,
        stack,
        reason: 'Unexpected password reset error',
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _errorText = 'Something went wrong. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final bool isDark = theme.brightness == Brightness.dark;
    final Color panelBackground = theme.cardColor;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(title: const Text('Reset Password')),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[
              colorScheme.primary.withValues(alpha: isDark ? 0.20 : 0.08),
              theme.scaffoldBackgroundColor,
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Card(
                elevation: 0,
                color: panelBackground,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22),
                  side: BorderSide(color: colorScheme.outlineVariant),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Enter your email to receive a reset link.',
                        style: TextStyle(
                          fontSize: 15,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          isDense: true,
                          filled: true,
                          fillColor: theme.inputDecorationTheme.fillColor,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 13,
                          ),
                          border: const OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(14)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: const BorderRadius.all(
                              Radius.circular(14),
                            ),
                            borderSide: BorderSide(
                              color: colorScheme.outlineVariant,
                            ),
                          ),
                        ),
                      ),
                      if (_errorText != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Text(
                            _errorText!,
                            style: TextStyle(color: colorScheme.error),
                          ),
                        ),
                      if (_successText != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Text(
                            _successText!,
                            style: const TextStyle(color: Color(0xFF2A7E4C)),
                          ),
                        ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: _isLoading ? null : _sendResetLink,
                          child: _isLoading
                              ? SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: colorScheme.onPrimary,
                                  ),
                                )
                              : const Text('Send Reset Link'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key, required this.localeCode});

  final String localeCode;

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final TextEditingController _currentPasswordController =
      TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _isLoading = false;
  String? _errorText;
  String? _successText;

  String _s(String key) => AppStrings.of(widget.localeCode, key);

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _updatePassword() async {
    final User? user = FirebaseAuth.instance.currentUser;
    final String? email = user?.email;
    final String currentPassword = _currentPasswordController.text.trim();
    final String newPassword = _newPasswordController.text.trim();
    final String confirmPassword = _confirmPasswordController.text.trim();

    if (user == null || email == null || email.isEmpty) {
      setState(() {
        _errorText = 'No active user found.';
      });
      return;
    }

    if (newPassword.length < 6) {
      setState(() {
        _errorText = _s('password_min_6');
        _successText = null;
      });
      return;
    }

    if (newPassword != confirmPassword) {
      setState(() {
        _errorText = _s('password_mismatch');
        _successText = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorText = null;
      _successText = null;
    });

    try {
      final AuthCredential credential = EmailAuthProvider.credential(
        email: email,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPassword);
      await AppFirebaseService.logEvent(
        'password_changed',
        parameters: const <String, Object?>{'method': 'email'},
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _successText = _s('password_updated');
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_s('password_updated'))));
      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
    } on FirebaseAuthException catch (e, stack) {
      await AppFirebaseService.recordNonFatal(
        e,
        stack,
        reason: 'Password update failed',
      );
      if (!mounted) {
        return;
      }
      setState(() {
        if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
          _errorText = _s('invalid_current_password');
        } else if (e.code == 'weak-password') {
          _errorText = _s('password_min_6');
        } else {
          _errorText = e.message ?? 'Unable to update password.';
        }
      });
    } catch (error, stack) {
      await AppFirebaseService.recordNonFatal(
        error,
        stack,
        reason: 'Unexpected password update error',
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _errorText = 'Unable to update password.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final bool isDark = theme.brightness == Brightness.dark;
    final Color panelBackground = theme.cardColor;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(title: Text(_s('change_password'))),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[
              colorScheme.primary.withValues(alpha: isDark ? 0.20 : 0.08),
              theme.scaffoldBackgroundColor,
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Card(
                elevation: 0,
                color: panelBackground,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22),
                  side: BorderSide(color: colorScheme.outlineVariant),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      TextField(
                        controller: _currentPasswordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: _s('current_password'),
                          isDense: true,
                          filled: true,
                          fillColor: theme.inputDecorationTheme.fillColor,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 13,
                          ),
                          border: const OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(14)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _newPasswordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: _s('new_password'),
                          isDense: true,
                          filled: true,
                          fillColor: theme.inputDecorationTheme.fillColor,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 13,
                          ),
                          border: const OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(14)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _confirmPasswordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: _s('confirm_new_password'),
                          isDense: true,
                          filled: true,
                          fillColor: theme.inputDecorationTheme.fillColor,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 13,
                          ),
                          border: const OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(14)),
                          ),
                        ),
                      ),
                      if (_errorText != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Text(
                            _errorText!,
                            style: TextStyle(color: colorScheme.error),
                          ),
                        ),
                      if (_successText != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Text(
                            _successText!,
                            style: const TextStyle(color: Color(0xFF2A7E4C)),
                          ),
                        ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: _isLoading ? null : _updatePassword,
                          child: _isLoading
                              ? SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: colorScheme.onPrimary,
                                  ),
                                )
                              : Text(_s('update_password')),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class PinUnlockPage extends StatefulWidget {
  const PinUnlockPage({
    super.key,
    required this.onUnlock,
    required this.localeCode,
  });

  final ValueChanged<String> onUnlock;
  final String localeCode;

  @override
  State<PinUnlockPage> createState() => _PinUnlockPageState();
}

class _PinUnlockPageState extends State<PinUnlockPage> {
  final TextEditingController _pinController = TextEditingController();
  String? _error;

  String _s(String key) => AppStrings.of(widget.localeCode, key);

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final bool isDark = theme.brightness == Brightness.dark;
    final Color panelBackground = theme.cardColor;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[
              colorScheme.primary.withValues(alpha: isDark ? 0.20 : 0.08),
              theme.scaffoldBackgroundColor,
            ],
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 380),
              child: Card(
                elevation: 0,
                color: panelBackground,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22),
                  side: BorderSide(color: colorScheme.outlineVariant),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Icon(
                        Icons.lock_rounded,
                        size: 46,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _s('unlock_my_notes'),
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _pinController,
                        maxLength: 6,
                        keyboardType: TextInputType.number,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: _s('enter_pin'),
                          errorText: _error,
                          isDense: true,
                          filled: true,
                          fillColor: theme.inputDecorationTheme.fillColor,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 13,
                          ),
                          border: const OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(14)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: () {
                            final String pin = _pinController.text.trim();
                            if (pin.length < 4) {
                              setState(() {
                                _error = _s('invalid_pin');
                              });
                              return;
                            }
                            widget.onUnlock(pin);
                            _pinController.clear();
                          },
                          child: Text(_s('unlock')),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

enum NoteScope { notes, archived, trash }

enum QuickFilter { all, dueToday, noReminder, pinned, withLabels }

enum NoteSortMode { newestFirst, oldestFirst, title, pinnedFirst }

class AppStrings {
  static const Map<String, Map<String, String>>
  _data = <String, Map<String, String>>{
    'en': <String, String>{
      'notes': 'Notes',
      'archive': 'Archive',
      'trash': 'Trash',
      'new_note': 'New note',
      'search_notes': 'Search notes',
      'search_trash': 'Search trash',
      'theme_system': 'Theme: System',
      'theme_light': 'Theme: Light',
      'theme_dark': 'Theme: Dark',
      'theme_palette': 'Color palette',
      'palette_emerald': 'Emerald',
      'palette_ocean': 'Ocean',
      'palette_sunset': 'Sunset',
      'palette_rose': 'Rose',
      'palette_amber': 'Amber',
      'palette_violet': 'Violet',
      'palette_teal': 'Teal',
      'palette_slate': 'Slate',
      'palette_coral': 'Coral',
      'palette_indigo': 'Indigo',
      'language': 'Language',
      'lang_en': 'English',
      'lang_bn': 'Bangla',
      'statistics': 'Statistics',
      'create_backup': 'Create backup',
      'restore_backup': 'Restore backup',
      'set_pin': 'Set PIN lock',
      'change_pin': 'Change PIN lock',
      'remove_pin': 'Remove PIN lock',
      'lock_now': 'Lock now',
      'enter_pin_4_6': 'Enter 4-6 digit PIN',
      'pin_must_4_6': 'PIN must be 4-6 digits',
      'numbers_only': 'Only numbers are allowed',
      'cancel': 'Cancel',
      'save': 'Save',
      'unlock_my_notes': 'Unlock My Notes',
      'enter_pin': 'Enter PIN',
      'invalid_pin': 'Invalid PIN',
      'unlock': 'Unlock',
      'theme': 'Theme',
      'switch_to_list': 'Switch to list view',
      'switch_to_grid': 'Switch to grid view',
      'app_actions': 'App actions',
      'all': 'All',
      'due_today': 'Due Today',
      'no_reminder': 'No Reminder',
      'pinned': 'Pinned',
      'with_labels': 'With Labels',
      'reorder_hint': 'Drag by the handle to reorder notes.',
      'no_notes': 'No notes yet',
      'no_notes_body': 'Tap + to create your first note.',
      'no_archived': 'No archived notes',
      'no_archived_body':
          'Archive notes you want to keep without cluttering your main list.',
      'trash_empty': 'Trash is empty',
      'trash_empty_body':
          'Deleted notes will appear here until you restore or delete forever.',
      'more_options': 'More options',
      'checklist_progress': 'Checklist',
      'reminder_prefix': 'Reminder',
      'pin': 'Pin',
      'unpin': 'Unpin',
      'favorite': 'Favorite',
      'unfavorite': 'Unfavorite',
      'export_pdf': 'Export as PDF',
      'duplicate': 'Duplicate',
      'move_to_trash': 'Move to trash',
      'unarchive': 'Unarchive',
      'restore': 'Restore',
      'delete_forever': 'Delete forever',
      'pdf_saved_to': 'PDF saved to',
      'pdf_export_failed': 'Unable to export PDF. Please try again.',
      'pdf_share_failed': 'PDF created, but sharing could not be opened.',
      'backup_saved': 'Backup saved to',
      'backup_missing': 'No backup file found yet.',
      'backup_restored': 'Backup restored successfully.',
      'stats_title': 'Notes statistics',
      'stats_total': 'Total',
      'stats_active': 'Active',
      'stats_archived': 'Archived',
      'stats_trash': 'Trash',
      'stats_pinned': 'Pinned',
      'stats_reminders': 'With reminders',
      'close': 'Close',
      'moved_to_trash': 'Moved to trash',
      'undo': 'Undo',
      'reorder_pinned_only': 'Reorder pinned notes within their section.',
      'edit_note': 'Edit note',
      'title': 'Title',
      'start_typing': 'Start typing...',
      'bold': 'Bold',
      'italic': 'Italic',
      'bullet': 'Bullet',
      'heading': 'Heading',
      'checklist': 'Checklist',
      'add_checklist_item': 'Add checklist item',
      'add': 'Add',
      'attachments': 'Attachments',
      'add_image': 'Add Image',
      'record_voice': 'Record Voice',
      'stop_voice': 'Stop Voice',
      'mic_permission_needed':
          'Microphone permission is required to record voice notes.',
      'play_audio': 'Play audio',
      'pause_audio': 'Pause audio',
      'audio_play_error': 'Unable to play this audio file.',
      'color': 'Color',
      'reminder': 'Reminder',
      'no_reminder_set': 'No reminder set',
      'set': 'Set',
      'clear': 'Clear',
      'labels': 'Labels',
      'labels_hint': 'work, ideas, personal',
      'pin_this_note': 'Pin this note',
      'delete_note': 'Move to trash',
      'save_note': 'Save note',
      'archive_note': 'Archive',
      'hidden_note': 'Hidden note',
      'note_locked': 'This note is locked. Tap to unlock.',
      'note_lock': 'Note lock',
      'lock_with_pin': 'PIN',
      'lock_with_password': 'Password',
      'lock_secret': 'Lock value',
      'lock_secret_required': 'Please enter PIN/Password for this note lock.',
      'unlock_failed': 'Incorrect PIN/Password.',
      'just_now': 'Just now',
      'minute_short_ago': 'm ago',
      'hour_short_ago': 'h ago',
      'day_short_ago': 'd ago',
      'untitled_note': 'Untitled note',
      'open_my_notes_review': 'Open My Notes to review it.',
      'no_notes_tap_open': 'No notes yet. Tap to open My Notes.',
      'tap_open_my_notes': 'Tap to open My Notes.',
      'note_single': 'active note',
      'note_plural': 'active notes',
      'no_upcoming_reminders': 'No upcoming reminders',
      'next_reminder': 'Next reminder',
      'logout': 'Logout',
      'logout_failed': 'Unable to logout. Please try again.',
      'logout_confirm_title': 'Confirm logout',
      'logout_confirm_message': 'Are you sure you want to logout?',
      'yes': 'Yes',
      'settings': 'Settings',
      'settings_title': 'App settings',
      'account': 'Account',
      'logged_in_as': 'Logged in as',
      'auto_backup_on_save': 'Auto backup on every save',
      'confirm_before_trash': 'Confirm before moving note to trash',
      'empty_trash': 'Empty trash',
      'trash_emptied': 'Trash emptied',
      'empty_trash_confirm_title': 'Empty trash?',
      'empty_trash_confirm_message':
          'Are you sure you want to permanently delete all trash notes?',
      'save_changes': 'Save changes',
      'user_email': 'User email',
      'change_password': 'Change password',
      'app_info': 'App info',
      'update_password': 'Update password',
      'current_password': 'Current password',
      'new_password': 'New password',
      'confirm_new_password': 'Confirm new password',
      'password_updated': 'Password updated successfully.',
      'password_mismatch': 'Passwords do not match.',
      'password_min_6': 'Password must be at least 6 characters.',
      'invalid_current_password': 'Current password is incorrect.',
      'preferences': 'Preferences',
      'security': 'Security',
      'about': 'About',
      'category': 'Category',
      'study': 'Study',
      'work': 'Work',
      'personal': 'Personal',
      'ideas': 'Ideas',
      'sort': 'Sort',
      'sort_newest_first': 'Newest first',
      'sort_oldest_first': 'Oldest first',
      'sort_title': 'Title',
      'sort_pinned_first': 'Pinned first',
      'created': 'Created',
      'updated': 'Updated',
    },
    'bn': <String, String>{
      'notes': 'नोट्स',
      'archive': 'संग्रह',
      'trash': 'ट्रैश',
      'new_note': 'नया नोट',
      'search_notes': 'नोट खोजें',
      'search_trash': 'ट्रैश खोजें',
      'theme_system': 'थीम: सिस्टम',
      'theme_light': 'थीम: लाइट',
      'theme_dark': 'थीम: डार्क',
      'theme_palette': 'कलर पैलेट',
      'palette_emerald': 'एमरल्ड',
      'palette_ocean': 'ओशन',
      'palette_sunset': 'सनसेट',
      'palette_rose': 'रोज',
      'palette_amber': 'एंबर',
      'palette_violet': 'वायलेट',
      'palette_teal': 'टील',
      'palette_slate': 'स्लेट',
      'palette_coral': 'कोरल',
      'palette_indigo': 'इंडिगो',
      'language': 'ভাষা',
      'lang_en': 'ইংরেজি',
      'lang_bn': 'বাংলা',
      'statistics': 'आंकड़े',
      'create_backup': 'बैकअप बनाएं',
      'restore_backup': 'बैकअप बहाल करें',
      'set_pin': 'पिन लॉक सेट करें',
      'change_pin': 'पिन लॉक बदलें',
      'remove_pin': 'पिन लॉक हटाएं',
      'lock_now': 'अभी लॉक करें',
      'enter_pin_4_6': '4-6 अंकों का पिन दर्ज करें',
      'pin_must_4_6': 'पिन 4-6 अंकों का होना चाहिए',
      'numbers_only': 'केवल नंबर मान्य हैं',
      'cancel': 'रद्द करें',
      'save': 'सहेजें',
      'unlock_my_notes': 'माय नोट्स अनलॉक करें',
      'enter_pin': 'पिन दर्ज करें',
      'invalid_pin': 'गलत पिन',
      'unlock': 'अनलॉक',
      'theme': 'थीम',
      'switch_to_list': 'सूची दृश्य पर जाएं',
      'switch_to_grid': 'ग्रिड दृश्य पर जाएं',
      'app_actions': 'ऐप विकल्प',
      'all': 'सभी',
      'due_today': 'आज देय',
      'no_reminder': 'रिमाइंडर नहीं',
      'pinned': 'पिन किए गए',
      'with_labels': 'लेबल वाले',
      'reorder_hint': 'नोट्स को क्रम बदलने के लिए ड्रैग करें।',
      'no_notes': 'अभी कोई नोट नहीं',
      'no_notes_body': 'अपना पहला नोट बनाने के लिए + पर टैप करें।',
      'no_archived': 'कोई संग्रहित नोट नहीं',
      'no_archived_body': 'मुख्य सूची साफ रखने के लिए नोट्स संग्रहित करें।',
      'trash_empty': 'ट्रैश खाली है',
      'trash_empty_body':
          'हटाए गए नोट्स यहां दिखेंगे जब तक आप बहाल या स्थायी हटाएं।',
      'more_options': 'अधिक विकल्प',
      'checklist_progress': 'चेकलिस्ट',
      'reminder_prefix': 'रिमाइंडर',
      'pin': 'पिन करें',
      'unpin': 'अनपिन',
      'favorite': 'फेवरेट',
      'unfavorite': 'अनफेवरेट',
      'export_pdf': 'PDF में एक्सपोर्ट करें',
      'duplicate': 'कॉपी बनाएं',
      'move_to_trash': 'ट्रैश में भेजें',
      'unarchive': 'संग्रह से निकालें',
      'restore': 'बहाल करें',
      'delete_forever': 'हमेशा के लिए हटाएं',
      'pdf_saved_to': 'PDF यहां सेव हुई',
      'pdf_export_failed':
          'PDF एक्सपोर्ट नहीं हो सकी। कृपया फिर से प्रयास करें।',
      'pdf_share_failed': 'PDF बन गई, लेकिन शेयर विकल्प नहीं खुला।',
      'backup_saved': 'बैकअप यहां सहेजा गया',
      'backup_missing': 'अभी कोई बैकअप फ़ाइल नहीं मिली।',
      'backup_restored': 'बैकअप सफलतापूर्वक बहाल हुआ।',
      'stats_title': 'नोट्स आंकड़े',
      'stats_total': 'कुल',
      'stats_active': 'सक्रिय',
      'stats_archived': 'संग्रहित',
      'stats_trash': 'ट्रैश',
      'stats_pinned': 'पिन',
      'stats_reminders': 'रिमाइंडर वाले',
      'close': 'बंद करें',
      'moved_to_trash': 'ट्रैश में भेजा गया',
      'undo': 'वापस लें',
      'reorder_pinned_only': 'पिन नोट्स को उनके सेक्शन में ही रीऑर्डर करें।',
      'edit_note': 'नोट संपादित करें',
      'title': 'शीर्षक',
      'start_typing': 'लिखना शुरू करें...',
      'bold': 'बोल्ड',
      'italic': 'इटैलिक',
      'bullet': 'बुलेट',
      'heading': 'शीर्षक',
      'checklist': 'चेकलिस्ट',
      'add_checklist_item': 'चेकलिस्ट आइटम जोड़ें',
      'add': 'जोड़ें',
      'attachments': 'अटैचमेंट',
      'add_image': 'इमेज जोड़ें',
      'record_voice': 'आवाज़ रिकॉर्ड करें',
      'stop_voice': 'रिकॉर्डिंग रोकें',
      'mic_permission_needed':
          'वॉइस नोट रिकॉर्ड करने के लिए माइक्रोफोन अनुमति चाहिए।',
      'play_audio': 'ऑडियो चलाएं',
      'pause_audio': 'ऑडियो रोकें',
      'audio_play_error': 'यह ऑडियो फ़ाइल नहीं चल सकी।',
      'color': 'रंग',
      'reminder': 'रिमाइंडर',
      'no_reminder_set': 'कोई रिमाइंडर सेट नहीं',
      'set': 'सेट करें',
      'clear': 'हटाएं',
      'labels': 'लेबल',
      'labels_hint': 'काम, विचार, निजी',
      'pin_this_note': 'इस नोट को पिन करें',
      'delete_note': 'ट्रैश में भेजें',
      'save_note': 'नोट सहेजें',
      'archive_note': 'संग्रहित करें',
      'hidden_note': 'छुपा हुआ नोट',
      'note_locked': 'यह नोट लॉक है। खोलने के लिए टैप करें।',
      'note_lock': 'नोट लॉक',
      'lock_with_pin': 'पिन',
      'lock_with_password': 'पासवर्ड',
      'lock_secret': 'लॉक वैल्यू',
      'lock_secret_required': 'इस नोट लॉक के लिए पिन/पासवर्ड दर्ज करें।',
      'unlock_failed': 'गलत पिन/पासवर्ड।',
      'just_now': 'अभी',
      'minute_short_ago': 'मि पहले',
      'hour_short_ago': 'घं पहले',
      'day_short_ago': 'दिन पहले',
      'untitled_note': 'बिना शीर्षक नोट',
      'open_my_notes_review': 'जांचने के लिए माय नोट्स खोलें।',
      'no_notes_tap_open': 'अभी कोई नोट नहीं। माय नोट्स खोलने के लिए टैप करें।',
      'tap_open_my_notes': 'माय नोट्स खोलने के लिए टैप करें।',
      'note_single': 'सक्रिय नोट',
      'note_plural': 'सक्रिय नोट्स',
      'no_upcoming_reminders': 'कोई आगामी रिमाइंडर नहीं',
      'next_reminder': 'अगला रिमाइंडर',
      'logout': 'लॉगआउट',
      'logout_failed': 'लॉगआउट नहीं हो सका। कृपया फिर से कोशिश करें।',
      'logout_confirm_title': 'लॉगआउट की पुष्टि',
      'logout_confirm_message': 'क्या आप वाकई लॉगआउट करना चाहते हैं?',
      'yes': 'हाँ',
      'settings': 'सेटिंग्स',
      'settings_title': 'ऐप सेटिंग्स',
      'account': 'खाता',
      'logged_in_as': 'इससे लॉग इन',
      'auto_backup_on_save': 'हर सेव पर ऑटो बैकअप',
      'confirm_before_trash': 'नोट को ट्रैश में भेजने से पहले पुष्टि',
      'empty_trash': 'ट्रैश खाली करें',
      'trash_emptied': 'ट्रैश खाली कर दिया गया',
      'empty_trash_confirm_title': 'ट्रैश खाली करें?',
      'empty_trash_confirm_message':
          'क्या आप वाकई ट्रैश के सभी नोट्स हमेशा के लिए हटाना चाहते हैं?',
      'save_changes': 'बदलाव सहेजें',
      'user_email': 'यूज़र ईमेल',
      'change_password': 'पासवर्ड बदलें',
      'app_info': 'ऐप जानकारी',
      'update_password': 'पासवर्ड अपडेट करें',
      'current_password': 'वर्तमान पासवर्ड',
      'new_password': 'नया पासवर्ड',
      'confirm_new_password': 'नया पासवर्ड पुष्टि करें',
      'password_updated': 'पासवर्ड सफलतापूर्वक अपडेट हुआ।',
      'password_mismatch': 'पासवर्ड मेल नहीं खाते।',
      'password_min_6': 'पासवर्ड कम से कम 6 अक्षरों का होना चाहिए।',
      'invalid_current_password': 'वर्तमान पासवर्ड गलत है।',
      'preferences': 'प्राथमिकताएं',
      'security': 'सुरक्षा',
      'about': 'जानकारी',
      'category': 'कैटेगरी',
      'study': 'Study',
      'work': 'Work',
      'personal': 'Personal',
      'ideas': 'Ideas',
      'sort': 'सॉर्ट',
      'sort_newest_first': 'नया पहले',
      'sort_oldest_first': 'पुराना पहले',
      'sort_title': 'शीर्षक',
      'sort_pinned_first': 'पिन पहले',
      'created': 'बनाया गया',
      'updated': 'अपडेट किया गया',
    },
  };

  static String of(String languageCode, String key) {
    return _data[languageCode]?[key] ?? _data['en']![key] ?? key;
  }
}

class ReminderNotificationService {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    try {
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: androidSettings,
          iOS: iosSettings,
        ),
      );

      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _plugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >();
      await androidImplementation?.requestNotificationsPermission();
      await androidImplementation?.requestExactAlarmsPermission();

      final TimezoneInfo localTimeZone =
          await FlutterTimezone.getLocalTimezone();
      tz.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation(localTimeZone.identifier));

      _initialized = true;
    } on MissingPluginException {
      // Plugins are unavailable in widget tests.
    } catch (_) {
      // Ignore plugin setup failures to keep note editing available.
    }
  }

  Future<void> syncForNotes(List<Note> notes) async {
    if (!_initialized) {
      return;
    }

    try {
      await _plugin.cancelAll();

      final DateTime now = DateTime.now();
      for (final Note note in notes) {
        if (note.trashed || note.reminderAt == null) {
          continue;
        }
        if (!note.reminderAt!.isAfter(now)) {
          continue;
        }

        final String localeCode =
            PlatformDispatcher.instance.locale.languageCode;
        final String title = note.title.trim().isEmpty
            ? AppStrings.of(localeCode, 'untitled_note')
            : note.title.trim();
        final String body = note.content.trim().isEmpty
            ? AppStrings.of(localeCode, 'open_my_notes_review')
            : note.content.trim();

        await _plugin.zonedSchedule(
          id: _notificationIdFromNoteId(note.id),
          title: '${AppStrings.of(localeCode, 'reminder_prefix')}: $title',
          body: body,
          scheduledDate: tz.TZDateTime.from(note.reminderAt!, tz.local),
          notificationDetails: const NotificationDetails(
            android: AndroidNotificationDetails(
              'note_reminders',
              'Note Reminders',
              channelDescription: 'Reminder notifications for notes',
              importance: Importance.max,
              priority: Priority.high,
            ),
            iOS: DarwinNotificationDetails(),
          ),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          payload: note.id,
        );
      }
    } on MissingPluginException {
      // Plugins are unavailable in widget tests.
    } catch (_) {
      // Keep app functional even when scheduling fails.
    }
  }

  int _notificationIdFromNoteId(String noteId) {
    return noteId.hashCode & 0x7fffffff;
  }
}

class NotesHomeWidgetService {
  static const List<String> _androidWidgetProviderNames = <String>[
    'MyNotesSmallWidgetProvider',
    'MyNotesWidgetProvider',
    'MyNotesLargeWidgetProvider',
  ];

  Future<void> syncForNotes(List<Note> notes) async {
    try {
      final List<Note> activeNotes =
          notes.where((Note note) => !note.archived && !note.trashed).toList()
            ..sort((Note a, Note b) {
              if (a.pinned != b.pinned) {
                return a.pinned ? -1 : 1;
              }
              return b.updatedAt.compareTo(a.updatedAt);
            });

      final Note? topNote = activeNotes.isEmpty ? null : activeNotes.first;
      final String localeCode = PlatformDispatcher.instance.locale.languageCode;
      final String title = topNote == null
          ? AppFirebaseService.appTitle
          : (topNote.title.trim().isEmpty
                ? AppStrings.of(localeCode, 'untitled_note')
                : topNote.title.trim());
      final String message = topNote == null
          ? AppStrings.of(localeCode, 'no_notes_tap_open')
          : (topNote.content.trim().isEmpty
                ? AppStrings.of(localeCode, 'tap_open_my_notes')
                : topNote.content.trim());
      final int noteCount = activeNotes.length;
      final String countText =
          '$noteCount ${noteCount == 1 ? AppStrings.of(localeCode, 'note_single') : AppStrings.of(localeCode, 'note_plural')}';
      final DateTime? nextReminder = activeNotes
          .where(
            (Note note) =>
                note.reminderAt != null &&
                note.reminderAt!.isAfter(DateTime.now()),
          )
          .map((Note note) => note.reminderAt!)
          .fold<DateTime?>(null, (DateTime? current, DateTime next) {
            if (current == null || next.isBefore(current)) {
              return next;
            }
            return current;
          });
      final String reminderText = nextReminder == null
          ? AppStrings.of(localeCode, 'no_upcoming_reminders')
          : '${AppStrings.of(localeCode, 'next_reminder')}: ${nextReminder.day}/${nextReminder.month} ${nextReminder.hour.toString().padLeft(2, '0')}:${nextReminder.minute.toString().padLeft(2, '0')}';

      await HomeWidget.saveWidgetData<String>('my_notes_widget_title', title);
      await HomeWidget.saveWidgetData<String>(
        'my_notes_widget_message',
        message,
      );
      await HomeWidget.saveWidgetData<String>(
        'my_notes_widget_count',
        countText,
      );
      await HomeWidget.saveWidgetData<String>(
        'my_notes_widget_reminder',
        reminderText,
      );
      for (final String providerName in _androidWidgetProviderNames) {
        await HomeWidget.updateWidget(androidName: providerName);
      }
    } on MissingPluginException {
      // Plugin is unavailable in widget tests.
    } catch (_) {
      // Ignore widget sync failures so note operations continue to work.
    }
  }
}

class NotesHomePage extends StatefulWidget {
  const NotesHomePage({
    super.key,
    required this.selectedThemeMode,
    required this.onThemeModeChanged,
    required this.selectedPalette,
    required this.onPaletteChanged,
    required this.onSetPinRequested,
    required this.onRemovePinRequested,
    required this.onLockNowRequested,
    required this.hasPin,
    required this.selectedLocale,
    required this.onLocaleChanged,
  });

  final ThemeMode selectedThemeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;
  final AppPalette selectedPalette;
  final ValueChanged<AppPalette> onPaletteChanged;
  final Future<void> Function(BuildContext context) onSetPinRequested;
  final Future<void> Function() onRemovePinRequested;
  final Future<void> Function() onLockNowRequested;
  final bool hasPin;
  final Locale selectedLocale;
  final ValueChanged<Locale> onLocaleChanged;

  @override
  State<NotesHomePage> createState() => _NotesHomePageState();
}

class _NotesHomePageState extends State<NotesHomePage> {
  static const String _storageKeyPrefix = 'keep_notes_v1';
  static const String _legacyStorageKey = 'keep_notes_v1';
  static const String _legacyStorageOwnerKey = 'keep_notes_v1_owner_uid';
  static const String _autoBackupSettingSuffix = 'auto_backup_on_save';
  static const String _confirmTrashSettingSuffix = 'confirm_before_trash';
  static const String _allLabelValue = '__all__';

  final List<Note> _notes = <Note>[];
  final ReminderNotificationService _notificationService =
      ReminderNotificationService();
  final NotesHomeWidgetService _homeWidgetService = NotesHomeWidgetService();
  final AudioPlayer _cardAudioPlayer = AudioPlayer();
  StreamSubscription<Uri?>? _widgetClickSubscription;
  StreamSubscription<PlayerState>? _cardPlayerStateSubscription;

  bool _loading = true;
  bool _gridView = true;
  String _query = '';
  String _activeLabel = _allLabelValue;
  NoteScope _scope = NoteScope.notes;
  QuickFilter _quickFilter = QuickFilter.all;
  NoteSortMode _sortMode = NoteSortMode.pinnedFirst;
  Note? _recentlyTrashed;
  bool _isCardAudioPlaying = false;
  String? _playingCardAudioPath;
  bool _autoBackupOnSave = false;
  bool _confirmBeforeTrash = true;

  String _s(String key) =>
      AppStrings.of(widget.selectedLocale.languageCode, key);

  String get _userScopedStorageKey {
    final String? uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty) {
      return _storageKeyPrefix;
    }
    return '${_storageKeyPrefix}_$uid';
  }

  String get _userScopedBackupFileName {
    final String? uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty) {
      return 'my_notes_backup.json';
    }
    return 'my_notes_backup_$uid.json';
  }

  String _userScopedSettingKey(String suffix) {
    final String? uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty) {
      return '${_storageKeyPrefix}_$suffix';
    }
    return '${_storageKeyPrefix}_${uid}_$suffix';
  }

  CollectionReference<Map<String, dynamic>> get _notesCollection {
    final String? uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty) {
      throw StateError('No authenticated user found.');
    }
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('notes');
  }

  Future<List<Note>> _loadLegacyNotesFromPrefs() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String? raw = prefs.getString(_userScopedStorageKey);

    if (raw == null) {
      final String? legacyRaw = prefs.getString(_legacyStorageKey);
      final String? ownerUid = prefs.getString(_legacyStorageOwnerKey);
      final String? currentUid = FirebaseAuth.instance.currentUser?.uid;

      final bool canMigrateLegacy =
          legacyRaw != null &&
          currentUid != null &&
          currentUid.isNotEmpty &&
          (ownerUid == null || ownerUid == currentUid);

      if (canMigrateLegacy) {
        raw = legacyRaw;
        await prefs.setString(_userScopedStorageKey, legacyRaw);
        await prefs.setString(_legacyStorageOwnerKey, currentUid);
        await prefs.remove(_legacyStorageKey);
      }
    }

    if (raw == null || raw.isEmpty) {
      return <Note>[];
    }

    final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((dynamic item) => Note.fromMap(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> _writeLocalCache() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String encoded = jsonEncode(
      _notes.map((Note note) => note.toMap()).toList(),
    );
    await prefs.setString(_userScopedStorageKey, encoded);
    final String? currentUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUid != null && currentUid.isNotEmpty) {
      await prefs.setString(_legacyStorageOwnerKey, currentUid);
    }
  }

  Future<void> _syncNotesToFirestore({bool deleteMissing = true}) async {
    final String? uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty) {
      return;
    }

    final QuerySnapshot<Map<String, dynamic>> snapshot = await _notesCollection
        .get();
    final Set<String> localIds = _notes.map((Note note) => note.id).toSet();

    WriteBatch batch = FirebaseFirestore.instance.batch();
    int operationCount = 0;

    Future<void> commitBatch() async {
      if (operationCount == 0) {
        return;
      }
      await batch.commit();
      batch = FirebaseFirestore.instance.batch();
      operationCount = 0;
    }

    for (final Note note in _notes) {
      batch.set(
        _notesCollection.doc(note.id),
        note.toMap(),
        SetOptions(merge: true),
      );
      operationCount += 1;
      if (operationCount >= 400) {
        await commitBatch();
      }
    }

    if (deleteMissing) {
      for (final QueryDocumentSnapshot<Map<String, dynamic>> doc
          in snapshot.docs) {
        if (localIds.contains(doc.id)) {
          continue;
        }
        batch.delete(doc.reference);
        operationCount += 1;
        if (operationCount >= 400) {
          await commitBatch();
        }
      }
    }

    await commitBatch();
  }

  @override
  void initState() {
    super.initState();
    _cardPlayerStateSubscription = _cardAudioPlayer.onPlayerStateChanged.listen(
      (PlayerState state) {
        if (!mounted) {
          return;
        }
        setState(() {
          _isCardAudioPlaying = state == PlayerState.playing;
        });
      },
    );
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    await _notificationService.initialize();
    await _initializeWidgetLaunchHandling();
    await _loadUserSettings();
    await _loadNotes();
  }

  Future<void> _loadUserSettings() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final bool autoBackup =
        prefs.getBool(_userScopedSettingKey(_autoBackupSettingSuffix)) ?? false;
    final bool confirmTrash =
        prefs.getBool(_userScopedSettingKey(_confirmTrashSettingSuffix)) ??
        true;
    if (!mounted) {
      return;
    }
    setState(() {
      _autoBackupOnSave = autoBackup;
      _confirmBeforeTrash = confirmTrash;
    });
  }

  Future<void> _saveUserSettings() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(
      _userScopedSettingKey(_autoBackupSettingSuffix),
      _autoBackupOnSave,
    );
    await prefs.setBool(
      _userScopedSettingKey(_confirmTrashSettingSuffix),
      _confirmBeforeTrash,
    );
  }

  Future<void> _initializeWidgetLaunchHandling() async {
    try {
      final Uri? initialLaunchUri =
          await HomeWidget.initiallyLaunchedFromHomeWidget();
      if (initialLaunchUri != null) {
        _handleHomeWidgetUri(initialLaunchUri);
      }

      _widgetClickSubscription = HomeWidget.widgetClicked.listen((Uri? uri) {
        if (uri != null) {
          _handleHomeWidgetUri(uri);
        }
      });
    } on MissingPluginException {
      // Plugin is unavailable in widget tests.
    } catch (_) {
      // Ignore widget click listener failures.
    }
  }

  void _handleHomeWidgetUri(Uri uri) {
    if (uri.scheme == 'mynotes' && uri.host == 'new-note') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _openNoteEditor();
        }
      });
    }
  }

  @override
  void dispose() {
    _widgetClickSubscription?.cancel();
    _cardPlayerStateSubscription?.cancel();
    _cardAudioPlayer.dispose();
    super.dispose();
  }

  Future<void> _toggleCardAudio(String path) async {
    try {
      if (_playingCardAudioPath == path && _isCardAudioPlaying) {
        await _cardAudioPlayer.pause();
        return;
      }
      _playingCardAudioPath = path;
      await _cardAudioPlayer.play(DeviceFileSource(path));
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_s('audio_play_error'))));
    }
  }

  Future<void> _loadNotes() async {
    try {
      final String? uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null || uid.isEmpty) {
        if (!mounted) {
          return;
        }
        setState(() {
          _notes.clear();
          _loading = false;
        });
        return;
      }

      final QuerySnapshot<Map<String, dynamic>> snapshot =
          await _notesCollection.get();

      if (snapshot.docs.isNotEmpty) {
        _notes
          ..clear()
          ..addAll(
            snapshot.docs.map((
              QueryDocumentSnapshot<Map<String, dynamic>> doc,
            ) {
              final Map<String, dynamic> data = doc.data();
              data['id'] = doc.id;
              return Note.fromMap(data);
            }),
          );
      } else {
        final List<Note> legacyNotes = await _loadLegacyNotesFromPrefs();
        _notes
          ..clear()
          ..addAll(legacyNotes);
        if (legacyNotes.isNotEmpty) {
          await _syncNotesToFirestore(deleteMissing: false);
        }
      }
    } catch (_) {
      final List<Note> cachedNotes = await _loadLegacyNotesFromPrefs();
      _notes
        ..clear()
        ..addAll(cachedNotes);
    }

    _normalizeSortOrder();
    final int countBeforeCleanup = _notes.length;
    _cleanupOldTrash();
    await _writeLocalCache();
    if (countBeforeCleanup != _notes.length) {
      try {
        await _syncNotesToFirestore();
      } catch (_) {
        // Keep local state even if remote cleanup fails.
      }
    }
    await _notificationService.syncForNotes(_notes);
    await _homeWidgetService.syncForNotes(_notes);
    if (!mounted) {
      return;
    }
    setState(() {
      _loading = false;
    });
  }

  Future<void> _saveNotes() async {
    await _writeLocalCache();
    await _syncNotesToFirestore();
    await _notificationService.syncForNotes(_notes);
    await _homeWidgetService.syncForNotes(_notes);
    if (_autoBackupOnSave) {
      await _exportBackup(showFeedback: false);
    }
  }

  void _cleanupOldTrash() {
    final DateTime threshold = DateTime.now().subtract(
      const Duration(days: 30),
    );
    _notes.removeWhere((Note note) {
      if (!note.trashed) {
        return false;
      }
      if (note.trashedAt == null) {
        return false;
      }
      return note.trashedAt!.isBefore(threshold);
    });
  }

  Future<void> _exportBackup({bool showFeedback = true}) async {
    final Directory directory = await getApplicationDocumentsDirectory();
    final File backup = File('${directory.path}\\$_userScopedBackupFileName');
    final String encoded = jsonEncode(
      _notes.map((Note note) => note.toMap()).toList(),
    );
    await backup.writeAsString(encoded);
    unawaited(
      AppFirebaseService.logEvent(
        'backup_exported',
        parameters: <String, Object?>{'note_count': _notes.length},
      ),
    );
    if (!mounted || !showFeedback) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${_s('backup_saved')} ${backup.path}')),
    );
  }

  Future<void> _exportNoteAsPdf(Note note) async {
    try {
      if (note.isLocked) {
        final bool unlocked = await _unlockNoteIfNeeded(note);
        if (!unlocked) {
          return;
        }
      }

      final Directory directory = await getApplicationDocumentsDirectory();
      final String baseName =
          (note.title.trim().isEmpty ? 'note_${note.id}' : note.title.trim())
              .replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')
              .replaceAll(RegExp(r'\s+'), '_');
      final String fileName =
          '${baseName}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final File output = File('${directory.path}\\$fileName');

      final pw.Document document = pw.Document();
      final String reminderText = note.reminderAt == null
          ? '-'
          : _friendlyDateTime(note.reminderAt!);
      final String categoryText =
          note.category == null || note.category!.isEmpty
          ? '-'
          : _s(note.category!);
      final String labelsText = note.labels.isEmpty
          ? '-'
          : note.labels.join(', ');
      final String checklistText = note.checklist.isEmpty
          ? '-'
          : note.checklist
                .map(
                  (ChecklistItem item) =>
                      '${item.done ? '[x]' : '[ ]'} ${item.text}',
                )
                .join('\n');

      document.addPage(
        pw.MultiPage(
          build: (pw.Context context) => <pw.Widget>[
            pw.Text(
              note.title.trim().isEmpty ? _s('untitled_note') : note.title,
              style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 12),
            pw.Text('${_s('created')}: ${_dateWithMonthName(note.createdAt)}'),
            pw.Text('${_s('updated')}: ${_dateWithMonthName(note.updatedAt)}'),
            pw.Text('${_s('category')}: $categoryText'),
            pw.Text('${_s('labels')}: $labelsText'),
            pw.Text('${_s('reminder')}: $reminderText'),
            pw.SizedBox(height: 14),
            pw.Text(
              _s('start_typing'),
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 6),
            pw.Text(note.content.isEmpty ? '-' : note.content),
            pw.SizedBox(height: 14),
            pw.Text(
              _s('checklist'),
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 6),
            pw.Text(checklistText),
          ],
        ),
      );

      await output.writeAsBytes(await document.save(), flush: true);
      unawaited(
        AppFirebaseService.logEvent(
          'note_exported_pdf',
          parameters: <String, Object?>{
            'has_title': note.title.trim().isNotEmpty,
          },
        ),
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${_s('pdf_saved_to')} ${output.path}')),
      );

      try {
        final XFile file = XFile(output.path, mimeType: 'application/pdf');
        final String subject = note.title.trim().isEmpty
            ? _s('untitled_note')
            : note.title.trim();
        await SharePlus.instance.share(
          ShareParams(files: <XFile>[file], subject: subject, text: subject),
        );
      } catch (_) {
        if (!mounted) {
          return;
        }
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_s('pdf_share_failed'))));
      }
    } catch (error, stack) {
      await AppFirebaseService.recordNonFatal(
        error,
        stack,
        reason: 'PDF export failed',
      );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_s('pdf_export_failed'))));
    }
  }

  Future<void> _restoreBackup() async {
    final Directory directory = await getApplicationDocumentsDirectory();
    final File backup = File('${directory.path}\\$_userScopedBackupFileName');
    if (!backup.existsSync()) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_s('backup_missing'))));
      return;
    }

    final String raw = await backup.readAsString();
    final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
    setState(() {
      _notes
        ..clear()
        ..addAll(
          decoded.map(
            (dynamic item) => Note.fromMap(item as Map<String, dynamic>),
          ),
        );
      _normalizeSortOrder();
      _cleanupOldTrash();
    });
    await _saveNotes();
    unawaited(
      AppFirebaseService.logEvent(
        'backup_restored',
        parameters: <String, Object?>{'note_count': _notes.length},
      ),
    );
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(_s('backup_restored'))));
  }

  Future<void> _logout() async {
    final bool? shouldLogout = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(_s('logout_confirm_title')),
          content: Text(_s('logout_confirm_message')),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(_s('cancel')),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(_s('yes')),
            ),
          ],
        );
      },
    );

    if (shouldLogout != true) {
      return;
    }

    try {
      await AppFirebaseService.logEvent('logout');
      await FirebaseAuth.instance.signOut();
      await AppFirebaseService.clearAnalyticsUser();
    } catch (error, stack) {
      await AppFirebaseService.recordNonFatal(
        error,
        stack,
        reason: 'Logout failed',
      );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_s('logout_failed'))));
    }
  }

  Future<void> _openSettings() async {
    bool autoBackup = _autoBackupOnSave;
    bool confirmTrash = _confirmBeforeTrash;
    ThemeMode themeMode = widget.selectedThemeMode;
    AppPalette palette = widget.selectedPalette;
    Locale selectedLocale = widget.selectedLocale;
    final String email = FirebaseAuth.instance.currentUser?.email ?? 'Unknown';

    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (BuildContext pageContext) {
          return StatefulBuilder(
            builder: (BuildContext context, StateSetter setPageState) {
              final ColorScheme pageScheme = Theme.of(context).colorScheme;
              final bool pageIsDark =
                  Theme.of(context).brightness == Brightness.dark;

              Widget sectionHeader(String title) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(4, 14, 4, 8),
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.primary,
                      letterSpacing: 0.4,
                    ),
                  ),
                );
              }

              Widget settingsCard({required Widget child}) {
                return Container(
                  decoration: BoxDecoration(
                    color: pageScheme.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: pageScheme.outlineVariant),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: pageIsDark
                            ? const Color(0x22000000)
                            : const Color(0x12000000),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: child,
                );
              }

              return Scaffold(
                appBar: AppBar(
                  title: Text(_s('settings_title')),
                  actions: <Widget>[
                    FilledButton.tonal(
                      onPressed: () async {
                        setState(() {
                          _autoBackupOnSave = autoBackup;
                          _confirmBeforeTrash = confirmTrash;
                        });
                        widget.onThemeModeChanged(themeMode);
                        widget.onPaletteChanged(palette);
                        widget.onLocaleChanged(selectedLocale);
                        await _saveUserSettings();
                        if (!context.mounted) {
                          return;
                        }
                        Navigator.of(context).pop();
                      },
                      style: FilledButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(_s('save_changes')),
                    ),
                    const SizedBox(width: 10),
                  ],
                ),
                body: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: <Color>[
                        pageIsDark
                            ? const Color(0xFF171B22)
                            : const Color(0xFFEFF3FB),
                        Theme.of(context).scaffoldBackgroundColor,
                      ],
                    ),
                  ),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    children: <Widget>[
                    sectionHeader(_s('account')),
                    settingsCard(
                      child: ListTile(
                        leading: const Icon(Icons.alternate_email_rounded),
                        title: Text(_s('user_email')),
                        subtitle: Text(email),
                      ),
                    ),
                    sectionHeader(_s('preferences')),
                    settingsCard(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                        child: Column(
                          children: <Widget>[
                            DropdownButtonFormField<ThemeMode>(
                              initialValue: themeMode,
                              decoration: InputDecoration(
                                labelText: _s('theme'),
                              ),
                              items: <DropdownMenuItem<ThemeMode>>[
                                DropdownMenuItem<ThemeMode>(
                                  value: ThemeMode.system,
                                  child: Text(_s('theme_system')),
                                ),
                                DropdownMenuItem<ThemeMode>(
                                  value: ThemeMode.light,
                                  child: Text(_s('theme_light')),
                                ),
                                DropdownMenuItem<ThemeMode>(
                                  value: ThemeMode.dark,
                                  child: Text(_s('theme_dark')),
                                ),
                              ],
                              onChanged: (ThemeMode? value) {
                                if (value == null) {
                                  return;
                                }
                                setPageState(() {
                                  themeMode = value;
                                });
                              },
                            ),
                            const SizedBox(height: 10),
                            DropdownButtonFormField<Locale>(
                              initialValue: selectedLocale,
                              decoration: InputDecoration(
                                labelText: _s('language'),
                              ),
                              items: <DropdownMenuItem<Locale>>[
                                DropdownMenuItem<Locale>(
                                  value: const Locale('en'),
                                  child: Text(_s('lang_en')),
                                ),
                                DropdownMenuItem<Locale>(
                                  value: const Locale('bn'),
                                  child: Text(_s('lang_bn')),
                                ),
                              ],
                              onChanged: (Locale? value) {
                                if (value == null) {
                                  return;
                                }
                                setPageState(() {
                                  selectedLocale = value;
                                });
                              },
                            ),
                            const SizedBox(height: 10),
                            DropdownButtonFormField<AppPalette>(
                              initialValue: palette,
                              decoration: InputDecoration(
                                labelText: _s('theme_palette'),
                              ),
                              items: <DropdownMenuItem<AppPalette>>[
                                DropdownMenuItem<AppPalette>(
                                  value: AppPalette.emerald,
                                  child: Text(_s('palette_emerald')),
                                ),
                                DropdownMenuItem<AppPalette>(
                                  value: AppPalette.ocean,
                                  child: Text(_s('palette_ocean')),
                                ),
                                DropdownMenuItem<AppPalette>(
                                  value: AppPalette.sunset,
                                  child: Text(_s('palette_sunset')),
                                ),
                                DropdownMenuItem<AppPalette>(
                                  value: AppPalette.rose,
                                  child: Text(_s('palette_rose')),
                                ),
                                DropdownMenuItem<AppPalette>(
                                  value: AppPalette.amber,
                                  child: Text(_s('palette_amber')),
                                ),
                                DropdownMenuItem<AppPalette>(
                                  value: AppPalette.violet,
                                  child: Text(_s('palette_violet')),
                                ),
                                DropdownMenuItem<AppPalette>(
                                  value: AppPalette.teal,
                                  child: Text(_s('palette_teal')),
                                ),
                                DropdownMenuItem<AppPalette>(
                                  value: AppPalette.slate,
                                  child: Text(_s('palette_slate')),
                                ),
                                DropdownMenuItem<AppPalette>(
                                  value: AppPalette.coral,
                                  child: Text(_s('palette_coral')),
                                ),
                                DropdownMenuItem<AppPalette>(
                                  value: AppPalette.indigo,
                                  child: Text(_s('palette_indigo')),
                                ),
                              ],
                              onChanged: (AppPalette? value) {
                                if (value == null) {
                                  return;
                                }
                                setPageState(() {
                                  palette = value;
                                });
                              },
                            ),
                            SwitchListTile.adaptive(
                              contentPadding: EdgeInsets.zero,
                              value: autoBackup,
                              onChanged: (bool value) {
                                setPageState(() {
                                  autoBackup = value;
                                });
                              },
                              title: Text(_s('auto_backup_on_save')),
                            ),
                            SwitchListTile.adaptive(
                              contentPadding: EdgeInsets.zero,
                              value: confirmTrash,
                              onChanged: (bool value) {
                                setPageState(() {
                                  confirmTrash = value;
                                });
                              },
                              title: Text(_s('confirm_before_trash')),
                            ),
                          ],
                        ),
                      ),
                    ),
                    sectionHeader(_s('security')),
                    settingsCard(
                      child: Column(
                        children: <Widget>[
                          ListTile(
                            leading: const Icon(Icons.lock_reset_rounded),
                            title: Text(_s('change_password')),
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (BuildContext context) =>
                                      ChangePasswordPage(
                                        localeCode:
                                            widget.selectedLocale.languageCode,
                                      ),
                                ),
                              );
                            },
                          ),
                          ListTile(
                            leading: const Icon(Icons.delete_sweep_outlined),
                            title: Text(_s('empty_trash')),
                            onTap: () async {
                              Navigator.of(context).pop();
                              await _emptyTrash();
                            },
                          ),
                          ListTile(
                            leading: const Icon(Icons.logout_rounded),
                            title: Text(_s('logout')),
                            onTap: () async {
                              Navigator.of(context).pop();
                              await _logout();
                            },
                          ),
                        ],
                      ),
                    ),
                    sectionHeader(_s('about')),
                    settingsCard(
                      child: ListTile(
                        leading: const Icon(Icons.info_outline_rounded),
                        title: Text(_s('app_info')),
                        onTap: () {
                          showAboutDialog(
                            context: context,
                            applicationName: AppFirebaseService.appTitle,
                            applicationVersion: '1.0.0',
                            applicationLegalese:
                                'Keep your notes organized.\nDeveloped By Mehedi Hasan',
                          );
                        },
                      ),
                    ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showStatistics() {
    final int total = _notes.length;
    final int active = _notes
        .where((Note note) => !note.archived && !note.trashed)
        .length;
    final int archived = _notes
        .where((Note note) => note.archived && !note.trashed)
        .length;
    final int trash = _notes.where((Note note) => note.trashed).length;
    final int reminders = _notes
        .where((Note note) => note.reminderAt != null && !note.trashed)
        .length;
    final int pinned = _notes
        .where((Note note) => note.pinned && !note.trashed)
        .length;

    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(_s('stats_title')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('${_s('stats_total')}: $total'),
              Text('${_s('stats_active')}: $active'),
              Text('${_s('stats_archived')}: $archived'),
              Text('${_s('stats_trash')}: $trash'),
              Text('${_s('stats_pinned')}: $pinned'),
              Text('${_s('stats_reminders')}: $reminders'),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(_s('close')),
            ),
          ],
        );
      },
    );
  }

  void _normalizeSortOrder() {
    int index = 0;
    for (final Note note in _notes) {
      if (note.sortOrder < 0) {
        final int currentIndex = _notes.indexOf(note);
        _notes[currentIndex] = note.copyWith(sortOrder: index);
      }
      index += 1;
    }
  }

  void _openNoteEditor({Note? note, bool startVoiceRecording = false}) async {
    if (note != null && note.isLocked) {
      final bool unlocked = await _unlockNoteIfNeeded(note);
      if (!unlocked) {
        return;
      }
    }

    final NoteEditorResult? result = await Navigator.of(context)
        .push<NoteEditorResult>(
          MaterialPageRoute(
            builder: (BuildContext context) => NoteEditorPage(
              note: note,
              localeCode: widget.selectedLocale.languageCode,
              startVoiceRecording: startVoiceRecording,
            ),
          ),
        );

    if (result == null) {
      return;
    }

    if (result.action == NoteEditorAction.moveToTrash && result.note != null) {
      await _moveToTrash(result.note!);
      return;
    }

    if (result.action == NoteEditorAction.save && result.note != null) {
      _upsertNote(result.note!);
    }
  }

  void _upsertNote(Note note) {
    final int index = _notes.indexWhere((Note item) => item.id == note.id);
    final bool isNew = index == -1;
    setState(() {
      if (isNew) {
        _notes.add(note.copyWith(sortOrder: _nextSortOrderFor(note.pinned)));
      } else {
        _notes[index] = note;
      }
    });
    unawaited(
      AppFirebaseService.logEvent(
        isNew ? 'note_created' : 'note_updated',
        parameters: <String, Object?>{
          'has_reminder': note.reminderAt != null,
          'label_count': note.labels.length,
          'has_checklist': note.checklist.isNotEmpty,
        },
      ),
    );
    _saveNotes();
  }

  int _nextSortOrderFor(bool pinned) {
    int maxOrder = -1;
    for (final Note note in _notes) {
      if (note.pinned == pinned && !note.archived && !note.trashed) {
        maxOrder = note.sortOrder > maxOrder ? note.sortOrder : maxOrder;
      }
    }
    return maxOrder + 1;
  }

  void _deleteForever(String id) {
    setState(() {
      _notes.removeWhere((Note note) => note.id == id);
    });
    unawaited(AppFirebaseService.logEvent('note_deleted_forever'));
    _saveNotes();
  }

  Future<void> _emptyTrash() async {
    final bool? shouldEmpty = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(_s('empty_trash_confirm_title')),
          content: Text(_s('empty_trash_confirm_message')),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(_s('cancel')),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(_s('empty_trash')),
            ),
          ],
        );
      },
    );

    if (shouldEmpty != true) {
      return;
    }

    final int deletedCount = _notes.where((Note note) => note.trashed).length;
    setState(() {
      _notes.removeWhere((Note note) => note.trashed);
    });
    unawaited(
      AppFirebaseService.logEvent(
        'trash_emptied',
        parameters: <String, Object?>{'deleted_count': deletedCount},
      ),
    );
    _saveNotes();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(_s('trash_emptied'))));
  }

  void _togglePin(Note note) {
    final bool willBePinned = !note.pinned;
    _upsertNote(
      note.copyWith(
        pinned: willBePinned,
        archived: false,
        trashed: false,
        sortOrder: _nextSortOrderFor(willBePinned),
        updatedAt: DateTime.now(),
      ),
    );
  }

  void _toggleFavorite(Note note) {
    final bool willBeFavorite = !note.favorite;
    unawaited(
      AppFirebaseService.logEvent(
        willBeFavorite ? 'note_favorited' : 'note_unfavorited',
      ),
    );
    _upsertNote(
      note.copyWith(favorite: willBeFavorite, updatedAt: DateTime.now()),
    );
  }

  Future<bool> _unlockNoteIfNeeded(Note note) async {
    if (!note.isLocked || note.lockSecret == null || note.lockSecret!.isEmpty) {
      return true;
    }

    final TextEditingController controller = TextEditingController();
    final bool? unlocked = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(_s('note_lock')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(_s('note_locked')),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                obscureText: true,
                keyboardType: note.lockType == 'pin'
                    ? TextInputType.number
                    : TextInputType.visiblePassword,
                decoration: InputDecoration(
                  labelText: _s('lock_secret'),
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(_s('cancel')),
            ),
            FilledButton(
              onPressed: () {
                final bool ok = controller.text == note.lockSecret;
                Navigator.of(dialogContext).pop(ok);
              },
              child: Text(_s('unlock')),
            ),
          ],
        );
      },
    );
    controller.dispose();

    if (unlocked == true) {
      return true;
    }

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_s('unlock_failed'))));
    }
    return false;
  }

  void _duplicateNote(Note note) {
    final DateTime now = DateTime.now();
    unawaited(AppFirebaseService.logEvent('note_duplicated'));
    _upsertNote(
      note.copyWith(
        id: now.microsecondsSinceEpoch.toString(),
        createdAt: now,
        updatedAt: now,
        archived: false,
        trashed: false,
        pinned: false,
        sortOrder: _nextSortOrderFor(false),
      ),
    );
  }

  void _archiveNote(Note note) {
    unawaited(AppFirebaseService.logEvent('note_archived'));
    _upsertNote(
      note.copyWith(
        archived: true,
        trashed: false,
        clearTrashedAt: true,
        pinned: false,
        updatedAt: DateTime.now(),
      ),
    );
  }

  void _unarchiveNote(Note note) {
    unawaited(AppFirebaseService.logEvent('note_unarchived'));
    _upsertNote(
      note.copyWith(
        archived: false,
        trashed: false,
        clearTrashedAt: true,
        sortOrder: _nextSortOrderFor(false),
        updatedAt: DateTime.now(),
      ),
    );
  }

  Future<void> _moveToTrash(Note note) async {
    final bool? shouldTrash = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(_s('move_to_trash')),
          content: Text(_s('delete_note')),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(_s('cancel')),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(_s('move_to_trash')),
            ),
          ],
        );
      },
    );

    if (shouldTrash != true) {
      return;
    }

    _recentlyTrashed = note;
    unawaited(AppFirebaseService.logEvent('note_trashed'));
    _upsertNote(
      note.copyWith(
        trashed: true,
        archived: false,
        pinned: false,
        trashedAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_s('moved_to_trash')),
        action: SnackBarAction(
          label: _s('undo'),
          onPressed: () {
            if (_recentlyTrashed != null) {
              _upsertNote(
                _recentlyTrashed!.copyWith(
                  trashed: false,
                  clearTrashedAt: true,
                ),
              );
            }
          },
        ),
      ),
    );
  }

  void _restoreFromTrash(Note note) {
    unawaited(AppFirebaseService.logEvent('note_restored'));
    _upsertNote(
      note.copyWith(
        trashed: false,
        archived: false,
        pinned: false,
        sortOrder: _nextSortOrderFor(false),
        clearTrashedAt: true,
        updatedAt: DateTime.now(),
      ),
    );
  }

  List<String> get _allLabels {
    final Set<String> labels = <String>{};
    for (final Note note in _notes.where((Note item) => !item.trashed)) {
      labels.addAll(note.labels);
      if (note.category != null && note.category!.isNotEmpty) {
        labels.add(note.category!);
      }
    }
    final List<String> sorted = labels.toList()..sort();
    return sorted;
  }

  List<Note> get _visibleNotes {
    final String normalizedQuery = _query.trim().toLowerCase();

    final List<Note> filtered = _notes.where((Note note) {
      if (_scope == NoteScope.notes && (note.archived || note.trashed)) {
        return false;
      }
      if (_scope == NoteScope.archived && (!note.archived || note.trashed)) {
        return false;
      }
      if (_scope == NoteScope.trash && !note.trashed) {
        return false;
      }

      if (_scope != NoteScope.trash) {
        final bool labelMatches =
            _activeLabel == _allLabelValue ||
            note.labels.contains(_activeLabel) ||
            note.category == _activeLabel;
        if (!labelMatches) {
          return false;
        }
      }

      if (_scope != NoteScope.trash) {
        switch (_quickFilter) {
          case QuickFilter.all:
            break;
          case QuickFilter.dueToday:
            final DateTime now = DateTime.now();
            final DateTime? reminder = note.reminderAt;
            if (reminder == null ||
                reminder.year != now.year ||
                reminder.month != now.month ||
                reminder.day != now.day) {
              return false;
            }
            break;
          case QuickFilter.noReminder:
            if (note.reminderAt != null) {
              return false;
            }
            break;
          case QuickFilter.pinned:
            if (!note.pinned) {
              return false;
            }
            break;
          case QuickFilter.withLabels:
            if (note.labels.isEmpty) {
              return false;
            }
            break;
        }
      }

      if (normalizedQuery.isEmpty) {
        return true;
      }

      final String haystack = [
        note.title,
        note.content,
        note.category ?? '',
        note.labels.join(' '),
      ].join(' ').toLowerCase();
      return haystack.contains(normalizedQuery);
    }).toList();

    filtered.sort((Note a, Note b) {
      switch (_sortMode) {
        case NoteSortMode.newestFirst:
          return b.updatedAt.compareTo(a.updatedAt);
        case NoteSortMode.oldestFirst:
          return a.updatedAt.compareTo(b.updatedAt);
        case NoteSortMode.title:
          final int byTitle = a.title.trim().toLowerCase().compareTo(
            b.title.trim().toLowerCase(),
          );
          if (byTitle != 0) {
            return byTitle;
          }
          return b.updatedAt.compareTo(a.updatedAt);
        case NoteSortMode.pinnedFirst:
          if (_scope == NoteScope.notes && a.pinned != b.pinned) {
            return a.pinned ? -1 : 1;
          }
          return b.updatedAt.compareTo(a.updatedAt);
      }
    });

    return filtered;
  }

  bool get _canReorder {
    return !_gridView &&
        _scope == NoteScope.notes &&
        _sortMode == NoteSortMode.pinnedFirst &&
        _query.trim().isEmpty &&
        _activeLabel == _allLabelValue;
  }

  void _handleReorder(int oldIndex, int newIndex, List<Note> visibleNotes) {
    if (visibleNotes.isEmpty) {
      return;
    }

    if (newIndex > oldIndex) {
      newIndex -= 1;
    }

    if (oldIndex == newIndex) {
      return;
    }

    final Note moving = visibleNotes[oldIndex];
    final Note destination =
        visibleNotes[newIndex.clamp(0, visibleNotes.length - 1)];

    if (moving.pinned != destination.pinned) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_s('reorder_pinned_only'))));
      return;
    }

    final List<Note> group =
        _notes
            .where(
              (Note note) =>
                  !note.archived &&
                  !note.trashed &&
                  note.pinned == moving.pinned,
            )
            .toList()
          ..sort((Note a, Note b) => a.sortOrder.compareTo(b.sortOrder));

    final int oldGroupIndex = group.indexWhere(
      (Note note) => note.id == moving.id,
    );
    final int newGroupIndex = group.indexWhere(
      (Note note) => note.id == destination.id,
    );

    if (oldGroupIndex == -1 || newGroupIndex == -1) {
      return;
    }

    final Note moved = group.removeAt(oldGroupIndex);
    group.insert(newGroupIndex, moved);

    final Map<String, int> newOrders = <String, int>{
      for (int i = 0; i < group.length; i++) group[i].id: i,
    };

    setState(() {
      for (int i = 0; i < _notes.length; i++) {
        final Note note = _notes[i];
        final int? sortOrder = newOrders[note.id];
        if (sortOrder != null) {
          _notes[i] = note.copyWith(sortOrder: sortOrder);
        }
      }
    });

    _saveNotes();
  }

  String get _scopeTitle {
    switch (_scope) {
      case NoteScope.notes:
        return AppFirebaseService.appTitle;
      case NoteScope.archived:
        return _s('archive');
      case NoteScope.trash:
        return _s('trash');
    }
  }

  Future<void> _handleAppAction(String value) async {
    switch (value) {
      case 'settings':
        await _openSettings();
        break;
      case 'stats':
        _showStatistics();
        break;
      case 'backup':
        await _exportBackup();
        break;
      case 'restore':
        await _restoreBackup();
        break;
      case 'setPin':
        await widget.onSetPinRequested(context);
        break;
      case 'removePin':
        await widget.onRemovePinRequested();
        break;
      case 'lockNow':
        await widget.onLockNowRequested();
        break;
      case 'logout':
        await _logout();
        break;
      case 'themeSystem':
        widget.onThemeModeChanged(ThemeMode.system);
        break;
      case 'themeLight':
        widget.onThemeModeChanged(ThemeMode.light);
        break;
      case 'themeDark':
        widget.onThemeModeChanged(ThemeMode.dark);
        break;
      case 'langEn':
        widget.onLocaleChanged(const Locale('en'));
        break;
      case 'langBn':
        widget.onLocaleChanged(const Locale('bn'));
        break;
    }
  }

  Widget _buildKeepDarkTopBar() {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Container(
        height: 58,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF2B2E35),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          children: <Widget>[
            PopupMenuButton<String>(
              tooltip: _s('app_actions'),
              icon: const Icon(Icons.menu_rounded, color: Color(0xFFE8EAED)),
              onSelected: (String value) {
                unawaited(_handleAppAction(value));
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                PopupMenuItem<String>(
                  value: 'settings',
                  child: Text(_s('settings')),
                ),
                PopupMenuItem<String>(
                  value: 'stats',
                  child: Text(_s('statistics')),
                ),
                PopupMenuItem<String>(
                  value: 'backup',
                  child: Text(_s('create_backup')),
                ),
                PopupMenuItem<String>(
                  value: 'restore',
                  child: Text(_s('restore_backup')),
                ),
                PopupMenuItem<String>(
                  value: 'themeSystem',
                  child: Text(_s('theme_system')),
                ),
                PopupMenuItem<String>(
                  value: 'themeLight',
                  child: Text(_s('theme_light')),
                ),
                PopupMenuItem<String>(
                  value: 'themeDark',
                  child: Text(_s('theme_dark')),
                ),
                PopupMenuItem<String>(value: 'langEn', child: Text(_s('lang_en'))),
                PopupMenuItem<String>(value: 'langBn', child: Text(_s('lang_bn'))),
                PopupMenuItem<String>(
                  value: 'setPin',
                  child: Text(widget.hasPin ? _s('change_pin') : _s('set_pin')),
                ),
                if (widget.hasPin)
                  PopupMenuItem<String>(
                    value: 'removePin',
                    child: Text(_s('remove_pin')),
                  ),
                if (widget.hasPin)
                  PopupMenuItem<String>(
                    value: 'lockNow',
                    child: Text(_s('lock_now')),
                  ),
                PopupMenuItem<String>(
                  value: 'logout',
                  child: Text(_s('logout')),
                ),
              ],
            ),
            Expanded(
              child: TextField(
                style: const TextStyle(color: Color(0xFFE8EAED), fontSize: 17),
                decoration: const InputDecoration(
                  hintText: 'Search Keep',
                  hintStyle: TextStyle(color: Color(0xFFB7BCC6), fontSize: 17),
                  border: InputBorder.none,
                  isCollapsed: true,
                ),
                onChanged: (String value) {
                  setState(() {
                    _query = value;
                  });
                },
              ),
            ),
            IconButton(
              tooltip: _gridView ? _s('switch_to_list') : _s('switch_to_grid'),
              icon: Icon(
                _gridView
                    ? Icons.view_agenda_outlined
                    : Icons.grid_view_rounded,
                color: const Color(0xFFD0D3DA),
              ),
              onPressed: () {
                setState(() {
                  _gridView = !_gridView;
                });
              },
            ),
            PopupMenuButton<NoteSortMode>(
              tooltip: _s('sort'),
              icon: const Icon(Icons.swap_vert_rounded, color: Color(0xFFD0D3DA)),
              initialValue: _sortMode,
              onSelected: (NoteSortMode mode) {
                setState(() {
                  _sortMode = mode;
                });
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<NoteSortMode>>[
                PopupMenuItem<NoteSortMode>(
                  value: NoteSortMode.newestFirst,
                  child: Text(_s('sort_newest_first')),
                ),
                PopupMenuItem<NoteSortMode>(
                  value: NoteSortMode.oldestFirst,
                  child: Text(_s('sort_oldest_first')),
                ),
                PopupMenuItem<NoteSortMode>(
                  value: NoteSortMode.title,
                  child: Text(_s('sort_title')),
                ),
                PopupMenuItem<NoteSortMode>(
                  value: NoteSortMode.pinnedFirst,
                  child: Text(_s('sort_pinned_first')),
                ),
              ],
            ),
            Container(
              width: 38,
              height: 38,
              margin: const EdgeInsets.only(right: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF2F56E2),
                shape: BoxShape.circle,
                border: Border.all(color: colorScheme.outlineVariant),
              ),
              child: const Icon(Icons.person_rounded, color: Colors.white, size: 20),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Note> notes = _visibleNotes;
    final List<String> labels = _allLabels;
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    const bool useKeepDarkChrome = false;

    return Scaffold(
      appBar: useKeepDarkChrome
          ? AppBar(
              toolbarHeight: 0,
              backgroundColor: Colors.transparent,
              elevation: 0,
            )
          : AppBar(
        title: Text(_scopeTitle),
        actions: <Widget>[
          PopupMenuButton<ThemeMode>(
            tooltip: _s('theme'),
            icon: const Icon(Icons.palette_outlined),
            initialValue: widget.selectedThemeMode,
            onSelected: widget.onThemeModeChanged,
            itemBuilder: (BuildContext context) => <PopupMenuEntry<ThemeMode>>[
              PopupMenuItem<ThemeMode>(
                value: ThemeMode.system,
                child: Text(_s('theme_system')),
              ),
              PopupMenuItem<ThemeMode>(
                value: ThemeMode.light,
                child: Text(_s('theme_light')),
              ),
              PopupMenuItem<ThemeMode>(
                value: ThemeMode.dark,
                child: Text(_s('theme_dark')),
              ),
            ],
          ),
          PopupMenuButton<Locale>(
            tooltip: _s('language'),
            icon: const Icon(Icons.translate_rounded),
            initialValue: widget.selectedLocale,
            onSelected: widget.onLocaleChanged,
            itemBuilder: (BuildContext context) => <PopupMenuEntry<Locale>>[
              PopupMenuItem<Locale>(
                value: const Locale('en'),
                child: Text(_s('lang_en')),
              ),
              PopupMenuItem<Locale>(
                value: const Locale('bn'),
                child: Text(_s('lang_bn')),
              ),
            ],
          ),
          IconButton(
            tooltip: _gridView ? _s('switch_to_list') : _s('switch_to_grid'),
            icon: Icon(
              _gridView ? Icons.view_agenda_outlined : Icons.grid_view_rounded,
            ),
            onPressed: () {
              setState(() {
                _gridView = !_gridView;
              });
            },
          ),
          PopupMenuButton<NoteSortMode>(
            tooltip: _s('sort'),
            icon: const Icon(Icons.sort_rounded),
            initialValue: _sortMode,
            onSelected: (NoteSortMode mode) {
              setState(() {
                _sortMode = mode;
              });
            },
            itemBuilder: (BuildContext context) =>
                <PopupMenuEntry<NoteSortMode>>[
                  PopupMenuItem<NoteSortMode>(
                    value: NoteSortMode.newestFirst,
                    child: Text(_s('sort_newest_first')),
                  ),
                  PopupMenuItem<NoteSortMode>(
                    value: NoteSortMode.oldestFirst,
                    child: Text(_s('sort_oldest_first')),
                  ),
                  PopupMenuItem<NoteSortMode>(
                    value: NoteSortMode.title,
                    child: Text(_s('sort_title')),
                  ),
                  PopupMenuItem<NoteSortMode>(
                    value: NoteSortMode.pinnedFirst,
                    child: Text(_s('sort_pinned_first')),
                  ),
                ],
          ),
          PopupMenuButton<String>(
            tooltip: _s('app_actions'),
            onSelected: (String value) async {
              switch (value) {
                case 'settings':
                  await _openSettings();
                  break;
                case 'stats':
                  _showStatistics();
                  break;
                case 'backup':
                  await _exportBackup();
                  break;
                case 'restore':
                  await _restoreBackup();
                  break;
                case 'setPin':
                  await widget.onSetPinRequested(context);
                  break;
                case 'removePin':
                  await widget.onRemovePinRequested();
                  break;
                case 'lockNow':
                  await widget.onLockNowRequested();
                  break;
                case 'logout':
                  await _logout();
                  break;
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              PopupMenuItem<String>(
                value: 'settings',
                child: Text(_s('settings')),
              ),
              PopupMenuItem<String>(
                value: 'stats',
                child: Text(_s('statistics')),
              ),
              PopupMenuItem<String>(
                value: 'backup',
                child: Text(_s('create_backup')),
              ),
              PopupMenuItem<String>(
                value: 'restore',
                child: Text(_s('restore_backup')),
              ),
              PopupMenuItem<String>(
                value: 'setPin',
                child: Text(widget.hasPin ? _s('change_pin') : _s('set_pin')),
              ),
              if (widget.hasPin)
                PopupMenuItem<String>(
                  value: 'removePin',
                  child: Text(_s('remove_pin')),
                ),
              if (widget.hasPin)
                PopupMenuItem<String>(
                  value: 'lockNow',
                  child: Text(_s('lock_now')),
                ),
              PopupMenuItem<String>(value: 'logout', child: Text(_s('logout'))),
            ],
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: switch (_scope) {
          NoteScope.notes => 0,
          NoteScope.archived => 1,
          NoteScope.trash => 2,
        },
        onDestinationSelected: (int index) {
          setState(() {
            _scope = switch (index) {
              0 => NoteScope.notes,
              1 => NoteScope.archived,
              _ => NoteScope.trash,
            };
          });
        },
        destinations: <Widget>[
          NavigationDestination(
            icon: const Icon(Icons.sticky_note_2_outlined),
            selectedIcon: const Icon(Icons.sticky_note_2_rounded),
            label: _s('notes'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.archive_outlined),
            selectedIcon: const Icon(Icons.archive_rounded),
            label: _s('archive'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.delete_outline_rounded),
            selectedIcon: const Icon(Icons.delete_rounded),
            label: _s('trash'),
          ),
        ],
      ),
      floatingActionButton: _scope == NoteScope.notes
          ? Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                if (AppFirebaseService.enableVoiceNoteFab)
                  FloatingActionButton.small(
                    heroTag: 'voice_note_fab',
                    onPressed: () => _openNoteEditor(startVoiceRecording: true),
                    tooltip: _s('record_voice'),
                    child: const Icon(Icons.mic_none_rounded),
                  ),
                if (AppFirebaseService.enableVoiceNoteFab)
                  const SizedBox(height: 10),
                FloatingActionButton.extended(
                  heroTag: 'new_note_fab',
                  onPressed: () => _openNoteEditor(),
                  icon: const Icon(Icons.edit_note_rounded),
                  label: Text(_s('new_note')),
                ),
              ],
            )
          : null,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: <Color>[
                    isDark
                        ? const Color(0xFF171B22)
                        : const Color(0xFFEFF3FB),
                    Theme.of(context).scaffoldBackgroundColor,
                  ],
                ),
              ),
              child: Column(
                children: <Widget>[
                if (useKeepDarkChrome)
                  _buildKeepDarkTopBar()
                else
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: colorScheme.outlineVariant),
                        boxShadow: <BoxShadow>[
                          BoxShadow(
                            color: isDark
                                ? const Color(0x22000000)
                                : const Color(0x14000000),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Row(
                        children: <Widget>[
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: colorScheme.primaryContainer,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.person_outline_rounded,
                              color: colorScheme.primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  FirebaseAuth.instance.currentUser?.email ??
                                      AppFirebaseService.appTitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${notes.where((Note note) => !note.archived && !note.trashed).length} ${_s('note_plural')}',
                                  style: TextStyle(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.secondaryContainer,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              _scopeTitle,
                              style: TextStyle(
                                color: colorScheme.onSecondaryContainer,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (_scope == NoteScope.notes &&
                    AppFirebaseService.homeBannerText.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        AppFirebaseService.homeBannerText,
                        style: TextStyle(
                          color: colorScheme.onSecondaryContainer,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                if (!useKeepDarkChrome)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: _scope == NoteScope.trash
                            ? _s('search_trash')
                            : _s('search_notes'),
                        prefixIcon: const Icon(Icons.search_rounded),
                        filled: true,
                        fillColor: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHighest,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onChanged: (String value) {
                        setState(() {
                          _query = value;
                        });
                      },
                    ),
                  ),
                if (_scope != NoteScope.trash && labels.isNotEmpty)
                  SizedBox(
                    height: 48,
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      scrollDirection: Axis.horizontal,
                      children: <Widget>[
                        _buildLabelChip(_s('all'), value: _allLabelValue),
                        ...labels.map((String label) => _buildLabelChip(label)),
                      ],
                    ),
                  ),
                if (_scope != NoteScope.trash)
                  SizedBox(
                    height: 44,
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      scrollDirection: Axis.horizontal,
                      children: <Widget>[
                        _buildQuickFilterChip(_s('all'), QuickFilter.all),
                        _buildQuickFilterChip(
                          _s('due_today'),
                          QuickFilter.dueToday,
                        ),
                        _buildQuickFilterChip(
                          _s('no_reminder'),
                          QuickFilter.noReminder,
                        ),
                        _buildQuickFilterChip(_s('pinned'), QuickFilter.pinned),
                        _buildQuickFilterChip(
                          _s('with_labels'),
                          QuickFilter.withLabels,
                        ),
                      ],
                    ),
                  ),
                if (_canReorder)
                  Padding(
                    padding: EdgeInsets.fromLTRB(16, 4, 16, 6),
                    child: Text(
                      _s('reorder_hint'),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                  Expanded(
                    child: notes.isEmpty
                        ? _buildEmptyState()
                        : Padding(
                            padding: const EdgeInsets.fromLTRB(12, 6, 12, 20),
                            child: _buildNotesViewport(notes),
                          ),
                  ),
                ],
              ),
            ),
    );
  }

  bool get _showSectionedGridHeadings {
    return _scope == NoteScope.notes && _sortMode == NoteSortMode.pinnedFirst;
  }

  Widget _buildSectionHeading(String text, {required bool first}) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: EdgeInsets.fromLTRB(6, first ? 2 : 18, 6, 10),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 15.5,
          fontWeight: FontWeight.w600,
          color: isDark ? const Color(0xFFE0E3E7) : const Color(0xFF2D3340),
          letterSpacing: 0.1,
        ),
      ),
    );
  }

  Widget _buildNotesViewport(List<Note> notes) {
    if (_gridView && _showSectionedGridHeadings) {
      final List<Note> pinnedNotes =
          notes.where((Note note) => note.pinned).toList();
      final List<Note> otherNotes =
          notes.where((Note note) => !note.pinned).toList();

      return LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final int columnCount = constraints.maxWidth > 700 ? 3 : 2;

          return CustomScrollView(
            slivers: <Widget>[
              if (pinnedNotes.isNotEmpty)
                SliverToBoxAdapter(
                  child: _buildSectionHeading(_s('pinned'), first: true),
                ),
              if (pinnedNotes.isNotEmpty)
                SliverGrid(
                  delegate: SliverChildBuilderDelegate(
                    (BuildContext context, int index) {
                      return _buildNoteCard(pinnedNotes[index]);
                    },
                    childCount: pinnedNotes.length,
                  ),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columnCount,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.68,
                  ),
                ),
              if (otherNotes.isNotEmpty)
                SliverToBoxAdapter(
                  child: _buildSectionHeading(_s('others'), first: false),
                ),
              if (otherNotes.isNotEmpty)
                SliverGrid(
                  delegate: SliverChildBuilderDelegate(
                    (BuildContext context, int index) {
                      return _buildNoteCard(otherNotes[index]);
                    },
                    childCount: otherNotes.length,
                  ),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columnCount,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.68,
                  ),
                ),
            ],
          );
        },
      );
    }

    if (_gridView) {
      return LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final int columnCount = constraints.maxWidth > 700 ? 3 : 2;
          return GridView.builder(
            itemCount: notes.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columnCount,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.68,
            ),
            itemBuilder: (BuildContext context, int index) {
              return _buildNoteCard(notes[index]);
            },
          );
        },
      );
    }

    if (_canReorder) {
      return ReorderableListView.builder(
        buildDefaultDragHandles: false,
        itemCount: notes.length,
        onReorder: (int oldIndex, int newIndex) {
          _handleReorder(oldIndex, newIndex, notes);
        },
        itemBuilder: (BuildContext context, int index) {
          final Note note = notes[index];
          return Padding(
            key: ValueKey<String>(note.id),
            padding: const EdgeInsets.only(bottom: 10),
            child: _buildNoteCard(note, dragIndex: index),
          );
        },
      );
    }

    return ListView.separated(
      itemCount: notes.length,
      separatorBuilder: (BuildContext context, int index) =>
          const SizedBox(height: 10),
      itemBuilder: (BuildContext context, int index) {
        return _buildNoteCard(notes[index]);
      },
    );
  }

  Widget _buildLabelChip(String label, {String? value}) {
    final String filterValue = value ?? label;
    final bool selected = _activeLabel == filterValue;
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        showCheckmark: false,
        labelStyle: TextStyle(
          fontWeight: FontWeight.w600,
          color: selected
              ? colorScheme.onSecondaryContainer
              : colorScheme.onSurface,
        ),
        selectedColor: colorScheme.secondaryContainer,
        backgroundColor: colorScheme.surfaceContainerHigh,
        side: BorderSide(
          color: selected
              ? colorScheme.secondaryContainer
              : colorScheme.outlineVariant,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        onSelected: (_) {
          setState(() {
            _activeLabel = filterValue;
          });
        },
      ),
    );
  }

  Widget _buildQuickFilterChip(String text, QuickFilter filter) {
    final bool selected = _quickFilter == filter;
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ChoiceChip(
        label: Text(text),
        selected: selected,
        showCheckmark: false,
        labelStyle: TextStyle(
          fontWeight: FontWeight.w600,
          color: selected ? colorScheme.onPrimary : colorScheme.onSurface,
        ),
        selectedColor: colorScheme.primary,
        backgroundColor: colorScheme.surfaceContainerHigh,
        side: BorderSide(
          color: selected ? colorScheme.primary : colorScheme.outlineVariant,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        onSelected: (_) {
          setState(() {
            _quickFilter = filter;
          });
        },
      ),
    );
  }

  Widget _buildHighlightedText(
    String source, {
    required TextStyle style,
    required int maxLines,
  }) {
    final String query = _query.trim();
    if (query.isEmpty) {
      return Text(
        source,
        style: style,
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
      );
    }

    final String lower = source.toLowerCase();
    final String q = query.toLowerCase();
    final int index = lower.indexOf(q);
    if (index < 0) {
      return Text(
        source,
        style: style,
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
      );
    }

    final TextStyle highlight = style.copyWith(
      backgroundColor: Colors.yellow.withValues(alpha: 0.45),
      fontWeight: FontWeight.w700,
    );

    final List<TextSpan> spans = <TextSpan>[
      if (index > 0) TextSpan(text: source.substring(0, index), style: style),
      TextSpan(
        text: source.substring(index, index + q.length),
        style: highlight,
      ),
      if (index + q.length < source.length)
        TextSpan(text: source.substring(index + q.length), style: style),
    ];

    return Text.rich(
      TextSpan(children: spans),
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildEmptyState() {
    return const SizedBox.expand();
  }

  Widget _buildNoteCard(Note note, {int? dragIndex}) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color background = isDark
        ? const Color(0xFF090C12)
        : const Color(0xFFF1F3F4);
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final bool hiddenByLock = note.isLocked && _scope != NoteScope.trash;

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: _scope == NoteScope.trash
          ? null
          : () => _openNoteEditor(note: note),
      child: Ink(
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDark ? const Color(0xFF656B77) : const Color(0xFFC3C7CC),
          ),
          boxShadow: const <BoxShadow>[],
        ),
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                if (note.pinned && _scope == NoteScope.notes)
                  Icon(
                    Icons.push_pin_rounded,
                    size: 18,
                    color: colorScheme.onSurface,
                  ),
                if (note.favorite)
                  Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: Icon(
                      Icons.star_rounded,
                      size: 18,
                      color: Colors.amber.shade700,
                    ),
                  ),
                if (note.isLocked)
                  Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: Icon(
                      Icons.lock_outline_rounded,
                      size: 17,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                if (_canReorder && dragIndex != null)
                  ReorderableDragStartListener(
                    index: dragIndex,
                    child: Padding(
                      padding: EdgeInsets.only(left: 6),
                      child: Icon(
                        Icons.drag_indicator_rounded,
                        size: 18,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                const Spacer(),
                PopupMenuButton<String>(
                  tooltip: _s('more_options'),
                  onSelected: (String value) async {
                    await _handleNoteMenuAction(value, note);
                  },
                  itemBuilder: (BuildContext context) =>
                      _buildMenuItemsForScope(note),
                ),
              ],
            ),
            if ((hiddenByLock ? _s('hidden_note') : note.title)
                .trim()
                .isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: _buildHighlightedText(
                  hiddenByLock ? _s('hidden_note') : note.title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 2,
                ),
              ),
            _buildHighlightedText(
              hiddenByLock ? _s('note_locked') : note.content,
              style: const TextStyle(fontSize: 13.5),
              maxLines: _gridView ? 8 : 4,
            ),
            if (!hiddenByLock && note.imagePaths.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    File(note.imagePaths.first),
                    height: 92,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder:
                        (
                          BuildContext context,
                          Object error,
                          StackTrace? stackTrace,
                        ) => Container(
                          height: 48,
                          color: colorScheme.surfaceContainerHighest,
                          alignment: Alignment.center,
                          child: const Icon(Icons.broken_image_outlined),
                        ),
                  ),
                ),
              ),
            if (!hiddenByLock && note.checklist.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '${_s('checklist_progress')} ${note.checklist.where((ChecklistItem item) => item.done).length}/${note.checklist.length}',
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            if (!hiddenByLock && note.audioPath != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: <Widget>[
                    IconButton(
                      onPressed: () => _toggleCardAudio(note.audioPath!),
                      icon: Icon(
                        _playingCardAudioPath == note.audioPath &&
                                _isCardAudioPlaying
                            ? Icons.pause_circle_outline_rounded
                            : Icons.play_circle_outline_rounded,
                        size: 18,
                      ),
                      tooltip:
                          _playingCardAudioPath == note.audioPath &&
                              _isCardAudioPlaying
                          ? _s('pause_audio')
                          : _s('play_audio'),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        note.audioPath!.split(Platform.pathSeparator).last,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            if (!hiddenByLock && note.labels.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: note.labels.take(3).map((String label) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.surface.withValues(alpha: 0.78),
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: Text(
                        label,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            if (!hiddenByLock &&
                note.category != null &&
                note.category!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0x224A84E0),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    '${_s('category')}: ${_s(note.category!)}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            if (!hiddenByLock && note.reminderAt != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.surface.withValues(alpha: 0.78),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    '${_s('reminder_prefix')} ${_friendlyDateTime(note.reminderAt!)}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    '${_s('created')}: ${_dateWithMonthName(note.createdAt)}',
                    style: TextStyle(
                      fontSize: 11,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${_s('updated')}: ${_dateWithMonthName(note.updatedAt)}',
                    style: TextStyle(
                      fontSize: 11,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<PopupMenuEntry<String>> _buildMenuItemsForScope(Note note) {
    switch (_scope) {
      case NoteScope.notes:
        return <PopupMenuEntry<String>>[
          PopupMenuItem<String>(
            value: 'favorite',
            child: Text(note.favorite ? _s('unfavorite') : _s('favorite')),
          ),
          if (AppFirebaseService.enablePdfExport)
            PopupMenuItem<String>(
              value: 'exportPdf',
              child: Text(_s('export_pdf')),
            ),
          PopupMenuItem<String>(
            value: 'pin',
            child: Text(note.pinned ? _s('unpin') : _s('pin')),
          ),
          PopupMenuItem<String>(
            value: 'archive',
            child: Text(_s('archive_note')),
          ),
          PopupMenuItem<String>(
            value: 'duplicate',
            child: Text(_s('duplicate')),
          ),
          PopupMenuItem<String>(
            value: 'trash',
            child: Text(_s('move_to_trash')),
          ),
        ];
      case NoteScope.archived:
        return <PopupMenuEntry<String>>[
          PopupMenuItem<String>(
            value: 'favorite',
            child: Text(note.favorite ? _s('unfavorite') : _s('favorite')),
          ),
          if (AppFirebaseService.enablePdfExport)
            PopupMenuItem<String>(
              value: 'exportPdf',
              child: Text(_s('export_pdf')),
            ),
          PopupMenuItem<String>(
            value: 'unarchive',
            child: Text(_s('unarchive')),
          ),
          PopupMenuItem<String>(
            value: 'duplicate',
            child: Text(_s('duplicate')),
          ),
          PopupMenuItem<String>(
            value: 'trash',
            child: Text(_s('move_to_trash')),
          ),
        ];
      case NoteScope.trash:
        return <PopupMenuEntry<String>>[
          PopupMenuItem<String>(value: 'restore', child: Text(_s('restore'))),
          PopupMenuItem<String>(
            value: 'deleteForever',
            child: Text(_s('delete_forever')),
          ),
        ];
    }
  }

  Future<void> _handleNoteMenuAction(String value, Note note) async {
    switch (value) {
      case 'favorite':
        _toggleFavorite(note);
        break;
      case 'exportPdf':
        await _exportNoteAsPdf(note);
        break;
      case 'pin':
        _togglePin(note);
        break;
      case 'archive':
        _archiveNote(note);
        break;
      case 'unarchive':
        _unarchiveNote(note);
        break;
      case 'duplicate':
        _duplicateNote(note);
        break;
      case 'trash':
        await _moveToTrash(note);
        break;
      case 'restore':
        _restoreFromTrash(note);
        break;
      case 'deleteForever':
        _deleteForever(note.id);
        break;
    }
  }

  String _friendlyDateTime(DateTime dateTime) {
    final String twoDigitHour = dateTime.hour.toString().padLeft(2, '0');
    final String twoDigitMinute = dateTime.minute.toString().padLeft(2, '0');
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} $twoDigitHour:$twoDigitMinute';
  }

  String _dateWithMonthName(DateTime date) {
    const List<String> months = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final String month = months[date.month - 1];
    return '${date.day} $month ${date.year}';
  }
}

enum NoteEditorAction { save, moveToTrash }

class NoteEditorResult {
  const NoteEditorResult({required this.action, this.note});

  final NoteEditorAction action;
  final Note? note;
}

class NoteEditorPage extends StatefulWidget {
  const NoteEditorPage({
    super.key,
    this.note,
    required this.localeCode,
    this.startVoiceRecording = false,
  });

  final Note? note;
  final String localeCode;
  final bool startVoiceRecording;

  @override
  State<NoteEditorPage> createState() => _NoteEditorPageState();
}

class _NoteEditorPageState extends State<NoteEditorPage> {
  static const List<int> _palette = <int>[
    0xFFFFF8B8,
    0xFFFFD7BA,
    0xFFC8F7C5,
    0xFFC3E6FF,
    0xFFE2D4FF,
    0xFFF9C5D5,
    0xFFFFFFFF,
  ];

  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  late final TextEditingController _labelsController;
  late final TextEditingController _lockSecretController;
  final TextEditingController _checklistController = TextEditingController();
  final List<ChecklistItem> _checklist = <ChecklistItem>[];
  final List<String> _imagePaths = <String>[];
  final List<String> _categoryValues = <String>[
    'study',
    'work',
    'personal',
    'ideas',
  ];
  String? _category;
  final AudioRecorder _audioRecorder = AudioRecorder();
  final ImagePicker _imagePicker = ImagePicker();
  final AudioPlayer _editorAudioPlayer = AudioPlayer();
  StreamSubscription<PlayerState>? _editorPlayerStateSubscription;

  late int _colorValue;
  late bool _pinned;
  late bool _favorite;
  late bool _isLocked;
  late String _lockType;
  DateTime? _reminderAt;
  String? _audioPath;
  bool _recording = false;
  bool _playingEditorAudio = false;

  String _s(String key) => AppStrings.of(widget.localeCode, key);

  @override
  void initState() {
    super.initState();
    _editorPlayerStateSubscription = _editorAudioPlayer.onPlayerStateChanged
        .listen((PlayerState state) {
          if (!mounted) {
            return;
          }
          setState(() {
            _playingEditorAudio = state == PlayerState.playing;
          });
        });
    final Note? note = widget.note;
    _titleController = TextEditingController(text: note?.title ?? '');
    _contentController = TextEditingController(text: note?.content ?? '');
    _labelsController = TextEditingController(
      text: note?.labels.join(', ') ?? '',
    );
    _lockSecretController = TextEditingController(text: note?.lockSecret ?? '');
    _category = note?.category;
    _colorValue = note?.colorValue ?? _palette.first;
    _pinned = note?.pinned ?? false;
    _favorite = note?.favorite ?? false;
    _isLocked = note?.isLocked ?? false;
    _lockType = note?.lockType ?? 'pin';
    _reminderAt = note?.reminderAt;
    _audioPath = note?.audioPath;
    _checklist
      ..clear()
      ..addAll(note?.checklist ?? <ChecklistItem>[]);
    _imagePaths
      ..clear()
      ..addAll(note?.imagePaths ?? <String>[]);

    if (widget.startVoiceRecording && note == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _toggleRecording();
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _labelsController.dispose();
    _lockSecretController.dispose();
    _checklistController.dispose();
    _audioRecorder.dispose();
    _editorPlayerStateSubscription?.cancel();
    _editorAudioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool editing = widget.note != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(editing ? _s('edit_note') : _s('new_note')),
        actions: <Widget>[
          if (editing)
            IconButton(
              tooltip: _s('delete_note'),
              icon: const Icon(Icons.delete_outline_rounded),
              onPressed: _moveToTrash,
            ),
          IconButton(
            tooltip: _s('save_note'),
            icon: const Icon(Icons.check_rounded),
            onPressed: _save,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                hintText: _s('title'),
                border: InputBorder.none,
              ),
              style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _contentController,
              decoration: InputDecoration(
                hintText: _s('start_typing'),
                border: InputBorder.none,
              ),
              maxLines: null,
              minLines: 8,
              keyboardType: TextInputType.multiline,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                OutlinedButton(
                  onPressed: () => _insertMarkup('**', '**'),
                  child: Text(_s('bold')),
                ),
                OutlinedButton(
                  onPressed: () => _insertMarkup('_', '_'),
                  child: Text(_s('italic')),
                ),
                OutlinedButton(
                  onPressed: () => _insertMarkup('- ', ''),
                  child: Text(_s('bullet')),
                ),
                OutlinedButton(
                  onPressed: () => _insertMarkup('## ', ''),
                  child: Text(_s('heading')),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              _s('checklist'),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: _checklistController,
                    decoration: InputDecoration(
                      hintText: _s('add_checklist_item'),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _addChecklistItem,
                  child: Text(_s('add')),
                ),
              ],
            ),
            if (_checklist.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Column(
                  children: _checklist.asMap().entries.map((
                    MapEntry<int, ChecklistItem> entry,
                  ) {
                    return CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      value: entry.value.done,
                      title: Text(entry.value.text),
                      onChanged: (bool? value) {
                        setState(() {
                          _checklist[entry.key] = entry.value.copyWith(
                            done: value ?? false,
                          );
                        });
                      },
                      secondary: IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          setState(() {
                            _checklist.removeAt(entry.key);
                          });
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
            const SizedBox(height: 18),
            Text(
              _s('attachments'),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                OutlinedButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.image_outlined),
                  label: Text(_s('add_image')),
                ),
                OutlinedButton.icon(
                  onPressed: _toggleRecording,
                  icon: Icon(
                    _recording
                        ? Icons.stop_circle_outlined
                        : Icons.mic_none_rounded,
                  ),
                  label: Text(
                    _recording ? _s('stop_voice') : _s('record_voice'),
                  ),
                ),
              ],
            ),
            if (_imagePaths.isNotEmpty)
              SizedBox(
                height: 90,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _imagePaths.length,
                  separatorBuilder: (BuildContext context, int index) =>
                      const SizedBox(width: 8),
                  itemBuilder: (BuildContext context, int index) {
                    final String path = _imagePaths[index];
                    return Stack(
                      children: <Widget>[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.file(
                            File(path),
                            width: 90,
                            height: 90,
                            fit: BoxFit.cover,
                            errorBuilder:
                                (
                                  BuildContext context,
                                  Object error,
                                  StackTrace? stackTrace,
                                ) => Container(
                                  width: 90,
                                  height: 90,
                                  color: Colors.black12,
                                  child: const Icon(
                                    Icons.broken_image_outlined,
                                  ),
                                ),
                          ),
                        ),
                        Positioned(
                          right: -8,
                          top: -8,
                          child: IconButton(
                            onPressed: () {
                              setState(() {
                                _imagePaths.removeAt(index);
                              });
                            },
                            icon: const Icon(Icons.cancel, color: Colors.red),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            if (_audioPath != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: <Widget>[
                    IconButton(
                      onPressed: _toggleEditorAudioPlayback,
                      icon: Icon(
                        _playingEditorAudio
                            ? Icons.pause_circle_outline_rounded
                            : Icons.play_circle_outline_rounded,
                      ),
                      tooltip: _playingEditorAudio
                          ? _s('pause_audio')
                          : _s('play_audio'),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _audioPath!.split(Platform.pathSeparator).last,
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _audioPath = null;
                        });
                      },
                      icon: const Icon(Icons.delete_outline_rounded),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 18),
            Text(
              _s('reminder'),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    _reminderAt == null
                        ? _s('no_reminder_set')
                        : '${_reminderAt!.day}/${_reminderAt!.month}/${_reminderAt!.year} '
                              '${_reminderAt!.hour.toString().padLeft(2, '0')}:${_reminderAt!.minute.toString().padLeft(2, '0')}',
                  ),
                ),
                TextButton.icon(
                  onPressed: _pickReminder,
                  icon: const Icon(Icons.notifications_active_outlined),
                  label: Text(_s('set')),
                ),
                if (_reminderAt != null)
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _reminderAt = null;
                      });
                    },
                    child: Text(_s('clear')),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _s('category'),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _categoryValues.map((String value) {
                final bool selected = _category == value;
                return ChoiceChip(
                  label: Text(_s(value)),
                  selected: selected,
                  onSelected: (bool isSelected) {
                    setState(() {
                      _category = isSelected ? value : null;
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _labelsController,
              decoration: InputDecoration(
                labelText: _s('labels'),
                hintText: _s('labels_hint'),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 6),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: Text(_s('favorite')),
              value: _favorite,
              onChanged: (bool value) {
                setState(() {
                  _favorite = value;
                });
              },
            ),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: Text(_s('pin_this_note')),
              value: _pinned,
              onChanged: (bool value) {
                setState(() {
                  _pinned = value;
                });
              },
            ),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: Text(_s('note_lock')),
              value: _isLocked,
              onChanged: (bool value) {
                setState(() {
                  _isLocked = value;
                });
              },
            ),
            if (_isLocked)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: <Widget>[
                    ChoiceChip(
                      label: Text(_s('lock_with_pin')),
                      selected: _lockType == 'pin',
                      onSelected: (_) {
                        setState(() {
                          _lockType = 'pin';
                        });
                      },
                    ),
                    ChoiceChip(
                      label: Text(_s('lock_with_password')),
                      selected: _lockType == 'password',
                      onSelected: (_) {
                        setState(() {
                          _lockType = 'password';
                        });
                      },
                    ),
                  ],
                ),
              ),
            if (_isLocked)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: TextField(
                  controller: _lockSecretController,
                  obscureText: true,
                  keyboardType: _lockType == 'pin'
                      ? TextInputType.number
                      : TextInputType.visiblePassword,
                  decoration: InputDecoration(
                    labelText: _s('lock_secret'),
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _insertMarkup(String prefix, String suffix) {
    final TextSelection selection = _contentController.selection;
    final String text = _contentController.text;
    final int start = selection.start < 0 ? text.length : selection.start;
    final int end = selection.end < 0 ? text.length : selection.end;
    final String selected = text.substring(start, end);
    final String updated = text.replaceRange(
      start,
      end,
      '$prefix$selected$suffix',
    );
    _contentController.value = TextEditingValue(
      text: updated,
      selection: TextSelection.collapsed(
        offset: start + prefix.length + selected.length + suffix.length,
      ),
    );
  }

  void _addChecklistItem() {
    final String value = _checklistController.text.trim();
    if (value.isEmpty) {
      return;
    }
    setState(() {
      _checklist.add(ChecklistItem(text: value, done: false));
      _checklistController.clear();
    });
  }

  Future<void> _pickImage() async {
    final XFile? picked = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked == null) {
      return;
    }
    setState(() {
      _imagePaths.add(picked.path);
    });
  }

  Future<void> _toggleRecording() async {
    if (_recording) {
      final String? path = await _audioRecorder.stop();
      setState(() {
        _recording = false;
        if (path != null) {
          _audioPath = path;
        }
      });
      return;
    }

    final bool hasPermission = await _audioRecorder.hasPermission();
    if (!hasPermission) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_s('mic_permission_needed'))));
      return;
    }

    final Directory directory = await getApplicationDocumentsDirectory();
    final String path =
        '${directory.path}${Platform.pathSeparator}voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
    await _audioRecorder.start(const RecordConfig(), path: path);
    setState(() {
      _recording = true;
    });
  }

  Future<void> _toggleEditorAudioPlayback() async {
    final String? path = _audioPath;
    if (path == null) {
      return;
    }
    try {
      if (_playingEditorAudio) {
        await _editorAudioPlayer.pause();
      } else {
        await _editorAudioPlayer.play(DeviceFileSource(path));
      }
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_s('audio_play_error'))));
    }
  }

  Future<void> _pickReminder() async {
    final DateTime now = DateTime.now();
    final DateTime initialDate = _reminderAt ?? now;

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
      initialDate: initialDate,
    );

    if (pickedDate == null) {
      return;
    }

    if (!mounted) {
      return;
    }

    final TimeOfDay initialTime = _reminderAt != null
        ? TimeOfDay(hour: _reminderAt!.hour, minute: _reminderAt!.minute)
        : TimeOfDay.now();

    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (pickedTime == null) {
      return;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _reminderAt = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
    });
  }

  void _save() {
    final String title = _titleController.text.trim();
    final String content = _contentController.text.trim();
    final bool hasNonTextContent =
        _checklist.isNotEmpty ||
        _imagePaths.isNotEmpty ||
        _audioPath != null ||
        _reminderAt != null ||
        _labelsController.text.trim().isNotEmpty ||
        (_category != null && _category!.isNotEmpty);

    if (title.isEmpty && content.isEmpty && !hasNonTextContent) {
      Navigator.of(context).pop();
      return;
    }

    if (_isLocked && _lockSecretController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_s('lock_secret_required'))));
      return;
    }

    final DateTime now = DateTime.now();
    final List<String> labels = _labelsController.text
        .split(',')
        .map((String value) => value.trim())
        .where((String value) => value.isNotEmpty)
        .toSet()
        .toList();

    if (_category != null && !labels.contains(_category!)) {
      labels.insert(0, _category!);
    }

    final Note note = (widget.note ?? Note.empty()).copyWith(
      id: widget.note?.id ?? now.microsecondsSinceEpoch.toString(),
      title: title,
      content: content,
      colorValue: _colorValue,
      category: _category,
      labels: labels,
      checklist: _checklist,
      imagePaths: _imagePaths,
      audioPath: _audioPath,
      pinned: _pinned,
      favorite: _favorite,
      isLocked: _isLocked,
      lockType: _isLocked ? _lockType : null,
      lockSecret: _isLocked ? _lockSecretController.text.trim() : null,
      reminderAt: _reminderAt,
      archived: false,
      trashed: false,
      clearTrashedAt: true,
      createdAt: widget.note?.createdAt ?? now,
      updatedAt: now,
    );

    Navigator.of(
      context,
    ).pop(NoteEditorResult(action: NoteEditorAction.save, note: note));
  }

  void _moveToTrash() {
    final Note? note = widget.note;
    if (note == null) {
      Navigator.of(context).pop();
      return;
    }
    Navigator.of(
      context,
    ).pop(NoteEditorResult(action: NoteEditorAction.moveToTrash, note: note));
  }
}

class Note {
  const Note({
    required this.id,
    required this.title,
    required this.content,
    required this.colorValue,
    this.category,
    required this.labels,
    required this.pinned,
    required this.favorite,
    required this.archived,
    required this.trashed,
    required this.isLocked,
    this.lockType,
    this.lockSecret,
    required this.sortOrder,
    required this.createdAt,
    required this.updatedAt,
    required this.checklist,
    required this.imagePaths,
    this.audioPath,
    this.reminderAt,
    this.trashedAt,
  });

  factory Note.empty() {
    final DateTime now = DateTime.now();
    return Note(
      id: '',
      title: '',
      content: '',
      colorValue: 0xFFFFF8B8,
      category: null,
      labels: const <String>[],
      pinned: false,
      favorite: false,
      archived: false,
      trashed: false,
      isLocked: false,
      lockType: null,
      lockSecret: null,
      sortOrder: -1,
      createdAt: now,
      updatedAt: now,
      checklist: const <ChecklistItem>[],
      imagePaths: const <String>[],
      audioPath: null,
      reminderAt: null,
      trashedAt: null,
    );
  }

  factory Note.fromMap(Map<String, dynamic> map) {
    return Note(
      id: map['id'] as String,
      title: map['title'] as String? ?? '',
      content: map['content'] as String? ?? '',
      colorValue: map['colorValue'] as int? ?? 0xFFFFF8B8,
      category: map['category'] as String?,
      labels: (map['labels'] as List<dynamic>? ?? <dynamic>[])
          .map((dynamic e) => e as String)
          .toList(),
      pinned: map['pinned'] as bool? ?? false,
      favorite: map['favorite'] as bool? ?? false,
      archived: map['archived'] as bool? ?? false,
      trashed: map['trashed'] as bool? ?? false,
      isLocked: map['isLocked'] as bool? ?? false,
      lockType: map['lockType'] as String?,
      lockSecret: map['lockSecret'] as String?,
      sortOrder: map['sortOrder'] as int? ?? -1,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
      checklist: (map['checklist'] as List<dynamic>? ?? <dynamic>[])
          .map((dynamic e) => ChecklistItem.fromMap(e as Map<String, dynamic>))
          .toList(),
      imagePaths: (map['imagePaths'] as List<dynamic>? ?? <dynamic>[])
          .map((dynamic e) => e as String)
          .toList(),
      audioPath: map['audioPath'] as String?,
      reminderAt: map['reminderAt'] == null
          ? null
          : DateTime.parse(map['reminderAt'] as String),
      trashedAt: map['trashedAt'] == null
          ? null
          : DateTime.parse(map['trashedAt'] as String),
    );
  }

  final String id;
  final String title;
  final String content;
  final int colorValue;
  final String? category;
  final List<String> labels;
  final bool pinned;
  final bool favorite;
  final bool archived;
  final bool trashed;
  final bool isLocked;
  final String? lockType;
  final String? lockSecret;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<ChecklistItem> checklist;
  final List<String> imagePaths;
  final String? audioPath;
  final DateTime? reminderAt;
  final DateTime? trashedAt;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'content': content,
      'colorValue': colorValue,
      'category': category,
      'labels': labels,
      'pinned': pinned,
      'favorite': favorite,
      'archived': archived,
      'trashed': trashed,
      'isLocked': isLocked,
      'lockType': lockType,
      'lockSecret': lockSecret,
      'sortOrder': sortOrder,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'checklist': checklist.map((ChecklistItem item) => item.toMap()).toList(),
      'imagePaths': imagePaths,
      'audioPath': audioPath,
      'reminderAt': reminderAt?.toIso8601String(),
      'trashedAt': trashedAt?.toIso8601String(),
    };
  }

  Note copyWith({
    String? id,
    String? title,
    String? content,
    int? colorValue,
    String? category,
    List<String>? labels,
    bool? pinned,
    bool? favorite,
    bool? archived,
    bool? trashed,
    bool? isLocked,
    String? lockType,
    String? lockSecret,
    int? sortOrder,
    List<ChecklistItem>? checklist,
    List<String>? imagePaths,
    String? audioPath,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? reminderAt,
    DateTime? trashedAt,
    bool clearReminder = false,
    bool clearTrashedAt = false,
  }) {
    return Note(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      colorValue: colorValue ?? this.colorValue,
      category: category ?? this.category,
      labels: labels ?? this.labels,
      pinned: pinned ?? this.pinned,
      favorite: favorite ?? this.favorite,
      archived: archived ?? this.archived,
      trashed: trashed ?? this.trashed,
      isLocked: isLocked ?? this.isLocked,
      lockType: lockType ?? this.lockType,
      lockSecret: lockSecret ?? this.lockSecret,
      sortOrder: sortOrder ?? this.sortOrder,
      checklist: checklist ?? this.checklist,
      imagePaths: imagePaths ?? this.imagePaths,
      audioPath: audioPath ?? this.audioPath,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      reminderAt: clearReminder ? null : (reminderAt ?? this.reminderAt),
      trashedAt: clearTrashedAt ? null : (trashedAt ?? this.trashedAt),
    );
  }
}

class ChecklistItem {
  const ChecklistItem({required this.text, required this.done});

  factory ChecklistItem.fromMap(Map<String, dynamic> map) {
    return ChecklistItem(
      text: map['text'] as String? ?? '',
      done: map['done'] as bool? ?? false,
    );
  }

  final String text;
  final bool done;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{'text': text, 'done': done};
  }

  ChecklistItem copyWith({String? text, bool? done}) {
    return ChecklistItem(text: text ?? this.text, done: done ?? this.done);
  }
}
