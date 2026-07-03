// Default entry point for plain `flutter run` / `flutter build` without
// --target. Falls back to the CHANNEL dart-define (defaults to prod).
// Prefer running via main_dev.dart / main_prod.dart with the matching
// --flavor so the channel used at compile time and the flavor match up.
import 'config/app_channel.dart';
import 'main_common.dart';

Future<void> main() => mainCommon(channelFromEnv);
