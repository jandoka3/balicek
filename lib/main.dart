import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import 'models/packing_item.dart';
import 'models/packing_list.dart';
import 'models/quantity_mode.dart';
import 'state/app_state.dart';
import 'strings.dart';
import 'screens/lists_overview.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  Hive.registerAdapter(QuantityModeAdapter());
  Hive.registerAdapter(PackingItemAdapter());
  Hive.registerAdapter(PackingListAdapter());

  final box = await Hive.openBox<PackingList>(AppState.boxName);

  runApp(BalicekApp(box: box));
}

class BalicekApp extends StatelessWidget {
  final Box<PackingList> box;

  const BalicekApp({super.key, required this.box});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppState(box),
      child: MaterialApp(
        title: S.appTitle,
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF4DB6AC), // teplá tyrkysová
            brightness: Brightness.light,
          ),
          visualDensity: VisualDensity.comfortable,
        ),
        home: const ListsOverviewScreen(),
      ),
    );
  }
}
