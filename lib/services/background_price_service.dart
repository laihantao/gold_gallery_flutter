/// Background price checking is handled in-app by [GoldAlertNotifier]
/// when the user refreshes prices on the home page.
///
/// WorkManager was removed because it required platform-specific BGTask
/// configuration on iOS (missing BGTaskSchedulerPermittedIdentifiers) and
/// caused a pre-launch crash on mobile devices.
Future<void> registerDailyPriceCheck() async {
  // No-op: background scheduling is not active.
}
