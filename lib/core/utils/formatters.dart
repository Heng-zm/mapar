import 'package:intl/intl.dart';

import '../../features/settings/controllers/settings_controller.dart';

class Formatters {
  const Formatters._();

  static String distance(double meters, DistanceUnit unit) {
    if (unit == DistanceUnit.mile) {
      final miles = meters / 1609.344;
      return miles >= 10 ? '${miles.toStringAsFixed(1)} mi' : '${miles.toStringAsFixed(2)} mi';
    }
    final km = meters / 1000;
    return km >= 10 ? '${km.toStringAsFixed(1)} km' : '${km.toStringAsFixed(2)} km';
  }

  static String speed(double metersPerSecond, SpeedUnit unit) {
    if (metersPerSecond.isNaN || metersPerSecond.isInfinite || metersPerSecond < 0) return '--';
    if (unit == SpeedUnit.mph) return '${(metersPerSecond * 2.236936).toStringAsFixed(0)} mph';
    return '${(metersPerSecond * 3.6).toStringAsFixed(0)} km/h';
  }

  static String duration(double seconds) {
    if (seconds <= 0 || seconds.isNaN) return '--';
    final minutes = (seconds / 60).round();
    if (minutes < 60) return '$minutes min';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return '${h}h ${m}m';
  }

  static String date(DateTime dateTime) => DateFormat('MMM d, yyyy • h:mm a').format(dateTime);
}
