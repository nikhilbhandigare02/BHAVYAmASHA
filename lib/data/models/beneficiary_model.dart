import 'dart:convert';

class BeneficiaryModel {
  final String? hhId;
  final String? name;
  final String? gender;
  final String? mobile;
  final String? rchId;
  final String? fatherName;
  final String? motherName;
  final String? dateOfBirth;
  final String? religion;
  final String? socialClass;
  final String? uniqueKey;

  BeneficiaryModel({
    this.hhId,
    this.name,
    this.gender,
    this.mobile,
    this.rchId,
    this.fatherName,
    this.motherName,
    this.dateOfBirth,
    this.religion,
    this.socialClass,
    this.uniqueKey,
  });

  factory BeneficiaryModel.fromJson(Map<String, dynamic> json) {
    final head = json['head_details'] ?? {};
    final memberDetails = json['member_details'] as List<dynamic>? ?? [];
    
    return BeneficiaryModel(
      hhId: head['houseNo']?.toString(),
      name: head['headName']?.toString(),
      gender: head['gender']?.toString(),
      mobile: head['mobileNo']?.toString(),
      fatherName: head['fatherName']?.toString(),
      dateOfBirth: head['dob']?.toString(),
      religion: head['religion']?.toString(),
      socialClass: head['category']?.toString(),
      uniqueKey: json['unique_key']?.toString(),
    );
  }

  static BeneficiaryModel? fromMemberJson(Map<String, dynamic> member, Map<String, dynamic> head) {
    try {
      return BeneficiaryModel(
        name: member['memberName']?.toString(),
        gender: member['gender']?.toString(),
        mobile: member['mobileNo']?.toString(),
        fatherName: member['fatherName']?.toString(),
        motherName: head['headName']?.toString(), // Assuming head is the mother
        dateOfBirth: member['dob']?.toString(),
        religion: member['religion']?.toString(),
        socialClass: member['category']?.toString(),
        uniqueKey: member['unique_key']?.toString(),
      );
    } catch (e) {
      print('Error parsing member data: $e');
      return null;
    }
  }

  Map<String, dynamic> toJson() => {
        'hhId': hhId,
        'name': name,
        'gender': gender,
        'mobile': mobile,
        'rchId': rchId,
        'fatherName': fatherName,
        'motherName': motherName,
        'dateOfBirth': dateOfBirth,
        'religion': religion,
        'socialClass': socialClass,
        'uniqueKey': uniqueKey,
      };

  @override
  String toString() => 'BeneficiaryModel(${toJson()})';
}
