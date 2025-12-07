import 'dart:convert';
import 'package:medixcel_new/data/NetworkAPIServices/APIs_Urls/Endpoints.dart';
import 'package:medixcel_new/data/NetworkAPIServices/api_services/network_services_API.dart';
import 'package:medixcel_new/data/models/guest_beneficiary/search_beneficiary_request.dart';
import 'package:medixcel_new/data/models/guest_beneficiary/search_beneficiary_response.dart';
import 'package:medixcel_new/data/Database/local_storage_dao.dart';

class GuestBeneficiaryRepository {
  final NetworkServiceApi _api;
  GuestBeneficiaryRepository({NetworkServiceApi? api}) : _api = api ?? NetworkServiceApi();

  Future<SearchBeneficiaryResponse> searchBeneficiary(String beneficiaryNumber) async {
    try {
      print('🔍 Searching beneficiary with number: $beneficiaryNumber');
      
      final request = SearchBeneficiaryRequest(
        beneficiaryNumber: beneficiaryNumber,
      );
      
      print('📤 Request: ${jsonEncode(request.toJson())}');
      
      final response = await _api.postApi(
        Endpoints.searchBeneficiary,
        request.toJson(),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );
      
      print('📥 Response: $response');
      
      try {
        await _persistGuestSearchResults(response);
      } catch (persistErr) {
        print('⚠️ Persist error (searchBeneficiary): $persistErr');
      }

      if (response is Map<String, dynamic>) {
        return SearchBeneficiaryResponse.fromJson(response);
      } else if (response is String) {
        return SearchBeneficiaryResponse.fromJson(jsonDecode(response));
      } else {
        throw Exception('Invalid response format');
      }
    } catch (e) {
      print('❌ Error in searchBeneficiary: $e');
      return SearchBeneficiaryResponse(
        success: false,
        message: e.toString(),
      );
    }
  }


  Future<Map<String, dynamic>> searchGuestBeneficiaries(Map<String, dynamic> data) async {
    final response = await _api.postApi('guest/search', data);
    try {
      await _persistGuestSearchResults(response);
    } catch (persistErr) {
      print('⚠️ Persist error (searchGuestBeneficiaries): $persistErr');
    }
    return response is String ? jsonDecode(response) : response;
  }

