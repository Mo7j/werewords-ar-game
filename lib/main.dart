import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'src/ui/setup_screen.dart';
import 'src/ui/theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: WerewordsApp()));
}

class WerewordsApp extends StatelessWidget {
  const WerewordsApp({super.key});

  @override
  Widget build(BuildContext context) {
    final baseDark = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF7C4DFF),
        brightness: Brightness.dark,
      ),
    );

    final theme = baseDark.copyWith(
      scaffoldBackgroundColor: AppColors.bg,
      cardColor: AppColors.surface,
      textTheme: GoogleFonts.cairoTextTheme(baseDark.textTheme),
      appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: const Locale('ar', 'SA'),
      supportedLocales: const [Locale('ar', 'SA')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: theme,
      home: const SetupScreen(),
    );
  }
}
