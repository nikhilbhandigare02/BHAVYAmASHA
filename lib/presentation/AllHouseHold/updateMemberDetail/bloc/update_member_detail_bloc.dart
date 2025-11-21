import 'dart:async';
import 'dart:convert';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:medixcel_new/data/Local_Storage/tables/beneficiaries_table.dart';
import 'package:medixcel_new/data/Local_Storage/database_provider.dart';

part 'update_member_detail_event.dart';
part 'update_member_detail_state.dart';

class UpdateMemberDetailBloc
    extends Bloc<UpdateMemberDetailEvent, UpdateMemberDetailState> {
  final DatabaseProvider databaseProvider;

  UpdateMemberDetailBloc({required this.databaseProvider})
      : super(const UpdateMemberDetailState()) {
    // Initialization
    on<UpdateMemberDetailInitialEvent>(_onInitial);
    
    // Basic Information Events
    on<UpdateMemberDetailNameChanged>(_onNameChanged);
    on<UpdateMemberDetailGenderChanged>(_onGenderChanged);
    on<UpdateMemberDetailDobChanged>(_onDobChanged);
    on<UpdateMemberDetailAgeChanged>(_onAgeChanged);
    on<UpdateMemberDetailRelationChanged>(_onRelationChanged);
    on<UpdateMemberDetailFatherNameChanged>(_onFatherNameChanged);
    on<UpdateMemberDetailMotherNameChanged>(_onMotherNameChanged);
    on<UpdateMemberDetailMobileNumberChanged>(_onMobileNumberChanged);
    on<UpdateMemberDetailAadharNumberChanged>(_onAadharNumberChanged);
    on<UpdateMemberDetailMemberTypeChanged>(_onMemberTypeChanged);
    on<UpdateMemberDetailRichIDChanged>(_onRichIDChanged);
    on<UpdateMemberDetailMaritalStatusChanged>(_onMaritalStatusChanged);
    on<UpdateMemberDetailMobileOwnerChanged>(_onMobileOwnerChanged);
    
    // Additional Fields Events
    on<UpdateMemberDetailToggleUseDob>(_onToggleUseDob);
    on<UpdateMemberDetailYearChanged>(_onYearChanged);
    on<UpdateMemberDetailMonthChanged>(_onMonthChanged);
    on<UpdateMemberDetailDayChanged>(_onDayChanged);
    on<UpdateMemberDetailBirthOrderChanged>(_onBirthOrderChanged);
    on<UpdateMemberDetailWeightChanged>(_onWeightChanged);
    on<UpdateMemberDetailCategoryChanged>(_onCategoryChanged);
    on<UpdateMemberDetailAbhaAddressChanged>(_onAbhaAddressChanged);
    on<UpdateMemberDetailBankAccountChanged>(_onBankAccountChanged);
    on<UpdateMemberDetailIfscChanged>(_onIfscChanged);
    on<UpdateMemberDetailOccupationChanged>(_onOccupationChanged);
    on<UpdateMemberDetailEducationChanged>(_onEducationChanged);
    on<UpdateMemberDetailVoterIdChanged>(_onVoterIdChanged);
    on<UpdateMemberDetailRationIdChanged>(_onRationIdChanged);
    on<UpdateMemberDetailPhIdChanged>(_onPhIdChanged);
    on<UpdateMemberDetailBeneficiaryTypeChanged>(_onBeneficiaryTypeChanged);
    on<UpdateMemberDetailAgeAtMarriageChanged>(_onAgeAtMarriageChanged);
    on<UpdateMemberDetailSpouseNameChanged>(_onSpouseNameChanged);
    on<UpdateMemberDetailHasChildrenChanged>(_onHasChildrenChanged);
    on<UpdateMemberDetailIsPregnantChanged>(_onIsPregnantChanged);
    on<UpdateMemberDetailChildrenChanged>(_onChildrenChanged);
    on<UpdateMemberDetailReligionChanged>(_onReligionChanged);
    on<UpdateMemberDetailChildSchoolChanged>(_onChildSchoolChanged);
    on<UpdateMemberDetailBirthCertificateChanged>(_onBirthCertificateChanged);
    
    // Form Submission
    on<UpdateMemberDetailSubmitEvent>(_onSubmit);
  }

  // Event Handlers for Basic Information
  void _onNameChanged(
    UpdateMemberDetailNameChanged event,
    Emitter<UpdateMemberDetailState> emit,
  ) {
    emit(state.copyWith(name: event.name));
  }

  void _onGenderChanged(
    UpdateMemberDetailGenderChanged event,
    Emitter<UpdateMemberDetailState> emit,
  ) {
    emit(state.copyWith(gender: event.gender));
  }

  void _onDobChanged(
    UpdateMemberDetailDobChanged event,
    Emitter<UpdateMemberDetailState> emit,
  ) {
    emit(state.copyWith(dob: event.dob));
  }

  void _onAgeChanged(
    UpdateMemberDetailAgeChanged event,
    Emitter<UpdateMemberDetailState> emit,
  ) {
    emit(state.copyWith(age: event.age));
  }

  void _onRelationChanged(
    UpdateMemberDetailRelationChanged event,
    Emitter<UpdateMemberDetailState> emit,
  ) {
    emit(state.copyWith(relation: event.relation));
  }

  void _onFatherNameChanged(
    UpdateMemberDetailFatherNameChanged event,
    Emitter<UpdateMemberDetailState> emit,
  ) {
    emit(state.copyWith(fatherName: event.fatherName));
  }

  void _onMotherNameChanged(
    UpdateMemberDetailMotherNameChanged event,
    Emitter<UpdateMemberDetailState> emit,
  ) {
    emit(state.copyWith(motherName: event.motherName));
  }

  void _onMobileNumberChanged(
    UpdateMemberDetailMobileNumberChanged event,
    Emitter<UpdateMemberDetailState> emit,
  ) {
    emit(state.copyWith(mobileNumber: event.mobileNumber));
  }

  void _onAadharNumberChanged(
    UpdateMemberDetailAadharNumberChanged event,
    Emitter<UpdateMemberDetailState> emit,
  ) {
    emit(state.copyWith(aadharNumber: event.aadharNumber));
  }

  void _onMemberTypeChanged(
    UpdateMemberDetailMemberTypeChanged event,
    Emitter<UpdateMemberDetailState> emit,
  ) {
    emit(state.copyWith(memberType: event.memberType));
  }

  void _onRichIDChanged(
    UpdateMemberDetailRichIDChanged event,
    Emitter<UpdateMemberDetailState> emit,
  ) {
    emit(state.copyWith(richID: event.richID));
  }

  void _onMaritalStatusChanged(
    UpdateMemberDetailMaritalStatusChanged event,
    Emitter<UpdateMemberDetailState> emit,
  ) {
    emit(state.copyWith(maritalStatus: event.maritalStatus));
  }

  void _onMobileOwnerChanged(
    UpdateMemberDetailMobileOwnerChanged event,
    Emitter<UpdateMemberDetailState> emit,
  ) {
    emit(state.copyWith(mobileOwner: event.mobileOwner));
  }

  // Event Handlers for Additional Fields
  void _onToggleUseDob(
    UpdateMemberDetailToggleUseDob event,
    Emitter<UpdateMemberDetailState> emit,
  ) {
    emit(state.copyWith(useDob: !(state.useDob ?? true)));
  }

  void _onYearChanged(
    UpdateMemberDetailYearChanged event,
    Emitter<UpdateMemberDetailState> emit,
  ) {
    emit(state.copyWith(updateYear: event.year));
  }

  void _onMonthChanged(
    UpdateMemberDetailMonthChanged event,
    Emitter<UpdateMemberDetailState> emit,
  ) {
    emit(state.copyWith(updateMonth: event.month));
  }

  void _onDayChanged(
    UpdateMemberDetailDayChanged event,
    Emitter<UpdateMemberDetailState> emit,
  ) {
    emit(state.copyWith(updateDay: event.day));
  }

  void _onBirthOrderChanged(
    UpdateMemberDetailBirthOrderChanged event,
    Emitter<UpdateMemberDetailState> emit,
  ) {
    emit(state.copyWith(birthOrder: event.birthOrder));
  }

  void _onWeightChanged(
    UpdateMemberDetailWeightChanged event,
    Emitter<UpdateMemberDetailState> emit,
  ) {
    emit(state.copyWith(weight: event.weight));
  }

  void _onCategoryChanged(
    UpdateMemberDetailCategoryChanged event,
    Emitter<UpdateMemberDetailState> emit,
  ) {
    emit(state.copyWith(category: event.category));
  }

  void _onAbhaAddressChanged(
    UpdateMemberDetailAbhaAddressChanged event,
    Emitter<UpdateMemberDetailState> emit,
  ) {
    emit(state.copyWith(abhaAddress: event.abhaAddress));
  }

  void _onBankAccountChanged(
    UpdateMemberDetailBankAccountChanged event,
    Emitter<UpdateMemberDetailState> emit,
  ) {
    emit(state.copyWith(bankAccount: event.bankAccount));
  }

  void _onIfscChanged(
    UpdateMemberDetailIfscChanged event,
    Emitter<UpdateMemberDetailState> emit,
  ) {
    emit(state.copyWith(ifsc: event.ifsc));
  }

  void _onOccupationChanged(
    UpdateMemberDetailOccupationChanged event,
    Emitter<UpdateMemberDetailState> emit,
  ) {
    emit(state.copyWith(occupation: event.occupation));
  }

  void _onEducationChanged(
    UpdateMemberDetailEducationChanged event,
    Emitter<UpdateMemberDetailState> emit,
  ) {
    emit(state.copyWith(education: event.education));
  }

  void _onVoterIdChanged(
    UpdateMemberDetailVoterIdChanged event,
    Emitter<UpdateMemberDetailState> emit,
  ) {
    emit(state.copyWith(voterId: event.voterId));
  }

  void _onRationIdChanged(
    UpdateMemberDetailRationIdChanged event,
    Emitter<UpdateMemberDetailState> emit,
  ) {
    emit(state.copyWith(rationId: event.rationId));
  }

  void _onPhIdChanged(
    UpdateMemberDetailPhIdChanged event,
    Emitter<UpdateMemberDetailState> emit,
  ) {
    emit(state.copyWith(phId: event.phId));
  }

  void _onBeneficiaryTypeChanged(
    UpdateMemberDetailBeneficiaryTypeChanged event,
    Emitter<UpdateMemberDetailState> emit,
  ) {
    emit(state.copyWith(beneficiaryType: event.beneficiaryType));
  }

  void _onAgeAtMarriageChanged(
    UpdateMemberDetailAgeAtMarriageChanged event,
    Emitter<UpdateMemberDetailState> emit,
  ) {
    emit(state.copyWith(ageAtMarriage: event.ageAtMarriage));
  }

  void _onSpouseNameChanged(
    UpdateMemberDetailSpouseNameChanged event,
    Emitter<UpdateMemberDetailState> emit,
  ) {
    emit(state.copyWith(spouseName: event.spouseName));
  }

  void _onHasChildrenChanged(
    UpdateMemberDetailHasChildrenChanged event,
    Emitter<UpdateMemberDetailState> emit,
  ) {
    emit(state.copyWith(hasChildren: event.hasChildren));
  }

  void _onIsPregnantChanged(
    UpdateMemberDetailIsPregnantChanged event,
    Emitter<UpdateMemberDetailState> emit,
  ) {
    emit(state.copyWith(isPregnant: event.isPregnant));
  }

  void _onChildrenChanged(
    UpdateMemberDetailChildrenChanged event,
    Emitter<UpdateMemberDetailState> emit,
  ) {
    emit(state.copyWith(children: event.children));
  }

  void _onReligionChanged(
    UpdateMemberDetailReligionChanged event,
    Emitter<UpdateMemberDetailState> emit,
  ) {
    emit(state.copyWith(religion: event.religion));
  }

  void _onChildSchoolChanged(
    UpdateMemberDetailChildSchoolChanged event,
    Emitter<UpdateMemberDetailState> emit,
  ) {
    emit(state.copyWith(childSchool: event.childSchool));
  }

  void _onBirthCertificateChanged(
    UpdateMemberDetailBirthCertificateChanged event,
    Emitter<UpdateMemberDetailState> emit,
  ) {
    emit(state.copyWith(birthCertificate: event.birthCertificate));
  }

  // Initial Load
  Future<void> _onInitial(
    UpdateMemberDetailInitialEvent event,
    Emitter<UpdateMemberDetailState> emit,
  ) async {
    try {
      // Update state with memberId
      emit(state.copyWith(memberId: event.memberId));
      
      // Load member data from database
      final db = await databaseProvider.database;
      final member = await db.query(
        'beneficiaries_new',
        where: 'id = ?',
        whereArgs: [event.memberId],
      );

      if (member.isNotEmpty) {
        final data = member.first;
        // Parse beneficiary_info if it's a JSON string
        dynamic beneficiaryInfo = data['beneficiary_info'];
        if (beneficiaryInfo is String) {
          try {
            beneficiaryInfo = json.decode(beneficiaryInfo);
          } catch (e) {
            print('Error parsing beneficiary_info: $e');
            beneficiaryInfo = {};
          }
        }
        
        // Get the member data from the appropriate location in the structure
        Map<String, dynamic> memberData = {};
        if (beneficiaryInfo is Map) {
          // Check if this is a head or member
          if (beneficiaryInfo['head_details'] != null) {
            memberData = Map<String, dynamic>.from(beneficiaryInfo['head_details'] ?? {});
          } else if (beneficiaryInfo['member_details'] != null && 
                    beneficiaryInfo['member_details'] is List &&
                    beneficiaryInfo['member_details'].isNotEmpty) {
            // For now, take the first member - you might need to handle multiple members differently
            memberData = Map<String, dynamic>.from(beneficiaryInfo['member_details'][0] ?? {});
          }
        }
        
        // Parse date if it exists
        DateTime? dob;
        if (memberData['dob'] != null) {
          if (memberData['dob'] is DateTime) {
            dob = memberData['dob'];
          } else if (memberData['dob'] is String) {
            dob = DateTime.tryParse(memberData['dob']);
          }
        }
        
        emit(state.copyWith(
          name: memberData['name']?.toString() ?? '',
          gender: memberData['gender']?.toString() ?? '',
          relation: memberData['relation']?.toString() ?? '',
          fatherName: memberData['fatherName']?.toString() ?? '',
          motherName: memberData['motherName']?.toString() ?? '',
          mobileNumber: memberData['mobileNo']?.toString() ?? '',
          aadharNumber: memberData['aadharNumber']?.toString() ?? '',
          dob: dob,
          age: memberData['age']?.toString() ?? (dob != null ? '${DateTime.now().difference(dob).inDays ~/ 365}' : ''),
          memberType: (memberData['memberType']?.toString() == 'Adult' || 
                      memberData['is_adult'] == 1 || 
                      memberData['is_adult'] == true) ? 'Adult' : 'Child',
        ));
      }
    } catch (e) {
      emit(state.copyWith(errorMessage: 'Failed to load member data: $e'));
    }
  }

  Future<void> _onSubmit(
    UpdateMemberDetailSubmitEvent event,
    Emitter<UpdateMemberDetailState> emit,
  ) async {
    emit(state.copyWith(isSubmitting: true, errorMessage: null));
    
    if (state.memberId == null) {
      emit(state.copyWith(
        isSubmitting: false,
        errorMessage: 'Error: Member ID is missing',
      ));
      return;
    }

    try {
      // Validate required fields
      if (state.name.isEmpty ||
          state.gender.isEmpty ||
          state.relation.isEmpty ||
          state.mobileNumber.isEmpty) {
        throw Exception('Please fill all required fields');
      }

      // Prepare member data for update
      final memberData = {
        'name': state.name,
        'gender': state.gender,
        'dob': state.dob?.toIso8601String(),
        'age': state.age,
        'relation': state.relation,
        'fatherName': state.fatherName,
        'motherName': state.motherName,
        'mobileNo': state.mobileNumber,
        'aadharNumber': state.aadharNumber,
        'modified_date_time': DateTime.now().toIso8601String(),
        'is_adult': state.memberType == 'Adult' ? 1 : 0,
      };

      // Get the database instance
      final db = await databaseProvider.database;
      
      if (state.memberId == null) {
        throw Exception('Member ID is required for update');
      }
      
      // First get the existing beneficiary data
      final existingData = await db.query(
        'beneficiaries_new',
        where: 'id = ?',
        whereArgs: [state.memberId],
      );
      
      if (existingData.isEmpty) {
        throw Exception('Member not found');
      }
      
      // Parse the existing beneficiary_info
      dynamic beneficiaryInfo = existingData.first['beneficiary_info'];
      if (beneficiaryInfo is String) {
        try {
          beneficiaryInfo = json.decode(beneficiaryInfo);
        } catch (e) {
          beneficiaryInfo = {};
        }
      }
      
      // Update the appropriate section of the beneficiary_info
      if (beneficiaryInfo is Map) {
        if (beneficiaryInfo['head_details'] != null) {
          // Update head details
          beneficiaryInfo['head_details'] = {
            ...?beneficiaryInfo['head_details'],
            ...memberData,
          };
        } else if (beneficiaryInfo['member_details'] != null && 
                  beneficiaryInfo['member_details'] is List) {
          // Update member details - assuming we're updating the first member
          // You might need to modify this if you need to update a specific member
          final members = List<Map<String, dynamic>>.from(beneficiaryInfo['member_details'] ?? []);
          if (members.isNotEmpty) {
            members[0] = {
              ...members[0],
              ...memberData,
            };
            beneficiaryInfo['member_details'] = members;
          }
        }
      }
      
      // Update the database
      await db.update(
        'beneficiaries_new',
        {
          'beneficiary_info': jsonEncode(beneficiaryInfo),
          'modified_date_time': DateTime.now().toIso8601String(),
          'is_synced': 0, // Mark as unsynced after update
        },
        where: 'id = ?',
        whereArgs: [state.memberId],
      );

      emit(state.copyWith(
        isSubmitting: false,
        isSuccess: true,
      ));
    } catch (e) {
      emit(state.copyWith(
        isSubmitting: false,
        errorMessage: e.toString(),
      ));
    }
  }
}
