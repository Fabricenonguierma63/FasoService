// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String timeSlotsHeader(Object count) {
    return 'Time slots ($count)';
  }

  @override
  String duration(Object duration) {
    return 'Duration: $duration';
  }

  @override
  String deleteSlotQuestion(Object timeRange) {
    return 'Are you sure you want to delete this time slot?\n$timeRange';
  }

  @override
  String durationHours(Object hours) {
    return '${hours}h';
  }

  @override
  String durationHoursMinutes(Object hours, Object minutes) {
    return '${hours}h$minutes';
  }

  @override
  String durationMinutes(Object minutes) {
    return '${minutes}min';
  }

  @override
  String timeFormat(Object hour, Object minute) {
    return '$hour:$minute';
  }
}
