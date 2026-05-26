import 'package:flutter/material.dart';

import 'src/app/chitra_app.dart';
import 'src/core/state/chitra_session.dart';
import 'src/core/storage/app_storage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Resolve and create the persistent base folder (Downloads/SvachronChitra)
  await AppStorage.init();

  // 2. Restore all previously saved documents + folders
  await ChitraSession.instance.loadFromDisk();

  runApp(const ChitraApp());
}
