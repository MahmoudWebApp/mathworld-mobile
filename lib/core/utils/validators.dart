/// Contains reusable validation helpers for authentication forms.
class AppValidators {
  const AppValidators._();

  static final RegExp _emailPattern = RegExp(
    r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$',
  );

  static bool isValidEmail(String value) {
    return _emailPattern.hasMatch(value.trim());
  }
}
