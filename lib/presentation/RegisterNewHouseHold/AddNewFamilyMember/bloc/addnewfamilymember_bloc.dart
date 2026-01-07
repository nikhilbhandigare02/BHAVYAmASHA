import 'dart:convert';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:meta/meta.dart';
import 'package:sqflite/sqflite.dart' show ConflictAlgorithm;
import '../../../../core/utils/device_info_utils.dart';
import '../../../../core/utils/enums.dart';
import '../../../../core/utils/geolocation_utils.dart';
import '../../../../core/utils/id_generator_utils.dart';
import '../../../../data/Database/User_Info.dart';
import '../../../../data/Database/database_provider.dart';
import '../../../../data/Database/local_storage_dao.dart';
import '../../../../data/repositories/AddBeneficiary/AddBeneficiaryRepository.dart';
import '../../AddFamilyHead/Children_Details/bloc/children_bloc.dart' show ChildrenBloc;
import '../../AddFamilyHead/SpousDetails/bloc/spous_bloc.dart';
import '../../RegisterNewHouseHold/bloc/registernewhousehold_bloc.dart';

part 'addnewfamilymember_event.dart';
part 'addnewfamilymember_state.dart';

class AddnewfamilymemberBloc
    extends Bloc<AddnewfamilymemberEvent, AddnewfamilymemberState> {
  final RegisterNewHouseholdBloc? householdBloc;
  final LocalStorageDao _localStorageDao = LocalStorageDao();

  int _daysInMonth(int year, int month) {
    if (month == 12) {
      return DateTime(year + 1, 1, 0).day;
    }
    return DateTime(year, month + 1, 0).day;
  }

  Map<String, int> _agePartsFromDob(DateTime dob) {
    final today = DateTime.now();
    int years = today.year - dob.year;
    int months = today.month - dob.month;
    int days = today.day - dob.day;

    if (days < 0) {
      months -= 1;
      final prevMonth = today.month == 1 ? 12 : today.month - 1;
      final prevYear = prevMonth == 12 ? today.year - 1 : today.year;
      days += _daysInMonth(prevYear, prevMonth);
    }

    if (months < 0) {
      years -= 1;
      months += 12;
    }

    if (years < 0) {
      years = 0;
      months = 0;
      days = 0;
    }

    return {
      'years': years,
      'months': months,
      'days': days,
    };
  }

  DateTime? _dobFromAgeParts(int years, int months, int days) {
    if (years < 0 || months < 0 || days < 0) return null;
    if (years == 0 && months == 0 && days == 0) return null;

    final today = DateTime.now();
    int y = today.year - years;
    int m = today.month - months;
    int d = today.day - days;

    while (d <= 0) {
      m -= 1;
      if (m <= 0) {
        m += 12;
        y -= 1;
      }
      d += _daysInMonth(y, m);
    }

    while (m <= 0) {
      m += 12;
      y -= 1;
    }

    if (y < 1900) {
      y = 1900;
    }

    return DateTime(y, m, d);
  }

  // Keep track of the beneficiary being edited (for update flow)
  String? _editingBeneficiaryKey;
  int? _editingBeneficiaryRowId;
  bool _dataClearedByTypeChange = false;

  Future<void> _onLoadBeneficiaryData(
      LoadBeneficiaryData event,
      Emitter<AddnewfamilymemberState> emit,
      ) async {
    try {
      print('📥 [Bloc] Loading beneficiary data: ${event.beneficiaryId}');
      print('📥 [Bloc] Data cleared flag: $_dataClearedByTypeChange');
      
      // If data was cleared by type change, don't reload beneficiary data
      if (_dataClearedByTypeChange) {
        print('📥 [Bloc] Skipping beneficiary data load due to type change clear');
        return;
      }
      
      // Get the complete beneficiary record
      final db = await DatabaseProvider.instance.database;
      final List<Map<String, dynamic>> results = await db.query(
        'beneficiaries_new',
        where: 'unique_key = ?',
        whereArgs: [event.beneficiaryId],
      );

      if (results.isNotEmpty) {
        final beneficiary = results.first;

        // Remember which row is being edited so that we can update it later
        _editingBeneficiaryRowId = beneficiary['id'] as int?;
        _editingBeneficiaryKey = beneficiary['unique_key']?.toString();
        
        print('=== Loaded Beneficiary for Editing ===');
        print('Row ID: $_editingBeneficiaryRowId');
        print('Unique Key: $_editingBeneficiaryKey');
        final beneficiaryInfo = jsonDecode(beneficiary['beneficiary_info'] as String? ?? '{}');

        // Create a map to hold all the data
        final Map<String, dynamic> allData = {
          // Basic info
          'id': beneficiary['id'],
          'server_id': beneficiary['server_id'],
          'household_ref_key': beneficiary['household_ref_key'],
          'unique_key': beneficiary['unique_key'],
          'beneficiary_state': beneficiary['beneficiary_state'],
          'pregnancy_count': beneficiary['pregnancy_count'],

          // JSON data from beneficiary_info
          ...beneficiaryInfo,

          // Other fields
          'geo_location': beneficiary['geo_location'],
          'spouse_key': beneficiary['spouse_key'],
          'mother_key': beneficiary['mother_key'],
          'father_key': beneficiary['father_key'],
          'is_family_planning': beneficiary['is_family_planning'] == 1,
          'is_adult': beneficiary['is_adult'] == 1,
          'is_guest': beneficiary['is_guest'] == 1,
          'is_death': beneficiary['is_death'] == 1,
          'death_details': beneficiary['death_details'],
          'is_migrated': beneficiary['is_migrated'] == 1,
          'is_separated': beneficiary['is_separated'] == 1,
          'device_details': beneficiary['device_details'],
          'app_details': beneficiary['app_details'],
          'parent_user': beneficiary['parent_user'],
          'current_user_key': beneficiary['current_user_key'],
          'facility_id': beneficiary['facility_id'],
          'created_date_time': beneficiary['created_date_time'],
          'modified_date_time': beneficiary['modified_date_time'],
          'is_synced': beneficiary['is_synced'] == 1,
          'is_deleted': beneficiary['is_deleted'] == 1,
        };

        // Derive primary name from available fields
        final String? primaryName =
            (allData['name'] as String?) ??
            (allData['memberName'] as String?) ??
            (allData['headName'] as String?);

        // Derive relation from either 'relation' or legacy 'relation_to_head'
        final String? rawRelation =
            (allData['relation'] as String?) ??
            (allData['relation_to_head'] as String?);
        String? primaryRelation;
        if (rawRelation != null) {
          final r = rawRelation.toString();
          final rl = r.toLowerCase();
          if (rl == 'self' || rl == 'head') {
            primaryRelation = 'Self';
          } else {
            primaryRelation = r;
          }
        }

        // If this beneficiary is actually the head of its household,
        // force relation to 'self' regardless of stored relation value.
        try {
          final String hhRef = beneficiary['household_ref_key']?.toString() ?? '';
          final String benKey = beneficiary['unique_key']?.toString() ?? '';
          if (hhRef.isNotEmpty && benKey.isNotEmpty) {
            final hhRows = await db.query(
              'households',
              where: 'unique_key = ?',
              whereArgs: [hhRef],
              limit: 1,
            );
            if (hhRows.isNotEmpty) {
              final headId = hhRows.first['head_id']?.toString() ?? '';
              if (headId.isNotEmpty && headId == benKey) {
                primaryRelation = 'Self';
              }
            }
          }
        } catch (_) {}

        // Derive approx age parts so direct edit can prefill
        // approximate age fields.
        DateTime? loadedDob = allData['dob'] != null
            ? DateTime.tryParse(allData['dob'])
            : null;
        String? loadedApproxAge = allData['approxAge']?.toString();
        String? loadedUpdateYear = allData['updateYear']?.toString();
        String? loadedUpdateMonth = allData['updateMonth']?.toString();
        String? loadedUpdateDay = allData['updateDay']?.toString();

        // Case 1: only DOB is present (older records) -> compute approxAge + Y/M/D
        if (loadedDob != null &&
            (loadedApproxAge == null || loadedApproxAge.trim().isEmpty) &&
            (loadedUpdateYear == null || loadedUpdateYear.trim().isEmpty) &&
            (loadedUpdateMonth == null || loadedUpdateMonth.trim().isEmpty) &&
            (loadedUpdateDay == null || loadedUpdateDay.trim().isEmpty)) {
          final parts = _agePartsFromDob(loadedDob);
          final years = parts['years'] ?? 0;
          final months = parts['months'] ?? 0;
          final days = parts['days'] ?? 0;
          loadedApproxAge = '$years years $months months $days days'.trim();
          loadedUpdateYear = years.toString();
          loadedUpdateMonth = months.toString();
          loadedUpdateDay = days.toString();
        }

        // Case 2: approxAge string exists but split fields are missing ->
        // derive updateYear/updateMonth/updateDay from approxAge.
        if (loadedApproxAge != null && loadedApproxAge.trim().isNotEmpty &&
            (loadedUpdateYear == null || loadedUpdateYear.trim().isEmpty) &&
            (loadedUpdateMonth == null || loadedUpdateMonth.trim().isEmpty) &&
            (loadedUpdateDay == null || loadedUpdateDay.trim().isEmpty)) {
          final matches = RegExp(r'\d+').allMatches(loadedApproxAge).toList();
          String _part(int index) =>
              matches.length > index ? (matches[index].group(0) ?? '') : '';

          final y = _part(0);
          final m = _part(1);
          final d = _part(2);

          if (y.isNotEmpty) loadedUpdateYear = y;
          if (m.isNotEmpty) loadedUpdateMonth = m;
          if (d.isNotEmpty) loadedUpdateDay = d;
        }

        // Parse LMP and EDD dates if they exist
        DateTime? lmpDate = allData['lmp'] != null
            ? DateTime.tryParse(allData['lmp'])
            : null;
        DateTime? eddDate = allData['edd'] != null
            ? DateTime.tryParse(allData['edd'])
            : null;

        // Check if 'other' fields exist
        final otherReligion = allData['otherReligion'] as String?;
        final otherCategory = allData['otherCategory'] as String?;
        final otherOccupation = allData['otherOccupation'] as String?;
        final otherRelation = allData['otherRelation'] as String?;

        // Handle 'Other' option fields - using the exact field names from the database
        final rawReligion = allData['religion'] as String?;
        final rawCategory = allData['category'] as String?;
        final rawOccupation = allData['occupation'] as String?;
        final rawMobileOwnerRelation = allData['mobileOwnerRelation'] as String?;
        
        // Check if the field is 'Other' in the database
        // final isReligionOther = rawReligion == 'Other';
        // final isCategoryOther = rawCategory == 'Other';
        // final isOccupationOther = rawOccupation == 'Other';
        // final isRelationOther = rawMobileOwnerRelation == 'Other';

        
        // Variables to store the processed values
        String? religionValue = rawReligion;
        String? otherReligionValue;
        String? categoryValue = rawCategory;
        String? otherCategoryValue;
        String? occupationValue = rawOccupation;
        String? otherOccupationValue;
        String? mobileOwnerRelationValue = rawMobileOwnerRelation;
        String? otherRelationValue;
        
        // Process religion field
        if (rawReligion != null && rawReligion.endsWith('_other')) {
          religionValue = 'Other';
          otherReligionValue = rawReligion.replaceAll('_other', '');
        } else {
          otherReligionValue = allData['other_religion'] as String?;
        }
        
        // Process category field
        if (rawCategory != null && rawCategory.endsWith('_other')) {
          categoryValue = 'Other';
          otherCategoryValue = rawCategory.replaceAll('_other', '');
        } else {
          otherCategoryValue = allData['other_category'] as String?;
        }
        
        // Process occupation field
        if (rawOccupation != null && rawOccupation.endsWith('_other')) {
          occupationValue = 'Other';
          otherOccupationValue = rawOccupation.replaceAll('_other', '');
        } else {
          otherOccupationValue = allData['other_occupation'] as String?;
        }
        
        // Process mobile owner relation field
        if (rawMobileOwnerRelation != null && rawMobileOwnerRelation.endsWith('_other')) {
          mobileOwnerRelationValue = 'Other';
          otherRelationValue = rawMobileOwnerRelation.replaceAll('_other', '');
        } else {
          otherRelationValue = allData['other_relation'] as String?;
        }
        
        // // Debug log to see what values we're getting from the database
        // print('Religion: $religionValue, Other: $otherReligionValue');
        // print('Category: $categoryValue, Other: $otherCategoryValue');
        // print('Occupation: $occupationValue, Other: $otherOccupationValue');
        // print('Relation: $mobileOwnerRelationValue, Other: $otherRelationValue');
        
        // Normalize member type to camelCase
        String normalizedMemberType = allData['memberType'] as String? ?? 'Adult';
        if (normalizedMemberType.isNotEmpty) {
          normalizedMemberType = normalizedMemberType[0].toUpperCase() + normalizedMemberType.substring(1).toLowerCase();
        }
        
        // Update the state with all the data
        emit(state.copyWith(
          // Map all the fields to the state
          name: primaryName,
          fatherName: allData['fatherName'] as String?,
          motherName: allData['motherName'] as String?,
          memberType: normalizedMemberType,
          relation: primaryRelation,
          otherRelation: otherRelationValue,
          useDob: allData['useDob'] as bool? ?? true,
          dob: loadedDob,
          approxAge: loadedApproxAge,
          children: allData['children']?.toString(),
          birthOrder: allData['birthOrder']?.toString(),
          gender: allData['gender'] as String?,
          bankAcc: allData['bankAcc'] as String?,
          ifsc: allData['ifsc'] as String?,
          // Handle occupation and other occupation
          occupation: occupationValue,
          otherOccupation: otherOccupationValue,
          
          education: allData['education'] as String?,
          
          // Handle religion and other religion
          religion: religionValue,
          otherReligion: otherReligionValue,
          
          // Handle category and other category
          category: categoryValue,
          otherCategory: otherCategoryValue,
          
          abhaAddress: allData['abhaAddress'] as String?,
          
          // Handle mobile owner and relation
          mobileOwner: allData['mobileOwner'] as String?,
          mobileOwnerRelation: rawMobileOwnerRelation ?? 
                            (allData['mobile_owner_relation'] as String?),
          mobileNo: allData['mobileNo'] as String?,
          voterId: allData['voterId'] as String?,
          rationId: allData['rationId'] as String?,
          phId: allData['phId'] as String?,
          beneficiaryType: allData['beneficiaryType'] as String?,
          maritalStatus: allData['maritalStatus'] as String?,
          ageAtMarriage: allData['ageAtMarriage'] as String?,
          spouseName: allData['spouseName'] as String?,
          hasChildren: (allData['hasChildren'] ?? allData['have_children']) as String?,
          isPregnant: allData['isPregnant'] as String?,
          lmp: lmpDate,
          edd: eddDate,
          updateDay: loadedUpdateDay,
          updateMonth: loadedUpdateMonth,
          updateYear: loadedUpdateYear,
          WeightChange: allData['weight'] as String?,
          birthWeight: allData['birthWeight']?.toString(),
          ChildSchool: allData['childSchool'] as String?,
          BirthCertificateChange: allData['birthCertificate'] as String?,
          errorMessage: null,

          // Additional fields from the database
          memberStatus: allData['member_status'] as String?,
          dateOfDeath: allData['date_of_death'] != null
              ? DateTime.tryParse(allData['date_of_death'])
              : null,
          deathReason: allData['death_reason'] as String?,
          otherDeathReason: allData['other_death_reason'] as String?,
          deathPlace: allData['death_place'] as String?,
          otherDeathPlace: allData['other_death_place'] as String?,
        ));
        // Handle family planning and pregnancy related fields
        final isFamilyPlanning = allData['isFamilyPlanning'] == true || allData['isFamilyPlanning'] == 'true';
        final familyPlanningMethod = allData['familyPlanningMethod'] as String?;
        final fpMethod = allData['fpMethod'] as String?;
        final antraDate = allData['antraDate'] != null ? DateTime.tryParse(allData['antraDate']) : null;
        final removalDate = allData['removalDate'] != null ? DateTime.tryParse(allData['removalDate']) : null;
        final removalReason = allData['removalReason'] as String?;
        final condomQuantity = allData['condomQuantity'] as String?;
        final malaQuantity = allData['malaQuantity'] as String?;
        final chhayaQuantity = allData['chhayaQuantity'] as String?;
        final ecpQuantity = allData['ecpQuantity'] as String?;

        emit(state.copyWith(
          isFamilyPlanning: isFamilyPlanning ? 'Yes' : 'No',
          familyPlanningMethod: familyPlanningMethod,
          fpMethod: fpMethod,
          antraDate: antraDate,
          removalDate: removalDate,
          removalReason: removalReason,
          condomQuantity: condomQuantity,
          malaQuantity: malaQuantity,
          chhayaQuantity: chhayaQuantity,
          ecpQuantity: ecpQuantity,
          otherRelation: allData['otherRelation'] as String?,
          mobileOwnerRelation: allData['mobileOwnerRelation'] as String?,
        ));
      } else {
        emit(state.copyWith(
          errorMessage: 'Beneficiary not found',
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        errorMessage: 'Error loading beneficiary data: $e',
      ));
    }
  }

  int _getIsAdultValue(String? memberType, bool useDob, DateTime? dob) {
    final type = (memberType ?? '').trim().toLowerCase();
    if (type == 'child' || type == 'children') {
      return 0;
    }
    if (type == 'adult') {
      return 1;
    }
    if (useDob && dob != null) {
      final age = DateTime.now().difference(dob).inDays ~/ 365;
      return age >= 18 ? 1 : 0;
    }
    return 1;
  }

  String _getBeneficiaryState(String? memberType) {
    if (memberType?.toLowerCase() == 'child') {
      return 'registration_due';
    } else {
      return 'active';
    }
  }

  AddnewfamilymemberBloc({this.householdBloc}) : super(const AddnewfamilymemberState()) {
    on<LoadBeneficiaryData>(_onLoadBeneficiaryData);
    on<AddnewfamilymemberEvent>((event, emit) {
      // TODO: implement event handler
    });
    on<AnmClearAllData>((e, emit) {
      print('🧹 [Bloc] ClearAllData event received - resetting state to default');
      _dataClearedByTypeChange = true; // Set flag to prevent data reloading
      emit(const AddnewfamilymemberState());
      print('🧹 [Bloc] State cleared - MemberType: ${state.memberType}, Name: ${state.name}');
    });
    on<AnmResetDataClearedFlag>((e, emit) {
      print('🔄 [Bloc] Resetting data cleared flag');
      _dataClearedByTypeChange = false;
    });
    on<AnmUpdateMemberType>((e, emit) {
      // Normalize member type to camelCase
      String normalizedValue = e.value;
      if (normalizedValue.isNotEmpty) {
        normalizedValue = normalizedValue[0].toUpperCase() + normalizedValue.substring(1).toLowerCase();
      }
      emit(state.copyWith(memberType: normalizedValue));
    });
    on<AnmUpdateRelation>((e, emit) => emit(state.copyWith(relation: e.value)));
    on<AnmUpdateOtherRelation>((e, emit) => emit(state.copyWith(otherRelation: e.value)));
    on<AnmUpdateName>((e, emit) => emit(state.copyWith(name: e.value)));
    on<AnmUpdateFatherName>(
          (e, emit) => emit(state.copyWith(fatherName: e.value)),
    );
    on<AnmUpdateMotherName>(
          (e, emit) => emit(state.copyWith(motherName: e.value)),
    );
    on<AnmToggleUseDob>((e, emit) {
      final toggled = !(state.useDob);
      emit(
        state.copyWith(
          useDob: toggled,
          dob: toggled ? state.dob : null,
          approxAge: toggled ? null : state.approxAge,
        ),
      );
    });
    on<AnmUpdateDob>((e, emit) {
      final dob = e.value;
      if (dob == null) {
        emit(state.copyWith(dob: null));
        return;
      }

      final parts = _agePartsFromDob(dob);
      final years = parts['years'] ?? 0;
      final months = parts['months'] ?? 0;
      final days = parts['days'] ?? 0;
      final approx = '$years years $months months $days days'.trim();

      emit(
        state.copyWith(
          dob: dob,
          updateYear: years.toString(),
          updateMonth: months.toString(),
          updateDay: days.toString(),
          approxAge: approx,
        ),
      );
    });
    on<AnmUpdateApproxAge>(
          (e, emit) => emit(state.copyWith(approxAge: e.value)),
    );
    on<UpdateDayChanged>((e, emit) {
      final dayStr = e.value;
      final yearStr = state.updateYear ?? '0';
      final monthStr = state.updateMonth ?? '0';

      final years = int.tryParse(yearStr.isEmpty ? '0' : yearStr) ?? 0;
      final months = int.tryParse(monthStr.isEmpty ? '0' : monthStr) ?? 0;
      final days = int.tryParse(dayStr.isEmpty ? '0' : dayStr) ?? 0;

      final dob = _dobFromAgeParts(years, months, days);
      final approx = '$years years $months months $days days'.trim();

      emit(
        state.copyWith(
          updateDay: dayStr,
          approxAge: approx,
          dob: dob ?? state.dob,
        ),
      );
    });
    on<UpdateMonthChanged>((e, emit) {
      final monthStr = e.value;
      final yearStr = state.updateYear ?? '0';
      final dayStr = state.updateDay ?? '0';

      final years = int.tryParse(yearStr.isEmpty ? '0' : yearStr) ?? 0;
      final months = int.tryParse(monthStr.isEmpty ? '0' : monthStr) ?? 0;
      final days = int.tryParse(dayStr.isEmpty ? '0' : dayStr) ?? 0;

      final dob = _dobFromAgeParts(years, months, days);
      final approx = '$years years $months months $days days'.trim();

      emit(
        state.copyWith(
          updateMonth: monthStr,
          approxAge: approx,
          dob: dob ?? state.dob,
        ),
      );
    });
    on<UpdateYearChanged>((e, emit) {
      final yearStr = e.value;
      final monthStr = state.updateMonth ?? '0';
      final dayStr = state.updateDay ?? '0';
      final years = int.tryParse(yearStr.isEmpty ? '0' : yearStr) ?? 0;
      final months = int.tryParse(monthStr.isEmpty ? '0' : monthStr) ?? 0;
      final days = int.tryParse(dayStr.isEmpty ? '0' : dayStr) ?? 0;

      final dob = _dobFromAgeParts(years, months, days);
      final approx = '$years years $months months $days days'.trim();

      emit(
        state.copyWith(
          updateYear: yearStr,
          approxAge: approx,
          dob: dob ?? state.dob,
        ),
      );
    });
    on<ChildrenChanged>((e, emit) => emit(state.copyWith(children: e.value)));
    on<AnmUpdateBirthOrder>(
          (e, emit) => emit(state.copyWith(birthOrder: e.value)),
    );
    on<AnmUpdateGender>((e, emit) => emit(state.copyWith(gender: e.value)));
    on<AnmUpdateBankAcc>((e, emit) => emit(state.copyWith(bankAcc: e.value)));
    on<RichIDChanged>(
          (e, emit) {
            final value = e.value;
            final isButtonEnabled = value.length == 12;
            emit(state.copyWith(
              RichIDChanged: value,
              isRchIdButtonEnabled: isButtonEnabled,
            ));
          },
    );
    on<AnmUpdateIfsc>((e, emit) => emit(state.copyWith(ifsc: e.value)));
    on<AnmUpdateOccupation>(
          (e, emit) => emit(state.copyWith(occupation: e.value)),
    );
    on<AnmUpdateOtherOccupation>(
          (e, emit) => emit(state.copyWith(otherOccupation: e.value)),
    );
    on<AnmUpdateEducation>(
          (e, emit) => emit(state.copyWith(education: e.value)),
    );
    on<AnmUpdateReligion>((e, emit) => emit(state.copyWith(religion: e.value)));
    on<AnmUpdateOtherReligion>((e, emit) => emit(state.copyWith(otherReligion: e.value)));
    on<AnmUpdateCategory>((e, emit) => emit(state.copyWith(category: e.value)));
    on<AnmUpdateOtherCategory>((e, emit) => emit(state.copyWith(otherCategory: e.value)));
    on<WeightChange>((e, emit) => emit(state.copyWith(WeightChange: e.value)));
    on<BirthWeightChange>((e, emit) => emit(state.copyWith(birthWeight: e.value)));
    on<ChildSchoolChange>(
          (e, emit) => emit(state.copyWith(ChildSchool: e.value)),
    );
    on<BirthCertificateChange>(
          (e, emit) => emit(state.copyWith(BirthCertificateChange: e.value)),
    );
    on<AnmUpdateAbhaAddress>(
          (e, emit) => emit(state.copyWith(abhaAddress: e.value)),
    );
    on<AnmUpdateMobileOwner>(
          (e, emit) => emit(state.copyWith(mobileOwner: e.value)),
    );
    on<AnmUpdateMobileOwnerRelation>(
          (e, emit) => emit(state.copyWith(mobileOwnerRelation: e.value)),
    );
    on<AnmUpdateMobileNo>((e, emit) => emit(state.copyWith(mobileNo: e.value)));
    on<AnmUpdateVoterId>((e, emit) => emit(state.copyWith(voterId: e.value)));
    on<AnmUpdateRationId>((e, emit) => emit(state.copyWith(rationId: e.value)));
    on<AnmUpdatePhId>((e, emit) => emit(state.copyWith(phId: e.value)));
    on<AnmUpdateBeneficiaryType>(
          (e, emit) => emit(state.copyWith(beneficiaryType: e.value)),
    );
    on<AnmUpdateMaritalStatus>(
          (e, emit) => emit(state.copyWith(maritalStatus: e.value)),
    );
    on<AnmUpdateAgeAtMarriage>(
          (e, emit) => emit(state.copyWith(ageAtMarriage: e.value)),
    );
    on<AnmUpdateSpouseName>(
          (e, emit) => emit(state.copyWith(spouseName: e.value)),
    );
    on<AnmUpdateHasChildren>(
          (e, emit) => emit(state.copyWith(hasChildren: e.value)),
    );
    on<AnmUpdateIsPregnant>(
          (e, emit) => emit(state.copyWith(isPregnant: e.value)),
    );
    on<AnmLMPChange>((e, emit) => emit(state.copyWith(lmp: e.date)));
    on<AnmEDDChange>((e, emit) => emit(state.copyWith(edd: e.date)));
    on<AnmUpdateFamilyPlanning>(
          (e, emit) => emit(state.copyWith(isFamilyPlanning: e.value)),
    );
    on<AnmUpdateFamilyPlanningMethod>(
          (e, emit) => emit(state.copyWith(familyPlanningMethod: e.value)),
    );
    // Family planning detailed fields (mirror spouse flow)
    on<AnmFpMethodChanged>((e, emit) => emit(state.copyWith(fpMethod: e.value)));
    on<AnmFpRemovalDateChanged>((e, emit) => emit(state.copyWith(removalDate: e.value)));
    on<AnmFpDateOfAntraChanged>((e, emit) => emit(state.copyWith(antraDate: e.value)));
    on<AnmFpRemovalReasonChanged>((e, emit) => emit(state.copyWith(removalReason: e.value)));
    on<AnmFpCondomQuantityChanged>((e, emit) => emit(state.copyWith(condomQuantity: e.value)));
    on<AnmFpMalaQuantityChanged>((e, emit) => emit(state.copyWith(malaQuantity: e.value)));
    on<AnmFpChhayaQuantityChanged>((e, emit) => emit(state.copyWith(chhayaQuantity: e.value)));
    on<AnmFpEcpQuantityChanged>((e, emit) => emit(state.copyWith(ecpQuantity: e.value)));
    on<UpdateIsMemberStatus>(
          (e, emit) => emit(state.copyWith(memberStatus: e.value)),
    );
    on<UpdateDateOfDeath>(
          (e, emit) => emit(state.copyWith(dateOfDeath: e.value)),
    );
    on<UpdateReasonOfDeath>(
          (e, emit) => emit(state.copyWith(deathReason: e.value)),
    );
    on<UpdateOtherReasonOfDeath>(
          (e, emit) => emit(state.copyWith(otherDeathReason: e.value)),
    );
    on<UpdateDatePlace>((e, emit) {
      final newState = state.copyWith(deathPlace: e.value);
      emit(newState);
      print('Updated deathPlace: ${newState.deathPlace}');
    });
    on<UpdateOtherDeathPlace>((e, emit) {
      emit(state.copyWith(otherDeathPlace: e.value));
    });

    on<AnmSubmit>((event,      emit) async {
      emit(
        state.copyWith(postApiStatus: PostApiStatus.loading, clearError: true),
      );

      final errors = <String>[];
      if (state.relation == null || state.relation!.trim().isEmpty)
        errors.add('Relation with family head is required');
      if (state.relation == 'Other' && (state.otherRelation == null || state.otherRelation!.trim().isEmpty))
        errors.add('Enter relation with family head');
      if (state.name == null || state.name!.trim().isEmpty)
        errors.add('Member name is required');
      if (state.useDob) {
        if (state.dob == null) errors.add('DOB required');
      } else {
        if (state.approxAge == null || state.approxAge!.trim().isEmpty)
          errors.add('Age required');
      }
      if (state.gender == null || state.gender!.isEmpty)
        errors.add('Gender required');
      if (state.mobileOwner == 'Other' && (state.mobileOwnerRelation == null || state.mobileOwnerRelation!.trim().isEmpty))
        errors.add('Enter relation with mobile holder');

      // Marital status is only required for Adults, not for Children
      if (state.memberType != 'Child') {
        if (state.maritalStatus == null || state.maritalStatus!.isEmpty) {
          errors.add('Marital status required');
        } else if (state.maritalStatus == 'Married') {
          if (state.spouseName == null || state.spouseName!.trim().isEmpty) {
            errors.add('Spouse Name is required for married status');
          }
        }
      }

      if (errors.isNotEmpty) {
        emit(
          state.copyWith(
            postApiStatus: PostApiStatus.error,
            // Show only the first validation error message instead of
            // grouping multiple messages together.
            errorMessage: errors.first,
          ),
        );
        return;
      }

      try {
        final now = DateTime.now();
        final ts = DateFormat('yyyy-MM-dd HH:mm:ss').format(now);
        final deviceInfo = await DeviceInfo.getDeviceInfo();

        // Initialize with empty string or use provided hhid
        String householdRefKey = event.hhid?.toString() ?? '';

        // Generate member and spouse keys without database checks
        final memberId = await IdGenerator.generateUniqueId(deviceInfo);
        final spousKey = await IdGenerator.generateUniqueId(deviceInfo);
        // Use empty string as fallback for spouse key
        final uniqueKeyForSpouseFallback = '';

        // Get current user info
        final currentUser = await UserInfo.getCurrentUser();
        final userDetails = currentUser?['details'] is String
            ? jsonDecode(currentUser?['details'] ?? '{}')
            : currentUser?['details'] ?? {};

        final working = userDetails['working_location'] ?? {};
        final facilityId = working['asha_associated_with_facility_id'] ??
            userDetails['asha_associated_with_facility_id'] ?? 0;
        final ashaUniqueKey = userDetails['unique_key'] ?? {};


        final geoLocation = await GeoLocation.getCurrentLocation();
        final locationData = Map<String, String>.from(geoLocation.toJson());
        locationData['source'] = 'gps';
        if (!geoLocation.hasCoordinates) {
          locationData['status'] = 'unavailable';
          locationData['reason'] = 'Could not determine location';
        }
        final geoLocationJson = jsonEncode(locationData);

        // Use helper method to determine beneficiary_state and isAdult
        final beneficiaryState = _getBeneficiaryState(state.memberType);
        final isAdult = _getIsAdultValue(state.memberType, state.useDob, state.dob);

        final isDeath = (state.memberStatus?.toLowerCase() == 'death') ? 1 : 0;

        final deathDetails = isDeath == 1
            ? {
          'dateOfDeath': state.dateOfDeath?.toIso8601String(),
          'deathReason': state.deathReason,
          'otherDeathReason': state.otherDeathReason,
          'deathPlace': state.deathPlace,
          'otherDeathPlace': state.otherDeathPlace,
        }
            : {};

        Map<String, dynamic> childrenData = {};
        try {
          final childrenBloc = BlocProvider.of<ChildrenBloc>(event.context);
          final childrenState = childrenBloc.state;

          childrenData = {
            'totalBorn': childrenState.totalBorn,
            'totalLive': childrenState.totalLive,
            'totalMale': childrenState.totalMale,
            'totalFemale': childrenState.totalFemale,
            'youngestAge': childrenState.youngestAge,
            'ageUnit': childrenState.ageUnit,
            'youngestGender': childrenState.youngestGender,
            'children': childrenState.children,
          };
        } catch (e) {
          print('Error getting children data: $e');
        }

        String? resolvedMotherKey;
        String? resolvedFatherKey;
        try {
          if (state.relation == 'Mother' || state.relation == 'Father' || state.relation == 'Child') {
            final hhBeneficiaries = await LocalStorageDao.instance
                .getBeneficiariesByHousehold(householdRefKey.toString());

            Map<String, dynamic>? headRecord;
            Map<String, dynamic>? spouseRecord;
            for (final b in hhBeneficiaries) {
              try {
                final info = b['beneficiary_info'] is Map
                    ? Map<String, dynamic>.from(b['beneficiary_info'])
                    : <String, dynamic>{};
                final relToHead = (info['relation_to_head'] ?? '').toString().toLowerCase();
                final rel = (info['relation'] ?? '').toString().toLowerCase();
                if (relToHead == 'self' || rel == 'head') {
                  headRecord = b as Map<String, dynamic>;
                  break;
                }
              } catch (_) {}
            }
            if (headRecord != null) {
              final headUnique = (headRecord['unique_key'] ?? '').toString();
              String? spouseKeyLocal = headRecord['spouse_key']?.toString();
              if (spouseKeyLocal == null || spouseKeyLocal.isEmpty) {
                try {
                  for (final b in hhBeneficiaries) {
                    if ((b['spouse_key'] ?? '').toString() == headUnique) {
                      spouseKeyLocal = (b['unique_key'] ?? '').toString();
                      spouseRecord = b as Map<String, dynamic>;
                      break;
                    }
                  }
                } catch (_) {}
              } else {
                try {
                  for (final b in hhBeneficiaries) {
                    if ((b['unique_key'] ?? '').toString() == spouseKeyLocal) {
                      spouseRecord = b as Map<String, dynamic>;
                      break;
                    }
                  }
                } catch (_) {}
              }

              if (state.relation == 'Mother') {
                resolvedMotherKey = headUnique;
                resolvedFatherKey = spouseKeyLocal;
              } else if (state.relation == 'Father') {
                resolvedFatherKey = headUnique;
                resolvedMotherKey = spouseKeyLocal;
              } else if (state.relation == 'Child') {
                final headInfo = headRecord['beneficiary_info'] is Map
                    ? Map<String, dynamic>.from(headRecord['beneficiary_info'])
                    : <String, dynamic>{};
                final spouseInfo = spouseRecord != null && spouseRecord['beneficiary_info'] is Map
                    ? Map<String, dynamic>.from(spouseRecord['beneficiary_info'])
                    : <String, dynamic>{};
                final headGender = (headInfo['gender'] ?? '').toString().toLowerCase();
                final spouseGender = (spouseInfo['gender'] ?? '').toString().toLowerCase();
                // Assign based on gender where possible
                if (headGender == 'female') {
                  resolvedMotherKey = headUnique;
                  resolvedFatherKey = spouseKeyLocal;
                } else if (headGender == 'male') {
                  resolvedFatherKey = headUnique;
                  resolvedMotherKey = spouseKeyLocal;
                } else if (spouseGender.isNotEmpty) {
                  if (spouseGender == 'female') {
                    resolvedMotherKey = spouseKeyLocal;
                    resolvedFatherKey = headUnique;
                  } else if (spouseGender == 'male') {
                    resolvedFatherKey = spouseKeyLocal;
                    resolvedMotherKey = headUnique;
                  }
                } else {
                  resolvedMotherKey = headUnique;
                  resolvedFatherKey = spouseKeyLocal;
                }
              }
            }
          }
        } catch (_) {}

        final memberPayload = {
          'server_id': null,
          'household_ref_key': householdRefKey,
          'unique_key': memberId,
          'beneficiary_state': beneficiaryState,
          'pregnancy_count': 0,
          'beneficiary_info': jsonEncode({
            'memberType': state.memberType,
            'relation': state.relation,
            'otherRelation': state.otherRelation,
            'name': state.name,
            'fatherName': state.fatherName,
            'motherName': state.motherName,
            'useDob': state.useDob,
            'dob': state.dob?.toIso8601String(),
            'approxAge': state.approxAge,
            'updateDay': state.updateDay,
            'updateMonth': state.updateMonth,
            'updateYear': state.updateYear,
            'children': state.children,
            'birthOrder': state.birthOrder,
            'gender': state.gender,
            'bankAcc': state.bankAcc,
            'ifsc': state.ifsc,
            'occupation': state.occupation,
            'education': state.education,
            'religion': state.religion,
            'category': state.category,
            'weight': state.WeightChange,
            'childSchool': state.ChildSchool,
            'birthCertificate': state.BirthCertificateChange,
            'birthWeight': state.birthWeight,
            'abhaAddress': state.abhaAddress,
            'abhaNumber': state.abhaAddress,
            'mobileOwner': state.mobileOwner,
            'mobileOwnerRelation': state.mobileOwnerRelation,
            'mobileNo': state.mobileNo,
            'voterId': state.voterId,
            'rationId': state.rationId,
            'phId': state.phId,
            'beneficiaryType': state.beneficiaryType,
            'maritalStatus': state.maritalStatus,
            'ageAtMarriage': state.ageAtMarriage,
            'spouseName': state.spouseName,
            'hasChildren': state.hasChildren,
            'isPregnant': state.isPregnant,
            'lmp': state.lmp?.toIso8601String(),
            'isFamilyPlanning': state.isFamilyPlanning,
            'familyPlanningMethod': state.familyPlanningMethod,
            'other_occupation': state.otherOccupation,
            'other_religion': state.otherReligion,
            'other_category': state.otherCategory,
            'mobile_owner_relation': state.mobileOwnerRelation,
            // 'education': state.education,
            // 'occupation': state.occupation,
            // 'religion': state.religion,
            // 'category': state.category,
            // 'memberType': state.memberType,
            'years': state.updateYear,
            'months': state.updateMonth,
            'days': state.updateDay,
            // 'gender': state.gender,
            'fpMethod': state.fpMethod,
            'removalDate': state.removalDate?.toIso8601String(),
            'removalReason': state.removalReason,
            'condomQuantity': state.condomQuantity,
            'malaQuantity': state.malaQuantity,
            'chhayaQuantity': state.chhayaQuantity,
            'ecpQuantity': state.ecpQuantity,
            'antraDate': state.antraDate?.toIso8601String(),
            'memberStatus': state.memberStatus,
            'relation_to_head': state.relation,
            'isFamilyhead': false,
            'isFamilyheadWife': false,
            ...childrenData,
          }),
          'geo_location': geoLocationJson,
          'spouse_key': state.maritalStatus == 'Married' ? spousKey : null,
          'mother_key': resolvedMotherKey,
          'father_key': resolvedFatherKey,
          'is_family_planning': (state.isFamilyPlanning?.toLowerCase() == 'yes') ? 1 : 0,
          'is_adult': isAdult,
          'is_guest': 0,
          'is_death': isDeath,
          'death_details': jsonEncode(deathDetails),
          'is_migrated': 0,
          'is_separated': 0,
          'device_details': jsonEncode({
            'id': deviceInfo.deviceId,
            'platform': deviceInfo.platform,
            'version': deviceInfo.osVersion,
          }),
          'app_details': jsonEncode({
            'app_version': deviceInfo.appVersion.split('+').first,
            'app_name': deviceInfo.appName,
            'build_number': deviceInfo.buildNumber,
            'package_name': deviceInfo.packageName,
          }),
          'parent_user': jsonEncode({}),
          'current_user_key': ashaUniqueKey,
          'facility_id': facilityId,
          'created_date_time': ts,
          'modified_date_time': ts,
          'is_synced': 0,
          'is_deleted': 0,
        };

        print('Saving new family member with payload: ${jsonEncode(memberPayload)}');
        await LocalStorageDao.instance.insertBeneficiary(memberPayload);

        int age = 0;
        if (state.dob != null) {
          try {
            final now = DateTime.now();
            final dob = state.dob!;
            age = now.year - dob.year;
            if (now.month < dob.month ||
                (now.month == dob.month && now.day < dob.day)) {
              age--;
            }
          } catch (e) {
            print('Error calculating age from DOB: $e');
          }
        }

        // Check if member is female, married, and within childbearing age
        // final isFemaleMarried =
        //     spousState.gender == 'female' || state.gender == 'female' &&
        //         state.maritalStatus == 'Married'  &&
        //         spousState.fpMethod == 'male sterilization' && state.fpMethod == 'male sterilization' &&
        //         spousState.fpMethod == 'female sterilization' && state.fpMethod == 'female sterilization' &&
        //         age >= 15 &&
        //         age <= 49;
        //
        //
        // if (isFemaleMarried) {
        //   final isPregnant = state.isPregnant == 'Yes' || state.isPregnant == 'yes';
        //   final coupleState = isPregnant ? 'eligible_couple' : 'tracking_due';
        //
        //   print('${isPregnant ? 'Pregnant' : 'Non-pregnant'} eligible couple detected. State: $coupleState');
        //   try {
        //     final db = await DatabaseProvider.instance.database;
        //     final eligibleCoupleActivityData = {
        //       'server_id': '',
        //       'household_ref_key': householdRefKey,
        //       'beneficiary_ref_key': memberId,
        //       'eligible_couple_state': 'eligible_couple',
        //       'device_details': jsonEncode({
        //         'id': deviceInfo.deviceId,
        //         'platform': deviceInfo.platform,
        //         'version': deviceInfo.osVersion,
        //       }),
        //       'app_details': jsonEncode({
        //         'app_version': deviceInfo.appVersion.split('+').first,
        //         'form_data': {
        //           'created_at': DateTime.now().toIso8601String(),
        //           'updated_at': DateTime.now().toIso8601String(),
        //         },
        //       }),
        //       'parent_user': '',
        //       'current_user_key': ashaUniqueKey,
        //       'facility_id': facilityId,
        //       'created_date_time': ts,
        //       'modified_date_time': ts,
        //       'is_synced': 0,
        //       'is_deleted': 0,
        //     };
        //
        //     print('Inserting eligible couple activity for head: $memberId');
        //     await db.insert(
        //       'eligible_couple_activities',
        //       eligibleCoupleActivityData,
        //       conflictAlgorithm: ConflictAlgorithm.replace,
        //     );
        //   } catch (e) {
        //     print(
        //       'Error inserting eligible couple activity for head: $e',
        //     );
        //   }
        // }


        // Check if member is female and pregnant, then insert ANC due status
        if (state.gender?.toLowerCase() == 'female' && 
            (state.isPregnant?.toLowerCase() == 'yes' || state.isPregnant?.toLowerCase() == 'true')) {
          try {
            final motherCareActivityData = {
              'server_id': null,
              'household_ref_key': householdRefKey,
              'beneficiary_ref_key': memberId,
              'mother_care_state': 'anc_due',
              'device_details': jsonEncode({
                'id': deviceInfo.deviceId,
                'platform': deviceInfo.platform,
                'version': deviceInfo.osVersion,
              }),
              'app_details': jsonEncode({
                'app_version': deviceInfo.appVersion.split('+').first,
                'app_name': deviceInfo.appName,
                'build_number': deviceInfo.buildNumber,
                'package_name': deviceInfo.packageName,
              }),
              'parent_user': jsonEncode({}),
              'current_user_key': ashaUniqueKey,
              'facility_id': facilityId,
              'created_date_time': ts,
              'modified_date_time': ts,
              'is_synced': 0,
              'is_deleted': 0,
            };
            
            print('Inserting mother care activity for pregnant member: ${jsonEncode(motherCareActivityData)}');
            await LocalStorageDao.instance.insertMotherCareActivity(motherCareActivityData);
          } catch (e) {
            print('Error inserting mother care activity for member: $e');
          }
        }
        
        if (state.memberType?.toLowerCase() == 'child') {
          try {
            final childCareActivityData = {
              'server_id': null,
              'household_ref_key': householdRefKey,
              'beneficiary_ref_key': memberId,
              'mother_key': resolvedMotherKey,
              'father_key': resolvedFatherKey,
              'child_care_state': 'registration_due',
              'device_details': jsonEncode({
                'id': deviceInfo.deviceId,
                'platform': deviceInfo.platform,
                'version': deviceInfo.osVersion,
              }),
              'app_details': jsonEncode({
                'app_version': deviceInfo.appVersion.split('+').first,
                'app_name': deviceInfo.appName,
                'build_number': deviceInfo.buildNumber,
                'package_name': deviceInfo.packageName,
              }),
              'parent_user': jsonEncode({}),
              'current_user_key': ashaUniqueKey,
              'facility_id': facilityId,
              'created_date_time': ts,
              'modified_date_time': ts,
              'is_synced': 0,
              'is_deleted': 0,
            };
            
            print('Inserting child care activity: ${jsonEncode(childCareActivityData)}');
            await LocalStorageDao.instance.insertChildCareActivity(childCareActivityData);
          } catch (e) {
            print('Error inserting child care activity: $e');
          }
        }

        if (state.maritalStatus == 'Married' && state.spouseName != null) {
          try {
            final spousBloc = BlocProvider.of<SpousBloc>(event.context);
            final spousState = spousBloc.state;

            final spousePayload = {
              'server_id': null,
              'household_ref_key': householdRefKey,
              'unique_key': spousKey,
              'beneficiary_state': 'active',
              'pregnancy_count': 0,
              'beneficiary_info': jsonEncode({
                'relation': spousState.relation ?? 'spouse',
                'memberName': spousState.memberName ?? state.spouseName,
                'ageAtMarriage': spousState.ageAtMarriage,
                'RichIDChanged': spousState.RichIDChanged,
                'spouseName': spousState.spouseName,
                'fatherName': spousState.fatherName,
                'useDob': spousState.useDob,
                'dob': spousState.dob?.toIso8601String(),
                'edd': spousState.edd?.toIso8601String(),
                'lmp': spousState.lmp?.toIso8601String(),
                'approxAge': spousState.approxAge,
                'gender': spousState.gender ?? (state.gender == 'Male' ? 'Female' : 'Male'),
                'occupation': spousState.occupation,
                'education': spousState.education,
                'religion': spousState.religion,
                'category': spousState.category,
                'mobile_owner_relation': spousState.mobileOwnerOtherRelation,
                'other_category': spousState.otherCategory,
                'other_religion': spousState.otherReligion,
                'other_occupation': spousState.otherOccupation,
                'antraDate':spousState.antraDate,
                'abhaAddress': spousState.abhaAddress,
                'mobileOwner': spousState.mobileOwner,
                'mobileNo': spousState.mobileNo,
                'bankAcc': spousState.bankAcc,
                'ifsc': spousState.ifsc,
                'voterId': spousState.voterId,
                'rationId': spousState.rationId,
                'phId': spousState.phId,
                'beneficiaryType': spousState.beneficiaryType,
                'isPregnant': spousState.isPregnant,
                'familyPlanningCounseling': spousState.familyPlanningCounseling,
                'fpMethod': spousState.fpMethod,
                'removalDate': spousState.removalDate?.toIso8601String(),
                'removalReason': spousState.removalReason,
                'condomQuantity': spousState.condomQuantity,
                'malaQuantity': spousState.malaQuantity,
                'chhayaQuantity': spousState.chhayaQuantity,
                'ecpQuantity': spousState.ecpQuantity,
                'relation_to_head': 'spouse',
                'isFamilyhead': false,
                'isFamilyheadWife': false,
                ...childrenData,
              }),
              'geo_location': geoLocationJson,
              'spouse_key': memberId,
              'mother_key': null,
              'father_key': null,
              'is_family_planning': 0,
              'is_adult': 1,
              'is_guest': 0,
              'is_death': 0,
              'death_details': jsonEncode({}),
              'is_migrated': 0,
              'is_separated': 0,
              'device_details': jsonEncode({
                'id': deviceInfo.deviceId,
                'platform': deviceInfo.platform,
                'version': deviceInfo.osVersion,
              }),
              'app_details': jsonEncode({
                'app_version': deviceInfo.appVersion.split('+').first,
                'app_name': deviceInfo.appName,
                'build_number': deviceInfo.buildNumber,
                'package_name': deviceInfo.packageName,
              }),
              'parent_user': jsonEncode({}),
              'current_user_key': ashaUniqueKey,
              'facility_id': facilityId,
              'created_date_time': ts,
              'modified_date_time': ts,
              'is_synced': 0,
              'is_deleted': 0,
            };

            await LocalStorageDao.instance.insertBeneficiary(spousePayload);

            // Calculate spouse age using the same logic as RegisterNewHouseHold uses for head
            int age = 0;
            if (spousState.dob != null) {
              try {
                final dob = spousState.dob!;
                final now = DateTime.now();
                age = now.year - dob.year;
                if (now.month < dob.month ||
                    (now.month == dob.month && now.day < dob.day)) {
                  age--;
                }
              } catch (e) {
                print('Error calculating spouse age from DOB: $e');
              }
            } else if (spousState.UpdateYears != null && spousState.UpdateYears!.isNotEmpty) {
              // Parse approximate age from years field (same as RegisterNewHouseHold)
              age = int.tryParse(spousState.UpdateYears!) ?? 0;
            }


            // Determine spouse gender properly - use the same logic as in payload
            final spouseGender = spousState.gender ?? (state.gender == 'Male' ? 'Female' : 'Male');

            final bool isSterilized =
                spousState.fpMethod?.toLowerCase() == 'male sterilization' ||
                    spousState.fpMethod?.toLowerCase() == 'female sterilization' ||
                    state.fpMethod?.toLowerCase() == 'male sterilization' ||
                    state.fpMethod?.toLowerCase() == 'female sterilization';

            // Use the same logic as RegisterNewHouseHold for gender and marital status
            final bool isFemale =
                spouseGender.toLowerCase() == 'female'; // Only check spouse gender for spouse record

            final bool isMarried =
                state.maritalStatus == 'Married'; // Check main member's marital status

            final bool isFemaleMarried =
                isFemale &&
                    isMarried &&
                    !isSterilized &&
                    age >= 15 &&
                    age <= 49;


            if (isFemaleMarried) {
              // Use the same logic as RegisterNewHouseHold for pregnancy status
              final bool isPregnant = spousState.isPregnant == 'Yes' || state.isPregnant == 'Yes';

              try {
                final db = await DatabaseProvider.instance.database;

                // Check if eligible_couple record already exists
                final existingEC = await db.query(
                  'eligible_couple_activities',
                  where: 'beneficiary_ref_key = ? AND eligible_couple_state = ?',
                  whereArgs: [spousKey, 'eligible_couple'],
                );

                if (existingEC.isEmpty) {
                  await db.insert(
                    'eligible_couple_activities',
                    {
                      'server_id': '',
                      'household_ref_key': householdRefKey,
                      'beneficiary_ref_key': spousKey,
                      'eligible_couple_state': 'eligible_couple',
                      'device_details': jsonEncode({
                        'id': deviceInfo.deviceId,
                        'platform': deviceInfo.platform,
                        'version': deviceInfo.osVersion,
                      }),
                      'app_details': jsonEncode({
                        'app_version': deviceInfo.appVersion.split('+').first,
                      }),
                      'parent_user': '',
                      'current_user_key': ashaUniqueKey,
                      'facility_id': facilityId,
                      'created_date_time': ts,
                      'modified_date_time': ts,
                      'is_synced': 0,
                      'is_deleted': 0,
                    },
                    conflictAlgorithm: ConflictAlgorithm.ignore,
                  );

                  print('Inserted eligible_couple');
                } else {
                  print('eligible_couple record already exists, skipping insert');
                }

                if (!isPregnant) {
                  // Check if tracking_due record already exists
                  final existingTD = await db.query(
                    'eligible_couple_activities',
                    where: 'beneficiary_ref_key = ? AND eligible_couple_state = ?',
                    whereArgs: [spousKey, 'tracking_due'],
                  );

                  if (existingTD.isEmpty) {
                    await db.insert(
                      'eligible_couple_activities',
                      {
                        'server_id': '',
                        'household_ref_key': householdRefKey,
                        'beneficiary_ref_key': spousKey,
                        'eligible_couple_state': 'tracking_due',
                        'device_details': jsonEncode({
                          'id': deviceInfo.deviceId,
                          'platform': deviceInfo.platform,
                          'version': deviceInfo.osVersion,
                        }),
                        'app_details': jsonEncode({
                          'app_version': deviceInfo.appVersion.split('+').first,
                        }),
                        'parent_user': '',
                        'current_user_key': ashaUniqueKey,
                        'facility_id': facilityId,
                        'created_date_time': ts,
                        'modified_date_time': ts,
                        'is_synced': 0,
                        'is_deleted': 0,
                      },
                      conflictAlgorithm: ConflictAlgorithm.ignore,
                    );

                    print('Inserted tracking_due (Non-pregnant)');
                  } else {
                    print('tracking_due record already exists, skipping insert');
                  }
                }
              } catch (e) {
                print('Error inserting eligible couple activity: $e');
              }
            }

          } catch (e) {
            print('Error saving spouse: $e');
            // Continue even if spouse save fails
          }
        }
        try {
          final savedMember = await LocalStorageDao.instance.getBeneficiaryByUniqueKey(memberId);
          if (savedMember != null) {
            final info = (savedMember['beneficiary_info'] is Map)
                ? Map<String, dynamic>.from(savedMember['beneficiary_info'])
                : (savedMember['beneficiary_info'] is String && (savedMember['beneficiary_info'] as String).isNotEmpty)
                    ? Map<String, dynamic>.from(jsonDecode(savedMember['beneficiary_info']))
                    : <String, dynamic>{};

            final currentUser2 = await UserInfo.getCurrentUser();
            final userDetails = currentUser2?['details'] is String
                ? jsonDecode(currentUser2?['details'] ?? '{}')
                : currentUser2?['details'] ?? {};
            final working = userDetails['working_location'] ?? {};

            String? genderCode(String? g) {
              if (g == null) return null;
              final s = g.toLowerCase();
              if (s.startsWith('m')) return 'M';
              if (s.startsWith('f')) return 'F';
              if (s.startsWith('o')) return 'O';
              return null;
            }

            String? yyyyMMdd(String? iso) {
              if (iso == null || iso.isEmpty) return null;
              try {
                final d = DateTime.tryParse(iso);
                if (d == null) return null;
                return DateFormat('yyyy-MM-dd').format(d);
              } catch (_) {
                return null;
              }
            }

            Map<String, dynamic> apiGeo(dynamic g) {
              try {
                if (g is String && g.isNotEmpty) g = jsonDecode(g);
                if (g is Map) {
                  final m = Map<String, dynamic>.from(g);
                  final lat = m['lat'] ?? m['latitude'] ?? m['Lat'] ?? m['Latitude'];
                  final lng = m['lng'] ?? m['long'] ?? m['longitude'] ?? m['Lng'];
                  final acc = m['accuracy_m'] ?? m['accuracy'] ?? m['Accuracy'];
                  final tsCap = m['captured_at'] ?? m['captured_datetime'] ?? m['timestamp'];
                  return {
                    'lat': (lat is num) ? lat : double.tryParse('${lat ?? ''}'),
                    'lng': (lng is num) ? lng : double.tryParse('${lng ?? ''}'),
                    'accuracy_m': (acc is num) ? acc : double.tryParse('${acc ?? ''}'),
                    'captured_at': tsCap?.toString() ?? DateTime.now().toUtc().toIso8601String(),
                  }..removeWhere((k, v) => v == null || (v is String && v.isEmpty));
                }
              } catch (_) {}
              return {
                'lat': null,
                'lng': null,
                'accuracy_m': null,
                'captured_at': DateTime.now().toUtc().toIso8601String(),
              }..removeWhere((k, v) => v == null || (v is String && v.isEmpty));
            }

            final nameStr = (info['name'] ?? '').toString();
            final beneficiaryInfoApi = {
              'name': {
                'first_name': nameStr,
                'middle_name': '',
                'last_name': '',
              },
              'gender': genderCode((info['gender'] ?? state.gender)?.toString()),
              'dob': yyyyMMdd(info['dob']?.toString()),
              'marital_status': (info['maritalStatus'] ?? state.maritalStatus)?.toString().toLowerCase(),
              'aadhaar': (info['aadhaar'] ?? info['aadhar'])?.toString(),
              'phone': (info['mobileNo'] ?? state.mobileNo)?.toString(),
              'address': {
                'state': working['state'] ?? userDetails['stateName'],
                'district': working['district'] ?? userDetails['districtName'],
                'block': working['block'] ?? userDetails['blockName'],
                'village': working['village'] ?? userDetails['villageName'],
                'pincode': working['pincode'] ?? userDetails['pincode'],
              }..removeWhere((k, v) => v == null || (v is String && v.trim().isEmpty)),

              // Extra flat fields required by backend sample schema,
              // mapped from existing local info/state when possible.
              'is_abha_verified': info['is_abha_verified'] ?? false,
              'is_rch_id_verified': info['is_rch_id_verified'] ?? false,
              'is_fetched_from_abha': info['is_fetched_from_abha'] ?? false,
              'is_fetched_from_rch': info['is_fetched_from_rch'] ?? false,
              'is_existing_father': info['is_existing_father'] ?? false,
              'is_existing_mother': info['is_existing_mother'] ?? false,
              'ben_type': info['ben_type'] ?? (info['memberType'] ?? state.memberType ?? 'adult'),
              'mother_ben_ref_key': info['mother_ben_ref_key'] ?? savedMember['mother_key']?.toString() ?? '',
              'father_ben_ref_key': info['father_ben_ref_key'] ?? savedMember['father_key']?.toString() ?? '',
              'relaton_with_family_head':
                  info['relaton_with_family_head'] ?? info['relation_to_head'] ?? state.relation,
              'member_status': info['member_status'] ?? state.memberStatus ?? 'alive',
              'member_name': info['member_name'] ?? nameStr,
              'father_or_spouse_name': info['father_or_spouse_name'] ?? info['fatherName'] ?? info['spouseName'],
              'have_children': info['have_children'] ?? info['hasChildren'] ?? state.hasChildren,
              'is_family_planning': info['is_family_planning'] ?? savedMember['is_family_planning'] ?? 0,
              'total_children': info['total_children'] ?? info['totalBorn'],
              'total_live_children': info['total_live_children'] ?? info['totalLive'],
              'total_male_children': info['total_male_children'] ?? info['totalMale'],
              'age_of_youngest_child': info['age_of_youngest_child'] ?? info['youngestAge'],
              'gender_of_younget_child': info['gender_of_younget_child'] ?? info['youngestGender'],
              'whose_mob_no': info['whose_mob_no'] ?? info['mobileOwner'],
              'mobile_no': info['mobile_no'] ?? info['mobileNo'] ?? state.mobileNo,
              'dob_day': info['dob_day'],
              'dob_month': info['dob_month'],
              'dob_year': info['dob_year'],
              'age_by': info['age_by'],
              'date_of_birth': info['date_of_birth'] ?? info['dob'],
              'age': info['age'] ?? info['approxAge'] ?? state.approxAge,
              'village_name': info['village_name'] ?? working['village'] ?? userDetails['villageName'],
              'is_new_member': info['is_new_member'] ?? true,
              'isFamilyhead': info['isFamilyhead'] ?? false,
              'isFamilyheadWife': info['isFamilyheadWife'] ?? false,
              'age_of_youngest_child_unit':
                  info['age_of_youngest_child_unit'] ?? info['ageUnit'],
              'type_of_beneficiary':
                  info['type_of_beneficiary'] ?? info['beneficiaryType'] ?? state.beneficiaryType,
              'name_of_spouse': info['name_of_spouse'] ?? info['spouseName'] ?? state.spouseName,
            }..removeWhere((k, v) => v == null || (v is String && v.trim().isEmpty));

            final apiPayload = {
              'unique_key': savedMember['unique_key'],
              'id': null,
              'household_ref_key': savedMember['household_ref_key'],
              'beneficiary_state': [
                {
                  'state': 'registered',
                  'at': DateTime.now().toUtc().toIso8601String(),
                },
                {
                  'state': (savedMember['beneficiary_state'] ?? 'active').toString(),
                  'at': DateTime.now().toUtc().toIso8601String(),
                },
              ],
              'pregnancy_count': savedMember['pregnancy_count'] ?? 0,
              'beneficiary_info': beneficiaryInfoApi,
              'geo_location': apiGeo(savedMember['geo_location']),
              'spouse_key': savedMember['spouse_key'],
              'mother_key': savedMember['mother_key'],
              'father_key': savedMember['father_key'],
              'is_family_planning': savedMember['is_family_planning'] ?? 0,
              'is_adult': savedMember['is_adult'] ?? 0,
              'is_guest': savedMember['is_guest'] ?? 0,
              'is_death': savedMember['is_death'] ?? 0,
              'death_details': savedMember['death_details'] is Map ? savedMember['death_details'] : {},
              'is_migrated': savedMember['is_migrated'] ?? 0,
              'is_separated': savedMember['is_separated'] ?? 0,
              'device_details': {
                'device_id': deviceInfo.deviceId,
                'model': deviceInfo.model,
                'os': deviceInfo.platform + ' ' + (deviceInfo.osVersion ?? ''),
                'app_version': deviceInfo.appVersion.split('+').first,
              },
              'app_details': {
                'captured_by_user': userDetails['user_identifier'] ?? '',
                'captured_role_id': userDetails['role_id'] ?? userDetails['role'] ?? 0,
                'source': 'mobile',
              },
              'parent_user': {
                'user_key': userDetails['supervisor_user_key'] ?? '',
                'name': userDetails['supervisor_name'] ?? '',
              }..removeWhere((k, v) => v == null || (v is String && v.trim().isEmpty)),
              'current_user_key': savedMember['current_user_key'] ?? facilityId,
              'facility_id': savedMember['facility_id'] ?? facilityId,
              'created_date_time': savedMember['created_date_time'] ?? ts,
              'modified_date_time': savedMember['modified_date_time'] ?? ts,
            };

            try {
              final repo = AddBeneficiaryRepository();
              final reqUniqueKey = (savedMember['unique_key'] ?? '').toString();
              final resp = await repo.addBeneficiary(apiPayload);
              try {
                if (resp is Map && (resp['success'] == true)) {
                  if (resp['data'] is List && (resp['data'] as List).isNotEmpty) {
                    final first = resp['data'][0];
                    if (first is Map) {
                      final sid = (first['_id'] ?? first['id'] ?? '').toString();
                      if (sid.isNotEmpty && reqUniqueKey.isNotEmpty) {
                        final updated = await LocalStorageDao.instance.updateBeneficiaryServerIdByUniqueKey(uniqueKey: reqUniqueKey, serverId: sid);
                        print('Updated member with server_id='+sid+' rows='+updated.toString());
                      }
                    }
                  } else if (resp['data'] is Map) {
                    final map = Map<String, dynamic>.from(resp['data']);
                    final sid = (map['_id'] ?? map['id'] ?? '').toString();
                    if (sid.isNotEmpty && reqUniqueKey.isNotEmpty) {
                      final updated = await LocalStorageDao.instance.updateBeneficiaryServerIdByUniqueKey(uniqueKey: reqUniqueKey, serverId: sid);
                      print('Updated member with server_id='+sid+' rows='+updated.toString());
                    }
                  }
                }
              } catch (e) {
                print('Error updating local member after API: $e');
              }
            } catch (apiErr) {
              print('add_beneficiary API failed for member, will sync later: $apiErr');
            }
          }
        } catch (e) {
          print('Error preparing or posting add_beneficiary for member: $e');
        }

        try {
          final unsynced = await LocalStorageDao.instance.getUnsyncedBeneficiaries();
          for (final savedMember in unsynced) {
            try {
              if ((savedMember['is_synced'] == 1) || (savedMember['is_synced']?.toString() == '1')) {
                continue;
              }

              final info = (savedMember['beneficiary_info'] is Map)
                  ? Map<String, dynamic>.from(savedMember['beneficiary_info'])
                  : (savedMember['beneficiary_info'] is String && (savedMember['beneficiary_info'] as String).isNotEmpty)
                      ? Map<String, dynamic>.from(jsonDecode(savedMember['beneficiary_info']))
                      : <String, dynamic>{};

              final currentUser2 = await UserInfo.getCurrentUser();
              final userDetails = currentUser2?['details'] is String
                  ? jsonDecode(currentUser2?['details'] ?? '{}')
                  : currentUser2?['details'] ?? {};
              final working = userDetails['working_location'] ?? {};

              String? genderCode(String? g) {
                if (g == null) return null;
                final s = g.toLowerCase();
                if (s.startsWith('m')) return 'M';
                if (s.startsWith('f')) return 'F';
                if (s.startsWith('o')) return 'O';
                return null;
              }

              String? yyyyMMdd(String? iso) {
                if (iso == null || iso.isEmpty) return null;
                try {
                  final d = DateTime.tryParse(iso);
                  if (d == null) return null;
                  return DateFormat('yyyy-MM-dd').format(d);
                } catch (_) {
                  return null;
                }
              }

              Map<String, dynamic> apiGeo(dynamic g) {
                try {
                  if (g is String && g.isNotEmpty) g = jsonDecode(g);
                  if (g is Map) {
                    final m = Map<String, dynamic>.from(g);
                    final lat = m['lat'] ?? m['latitude'] ?? m['Lat'] ?? m['Latitude'];
                    final lng = m['lng'] ?? m['long'] ?? m['longitude'] ?? m['Lng'];
                    final acc = m['accuracy_m'] ?? m['accuracy'] ?? m['Accuracy'];
                    final tsCap = m['captured_at'] ?? m['captured_datetime'] ?? m['timestamp'];
                    return {
                      'lat': (lat is num) ? lat : double.tryParse('${lat ?? ''}'),
                      'lng': (lng is num) ? lng : double.tryParse('${lng ?? ''}'),
                      'accuracy_m': (acc is num) ? acc : double.tryParse('${acc ?? ''}'),
                      'captured_at': tsCap?.toString() ?? DateTime.now().toUtc().toIso8601String(),
                    }..removeWhere((k, v) => v == null || (v is String && v.isEmpty));
                  }
                } catch (_) {}
                return {
                  'lat': null,
                  'lng': null,
                  'accuracy_m': null,
                  'captured_at': DateTime.now().toUtc().toIso8601String(),
                }..removeWhere((k, v) => v == null || (v is String && v.isEmpty));
              }

              final nameStr = (info['name'] ?? '').toString();
              final beneficiaryInfoApi = {
                'name': {
                  'first_name': nameStr,
                  'middle_name': '',
                  'last_name': '',
                },
                'gender': genderCode((info['gender'] ?? state.gender)?.toString()),
                'dob': yyyyMMdd(info['dob']?.toString()),
                'marital_status': (info['maritalStatus'] ?? state.maritalStatus)?.toString().toLowerCase(),
                'aadhaar': (info['aadhaar'] ?? info['aadhar'])?.toString(),
                'phone': (info['mobileNo'] ?? state.mobileNo)?.toString(),
                'address': {
                  'state': working['state'] ?? userDetails['stateName'],
                  'district': working['district'] ?? userDetails['districtName'],
                  'block': working['block'] ?? userDetails['blockName'],
                  'village': working['village'] ?? userDetails['villageName'],
                  'pincode': working['pincode'] ?? userDetails['pincode'],
                }..removeWhere((k, v) => v == null || (v is String && v.trim().isEmpty)),
              }..removeWhere((k, v) => v == null || (v is String && v.trim().isEmpty));

              final apiPayload = {
                'unique_key': savedMember['unique_key'],
                'id': null,
                'household_ref_key': savedMember['household_ref_key'],
                'beneficiary_state': [
                  {
                    'state': 'registered',
                    'at': DateTime.now().toUtc().toIso8601String(),
                  },
                  {
                    'state': (savedMember['beneficiary_state'] ?? 'active').toString(),
                    'at': DateTime.now().toUtc().toIso8601String(),
                  },
                ],
                'pregnancy_count': savedMember['pregnancy_count'] ?? 0,
                'beneficiary_info': beneficiaryInfoApi,
                'geo_location': apiGeo(savedMember['geo_location']),
                'spouse_key': savedMember['spouse_key'],
                'mother_key': savedMember['mother_key'],
                'father_key': savedMember['father_key'],
                'is_family_planning': savedMember['is_family_planning'] ?? 0,
                'is_adult': savedMember['is_adult'] ?? 0,
                'is_guest': savedMember['is_guest'] ?? 0,
                'is_death': savedMember['is_death'] ?? 0,
                'death_details': savedMember['death_details'] is Map ? savedMember['death_details'] : {},
                'is_migrated': savedMember['is_migrated'] ?? 0,
                'is_separated': savedMember['is_separated'] ?? 0,
                'device_details': {
                  'device_id': deviceInfo.deviceId,
                  'model': deviceInfo.model,
                  'os': deviceInfo.platform + ' ' + (deviceInfo.osVersion ?? ''),
                  'app_version': deviceInfo.appVersion.split('+').first,
                },
                'app_details': {
                  'captured_by_user': userDetails['user_identifier'] ?? '',
                  'captured_role_id': userDetails['role_id'] ?? userDetails['role'] ?? 0,
                  'source': 'mobile',
                },
                'parent_user': {
                  'user_key': userDetails['supervisor_user_key'] ?? '',
                  'name': userDetails['supervisor_name'] ?? '',
                }..removeWhere((k, v) => v == null || (v is String && v.trim().isEmpty)),
                'current_user_key': savedMember['current_user_key'] ?? savedMember['facility_id'],
                'facility_id': savedMember['facility_id'] ?? savedMember['facility_id'],
                'created_date_time': savedMember['created_date_time'] ?? DateTime.now().toIso8601String(),
                'modified_date_time': savedMember['modified_date_time'] ?? DateTime.now().toIso8601String(),
              };

              try {
                final repo = AddBeneficiaryRepository();
                final reqUniqueKey = (savedMember['unique_key'] ?? '').toString();
                final resp = await repo.addBeneficiary(apiPayload);
                try {
                  if (resp is Map && (resp['success'] == true)) {
                    if (resp['data'] is List && (resp['data'] as List).isNotEmpty) {
                      final first = resp['data'][0];
                      if (first is Map) {
                        final sid = (first['_id'] ?? first['id'] ?? '').toString();
                        if (sid.isNotEmpty && reqUniqueKey.isNotEmpty) {
                          await LocalStorageDao.instance.markBeneficiarySyncedByUniqueKey(uniqueKey: reqUniqueKey, serverId: sid);
                        }
                      }
                    } else if (resp['data'] is Map) {
                      final map = Map<String, dynamic>.from(resp['data']);
                      final sid = (map['_id'] ?? map['id'] ?? '').toString();
                      if (sid.isNotEmpty && reqUniqueKey.isNotEmpty) {
                        await LocalStorageDao.instance.markBeneficiarySyncedByUniqueKey(uniqueKey: reqUniqueKey, serverId: sid);
                      }
                    }
                  }
                } catch (e) {
                  print('Error marking local member synced after API: $e');
                }
              } catch (apiErr) {
                print('add_beneficiary API failed for unsynced member, will retry later: $apiErr');
              }
            } catch (e) {
              print('Error preparing payload for unsynced member: $e');
            }
          }
        } catch (e) {
          print('Error syncing unsynced beneficiaries: $e');
        }

        emit(state.copyWith(postApiStatus: PostApiStatus.success));
      } catch (e) {
        print('Error saving family member: $e');
        emit(
          state.copyWith(
            postApiStatus: PostApiStatus.error,
            errorMessage: 'Failed to save family member: ${e.toString()}',
          ),
        );
      }
    });

    on<AnmUpdateSubmit>((event, emit) async {
      emit(
        state.copyWith(postApiStatus: PostApiStatus.loading, clearError: true),
      );

      final errors = <String>[];
      if (state.relation == null || state.relation!.trim().isEmpty)
        errors.add('Please Enter Relation with family head');
      if (state.relation == 'Other' && (state.otherRelation == null || state.otherRelation!.trim().isEmpty))
        errors.add('Enter relation with family head');
      if (state.name == null || state.name!.trim().isEmpty)
        errors.add('Please enter Member name');
      if (state.gender == null || state.gender!.isEmpty)
        errors.add('Please enter Gender ');
      if (state.useDob) {
        if (state.dob == null) errors.add('Date of birth is required');
      } else {
        if (state.approxAge == null || state.approxAge!.trim().isEmpty)
          errors.add('Please enter Approximate age ');
      }
      if (state.mobileOwner == 'Other' && (state.mobileOwnerRelation == null || state.mobileOwnerRelation!.trim().isEmpty))
        errors.add('Enter relation with mobile holder');

      if (errors.isNotEmpty) {
        emit(
          state.copyWith(
            postApiStatus: PostApiStatus.error,
            errorMessage: errors.join('\n'),
          ),
        );
        return;
      }
      try {
        // We must have a beneficiary loaded for update
        if (_editingBeneficiaryKey == null || _editingBeneficiaryRowId == null) {
          emit(
            state.copyWith(
              postApiStatus: PostApiStatus.error,
              errorMessage: 'No beneficiary loaded for update.',
            ),
          );
          return;
        }

        final now = DateTime.now();
        final ts = DateFormat('yyyy-MM-dd HH:mm:ss').format(now);
        final deviceInfo = await DeviceInfo.getDeviceInfo();

        // Load the existing beneficiary row by unique_key so we can merge changes
        final existing = await LocalStorageDao.instance
            .getBeneficiaryByUniqueKey(_editingBeneficiaryKey!);
        if (existing == null) {
          emit(
            state.copyWith(
              postApiStatus: PostApiStatus.error,
              errorMessage: 'Beneficiary not found for update.',
            ),
          );
          return;
        }

        final householdRefKey = existing['household_ref_key']?.toString() ?? event.hhid;
        String? headId = existing['household_ref_key']?.toString();

        final currentUser = await UserInfo.getCurrentUser();
        final userDetails = currentUser?['details'] is String
            ? jsonDecode(currentUser?['details'] ?? '{}')
            : currentUser?['details'] ?? {};

        final working = userDetails['working_location'] ?? {};
        final facilityId = working['asha_associated_with_facility_id'] ??
            userDetails['asha_associated_with_facility_id'] ?? 0;
        final ashaUniqueKey = userDetails['unique_key'] ?? {};



        final geoLocation = await GeoLocation.getCurrentLocation();
        final locationData = Map<String, String>.from(geoLocation.toJson());
        locationData['source'] = 'gps';
        if (!geoLocation.hasCoordinates) {
          locationData['status'] = 'unavailable';
          locationData['reason'] = 'Could not determine location';
        }
        final geoLocationJson = jsonEncode(locationData);

        final beneficiaryState = _getBeneficiaryState(state.memberType);
        final isAdult = _getIsAdultValue(state.memberType, state.useDob, state.dob);

        final isDeath = (state.memberStatus?.toLowerCase() == 'death') ? 1 : 0;

        final deathDetails = isDeath == 1
            ? {
          'dateOfDeath': state.dateOfDeath?.toIso8601String(),
          'deathReason': state.deathReason,
          'otherDeathReason': state.otherDeathReason,
          'deathPlace': state.deathPlace,
        }
            : {};

        String? resolvedMotherKey2;
        String? resolvedFatherKey2;
        try {
          if (state.relation == 'Mother' || state.relation == 'Father' || state.relation == 'Child') {
            final hhBeneficiaries2 = await LocalStorageDao.instance
                .getBeneficiariesByHousehold(householdRefKey.toString());

            if (headId == null || headId.isEmpty) {
              for (final b in hhBeneficiaries2) {
                try {
                  final info = b['beneficiary_info'] is Map
                      ? Map<String, dynamic>.from(b['beneficiary_info'])
                      : <String, dynamic>{};
                  final relToHead = (info['relation_to_head'] ?? '').toString().toLowerCase();
                  final rel = (info['relation'] ?? '').toString().toLowerCase();
                  if (relToHead == 'self' || rel == 'head') {
                    headId = (b['unique_key'] ?? '').toString();
                    break;
                  }
                } catch (_) {}
              }
            }

            // Try to get spouse from head row first
            String? spouseKeyLocal;
            Map<String, dynamic>? spouseRecord;
            for (final b in hhBeneficiaries2) {
              if ((b['unique_key'] ?? '') == headId) {
                final headSpouseKey = b['spouse_key'];
                if (headSpouseKey != null && headSpouseKey.toString().isNotEmpty) {
                  spouseKeyLocal = headSpouseKey.toString();
                }
                break;
              }
            }

            // Fallback: find any beneficiary whose spouse_key equals headId
            if ((spouseKeyLocal == null || spouseKeyLocal.isEmpty) && headId != null && headId.isNotEmpty) {
              for (final b in hhBeneficiaries2) {
                if ((b['spouse_key'] ?? '').toString() == headId) {
                  spouseKeyLocal = (b['unique_key'] ?? '').toString();
                  spouseRecord = b as Map<String, dynamic>;
                  break;
                }
              }
            } else if (spouseKeyLocal != null && spouseKeyLocal.isNotEmpty) {
              // Find spouse record by unique key
              try {
                for (final b in hhBeneficiaries2) {
                  if ((b['unique_key'] ?? '').toString() == spouseKeyLocal) {
                    spouseRecord = b as Map<String, dynamic>;
                    break;
                  }
                }
              } catch (_) {}
            }

            if (state.relation == 'Mother') {
              resolvedMotherKey2 = headId;
              resolvedFatherKey2 = spouseKeyLocal;
            } else if (state.relation == 'Father') {
              resolvedFatherKey2 = headId;
              resolvedMotherKey2 = spouseKeyLocal;
            } else if (state.relation == 'Child') {
              // Infer parent keys based on genders of head and spouse
              Map<String, dynamic>? headRecord;
              for (final b in hhBeneficiaries2) {
                if ((b['unique_key'] ?? '') == headId) {
                  headRecord = b as Map<String, dynamic>;
                  break;
                }
              }

              final headInfo = headRecord != null && headRecord['beneficiary_info'] is Map
                  ? Map<String, dynamic>.from(headRecord['beneficiary_info'])
                  : <String, dynamic>{};
              final spouseInfo = spouseRecord != null && spouseRecord['beneficiary_info'] is Map
                  ? Map<String, dynamic>.from(spouseRecord['beneficiary_info'])
                  : <String, dynamic>{};
              final headGender = (headInfo['gender'] ?? '').toString().toLowerCase();
              final spouseGender = (spouseInfo['gender'] ?? '').toString().toLowerCase();

              // Assign based on gender where possible
              if (headGender == 'female') {
                resolvedMotherKey2 = headId;
                resolvedFatherKey2 = spouseKeyLocal;
              } else if (headGender == 'male') {
                resolvedFatherKey2 = headId;
                resolvedMotherKey2 = spouseKeyLocal;
              } else if (spouseGender.isNotEmpty) {
                if (spouseGender == 'female') {
                  resolvedMotherKey2 = spouseKeyLocal;
                  resolvedFatherKey2 = headId;
                } else if (spouseGender == 'male') {
                  resolvedFatherKey2 = spouseKeyLocal;
                  resolvedMotherKey2 = headId;
                }
              } else {
                resolvedMotherKey2 = headId;
                resolvedFatherKey2 = spouseKeyLocal;
              }
            }

            if (resolvedMotherKey2 != null && resolvedMotherKey2.trim().isEmpty) {
              resolvedMotherKey2 = null;
            }
            if (resolvedFatherKey2 != null && resolvedFatherKey2.trim().isEmpty) {
              resolvedFatherKey2 = null;
            }
            print('Resolved parent keys (UpdateSubmit): headId=$headId spouse=$spouseKeyLocal -> mother_key=$resolvedMotherKey2 father_key=$resolvedFatherKey2');
          }
        } catch (_) {}


        final existingInfoRaw = existing['beneficiary_info'];
        final Map<String, dynamic> existingInfo = existingInfoRaw is Map
            ? Map<String, dynamic>.from(existingInfoRaw)
            : (existingInfoRaw is String && existingInfoRaw.isNotEmpty)
            ? Map<String, dynamic>.from(jsonDecode(existingInfoRaw))
            : <String, dynamic>{};

        existingInfo
          ..['memberType'] = state.memberType
          ..['relation'] = state.relation
          ..['otherRelation'] = state.otherRelation
          ..['name'] = state.name
          ..['memberName'] = state.name
          ..['headName'] = existingInfo.containsKey('headName') ? state.name : existingInfo['headName']
          ..['fatherName'] = state.fatherName
          ..['motherName'] = state.motherName
          ..['useDob'] = state.useDob
          ..['dob'] = state.dob?.toIso8601String()
          ..['approxAge'] = state.approxAge
          ..['updateDay'] = state.updateDay
          ..['updateMonth'] = state.updateMonth
          ..['updateYear'] = state.updateYear
          ..['children'] = state.children
          ..['birthOrder'] = state.birthOrder
          ..['gender'] = state.gender
          ..['bankAcc'] = state.bankAcc
          ..['ifsc'] = state.ifsc
          ..['occupation'] = state.occupation == 'Other' && state.otherOccupation != null && state.otherOccupation!.isNotEmpty ? '${state.otherOccupation}_other' : state.occupation
          ..['education'] = state.education
          ..['religion'] = state.religion == 'Other' && state.otherReligion != null && state.otherReligion!.isNotEmpty ? '${state.otherReligion}_other' : state.religion
          ..['category'] = state.category == 'Other' && state.otherCategory != null && state.otherCategory!.isNotEmpty ? '${state.otherCategory}_other' : state.category
          ..['weight'] = state.WeightChange
          ..['childSchool'] = state.ChildSchool
          ..['birthCertificate'] = state.BirthCertificateChange
          ..['abhaAddress'] = state.abhaAddress
          ..['mobileOwner'] = state.mobileOwner
          ..['mobileOwnerRelation'] = state.mobileOwnerRelation == 'Other' && state.otherRelation != null && state.otherRelation!.isNotEmpty ? '${state.otherRelation}_other' : state.mobileOwnerRelation
          // Add other_* fields for proper prefill
          ..['other_religion'] = state.religion == 'Other' ? state.otherReligion : null
          ..['other_category'] = state.category == 'Other' ? state.otherCategory : null
          ..['other_occupation'] = state.occupation == 'Other' ? state.otherOccupation : null
          ..['other_relation'] = state.mobileOwnerRelation == 'Other' ? state.otherRelation : null
          ..['mobileNo'] = state.mobileNo
          ..['voterId'] = state.voterId
          ..['rationId'] = state.rationId
          ..['phId'] = state.phId
          ..['beneficiaryType'] = state.beneficiaryType
          ..['maritalStatus'] = state.maritalStatus
          ..['ageAtMarriage'] = state.ageAtMarriage
          ..['spouseName'] = state.spouseName
          ..['hasChildren'] = state.hasChildren
          ..['isPregnant'] = state.isPregnant
          ..['memberStatus'] = state.memberStatus
          ..['relation_to_head'] = state.relation;

        final updatedRow = Map<String, dynamic>.from(existing);
        updatedRow['beneficiary_info'] = existingInfo;
        updatedRow['beneficiary_state'] = beneficiaryState;
        updatedRow['is_adult'] = isAdult;
        updatedRow['is_death'] = isDeath;
        updatedRow['death_details'] = deathDetails;
        updatedRow['mother_key'] = resolvedMotherKey2;
        updatedRow['father_key'] = resolvedFatherKey2;
        updatedRow['geo_location'] = existing['geo_location'] ?? geoLocationJson;

        await LocalStorageDao.instance.updateBeneficiary(updatedRow);

        if (state.gender?.toLowerCase() == 'female' &&
            (state.isPregnant?.toLowerCase() == 'yes' || state.isPregnant?.toLowerCase() == 'true')) {
          try {
            final existingAnc = await LocalStorageDao.instance
                .getMotherCareActivityByBeneficiary(_editingBeneficiaryKey!);

            if (existingAnc == null) {
              // Get device info and current user details
              final deviceInfo = await DeviceInfo.getDeviceInfo();
              final now = DateTime.now();
              final ts = DateFormat('yyyy-MM-dd HH:mm:ss').format(now);
              final currentUser = await UserInfo.getCurrentUser();
              final userDetails = currentUser?['details'] is String
                  ? jsonDecode(currentUser?['details'] ?? '{}')
                  : currentUser?['details'] ?? {};
              final working = userDetails['working_location'] ?? {};
              final facilityId = working['asha_associated_with_facility_id'] ??
                  userDetails['asha_associated_with_facility_id'] ?? 0;
              final ashaUniqueKey = userDetails['unique_key'] ?? '';

              final motherCareActivityData = {
                'server_id': null,
                'household_ref_key': householdRefKey,
                'beneficiary_ref_key': _editingBeneficiaryKey!,
                'mother_care_state': 'anc_due',
                'device_details': jsonEncode({
                  'id': deviceInfo.deviceId,
                  'platform': deviceInfo.platform,
                  'version': deviceInfo.osVersion,
                }),
                'app_details': jsonEncode({
                  'app_version': deviceInfo.appVersion.split('+').first,
                  'app_name': deviceInfo.appName,
                  'build_number': deviceInfo.buildNumber,
                  'package_name': deviceInfo.packageName,
                }),
                'parent_user': jsonEncode({}),
                'current_user_key': ashaUniqueKey,
                'facility_id': facilityId,
                'created_date_time': ts,
                'modified_date_time': ts,
                'is_synced': 0,
                'is_deleted': 0,
              };

              print('Inserting mother care activity for updated pregnant member: ${jsonEncode(motherCareActivityData)}');
              await LocalStorageDao.instance.insertMotherCareActivity(motherCareActivityData);
            } else {
              print('ANC record already exists for this beneficiary, skipping insertion');
            }
          } catch (e) {
            print('Error inserting/checking mother care activity during update: $e');
          }
        }

        try {
          final String? partnerKey = existing['spouse_key']?.toString();
          final String? currentName = state.name;
          if (partnerKey != null && partnerKey.isNotEmpty && currentName != null && currentName.trim().isNotEmpty) {
            final partner = await LocalStorageDao.instance.getBeneficiaryByUniqueKey(partnerKey);
            if (partner != null) {
              final partnerInfoRaw = partner['beneficiary_info'];
              final Map<String, dynamic> partnerInfo = partnerInfoRaw is Map
                  ? Map<String, dynamic>.from(partnerInfoRaw)
                  : (partnerInfoRaw is String && partnerInfoRaw.isNotEmpty)
                  ? Map<String, dynamic>.from(jsonDecode(partnerInfoRaw))
                  : <String, dynamic>{};

              // Store edited member's name as spouseName on partner row
              partnerInfo['spouseName'] = currentName;

              final updatedPartner = Map<String, dynamic>.from(partner);
              updatedPartner['beneficiary_info'] = partnerInfo;

              await LocalStorageDao.instance.updateBeneficiary(updatedPartner);
            }
          }
        } catch (e) {
          print('Error updating partner spouseName during member update: $e');
        }

        emit(state.copyWith(postApiStatus: PostApiStatus.success));
      } catch (e) {
        print('Error saving family member (update submit): $e');
        emit(
          state.copyWith(
            postApiStatus: PostApiStatus.error,
            errorMessage: 'Failed to save family member: ${e.toString()}',
          ),
        );
      }
    });
  }
}
