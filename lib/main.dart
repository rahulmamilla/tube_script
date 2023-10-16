import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'channels.dart';
import 'firebase_options.dart';
import 'providers/data_provider.dart';

late DataProvider dp;
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.debug,
    appleProvider: AppleProvider.debug,
  );
  runApp(MultiProvider(providers: [
    ChangeNotifierProvider<DataProvider>(create: (context) {
      dp = DataProvider();

      return dp;
    })
  ], child: const Home()));
}

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> with WidgetsBindingObserver {
  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DataProvider>(
      builder: (context, dp, child) {
        return MaterialApp(
            themeAnimationCurve: Curves.easeIn,
            themeMode: dp.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            themeAnimationDuration: const Duration(milliseconds: 200),
            darkTheme: ThemeData.dark(useMaterial3: true),
            theme: ThemeData.light(useMaterial3: true),
            home: const Channels());
      },
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.inactive) {
      dp.saveUserData();
    }
  }
}
