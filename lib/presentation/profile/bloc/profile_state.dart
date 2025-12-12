part of 'profile_bloc.dart';

@immutable
class ProfileState extends Equatable {
  final String areaOfWorking;
  final String ashaId;
  final String ashaName;
  final DateTime? dob;
  final String mobile;
  final String altMobile;
  final String fatherSpouse;
  final DateTime? doj;
  final String accountNumber;
  final String ifsc;
  final String stateName;
  final String division;
  final String district;
  final String block;
  final String panchayat;
  final String village;
  final String tola;
  final String mukhiyaName;
  final String mukhiyaMobile;
  final String hwcName;
  final String hscName;
  final String fruName;
  final String phcChc;
  final String rhSdhDh;
  final String populationCovered;
  final String ashaFacilitatorName;
  final String ashaFacilitatorMobile;
  final String choName;
  final String choMobile;
  final String awwName;
  final String awwMobile;
  final String anganwadiCenterNo;
  final String anm1Name;
  final String anm1Mobile;
  final String anm2Name;
  final String anm2Mobile;
  final String bcmName;
  final String bcmMobile;
  final String dcmName;
  final String dcmMobile;
  final int? appRoleId;
  final int? ashaListCount;
  final bool submitting;
  final bool success;
  final String? error;

  const ProfileState({
    this.areaOfWorking = '',
    this.ashaId = '',
    this.ashaName = '',
    this.dob,
    this.mobile = '',
    this.altMobile = '',
    this.fatherSpouse = '',
    this.doj,
    this.accountNumber = '',
    this.ifsc = '',
    this.stateName = '',
    this.division = '',
    this.district = '',
    this.block = '',
    this.panchayat = '',
    this.village = '',
    this.tola = '',
    this.mukhiyaName = '',
    this.mukhiyaMobile = '',
    this.hwcName = '',
    this.hscName = '',
    this.fruName = '',
    this.phcChc = '',
    this.rhSdhDh = '',
    this.populationCovered = '',
    this.ashaFacilitatorName = '',
    this.ashaFacilitatorMobile = '',
    this.choName = '',
    this.choMobile = '',
    this.awwName = '',
    this.awwMobile = '',
    this.anganwadiCenterNo = '',
    this.anm1Name = '',
    this.anm1Mobile = '',
    this.anm2Name = '',
    this.anm2Mobile = '',
    this.bcmName = '',
    this.bcmMobile = '',
    this.dcmName = '',
    this.dcmMobile = '',
    this.appRoleId,

    this.ashaListCount,
    this.submitting = false,
    this.success = false,
    this.error,
  });

  int get ageYears {
    if (dob == null) return 0;
    final now = DateTime.now();
    int years = now.year - dob!.year;
    final hadBirthday = (now.month > dob!.month) || (now.month == dob!.month && now.day >= dob!.day);
    if (!hadBirthday) years--;
    return years;
  }

  ProfileState copyWith({
    String? areaOfWorking,
    String? ashaId,
    String? ashaName,
    DateTime? dob,
    bool dobClear = false,
    String? mobile,
    String? altMobile,
    String? fatherSpouse,
    DateTime? doj,
    bool dojClear = false,
    String? accountNumber,
    String? ifsc,
    String? stateName,
    String? division,
    String? district,
    String? block,
    String? panchayat,
    String? village,
    String? tola,
    String? mukhiyaName,
    String? mukhiyaMobile,
    String? hwcName,
    String? hscName,
    String? fruName,
    String? phcChc,
    String? rhSdhDh,
    String? populationCovered,
    String? ashaFacilitatorName,
    String? ashaFacilitatorMobile,
    String? choName,
    String? choMobile,
    String? awwName,
    String? awwMobile,
    String? anganwadiCenterNo,
    String? anm1Name,
    String? anm1Mobile,
    String? anm2Name,
    String? anm2Mobile,
    String? bcmName,
    String? bcmMobile,
    String? dcmName,
    String? dcmMobile,
    bool? submitting,
    int? appRoleId,
    int? ashaListCount,
    bool? success,
    String? error,
  }) {
    return ProfileState(
      areaOfWorking: areaOfWorking ?? this.areaOfWorking,
      ashaId: ashaId ?? this.ashaId,
      ashaName: ashaName ?? this.ashaName,
      dob: dobClear ? null : (dob ?? this.dob),
      mobile: mobile ?? this.mobile,
      altMobile: altMobile ?? this.altMobile,
      fatherSpouse: fatherSpouse ?? this.fatherSpouse,
      doj: dojClear ? null : (doj ?? this.doj),
      accountNumber: accountNumber ?? this.accountNumber,
      ifsc: ifsc ?? this.ifsc,
      stateName: stateName ?? this.stateName,
      division: division ?? this.division,
      district: district ?? this.district,
      block: block ?? this.block,
      panchayat: panchayat ?? this.panchayat,
      village: village ?? this.village,
      tola: tola ?? this.tola,
      mukhiyaName: mukhiyaName ?? this.mukhiyaName,
      mukhiyaMobile: mukhiyaMobile ?? this.mukhiyaMobile,
      hwcName: hwcName ?? this.hwcName,
      hscName: hscName ?? this.hscName,
      fruName: fruName ?? this.fruName,
      phcChc: phcChc ?? this.phcChc,
      rhSdhDh: rhSdhDh ?? this.rhSdhDh,
      populationCovered: populationCovered ?? this.populationCovered,
      ashaFacilitatorName: ashaFacilitatorName ?? this.ashaFacilitatorName,
      ashaFacilitatorMobile: ashaFacilitatorMobile ?? this.ashaFacilitatorMobile,
      choName: choName ?? this.choName,
      choMobile: choMobile ?? this.choMobile,
      awwName: awwName ?? this.awwName,
      awwMobile: awwMobile ?? this.awwMobile,
      anganwadiCenterNo: anganwadiCenterNo ?? this.anganwadiCenterNo,
      anm1Name: anm1Name ?? this.anm1Name,
      anm1Mobile: anm1Mobile ?? this.anm1Mobile,
      anm2Name: anm2Name ?? this.anm2Name,
      anm2Mobile: anm2Mobile ?? this.anm2Mobile,
      bcmName: bcmName ?? this.bcmName,
      bcmMobile: bcmMobile ?? this.bcmMobile,
      dcmName: dcmName ?? this.dcmName,
      dcmMobile: dcmMobile ?? this.dcmMobile,
      appRoleId: appRoleId ?? this.appRoleId,
      ashaListCount: ashaListCount ?? this.ashaListCount,
      submitting: submitting ?? this.submitting,
      success: success ?? this.success,
      error: error,
    );
  }

  @override
  List<Object?> get props => [
    areaOfWorking,
    ashaId,
    ashaName,
    dob,
    mobile,
    altMobile,
    fatherSpouse,
    doj,
    accountNumber,
    ifsc,
    stateName,
    appRoleId,
    ashaListCount,
    division,
    district,
    block,
    panchayat,
    village,
    tola,
    mukhiyaName,
    mukhiyaMobile,
    hwcName,
    hscName,
    fruName,
    phcChc,
    rhSdhDh,
    populationCovered,
    ashaFacilitatorName,
    ashaFacilitatorMobile,
    choName,
    choMobile,
    awwName,
    awwMobile,
    anganwadiCenterNo,
    anm1Name,
    anm1Mobile,
    anm2Name,
    anm2Mobile,
    bcmName,
    bcmMobile,
    dcmName,
    dcmMobile,

    submitting,
    success,
    error,
  ];
}
