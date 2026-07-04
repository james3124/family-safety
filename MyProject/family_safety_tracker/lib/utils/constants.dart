class AppConstants {
  static const String appName = 'Family Safety Tracker';
  static const int locationUpdateIntervalSec = 15;
  static const int batteryCheckIntervalMin = 15;
  static const int lowBatteryThreshold = 20;
  static const int locationHistoryDays = 30;
  static const double defaultMapZoom = 14.0;
  static const Duration locationStaleThreshold = Duration(minutes: 5);
}
