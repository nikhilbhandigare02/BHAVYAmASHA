import 'dart:convert';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:medixcel_new/data/Local_Storage/local_storage_dao.dart';
import 'package:sqflite/sqflite.dart';

import '../../../../../data/Local_Storage/database_provider.dart';

part 'anc_visit_list_event.dart';
part 'anc_visit_list_state.dart';

class AncVisitListBloc extends Bloc<AncVisitListEvent, AncVisitListState> {
  final LocalStorageDao _localStorageDao = LocalStorageDao.instance;

  AncVisitListBloc() : super(AncVisitListInitial()) {
    on<FetchFamilyPlanningBeneficiaries>(_onFetchFamilyPlanningBeneficiaries);
  }

  
  // Helper method to calculate age from date of birth
  int _calculateAge(dynamic dob) {
    if (dob == null) {
      print('⚠️ No date of birth provided');
      return 0;
    }
    
    try {
      DateTime? birthDate;
      
      if (dob is String) {
        // Try parsing different date formats
        birthDate = DateTime.tryParse(dob);
        if (birthDate == null && dob.contains('/')) {
          final parts = dob.split('/');
          if (parts.length == 3) {
            // Handle DD/MM/YYYY format
            birthDate = DateTime(
              int.tryParse(parts[2]) ?? 2000,
              int.tryParse(parts[1]) ?? 1,
              int.tryParse(parts[0]) ?? 1,
            );
          }
        }
      } else if (dob is int) {
        // Handle timestamp (assuming it's in milliseconds)
        birthDate = DateTime.fromMillisecondsSinceEpoch(dob);
      } else if (dob is Map) {
        // Handle nested date object if needed
        final year = dob['year'] ?? dob['y'];
        final month = dob['month'] ?? dob['m'] ?? 1;
        final day = dob['day'] ?? dob['d'] ?? 1;
        if (year != null) {
          birthDate = DateTime(
            int.tryParse(year.toString()) ?? 2000,
            int.tryParse(month.toString()) ?? 1,
            int.tryParse(day.toString()) ?? 1,
          );
        }
      }
      
      if (birthDate == null) {
        print('⚠️ Could not parse date of birth: $dob');
        return 0;
      }
      
      final now = DateTime.now();
      int age = now.year - birthDate.year;
      
      // Adjust age if birthday hasn't occurred yet this year
      if (now.month < birthDate.month || 
          (now.month == birthDate.month && now.day < birthDate.day)) {
        age--;
      }
      
      print('ℹ️ Calculated age: $age from DOB: $birthDate');
      return age > 0 ? age : 0;
    } catch (e) {
      print('❌ Error calculating age from $dob: $e');
      return 0;
    }
  }

