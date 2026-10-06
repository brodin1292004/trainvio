import 'package:flutter/material.dart';

import 'app.dart';
import 'data/saved_trains_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SavedTrainsStore.instance.load();
  runApp(const TrainVioApp());
}
