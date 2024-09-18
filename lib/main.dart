import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
//import 'package:vigilant_care/home_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vigilant_care/child/childlogin_screen.dart';
import 'package:vigilant_care/db/shared_pref.dart';
import 'package:vigilant_care/utils/flutter_background_services.dart';

final navigatorkey = GlobalKey<ScaffoldMessengerState>();
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: FirebaseOptions(
      apiKey: 'AIzaSyB7HH6R4DRoHtXJSmPVi-BKN21CEYIZFLk',
      appId: '1:795854733296:android:5bdab20a839dd68d176735',
      messagingSenderId: '795854733296',
      projectId: 'vigilant-care-8db7e',
      storageBucket: 'vigilant-care-8db7e.appspot.com',
    ),
  );
  await Firebase.initializeApp();
  MySharedPrefference.init();
  await initializeService();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Flutter Demo',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          textTheme: GoogleFonts.firaSansTextTheme(
            Theme.of(context).textTheme,
          ),
          primarySwatch: Colors.blue,
        ),
        home: LoginScreen());
  }
}
