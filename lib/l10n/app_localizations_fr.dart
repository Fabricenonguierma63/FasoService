// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String timeSlotsHeader(Object count) {
    return 'Créneaux horaires ($count)';
  }

  @override
  String duration(Object duration) {
    return 'Durée: $duration';
  }

  @override
  String deleteSlotQuestion(Object timeRange) {
    return 'Êtes-vous sûr de vouloir supprimer ce créneau ?\n$timeRange';
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
