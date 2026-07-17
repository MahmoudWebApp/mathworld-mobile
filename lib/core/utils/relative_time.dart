import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';

/// Represents a translation key and its named arguments for relative time.
class RelativeTimeValue {
  final String key;
  final Map<String, String> namedArgs;

  const RelativeTimeValue(this.key, [this.namedArgs = const {}]);
}

/// Calculates the appropriate relative-time translation value.
RelativeTimeValue relativeTimeValue(
  DateTime dateTime, {
  DateTime? now,
}) {
  final localDate = dateTime.toLocal();
  final reference = (now ?? DateTime.now()).toLocal();
  final difference = reference.difference(localDate);

  if (difference.isNegative || difference.inMinutes < 1) {
    return const RelativeTimeValue('just_now');
  }
  if (difference.inHours < 1) {
    return RelativeTimeValue(
      'minutes_ago',
      {'minutes': '${difference.inMinutes}'},
    );
  }
  if (difference.inDays < 1) {
    return RelativeTimeValue(
      'hours_ago',
      {'hours': '${difference.inHours}'},
    );
  }
  if (difference.inDays < 7) {
    return RelativeTimeValue(
      'days_ago',
      {'days': '${difference.inDays}'},
    );
  }

  return const RelativeTimeValue('absolute_date');
}

/// Formats a date using relative time for recent values and a localized date otherwise.
String formatLocalizedDateTime(BuildContext context, DateTime? dateTime) {
  if (dateTime == null) {
    return '';
  }

  final value = relativeTimeValue(dateTime);
  if (value.key != 'absolute_date') {
    return value.key.tr(namedArgs: value.namedArgs);
  }

  return DateFormat.yMMMd(context.locale.toLanguageTag()).format(
    dateTime.toLocal(),
  );
}
