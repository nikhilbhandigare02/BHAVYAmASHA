import 'package:medixcel_new/l10n/app_localizations.dart';

class Validations {
  static String? validateUsername(AppLocalizations l10n, String? username) {
    if (username == null || username.isEmpty) {
      return l10n.usernameEmpty;
    }
    return null; // valid
  }

  static String? validatePassword(AppLocalizations l10n, String? password) {
    if (password == null || password.isEmpty) {
      return l10n.passwordEmpty;
    }

    if (password.length < 6) {
      return l10n.passwordTooShort;
    }

    // Regex for at least one letter, one number, and one special character
    final passwordRegex = RegExp(r'^(?=.*[A-Za-z])(?=.*\d)(?=.*[!@#$%^&*()_+{}\[\]:;<>,.?~\\\/-]).{6,}$');
    if (!passwordRegex.hasMatch(password)) {
      return l10n.passwordComplexity;
    }

    return null; // valid
  }

  static String? validateCurrentPassword(AppLocalizations l10n, String? password) {
    if (password == null || password.isEmpty) {
      return l10n.currentPasswordEmpty;
    }

    if (password.length < 6) {
      return l10n.passwordTooShort;
    }
    return null;
  }

  static String? validateNewPassword(AppLocalizations l10n, String? password) {
    if (password == null || password.isEmpty) {
      return l10n.newPasswordEmpty;
    }

    if (password.length < 6) {
      return l10n.newPasswordTooShort;
    }

    return null; // ✅ Valid
  }

  static String? validateReEnterPassword(AppLocalizations l10n, String? password, String? newPassword) {
    if (password == null || password.isEmpty) {
      return l10n.reenterPasswordEmpty;
    }

    if (password.length < 6) {
      return l10n.reenterPasswordTooShort;
    }

    if (password != newPassword) {
      return l10n.passwordsDoNotMatch;
    }

    return null; // ✅ Valid
  }
}
