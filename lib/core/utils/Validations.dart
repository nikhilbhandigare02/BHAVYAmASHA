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


  static String? validateYoungestChildAge(AppLocalizations l10n, String? rawAge, String? unit) {
    final raw = (rawAge ?? '').trim();
    if (raw.isEmpty) return null;

    final value = int.tryParse(raw);
    if (value == null) {
      return l10n.enterValidNumber;
    }
    if (unit == null || unit.isEmpty) {
      return l10n.selectAgeUnit;
    }

    if (unit == l10n.days) {
      if (value < 1 || value > 30) {
        return '${l10n.youngestChildAgeDaysRange} ${l10n.days}: 1 day to 30 days';
      }
    } else if (unit == l10n.months) {
      if (value < 1 || value > 11) {
        return '${l10n.youngestChildAgeMonthsRange} ${l10n.months}: 1 month to 11 months';
      }
    } else if (unit == l10n.years) {
      if (value < 1 || value > 90) {
        return '${l10n.youngestChildAgeYearsRange} ${l10n.years}: 1 year to 90 years';
      }
    }
    return null;
  }
  static String? validateHouseNo(AppLocalizations l10n, String? houseNo) {
    if (houseNo == null || houseNo.isEmpty) {
      return l10n.enterHouseNumber;
    }

    // Allow only letters, numbers, space, dash, and slash
    final regex = RegExp(r'^[a-zA-Z0-9\s\-\/]+$');
    if (!regex.hasMatch(houseNo)) {
      return l10n.houseNumberValidation;
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

    return null;
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

  static String? validateDOB(AppLocalizations l10n, DateTime? dob) {
    if (dob == null) {
      return l10n.pleaseEnterDateOfBirth;
    }

    final today = DateTime.now();
    final dobDate = DateTime(dob.year, dob.month, dob.day);
    final todayDate = DateTime(today.year, today.month, today.day);

    if (dobDate.isAfter(todayDate)) {
      return l10n.dateOfBirthFuture;
    }

    int years = today.year - dob.year;
    int months = today.month - dob.month;
    int days = today.day - dob.day;

    if (months < 0 || (months == 0 && days < 0)) {
      years--;
      months += 12;
      if (days < 0) {
        months--;
        final lastMonth = today.month == 1 ? 12 : today.month - 1;
        final lastYear = today.month == 1 ? today.year - 1 : today.year;
        final daysInLastMonth = DateTime(lastYear, lastMonth + 1, 0).day;
        days += daysInLastMonth;
      }
    }

    // Check if age is exactly 15 years or more
    if (years < 15 || (years == 15 && (months < 0 || (months == 0 && days < 0)))) {
      return l10n.pleaseEnterAgeBetween15To110;
    }

    // Check maximum age (110 years)
    if (years > 110 || (years == 110 && (months > 0 || days > 0))) {
      return l10n.pleaseEnterAgeBetween15To110;
    }

    return null; // ✅ valid
  }
  static String? validateApproxAge(AppLocalizations l10n, String? years, String? months, String? days) {
    const int minAgeYears = 15;
    const int maxAgeYears = 110;
    const int maxMonths = 11;
    const int maxDays = 30;

    // Check if all fields are empty
    if ((years?.trim().isEmpty ?? true) &&
        (months?.trim().isEmpty ?? true) &&
        (days?.trim().isEmpty ?? true)) {
      return l10n.pleaseEnterAgeBetween15To110;
    }

    final y = int.tryParse((years ?? '').trim()) ?? 0;
    final m = int.tryParse((months ?? '').trim()) ?? 0;
    final d = int.tryParse((days ?? '').trim()) ?? 0;

    if (y < 15 || y > 110) {
      return l10n.pleaseEnterAgeBetween15To110;
    }
    if (m < 0 || m > maxMonths) {
      return l10n.pleaseEnterAgeBetween15To110;
    }
    if (d < 0 || d > maxDays) {
      return l10n.pleaseEnterAgeBetween15To110;
    }

    // Check if all zeros
    if (y == 0 && m == 0 && d == 0) {
      return l10n.pleaseEnterDateOfBirth;
    }

    // Calculate total years for range check
    final totalYears = y + (m / 12.0) + (d / 365.0);

    if (totalYears < minAgeYears) {
      return l10n.pleaseEnterAgeBetween15To110;
    }

    if (totalYears > maxAgeYears) {
      return l10n.pleaseEnterAgeBetween15To110;
    }

    return null;
  }

  static String? validateApproxAgeChild(AppLocalizations l10n, String? years, String? months, String? days) {
    const double minAgeYears = 1.0 / 365.0;
    const int maxAgeYears = 15;

    final y = int.tryParse((years ?? '').trim());
    final m = int.tryParse((months ?? '').trim());
    final d = int.tryParse((days ?? '').trim());

    final yy = y ?? 0;
    final mm = m ?? 0;
    final dd = d ?? 0;

    if (yy == 0 && mm == 0 && dd == 0) {
      return l10n.pleaseEnterAgeBetween1DayTo15Year;
    }

    final totalYears = yy + (mm / 12.0) + (dd / 365.0);

    if (totalYears < minAgeYears || totalYears > maxAgeYears) {
      return l10n.pleaseEnterAgeBetween1DayTo15Year;;
    }

    return null;
  }
  static String? validateLMP(AppLocalizations l10n, DateTime? dob) {
    if (dob == null) {
      return l10n.pleaseEnterLMP;
    }
    return null;
  }

  static String? validateAntra(AppLocalizations l10n, String? antra) {
    if (antra == null || antra.trim().isEmpty || antra == 'Select') {
      return l10n.pleaseEnterMethodOfContraception;
    }
    return null;
  }
  static String? validateEDD(AppLocalizations l10n, DateTime? dob) {
    if (dob == null) {
      return l10n.pleaseEnterExpectedDeliveryDate;
    }



    return null; // ✅ valid
  }
  static String? validateAdoptingPlan(AppLocalizations l10n, String? dob) {
    if (dob == null || dob.trim().isEmpty || dob == 'Select') {
      return l10n.pleaseEnterFamilyPlanning;
    }

    return null; // ✅ valid
  }

  static String? validateGender(AppLocalizations l10n, String? gender) {
    if (gender == null || gender.isEmpty) {
      return l10n.pleaseEnterGender;
    }

    return null;
  }
  static String? validateWhoMobileNo(AppLocalizations l10n, String? mobileNo) {
    if (mobileNo == null || mobileNo.isEmpty) {
      return l10n.pleaseEnterWhoseMobile;
    }

    return null;
  }
  static String? validateMobileNo(AppLocalizations l10n, String? mobileNo) {
    if (mobileNo == null || mobileNo.isEmpty) {
      return l10n.pleaseEnterMobileNo;
    }

    final regex = RegExp(r'^[6-9]\d{9}$');
    if (!regex.hasMatch(mobileNo)) {
      return l10n.mobileNo10DigitsStart6To9;
    }

    return null; // ✅ valid
  }

  static String? validateMaritalStatus(AppLocalizations l10n, String? maritalStatus) {
    if (maritalStatus == null || maritalStatus.isEmpty) {
      return l10n.pleaseEnterMaritalStatus;
    }

    return null;
  }
  static String? validateFamilyHead(AppLocalizations l10n, String? familyHead) {
    if (familyHead == null || familyHead.isEmpty) {
      return l10n.pleaseEnterFamilyHead;
    }

    // Only letters and spaces allowed between words
    final regex = RegExp(r'^[a-zA-Z\s]+$');
    if (!regex.hasMatch(familyHead)) {
      return l10n.familyHeadLettersOnly;
    }

    return null;
  }

  static String? validateFamilyHeadRelation(AppLocalizations l10n, String? familyHead) {
    if (familyHead == null || familyHead.isEmpty) {
      return l10n.enter_relation_with_family_head;
    }


    return null;
  }


  static String? validateSpousName(AppLocalizations l10n, String? spousName) {
    if (spousName == null || spousName.isEmpty) {
      return l10n.pleaseEnterSpouseName;
    }

    return null;
  }

  static String? validateIsPregnant(AppLocalizations l10n, String? isPregnant) {
    if (isPregnant == null || isPregnant.isEmpty) {
      return l10n.pleaseEnterIsWomanPregnant;
    }

    return null;
  }
  static String? validateRelationWithHead(AppLocalizations l10n, String? relation) {
    if (relation == null || relation.isEmpty) {
      return l10n.enter_relation_with_family_head;
    }

    return null;
  }
  static String? validateNameofMember(AppLocalizations l10n, String? name) {
    if (name == null || name.isEmpty) {
      return l10n.pleaseEnterNameOfMember;
    }

    return null;
  }

  static String? validateMemberType(AppLocalizations l10n, String? memberType) {
    if (memberType == null || memberType.isEmpty) {
      return l10n.pleaseEnterMemberType;
    }
    if (!['Adult', 'Child'].contains(memberType)) {
      return l10n.invalidMemberType;
    }
    return null;
  }

  static String? validateBankAccountNumber(AppLocalizations l10n, String? accountNumber) {
    if (accountNumber == null || accountNumber.trim().isEmpty) {
      return null;
    }

    final digitsOnly = accountNumber.replaceAll(RegExp(r'[^0-9]'), '');

    if (digitsOnly.length < 10) {
      return l10n.accountNumberAtLeast10Digits;
    }
    return null;
  }
}
