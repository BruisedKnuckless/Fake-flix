import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'nav.dart';
import 'screens/profiles_screen.dart';
import 'screens/shell.dart';
import 'state/profile_store.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // The app is portrait; only the player turns sideways (see PlayerScreen)
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // Read the profiles saved on this device before showing anything
  store = await ProfileStore.load();

  runApp(const FakeFlixApp());
}

class FakeFlixApp extends StatelessWidget {
  const FakeFlixApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FakeFlix',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      navigatorKey: navigatorKey,
      // white status bar text over the dark app
      builder: (context, child) => AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: child!,
      ),
      home: const _Start(),
    );
  }
}

/// Shared phone (two or more profiles): ask who's watching first.
/// Otherwise go straight in.
class _Start extends StatefulWidget {
  const _Start();

  @override
  State<_Start> createState() => _StartState();
}

class _StartState extends State<_Start> {
  bool _asking = store.profiles.length >= 2;

  @override
  Widget build(BuildContext context) {
    if (_asking) return ProfilesScreen(onDone: () => setState(() => _asking = false));
    return const Shell();
  }
}
