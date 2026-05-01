import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'firebase_options.dart';
import 'pages/start_page.dart';
import 'pages/home_page.dart';

/// نقطة البداية لتشغيل التطبيق بالكامل (Entry Point).
/// تقوم بتهيئة خدمات Flutter ومن ثم تهيئة خدمات Firebase قبل تشغيل التطبيق.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const UnveilApp());
}

/// الويدجت الرئيسي للتطبيق (Root Widget).
/// يتحكم في إعدادات التطبيق العامة مثل الثيم (Theme) واللغات المدعومة والتجاوب (Responsive ScreenUtil).
class UnveilApp extends StatefulWidget {
  const UnveilApp({super.key});

  static _UnveilAppState of(BuildContext context) =>
      context.findAncestorStateOfType<_UnveilAppState>()!;

  @override
  State<UnveilApp> createState() => _UnveilAppState();
}

class _UnveilAppState extends State<UnveilApp> {
  Locale _locale = const Locale('en');

  /// دالة لتغيير لغة التطبيق وتحديث واجهة المستخدم (UI) لتعكس اللغة الجديدة.
  void changeLanguage(String languageCode) {
    setState(() {
      _locale = Locale(languageCode);
    });
  }

  /// دالة البناء الرئيسية، هنا نستخدم ScreenUtil لجعل التطبيق متجاوباً (Responsive) مع مختلف أحجام الشاشات.
  /// ونمرر اللغات المدعومة والـ Theme (الألوان) الخاصة بالتطبيق لـ MaterialApp.
  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(412, 915),
      minTextAdapt: false,
      splitScreenMode: false,
      builder: (context, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Unveil',
          locale: _locale,
          supportedLocales: const [
            Locale('en'),
            Locale('ar'),
            Locale('es'),
            Locale('fr'),
            Locale('zh'),
            Locale('hi'),
          ],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          theme: ThemeData(
            useMaterial3: true,
            scaffoldBackgroundColor: const Color(0xFF18245C),
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFFF5A623),
              brightness: Brightness.dark,
            ),
          ),
          home: const AuthGate(),
        );
      },
    );
  }
}

/// بوابة المصادقة (AuthGate).
/// تقوم بمراقبة حالة المستخدم (هل قام بتسجيل الدخول أم لا) عبر StreamBuilder.
/// إذا كان المستخدم مسجلاً، يتم توجيهه مباشرة إلى الصفحة الرئيسية (HomeScreen).
/// إذا لم يكن مسجلاً، يتم توجيهه إلى صفحة البداية (StartPage).
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFF18245C),
            body: Center(
              child: CircularProgressIndicator(
                color: Color(0xFFF5A623),
              ),
            ),
          );
        }

        if (snapshot.hasData) {
          return const HomeScreen();
        }

        return const StartPage();
      },
    );
  }
}