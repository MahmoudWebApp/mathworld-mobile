import 'package:easy_localization/easy_localization.dart';

import '../errors/app_exception.dart';

/// Returns a localized user-facing message for any application error.
String localizedErrorMessage(Object error) {
  if (error is AppException) {
    final serverMessage = error.serverMessage?.trim();
    if (serverMessage != null && serverMessage.isNotEmpty) {
      return serverMessage;
    }
    return error.messageKey.tr();
  }

  return 'unexpected_error'.tr();
}
