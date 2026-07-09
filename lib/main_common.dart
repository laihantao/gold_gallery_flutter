import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'config/app_channel.dart';
import 'models/gold_price.dart';
import 'l10n/app_localizations.dart';
import 'providers/gold_price_notifier.dart';
import 'providers/locale_notifier.dart';
import 'providers/privacy_notifier.dart';
import 'services/collection_service.dart';
import 'services/gold_alert_service.dart';
import 'services/gold_price_history_backfill_service.dart';
import 'services/gold_price_history_seed_service.dart';
import 'services/gold_price_history_service.dart';
import 'services/hive_service.dart';
import 'services/background_price_service.dart';
import 'services/notification_service.dart';
import 'services/splash_caption_service.dart';
import 'theme/theme_notifier.dart';
import 'routes/app_router.dart';

/// Shared app bootstrap, invoked by `main_dev.dart` / `main_prod.dart` (and by
/// `main.dart` as a default entry point) with the channel that build was
/// compiled for.
Future<void> mainCommon(AppChannel channel) async {
  WidgetsFlutterBinding.ensureInitialized();

  // Make the boot channel authoritative for the rest of the app (e.g. the OTA
  // update check), independent of the compile-time CHANNEL dart-define.
  activeChannel = channel;

  await Hive.initFlutter();
  Hive.registerAdapter(GoldPriceAdapter());
  await Hive.openBox<GoldPrice>('goldPriceBox');
  await Hive.openBox<String>(GoldPriceHistoryService.boxName);
  await HiveService.initialize();
  await GoldPriceHistorySeedService.seedIfNeeded();
  await GoldPriceHistoryBackfillService.backfillIfNeeded();
  await GoldPriceHistoryBackfillService.reconcileRecentHistory();
  await SplashCaptionService.initialize();
  await NotificationService.initialize();
  await registerDailyPriceCheck();

  runApp(MyApp(channel: channel));
}

class MyApp extends StatelessWidget {
  final AppChannel channel;

  const MyApp({super.key, required this.channel});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeNotifier()),
        ChangeNotifierProvider(create: (_) => GoldPriceNotifier()),
        ChangeNotifierProvider(create: (_) => GoldAlertNotifier()),
        ChangeNotifierProvider(create: (_) => CollectionNotifier()),
        ChangeNotifierProvider(create: (_) => LocaleNotifier()),
        ChangeNotifierProvider(create: (_) => PrivacyNotifier()),
      ],
      child: Consumer2<ThemeNotifier, LocaleNotifier>(
        builder: (context, themeNotifier, localeNotifier, _) {
          return MaterialApp.router(
            title: channel.label,
            theme: themeNotifier.getThemeData(),
            routerConfig: router,
            debugShowCheckedModeBanner: false,
            locale: localeNotifier.locale.toFlutterLocale(),
            supportedLocales:
                AppLocale.values.map((l) => l.toFlutterLocale()).toList(),
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            // For ZH-CN, merge ZCOOL KuaiLe into the inherited DefaultTextStyle
            // so that any Text widget without an explicit fontFamily picks it up.
            // Widgets that already set a fontFamily (AppTextStyles.*) are unaffected.
            builder: (context, child) {
              if (localeNotifier.locale == AppLocale.zhCN) {
                return DefaultTextStyle.merge(
                  style: GoogleFonts.zcoolKuaiLe(),
                  child: child!,
                );
              }
              return child!;
            },
          );
        },
      ),
    );
  }
}
