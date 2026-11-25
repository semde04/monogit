import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';

import 'app.dart';
import 'core/di/injection.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.android);
  }
  await configureDependencies();
  runApp(const LostFoundApp());
}
