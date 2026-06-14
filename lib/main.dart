import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'models/gold_price.dart';
import 'providers/gold_price_notifier.dart';
import 'services/gold_price_history_backfill_service.dart';
import 'services/gold_price_history_seed_service.dart';
import 'services/gold_price_history_service.dart';
import 'services/hive_service.dart';
import 'theme/theme_notifier.dart';
import 'routes/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  Hive.registerAdapter(GoldPriceAdapter());
  await Hive.openBox<GoldPrice>('goldPriceBox');
  await Hive.openBox<String>(GoldPriceHistoryService.boxName);
  await HiveService.initialize();
  await GoldPriceHistorySeedService.seedIfNeeded();
  await GoldPriceHistoryBackfillService.backfillIfNeeded();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeNotifier()),
        ChangeNotifierProvider(create: (_) => GoldPriceNotifier()),
      ],
      child: Consumer<ThemeNotifier>(
        builder: (context, themeNotifier, child) {
          return MaterialApp.router(
            title: 'Pocket Gold',
            theme: context.watch<ThemeNotifier>().getThemeData(),
            routerConfig: router,
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}
