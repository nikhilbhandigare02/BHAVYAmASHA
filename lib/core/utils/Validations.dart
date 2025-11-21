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
      return 'Date of birth is required'; // or l10n.dobRequired
    }

    final today = DateTime.now();
    final dobDate = DateTime(dob.year, dob.month, dob.day);
    final todayDate = DateTime(today.year, today.month, today.day);

    if (dobDate.isAfter(todayDate)) {
      return 'Date of birth cannot be in the future';
    }

    int age = today.year - dob.year;
    if (today.month < dob.month || (today.month == dob.month && today.day < dob.day)) {
      age--;
    }

    if (age < 15 || age > 110) {
      return 'Age must be between 15 and 110 years';
    }

    return null; // ✅ valid
  }
  static String? validateLMP(AppLocalizations l10n, DateTime? dob) {
    if (dob == null) {
      return 'LMP is required'; // or l10n.dobRequired
    }



    return null; // ✅ valid
  }
  static String? validateEDD(AppLocalizations l10n, DateTime? dob) {
    if (dob == null) {
      return 'Expected Delivery Date is required';
    }



    return null; // ✅ valid
  }
  static String? validateAdoptingPlan(AppLocalizations l10n, String? dob) {
    if (dob == null) {
      return 'family adopting planning is required';
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
