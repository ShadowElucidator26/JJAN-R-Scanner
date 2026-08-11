import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:jjan/services/color_extension.dart';
import 'package:month_year_picker/month_year_picker.dart';
import 'services/firebase_options.dart';
//import 'package:jjan/MainLobbyUI/mainLobby_Page.dart';
import 'package:jjan/loginSignup/welcomeUI.dart';
//import 'TechnoExpo/offline/off_welcomeUI.dart';
//import 'package:jjan/rscanner/ScannerScreen.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform
  );
  runApp(const MyApp());
}
class MyApp extends StatelessWidget {
  const MyApp({super.key}); 

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(412, 917),
      builder: (context, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'StartScreen',
          theme: ThemeData(
            fontFamily: "Inter",
            colorScheme: ColorScheme.fromSeed(
              seedColor: TColor.primary,
              primary: TColor.primary,
              primaryContainer: TColor.gray60,
              secondary: TColor.secondary,
            ),
            useMaterial3: false,
          ),
          // 👇 this is the important part
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            MonthYearPickerLocalizations
                .delegate, // ✅ added so month_year_picker works
          ],
          supportedLocales: const [
            Locale('en', 'US'), // add more if needed
          ],
          home: child, 
        );
      },
      //child: TutorialPage(email: '', storeName: '',),
      //child: mainLobby_Page(),
      //child: UserImageUI(email: "", storeName: "",),
      //child: infoFormUI(email: ""),
      child: Welcomeui(),
      //child: ScannerScreen(),
    );
  }
}