  Future<void> _persistGuestSearchResults(dynamic response) async {
    final Map<String, dynamic> respMap = response is String
        ? jsonDecode(response)
        : (response is Map<String, dynamic>)
            ? response
            : <String, dynamic>{};

    final List<dynamic> dataListDyn = (respMap['data'] is List) ? respMap['data'] as List : const [];
    final List<Map<String, dynamic>> dataList = dataListDyn
        .map((e) => e is Map<String, dynamic> ? e : <String, dynamic>{})
        .where((e) => e.isNotEmpty)
        .toList();

    if (dataList.isEmpty) {
      print('ℹ️ No records to persist from guest search');
      return;
    }

    int benInserted = 0;
    int benUpdated = 0;
    int hhInserted = 0;
    int hhSkipped = 0;

    for (final rec in dataList) {
      try {
        final serverId = (rec['_id'] ?? rec['id'])?.toString();
        final uniqueKey = rec['unique_key']?.toString();
        final deviceDetails = rec['device_details'];

        final Map<String, dynamic>? householdDetails =
            rec['household_details'] is Map<String, dynamic>
                ? Map<String, dynamic>.from(rec['household_details'] as Map)
                : null;

        final householdUniqueKey = householdDetails?['unique_key']?.toString();

        final benRow = <String, dynamic>{
          'server_id': serverId,
          'household_ref_key': rec['household_ref_key']?.toString() ?? householdUniqueKey,
          'unique_key': uniqueKey,
          'beneficiary_state': rec['beneficiary_status'],
          'pregnancy_count': rec['pregnancy_count'],
          'beneficiary_info': rec,
          'geo_location': rec['geo_location'],
          'spouse_key': rec['spouse_key']?.toString(),
          'mother_key': rec['mother_key']?.toString(),
          'father_key': rec['father_key']?.toString(),
          'is_family_planning': (rec['is_family_planning'] == true || rec['is_family_planning'] == 1) ? 1 : 0,
          'is_adult': (rec['is_adult'] == true || rec['is_adult'] == 1) ? 1 : 0,
          'is_guest': 1,
          'is_death': (rec['is_death'] == true || rec['is_death'] == 1) ? 1 : 0,
          'death_details': rec['death_details'],
          'is_migrated': (rec['is_migrated'] == true || rec['is_migrated'] == 1) ? 1 : 0,
          'is_separated': (rec['is_separated'] == true || rec['is_separated'] == 1) ? 1 : 0,
          'device_details': householdDetails != null && householdDetails['device_details'] != null
              ? householdDetails['device_details']
              : deviceDetails,
          'app_details': rec['app_details'],
          'parent_user': {
            'hsc_name': householdDetails?['hsc_name'],
            'asha_name': householdDetails?['asha_name'],
            'ashwin_id': householdDetails?['ashwin_id'],
          },
          'current_user_key': rec['current_user_key']?.toString(),
          'facility_id': rec['facility_id'],
          'created_date_time': rec['created_date_time']?.toString() ?? DateTime.now().toIso8601String(),
          'modified_date_time': rec['modified_date_time']?.toString() ?? DateTime.now().toIso8601String(),
          'is_synced': 1,
          'is_deleted': rec['is_deleted'] ?? 0,

        };

        if (uniqueKey != null && uniqueKey.isNotEmpty) {
          final existing = await LocalStorageDao.instance.getBeneficiaryByUniqueKey(uniqueKey);
          if (existing == null || existing.isEmpty) {
            await LocalStorageDao.instance.insertBeneficiary(benRow);
            benInserted++;
            try {
              await LocalStorageDao.instance.updateBeneficiaryParentUserByUniqueKey(
                uniqueKey: uniqueKey,
                parentUser: Map<String, dynamic>.from(benRow['parent_user'] as Map),
              );
            } catch (e) {
              print('Error enforcing parent_user after insert: $e');
            }
          } else {
            final updated = Map<String, dynamic>.from(existing)..addAll(benRow);
            updated['id'] = existing['id'];
            await LocalStorageDao.instance.updateBeneficiary(updated);
            benUpdated++;
            try {
              await LocalStorageDao.instance.updateBeneficiaryParentUserByUniqueKey(
                uniqueKey: uniqueKey,
                parentUser: Map<String, dynamic>.from(benRow['parent_user'] as Map),
              );
            } catch (e) {
              print('Error enforcing parent_user after update: $e');
            }
          }
        } else {
          await LocalStorageDao.instance.insertBeneficiary(benRow);
          benInserted++;
          try {
            final uk = benRow['unique_key']?.toString() ?? '';
            if (uk.isNotEmpty) {
              await LocalStorageDao.instance.updateBeneficiaryParentUserByUniqueKey(
                uniqueKey: uk,
                parentUser: Map<String, dynamic>.from(benRow['parent_user'] as Map),
              );
            }
          } catch (e) {
            print('Error enforcing parent_user after insert (no uniqueKey in rec): $e');
          }
        }

        if (householdDetails != null && householdDetails.isNotEmpty) {
          String? headId;
          dynamic members;

          // First try to get all_members from form_json
          if (householdDetails['form_json'] is Map<String, dynamic>) {
            members = (householdDetails['form_json'] as Map<String, dynamic>)['all_members'];
          }

          // Fallback to direct all_members
          members ??= householdDetails['all_members'];

          // CRITICAL FIX: If members is a String, parse it as JSON
          if (members is String) {
            try {
              members = jsonDecode(members);
            } catch (e) {
              print('Error parsing all_members JSON: $e');
              members = null;
            }
          }

          if (members is List) {
            for (final m in members) {
              try {
                String? rel;
                String? benKey;

                if (m is Map) {
                  // Check memberDetails first (this is where the data actually is)
                  final md = m['memberDetails'];
                  if (md is Map) {
                    rel = (md['relaton_with_family_head'] ?? md['relation_with_family_head'])?.toString();
                    benKey = md['beneficiary_key']?.toString();
                  }

                  // Fallback to top level if not found in memberDetails
                  if (rel == null || rel.isEmpty || benKey == null || benKey.isEmpty) {
                    rel = (m['relaton_with_family_head'] ?? m['relation_with_family_head'])?.toString() ?? rel;
                    benKey = (m['beneficiary_key'] ?? m['unique_key'])?.toString() ?? benKey;
                  }
                }

                // Check for 'self' or 'Self' relation
                if ((rel ?? '').toLowerCase() == 'self' && (benKey != null && benKey.isNotEmpty)) {
                  headId = benKey;
                  print('Found household head: $headId');
                  break;
                }
              } catch (e) {
                print('Error processing member: $e');
              }
            }
          }

          // If still no head found, log warning
          if (headId == null || headId.isEmpty) {
            print('Warning: No household head found for household: ${householdDetails['unique_key']}');
          }

          final hhRow = <String, dynamic>{
            'server_id': (householdDetails['_id'] ?? householdDetails['id'] ?? serverId)?.toString(),
            'unique_key': householdUniqueKey ?? uniqueKey,
            'address': householdDetails['address'] ?? {},
            'geo_location': householdDetails['geo_location'] ?? {},
            'head_id': headId,
            'household_info': (householdDetails['form_json'] ?? rec['form_json']) ?? rec,
            'device_details': deviceDetails ?? householdDetails['device_details'] ?? {},
            'app_details': rec['app_details'] ?? {},
            'parent_user': rec['parent_user'] ?? {},
            'current_user_key': rec['current_user_key']?.toString(),
            'facility_id': rec['facility_id'],
            'created_date_time': rec['created_date_time']?.toString() ?? householdDetails['created_date_time']?.toString(),
            'modified_date_time': rec['modified_date_time']?.toString() ?? householdDetails['modified_date_time']?.toString(),
            'is_synced': 1,
            'is_deleted': householdDetails['is_deleted'] ?? 0,
          };

          final existsH = (hhRow['unique_key']?.toString().isNotEmpty == true)
              ? await LocalStorageDao.instance.getHouseholdByUniqueKey(hhRow['unique_key']?.toString() ?? '')
              : null;

          if (existsH == null || existsH.isEmpty) {
            await LocalStorageDao.instance.insertHousehold(hhRow);
            hhInserted++;
            print('Household inserted: ${hhRow['unique_key']} with head_id: $headId');
          } else {
            hhSkipped++;
            print('Household skipped (already exists): ${hhRow['unique_key']}');
          }
        }
      } catch (e) {
        print('❌ Error persisting record: $e');
      }
    }

    print('✅ Persist summary: beneficiaries inserted=$benInserted, updated=$benUpdated, households inserted=$hhInserted, households skipped=$hhSkipped');
  }
}
