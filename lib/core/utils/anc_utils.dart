import 'dart:convert';

import '../../data/Database/database_provider.dart';
import '../../data/Database/local_storage_dao.dart';

class ANCUtils {
  static Future<int> getAncVisitCount() async {
    try {
      final Set<String> uniqueKeys = {};

      // Get regular pregnant women count
      final rows = await LocalStorageDao.instance.getAllBeneficiaries();
      for (final row in rows) {
        try {
          final dynamic rawInfo = row['beneficiary_info'];
          if (rawInfo == null) continue;

          Map<String, dynamic> info = rawInfo is String
              ? jsonDecode(rawInfo) as Map<String, dynamic>
              : Map<String, dynamic>.from(rawInfo as Map);

          final isPregnant = info['isPregnant']?.toString().toLowerCase() == 'yes';
          if (!isPregnant) continue;

          final gender = info['gender']?.toString().toLowerCase() ?? '';
          if (gender != 'f' && gender != 'female') continue;

          final uniqueKey = row['unique_key']?.toString();
          if (uniqueKey != null) {
            uniqueKeys.add(uniqueKey);
          }
        } catch (e) {
          print('Error processing regular beneficiary: $e');
        }
      }

      final db = await DatabaseProvider.instance.database;
      final ancDueRecords = await db.rawQuery('''
        SELECT DISTINCT mca.beneficiary_ref_key
        FROM mother_care_activities mca
        INNER JOIN beneficiaries_new bn ON mca.beneficiary_ref_key = bn.unique_key
        WHERE mca.mother_care_state = 'anc_due' 
          AND bn.is_deleted = 0
      ''');

      // Add unique ANC due records to our count
      for (final record in ancDueRecords) {
        final key = record['beneficiary_ref_key']?.toString();
        if (key != null && !uniqueKeys.contains(key)) {
          uniqueKeys.add(key);
        }
      }

      return uniqueKeys.length;
    } catch (e) {
      print('Error getting ANC visit count: $e');
      return 0;
    }
  }

  static Future<int> getMotherCareTotalCount() async {
    try {
      final db = await DatabaseProvider.instance.database;

      final ancDueRecords = await db.rawQuery('''
        SELECT DISTINCT mca.beneficiary_ref_key
        FROM mother_care_activities mca
        INNER JOIN beneficiaries_new bn ON mca.beneficiary_ref_key = bn.unique_key
        WHERE mca.mother_care_state = 'anc_due' AND bn.is_deleted = 0
      ''');

      final Set<String> ancDueBeneficiaryIds = ancDueRecords
          .map((e) => e['beneficiary_ref_key']?.toString() ?? '')
          .where((id) => id.isNotEmpty)
          .toSet();

      final deliveryOutcomes = await db.query(
        'followup_form_data',
        where: "forms_ref_key = 'bt7gs9rl1a5d26mz' AND form_json LIKE '%\"gives_birth_to_baby\":\"Yes\"%'",
        columns: ['beneficiary_ref_key'],
      );

      final Set<String?> deliveredBeneficiaryIds = deliveryOutcomes
          .map((e) => e['beneficiary_ref_key']?.toString())
          .where((id) => id != null && id.isNotEmpty)
          .toSet();

      final rows = await LocalStorageDao.instance.getAllBeneficiaries();
      final Set<String> ancUniqueBeneficiaries = {};
      for (final row in rows) {
        try {
          final dynamic rawInfo = row['beneficiary_info'];
          if (rawInfo == null) continue;
          Map<String, dynamic> info = rawInfo is String
              ? jsonDecode(rawInfo) as Map<String, dynamic>
              : Map<String, dynamic>.from(rawInfo as Map);
          final isPregnant = info['isPregnant']?.toString().toLowerCase() == 'yes';
          final gender = info['gender']?.toString().toLowerCase() ?? '';
          final beneficiaryId = row['unique_key']?.toString() ?? '';
          final isAncDue = ancDueBeneficiaryIds.contains(beneficiaryId);
          if (deliveredBeneficiaryIds.contains(beneficiaryId)) {
            continue;
          }
          if ((isPregnant || isAncDue) && (gender == 'f' || gender == 'female')) {
            if (beneficiaryId.isNotEmpty) {
              ancUniqueBeneficiaries.add(beneficiaryId);
            }
          }
        } catch (_) {}
      }
      for (final id in ancDueBeneficiaryIds) {
        if (id.isNotEmpty && !deliveredBeneficiaryIds.contains(id)) {
          ancUniqueBeneficiaries.add(id);
        }
      }
      final int ancCount = ancUniqueBeneficiaries.length;

      const ancRefKey = 'bt7gs9rl1a5d26mz';
      final ancForms = await db.rawQuery('''
        SELECT f.beneficiary_ref_key, f.form_json, f.household_ref_key, f.forms_ref_key, f.created_date_time, f.id as form_id
        FROM followup_form_data f
        WHERE f.forms_ref_key = '$ancRefKey' AND f.form_json LIKE '%"gives_birth_to_baby":"Yes"%' AND f.is_deleted = 0
        ORDER BY f.created_date_time DESC
      ''');
      final String deliveryOutcomeKey = '4r7twnycml3ej1vg';
      final Set<String> beneficiariesNeedingOutcome = {};
      final Set<String> beneficiariesProcessed = {};
      for (final form in ancForms) {
        try {
          final beneficiaryRefKey = form['beneficiary_ref_key']?.toString();
          if (beneficiaryRefKey == null || beneficiaryRefKey.isEmpty) continue;
          if (beneficiariesProcessed.contains(beneficiaryRefKey)) continue;
          beneficiariesProcessed.add(beneficiaryRefKey);
          final existingOutcome = await db.query(
            'followup_form_data',
            where: 'forms_ref_key = ? AND beneficiary_ref_key = ? AND is_deleted = 0',
            whereArgs: [deliveryOutcomeKey, beneficiaryRefKey],
            limit: 1,
          );
          if (existingOutcome.isNotEmpty) continue;
          beneficiariesNeedingOutcome.add(beneficiaryRefKey);
        } catch (_) {}
      }
      final int deliveryOutcomeCount = beneficiariesNeedingOutcome.length;

      final dbOutcomes = await db.query(
        'followup_form_data',
        where: 'forms_ref_key = ?',
        whereArgs: [deliveryOutcomeKey],
      );
      final Set<String> processedBeneficiaries = <String>{};
      for (final outcome in dbOutcomes) {
        try {
          final beneficiaryRefKey = outcome['beneficiary_ref_key']?.toString();
          if (beneficiaryRefKey == null || beneficiaryRefKey.isEmpty) continue;
          if (processedBeneficiaries.contains(beneficiaryRefKey)) continue;
          final beneficiaryResults = await db.query(
            'beneficiaries_new',
            where: 'unique_key = ?',
            whereArgs: [beneficiaryRefKey],
          );
          if (beneficiaryResults.isEmpty) continue;
          final beneficiaryInfoRaw = beneficiaryResults.first['beneficiary_info'] as String? ?? '{}';
          try {
            jsonDecode(beneficiaryInfoRaw) as Map<String, dynamic>;
            processedBeneficiaries.add(beneficiaryRefKey);
          } catch (_) {}
        } catch (_) {}
      }
      final int hbcnMotherCount = processedBeneficiaries.length;

      return ancCount + deliveryOutcomeCount + hbcnMotherCount;
    } catch (e) {
      return 0;
    }
  }


