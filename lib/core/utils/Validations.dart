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
  
  // Youngest child age validation used in Children details and Head submit.
  // rawAge is the numeric string, unit is one of l10n.days / l10n.months / l10n.years.
  static String? validateYoungestChildAge(AppLocalizations l10n, String? rawAge, String? unit) {
    final raw = (rawAge ?? '').trim();
    if (raw.isEmpty) return null;

    final value = int.tryParse(raw);
    if (value == null) {
      return 'Enter valid number';
    }
    if (unit == null || unit.isEmpty) {
      return 'Select age unit';
    }

    if (unit == l10n.days) {
      if (value < 1 || value > 30) {
        return 'Please enter age of Youngest Child between ${l10n.days}: 1 day to 30 days';
      }
    } else if (unit == l10n.months) {
      if (value < 1 || value > 11) {
        return 'Please enter age of Youngest Child between ${l10n.months}: 1 month to 11 months';
      }
    } else if (unit == l10n.years) {
      if (value < 1 || value > 90) {
        return 'Please enter age of Youngest Child between ${l10n.years}: 1 year to 90 years';
      }
    }
    return null;
  }
  static String? validateHouseNo(AppLocalizations l10n, String? houseNo) {
    if (houseNo == null || houseNo.isEmpty) {
      return 'House number is required';
    }

    // Allow only letters, numbers, space, dash, and slash
    final regex = RegExp(r'^[a-zA-Z0-9\s\-\/]+$');
    if (!regex.hasMatch(houseNo)) {
      return 'House number can only contain letters, numbers, spaces, dash or slash';
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

  static String? validateDOB(AppLocalizations l10n, DateTime? dob) {
    if (dob == null) {
      return 'Date of birth is required';
    }

    final today = DateTime.now();
    final dobDate = DateTime(dob.year, dob.month, dob.day);
    final todayDate = DateTime(today.year, today.month, today.day);

    if (dobDate.isAfter(todayDate)) {
      return 'Date of birth cannot be in the future';
    }

    int years = today.year - dob.year;
    int months = today.month - dob.month;
    int days = today.day - dob.day;

    if (months < 0 || (months == 0 && days < 0)) {
      years--;
      months += 12;
      if (days < 0) {
        months--;
        // Get the number of days in the previous month
        final lastMonth = today.month == 1 ? 12 : today.month - 1;
        final lastYear = today.month == 1 ? today.year - 1 : today.year;
        final daysInLastMonth = DateTime(lastYear, lastMonth + 1, 0).day;
        days += daysInLastMonth;
      }
    }

    // Check if age is exactly 15 years or more
    if (years < 15 || (years == 15 && (months < 0 || (months == 0 && days < 0)))) {
      return 'Age must be 15 years or more';
    }

    // Check maximum age (110 years)
    if (years > 110 || (years == 110 && (months > 0 || days > 0))) {
      return 'Age cannot be more than 110 years';
    }

    return null; // ✅ valid
  }
  static String? validateApproxAge(AppLocalizations l10n, String? years, String? months, String? days) {
    const int minAgeYears = 15;
    const int maxAgeYears = 110;
    const int maxMonths = 11;
    const int maxDays = 30; // Using 30 as an average month length for validation

    // Check if all fields are empty
    if ((years?.trim().isEmpty ?? true) && 
        (months?.trim().isEmpty ?? true) && 
        (days?.trim().isEmpty ?? true)) {
      return 'Please enter age between 15 to 110 years';
    }

    // Parse values, defaulting to 0 if empty or invalid
    final y = int.tryParse((years ?? '').trim()) ?? 0;
    final m = int.tryParse((months ?? '').trim()) ?? 0;
    final d = int.tryParse((days ?? '').trim()) ?? 0;

    // Validate individual fields
    if (y < 0 || y > 110) {
      return 'Years must be between 0 and 110';
    }
    if (m < 0 || m > maxMonths) {
      return 'Months must be between 0 and 11';
    }
    if (d < 0 || d > maxDays) {
      return 'Days must be between 0 and 30';
    }

    // Check if all zeros
    if (y == 0 && m == 0 && d == 0) {
      return 'Age cannot be zero';
    }

    // Calculate total years for range check
    final totalYears = y + (m / 12.0) + (d / 365.0);

    if (totalYears < minAgeYears) {
      return 'Minimum age must be $minAgeYears years';
    }
    
    if (totalYears > maxAgeYears) {
      return 'Maximum age is $maxAgeYears years';
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
      return 'Please enter the age between 1 day to 15 year';
    }

    final totalYears = yy + (mm / 12.0) + (dd / 365.0);

    if (totalYears < minAgeYears || totalYears > maxAgeYears) {
      return 'Please enter the age between 1 day to 15 year';
    }

    return null;
  }
  static String? validateLMP(AppLocalizations l10n, DateTime? dob) {
    if (dob == null) {
      return 'LMP is required'; // or l10n.dobRequired
    }



    return null; // ✅ valid
  }
  static String? validateAntra(AppLocalizations l10n, String? antra) {
    if (antra == null || antra.trim().isEmpty || antra == 'Select') {
      return 'Method of contraception is required';
    }

    return null;
  }
  static String? validateEDD(AppLocalizations l10n, DateTime? dob) {
    if (dob == null) {
      return 'Expected Delivery Date is required';
    }



    return null; // ✅ valid
  }
  static String? validateAdoptingPlan(AppLocalizations l10n, String? dob) {
    if (dob == null || dob.trim().isEmpty || dob == 'Select') {
      return 'Are you/your partner adopting family planning is required';
    }

    return null; // ✅ valid
  }

  static String? validateGender(AppLocalizations l10n, String? gender) {
    if (gender == null || gender.isEmpty) {
      return 'Gender is required';
    }

    return null;
  }
  static String? validateWhoMobileNo(AppLocalizations l10n, String? mobileNo) {
    if (mobileNo == null || mobileNo.isEmpty) {
      return 'Whose mobile is required';
    }

    return null;
  }
  static String? validateMobileNo(AppLocalizations l10n, String? mobileNo) {
    if (mobileNo == null || mobileNo.isEmpty) {
      return 'Mobile no. is required';
    }

    final regex = RegExp(r'^[6-9]\d{9}$');
    if (!regex.hasMatch(mobileNo)) {
      return 'Mobile no. must be 10 digits and start with 6-9';
    }

    return null; // ✅ valid
  }

  static String? validateMaritalStatus(AppLocalizations l10n, String? maritalStatus) {
    if (maritalStatus == null || maritalStatus.isEmpty) {
      return 'Marital Status is required';
    }

    return null;
  }
  static String? validateFamilyHead(AppLocalizations l10n, String? familyHead) {
    if (familyHead == null || familyHead.isEmpty) {
      return 'Family Head is required';
    }

    // Only letters and spaces allowed between words
    final regex = RegExp(r'^[a-zA-Z\s]+$');
    if (!regex.hasMatch(familyHead)) {
      return 'Family Head can only contain letters';
    }

    return null;
  }

  static String? validateFamilyHeadRelation(AppLocalizations l10n, String? familyHead) {
    if (familyHead == null || familyHead.isEmpty) {
      return 'Relation with family head is required';
    }


    return null;
  }


  static String? validateSpousName(AppLocalizations l10n, String? spousName) {
    if (spousName == null || spousName.isEmpty) {
      return 'FSpous Name is required';
    }

    return null;
  }
  static String? validateIsPregnant(AppLocalizations l10n, String? isPregnant) {
    if (isPregnant == null || isPregnant.isEmpty) {
      return 'Is Woman Pregnant is required';
    }

    return null;
  }
  static String? validateRelationWithHead(AppLocalizations l10n, String? relation) {
    if (relation == null || relation.isEmpty) {
      return 'Relation head is required';
    }

    return null;
  }
  static String? validateNameofMember(AppLocalizations l10n, String? name) {
    if (name == null || name.isEmpty) {
      return 'Name of Member is required';
    }

    return null;
  }

  static String? validateMemberType(AppLocalizations l10n, String? memberType) {
    if (memberType == null || memberType.isEmpty) {
      return 'Member type is required';
    }
    if (!['Adult', 'Child'].contains(memberType)) {
      return 'Invalid member type';
    }
    return null;
  }

  static String? validateBankAccountNumber(AppLocalizations l10n, String? accountNumber) {
    // If the field is empty, it's valid (not required)
    if (accountNumber == null || accountNumber.trim().isEmpty) {
      return null;
    }

    // Remove any non-digit characters
    final digitsOnly = accountNumber.replaceAll(RegExp(r'[^0-9]'), '');
    
    // If something is entered, it must be at least 10 digits
    if (digitsOnly.length < 10) {
      return 'Account number must be at least 10 digits';
    }

    return null;
  }



}
