part of flutter_rocketchat;

class _Durations {
  static const Duration networkDownloadConnectTimeout = Duration(seconds: 10);
  static const Duration networkDownloadReceiveTimeout = Duration(seconds: 900); // 15 minutes
  static const Duration networkDownloadSendTimeout = Duration(seconds: 10);
  static const Duration networkConnectTimeout = Duration(seconds: 10);
  static const Duration networkReceiveTimeout = Duration(seconds: 10);
  static const Duration networkSendTimeout = Duration(seconds: 10);
  static const Duration socketConnectTimeout = Duration(seconds: 10);
}