  static Future<int> getMotherCareTotalSyncCount() async {
    try {
      final db = await DatabaseProvider.instance.database;

      final ancDueRecords = await db.rawQuery('''
        SELECT DISTINCT mca.beneficiary_ref_key
        FROM mother_care_activities mca
        INNER JOIN beneficiaries_new bn ON mca.beneficiary_ref_key = bn.unique_key
        WHERE mca.mother_care_state = 'anc_due' AND bn.is_deleted = 0
      ''');

      final ancAllRecords = await db.rawQuery('''
        SELECT DISTINCT mca.beneficiary_ref_key
        FROM mother_care_activities mca
        INNER JOIN beneficiaries_new bn ON mca.beneficiary_ref_key = bn.unique_key
        WHERE mca.mother_care_state = 'anc_due' AND bn.is_deleted = 0
      ''');

      final Set<String> ancDueBeneficiaryIds = ancDueRecords
          .map((e) => e['beneficiary_ref_key']?.toString() ?? '')
          .where((id) => id.isNotEmpty)
          .toSet();

      final deliveryOutcomes = await db.query(
        'followup_form_data',
        where: "forms_ref_key = 'bt7gs9rl1a5d26mz' AND form_json LIKE '%\"gives_birth_to_baby\":\"Yes\"%'",
        columns: ['beneficiary_ref_key'],
      );

      final Set<String?> deliveredBeneficiaryIds = deliveryOutcomes
          .map((e) => e['beneficiary_ref_key']?.toString())
          .where((id) => id != null && id.isNotEmpty)
          .toSet();

      final rows = await LocalStorageDao.instance.getAllBeneficiaries();
      final Set<String> ancUniqueBeneficiaries = {};
      for (final row in rows) {
        try {
          final dynamic rawInfo = row['beneficiary_info'];
          if (rawInfo == null) continue;
          Map<String, dynamic> info = rawInfo is String
              ? jsonDecode(rawInfo) as Map<String, dynamic>
              : Map<String, dynamic>.from(rawInfo as Map);
          final isPregnant = info['isPregnant']?.toString().toLowerCase() == 'yes';
          final gender = info['gender']?.toString().toLowerCase() ?? '';
          final beneficiaryId = row['unique_key']?.toString() ?? '';
          final isAncDue = ancDueBeneficiaryIds.contains(beneficiaryId);
          if (deliveredBeneficiaryIds.contains(beneficiaryId)) {
            continue;
          }
          if ((isPregnant || isAncDue) && (gender == 'f' || gender == 'female')) {
            if (beneficiaryId.isNotEmpty) {
              ancUniqueBeneficiaries.add(beneficiaryId);
            }
          }
        } catch (_) {}
      }
      for (final id in ancDueBeneficiaryIds) {
        if (id.isNotEmpty && !deliveredBeneficiaryIds.contains(id)) {
          ancUniqueBeneficiaries.add(id);
        }
      }
      final int ancCount = ancUniqueBeneficiaries.length;

      final int ancCountSync = rows.where((r) {
        final id = r['unique_key']?.toString() ?? '';
        final isSynced = (r['is_synced'] ?? 0) == 1;

        return ancUniqueBeneficiaries.contains(id) && isSynced;
      }).length;

      const ancRefKey = 'bt7gs9rl1a5d26mz';
      final ancForms = await db.rawQuery('''
        SELECT f.beneficiary_ref_key, f.form_json, f.household_ref_key, f.forms_ref_key, f.created_date_time, f.id as form_id, f.is_synced
        FROM followup_form_data f
        WHERE f.forms_ref_key = '$ancRefKey' AND f.form_json LIKE '%"gives_birth_to_baby":"Yes"%' AND f.is_deleted = 0
        ORDER BY f.created_date_time DESC
      ''');
      final String deliveryOutcomeKey = '4r7twnycml3ej1vg';
      final Set<String> beneficiariesNeedingOutcome = {};
      final Set<String> beneficiariesProcessed = {};
      for (final form in ancForms) {
        try {
          final beneficiaryRefKey = form['beneficiary_ref_key']?.toString();
          if (beneficiaryRefKey == null || beneficiaryRefKey.isEmpty) continue;
          if (beneficiariesProcessed.contains(beneficiaryRefKey)) continue;
          beneficiariesProcessed.add(beneficiaryRefKey);
          final existingOutcome = await db.query(
            'followup_form_data',
            where: 'forms_ref_key = ? AND beneficiary_ref_key = ? AND is_deleted = 0',
            whereArgs: [deliveryOutcomeKey, beneficiaryRefKey],
            limit: 1,
          );
          if (existingOutcome.isNotEmpty) continue;
          beneficiariesNeedingOutcome.add(beneficiaryRefKey);
        } catch (_) {}
      }
      final int deliveryOutcomeCount = beneficiariesNeedingOutcome.length;

      final int deliveryOutcomeSyncedCount = ancDueRecords.where((r) {
        final id = (r['unique_key'] ?? '').toString();
        final isSynced = (r['is_synced'] ?? 0) == 1;

        return beneficiariesNeedingOutcome.contains(id) && isSynced;
      }).length;


      final dbOutcomes = await db.query(
        'followup_form_data',
        where: 'forms_ref_key = ?',
        whereArgs: [deliveryOutcomeKey],
      );
      final Set<String> processedBeneficiaries = <String>{};
      for (final outcome in dbOutcomes) {
        try {
          final beneficiaryRefKey = outcome['beneficiary_ref_key']?.toString();
          if (beneficiaryRefKey == null || beneficiaryRefKey.isEmpty) continue;
          if (processedBeneficiaries.contains(beneficiaryRefKey)) continue;
          final beneficiaryResults = await db.query(
            'beneficiaries_new',
            where: 'unique_key = ?',
            whereArgs: [beneficiaryRefKey],
          );
          if (beneficiaryResults.isEmpty) continue;
          final beneficiaryInfoRaw = beneficiaryResults.first['beneficiary_info'] as String? ?? '{}';
          try {
            jsonDecode(beneficiaryInfoRaw) as Map<String, dynamic>;
            processedBeneficiaries.add(beneficiaryRefKey);
          } catch (_) {}
        } catch (_) {}
      }
      final int hbcnMotherCount = processedBeneficiaries.length;

      final int hbcnMotherSyncedCount = dbOutcomes.where((r) {
        final id = (r['unique_key'] ?? '').toString();
        if (id.isEmpty) return false;

        final isSynced = (r['is_synced'] ?? 0) == 1;

        return processedBeneficiaries.contains(id) && isSynced;
      }).length;

      /*_motherCareSynced = ancCountSync + deliveryOutcomeSyncedCount +hbcnMotherSyncedCount;
      _motherCareTotal = ancCount + deliveryOutcomeCount + hbcnMotherCount;
*/

      /*  setState(() {
        _motherCareSynced;
        _motherCareTotal;
      });*/
      return ancCountSync + deliveryOutcomeSyncedCount +hbcnMotherSyncedCount;
    } catch (e) {
      return 0;
    }
  }
}