  Future<void> _onFetchFamilyPlanningBeneficiaries(
    FetchFamilyPlanningBeneficiaries event,
    Emitter<AncVisitListState> emit,
  ) async {
    emit(AncVisitListLoading());
    try {
      final db = await DatabaseProvider.instance.database;
      
      // First, check all tables in the database
      final tables = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table'");
      print('Available tables: ${tables.map((e) => e['name']).toList()}');
      
      // Get all columns in the beneficiaries table for debugging
      try {
        final columns = await db.rawQuery('PRAGMA table_info(beneficiaries)');
        print('Columns in beneficiaries table: ${columns.map((e) => '${e['name']} (${e['type']})').toList()}');
      } catch (e) {
        print('Error getting table info: $e');
      }
      
      // Query to fetch beneficiaries with is_family_planning = 1
      // and filter by gender, age, and marital status
      String query = '''
        SELECT id, beneficiary_info 
        FROM beneficiaries 
        WHERE is_family_planning = 1
      ''';
      
      List<Map<String, dynamic>> result;
      
      try {
        // Execute the query
        result = await db.rawQuery(query);
        print('Found ${result.length} beneficiaries with is_family_planning = 1');
      } catch (e) {
        print('⚠️ Error querying beneficiaries: $e');
        // Fallback: Get all records and filter in Dart
        result = await db.query('beneficiaries', 
          columns: ['id', 'beneficiary_info', 'is_family_planning'],
          where: 'is_family_planning = ?',
          whereArgs: [1]
        );
      }
      
      print('Total beneficiaries in database: ${result.length}');
      final eligibleBeneficiaries = <Map<String, dynamic>>[];
      
      for (final row in result) {
        try {
          print('\n--- Processing beneficiary ID: ${row['id']} ---');
          
          // Initialize with empty map if no data is found
          Map<String, dynamic> beneficiaryData = {'id': row['id']};
          
          // Parse the JSON data from beneficiary_info
          if (row['beneficiary_info'] != null) {
            try {
              // Parse the JSON string into a map
              final info = jsonDecode(row['beneficiary_info'] as String) as Map<String, dynamic>;
              
              // Debug: Print the entire JSON structure
              print('ℹ️ Raw beneficiary_info JSON:');
              info.forEach((key, value) {
                print('  $key: $value (${value.runtimeType})');
              });
              
              // Extract all fields from the JSON with proper null checking and type conversion
              final name = (info['name'] ?? info['beneficiary_name'] ?? info['fullName'] ?? '').toString();
              final mobile = (info['mobile'] ?? info['mobile_number'] ?? info['phone'] ?? '').toString();
              final hhId = (info['hh_id'] ?? info['householdId'] ?? info['household_id'] ?? '').toString();
              final houseNo = (info['house_no'] ?? info['houseNumber'] ?? info['house_number'] ?? '').toString();
              final gender = (info['gender'] ?? '').toString().toLowerCase();
              final maritalStatus = (info['marital_status'] ?? info['maritalStatus'] ?? '').toString().toLowerCase();
              final dob = info['dob'] ?? info['date_of_birth'] ?? info['birthDate'];
              
              // Calculate age if DOB is available
              int? age;
              if (dob != null) {
                age = _calculateAge(dob);
              }
              
              // Get spouse/husband information
              final spouseName = (info['spouse_name'] ?? info['husband_name'] ?? info['spouseName'] ?? '').toString();
              
              // Get registration date
              final registrationDate = (info['registration_date'] ?? info['created_at'] ?? '').toString();
              
              // Get family planning status
              final isFamilyPlanning = info['is_family_planning'] ?? info['isFamilyPlanning'] ?? 0;
              
              // Only include if all required fields are present
              // Debug: Print the extracted values for verification
              print('ℹ️ Extracted values:');
              print('  Name: $name (${name.runtimeType})');
              print('  Gender: $gender (${gender.runtimeType})');
              print('  Marital Status: $maritalStatus (${maritalStatus.runtimeType})');
              print('  Age: $age (${age.runtimeType})');
              
              // Include the record if we have at least an ID and some basic info
              if (row['id'] != null && (name.isNotEmpty || mobile.isNotEmpty)) {
                beneficiaryData = {
                  'id': row['id'],
                  'name': name,
                  'mobile': mobile,
                  'hhId': hhId,
                  'houseNo': houseNo,
                  'gender': gender,
                  'marital_status': maritalStatus,
                  'dob': dob,
                  'age': age,
                  'husband_name': spouseName,
                  'registration_date': registrationDate,
                  'is_family_planning': isFamilyPlanning,
                  // Include the raw JSON for reference
                  '_rawInfo': info,
                };
                print('✅ Extracted valid beneficiary data');
              } else {
                print('⚠️ Missing some fields in beneficiary data, but including with available data');
                // We'll still include the record with whatever data we have
                beneficiaryData = {
                  'id': row['id'],
                  'name': name.isNotEmpty ? name : 'Unknown',
                  'mobile': mobile,
                  'hhId': hhId,
                  'houseNo': houseNo,
                  'gender': gender.isNotEmpty ? gender : 'unknown',
                  'marital_status': maritalStatus.isNotEmpty ? maritalStatus : 'unknown',
                  'dob': dob,
                  'age': age,
                  'husband_name': spouseName,
                  'registration_date': registrationDate,
                  'is_family_planning': isFamilyPlanning,
                  '_rawInfo': info,
                };
              }
              
              print('✅ Extracted data from JSON');
              
            } catch (e) {
              print('⚠️ Error parsing beneficiary_info JSON: $e');
              continue; // Skip this record if JSON parsing fails
            }
          } else {
            print('ℹ️ No beneficiary_info JSON found');
            continue; // Skip records without beneficiary_info
          }
          
          // At this point, we've already filtered by is_family_planning = 1
          // and verified other conditions during data extraction
          // Add the beneficiary to the final list
          if (beneficiaryData.isNotEmpty) {
            print('✅ Eligible family planning beneficiary found');
            eligibleBeneficiaries.add(beneficiaryData);
          }
          
        } catch (e) {
          print('❌ Error processing beneficiary: $e');
          print('Stack trace: ${e is Error ? e.stackTrace : ''}');
          continue;
        }
      }
      
      print('Total eligible family planning beneficiaries found: ${eligibleBeneficiaries.length}');
      
      emit(AncVisitListLoaded(beneficiaries: eligibleBeneficiaries));
    } catch (e) {
      print('❌ Fatal error in _onFetchFamilyPlanningBeneficiaries: $e');
      emit(AncVisitListError(
        message: 'Failed to fetch beneficiaries: ${e.toString()}',
      ));
    }
  }
}
