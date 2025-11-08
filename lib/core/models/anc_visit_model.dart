class ANCVisitModel {
  final String? id;
  final String? hhId;
  final String? houseNumber;
  final String? womanName;
  final String? gender;
  final String? husbandName;
  final String? rchNumber;
  final String? visitType;
  final bool isHighRisk;
  final DateTime? dateOfInspection;
  final DateTime? eddDate;
  final int? weeksOfPregnancy;
  final double? weight;
  final double? hemoglobin;
  final String? preExistingDisease;
  final bool beneficiaryAbsent;
  final String? registrationDate;
  final String? mobileNumber;
  final String? age;
  final String? dateOfBirth;

  // Getter to extract age from the pre-formatted string (e.g., '23 Y / Female')
  String get formattedAge {
    if (age != null && age!.isNotEmpty) {
      // Extract just the age part (e.g., '23 Y' from '23 Y / Female')
      final agePart = age!.split(' / ').first.trim();
      return agePart;
    }
    return '';
  }

  // Getter to extract gender from the pre-formatted string (e.g., '23 Y / Female')
  String get displayGender {
    if (age != null && age!.contains('/')) {
      // Extract just the gender part (e.g., 'Female' from '23 Y / Female')
      final parts = age!.split('/');
      if (parts.length > 1) {
        return parts[1].trim().isNotEmpty ? parts[1].trim() : 'F';
      }
    }
    // Fallback to gender field if available, otherwise default to 'F'
    return (gender ?? 'F').toUpperCase();
  }

  ANCVisitModel({
    this.id,
    this.hhId,
    this.houseNumber,
    this.womanName,
    this.husbandName,
    this.rchNumber,
    this.gender,
    this.visitType,
    this.isHighRisk = false,
    this.dateOfInspection,
    this.eddDate,
    this.weeksOfPregnancy,
    this.weight,
    this.hemoglobin,
    this.preExistingDisease,
    this.beneficiaryAbsent = false,
    this.registrationDate,
    this.mobileNumber,
    this.age,
    this.dateOfBirth,
  });

  factory ANCVisitModel.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(String? dateString) {
      if (dateString == null) return null;
      
      var date = DateTime.tryParse(dateString);
      if (date != null) return date;
      
      final parts = dateString.split('-');
      if (parts.length == 3) {
        final day = int.tryParse(parts[0]);
        final month = int.tryParse(parts[1]);
        final year = int.tryParse(parts[2]);
        if (day != null && month != null && year != null) {
          return DateTime(year, month, day);
        }
      }
      
      return null;
    }

    return ANCVisitModel(
      id: json['id']?.toString() ?? json['BeneficiaryID']?.toString(),
      hhId: json['hhId']?.toString() ?? json['hhId']?.toString(),
      gender: json['gender']?.toString(),
      houseNumber: json['house_number']?.toString() ?? (json['_rawRow']?['houseNo'] ?? json['houseNo'])?.toString(),
      womanName: json['woman_name']?.toString() ?? json['Name']?.toString(),
      husbandName: json['husband_name']?.toString() ?? json['HusbandName']?.toString(),
      rchNumber: json['rch_number']?.toString() ?? json['RichID']?.toString(),
      visitType: json['visit_type']?.toString() ?? json['RegistrationType']?.toString(),
      isHighRisk: json['high_risk'] == true || 
                 json['high_risk'] == 'true' ||
                 json['_rawRow']?['high_risk'] == true ||
                 json['_rawRow']?['high_risk'] == 'true',
      dateOfInspection: parseDate(json['date_of_inspection']?.toString() ?? json['RegistrationDate']?.toString()),
      registrationDate: json['RegistrationDate']?.toString(),
      mobileNumber: json['mobileno']?.toString(),
      age: json['age']?.toString(),
      dateOfBirth: json['date_of_birth']?.toString(),
      // These fields might not be in the initial data
      eddDate: parseDate(json['edd_date']?.toString()),
      weeksOfPregnancy: json['weeks_of_pregnancy'] != null ? int.tryParse(json['weeks_of_pregnancy'].toString()) : null,
      weight: json['weight'] != null ? double.tryParse(json['weight'].toString()) : null,
      hemoglobin: json['hemoglobin'] != null ? double.tryParse(json['hemoglobin'].toString()) : null,
      preExistingDisease: json['pre_existing_disease']?.toString(),
      beneficiaryAbsent: json['beneficiary_absent'] == true || json['beneficiary_absent'] == 'true',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'hhId': hhId,
      'gender': gender ?? 'F',
      'date_of_birth': dateOfBirth,
      'house_number': houseNumber,
      'woman_name': womanName,
      'husband_name': husbandName,
      'rch_number': rchNumber,
      'visit_type': visitType,
      'high_risk': isHighRisk,
      'date_of_inspection': dateOfInspection?.toIso8601String(),
      'edd_date': eddDate?.toIso8601String(),
      'weeks_of_pregnancy': weeksOfPregnancy,
      'weight': weight,
      'hemoglobin': hemoglobin,
      'pre_existing_disease': preExistingDisease,
      'beneficiary_absent': beneficiaryAbsent,
    };
  }

  
}
