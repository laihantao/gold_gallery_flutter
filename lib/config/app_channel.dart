/// The distribution channel this build belongs to.
///
/// `dev` is the internal testing app (applicationId suffix `.dev`, installed
/// side-by-side with `prod`); `prod` is the release shipped to other users.
enum AppChannel {
  dev,
  prod;

  String get label => this == AppChannel.dev ? 'Pocket Gold (Dev)' : 'Pocket Gold';
}

/// Channel baked in at compile time via `--dart-define=CHANNEL=dev|prod`.
///
/// Used as the fallback for [lib/main.dart], which doesn't get an explicit
/// channel argument the way `main_dev.dart` / `main_prod.dart` do.
const String _channelEnv = String.fromEnvironment('CHANNEL', defaultValue: 'prod');

const AppChannel channelFromEnv =
    _channelEnv == 'dev' ? AppChannel.dev : AppChannel.prod;
