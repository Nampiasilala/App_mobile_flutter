import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialise les données de formatage pour fr_FR
  await initializeDateFormatting('fr_FR', null);
  Intl.defaultLocale = 'fr_FR';

  runApp(const ProviderScope(child: App()));
}
