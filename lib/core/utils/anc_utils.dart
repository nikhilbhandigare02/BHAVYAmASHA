import 'dart:convert';

import '../../data/Database/database_provider.dart';
import '../../data/Database/local_storage_dao.dart';

class ANCUtils {

  static Future<Map<String, int>> _loadAncVisitCount() async {
    try {
      final db = await DatabaseProvider.instance.database;

      final deliveredIds = await _getDeliveredBeneficiaryIds();
      final ancDueIds = await _getAncDueBeneficiaryIds();

      final rows = await LocalStorageDao.instance.getAllBeneficiaries();

      final Set<String> countedIds = {};
      int syncedCount = 0;

      for (final row in rows) {
        final rawInfo = row['beneficiary_info'];
        if (rawInfo == null) continue;

        final info = rawInfo is String
            ? jsonDecode(rawInfo)
            : Map<String, dynamic>.from(rawInfo);

        final beneficiaryId = row['unique_key']?.toString() ?? '';
        if (beneficiaryId.isEmpty) continue;

        // ❌ Exclude delivered
        if (deliveredIds.contains(beneficiaryId)) continue;

        final gender = info['gender']?.toString().toLowerCase() ?? '';
        if (gender != 'f' && gender != 'female') continue;

        final isPregnant =
            info['isPregnant']?.toString().toLowerCase() == 'yes';
        final isAncDue = ancDueIds.contains(beneficiaryId);

        if (isPregnant || isAncDue) {
          countedIds.add(beneficiaryId);

          final syncRows = await db.rawQuery('''
          SELECT 1
          FROM mother_care_activities
          WHERE beneficiary_ref_key = ?
            AND is_synced = 1
          LIMIT 1
        ''', [beneficiaryId]);

          if (syncRows.isNotEmpty) {
            syncedCount++;
          }
        }
      }

      print('✅ ANC total count: ${countedIds.length}');
      print('🔄 Synced ANC count: $syncedCount');

      // ✅ ONLY RETURN CHANGED
      return {
        'total': countedIds.length,
        'synced': syncedCount,
      };
    } catch (e, s) {
      return {
        'total': 0,
        'synced': 0,
      };
    }
  }


  static Future<int> getMotherCareTotalCount() async {
    try {
      final db = await DatabaseProvider.instance.database;

      final deliveredIds = await _getDeliveredBeneficiaryIds();

      final ancResult = await _loadAncVisitCount();
      final deliveryOutcomeResult = await _getDeliveryOutcomeCount();
      final hbncResult = await _getHBNCCount();

      final ancTotal = ancResult['total'] ?? 0;
      final deliveryOutcomeCount = deliveryOutcomeResult['total'] ?? 0;
      final hbncCount = hbncResult['total'] ?? 0;

      final totalCount = ancTotal + deliveryOutcomeCount + hbncCount;

      print('''
Mother Care Counts:
  Pregnant/ANC Due: $ancTotal
  Delivery Outcome: $deliveryOutcomeCount
  HBNC: $hbncCount
  Total: $totalCount
''');

      return totalCount;
    } catch (e) {
      print('Error in getMotherCareTotalCount: $e');
      return 0;
    }
  }

  static Future<Set<String>> _getDeliveredBeneficiaryIds() async {
    final db = await DatabaseProvider.instance.database;

    final rows = await db.query(
      'followup_form_data',
      where: '''
      forms_ref_key = ?
      AND LOWER(form_json) LIKE ?
    ''',
      whereArgs: [
        'bt7gs9rl1a5d26mz',
        '%"gives_birth_to_baby":"yes"%',
      ],
      columns: ['beneficiary_ref_key'],
      distinct: true,
    );

    return rows
        .map((e) => e['beneficiary_ref_key']?.toString())
        .where((id) => id != null && id.isNotEmpty)
        .cast<String>()
        .toSet();
  }

  static Future<Set<String>> _getAncDueBeneficiaryIds() async {
    final db = await DatabaseProvider.instance.database;

    final rows = await db.rawQuery('''
     SELECT mca.*
FROM mother_care_activities mca
INNER JOIN (
    SELECT beneficiary_ref_key,
           MAX(created_date_time) AS max_date
    FROM mother_care_activities
    WHERE mother_care_state = 'anc_due'
    GROUP BY beneficiary_ref_key
) latest
  ON mca.beneficiary_ref_key = latest.beneficiary_ref_key
 AND mca.created_date_time = latest.max_date
INNER JOIN beneficiaries_new bn
  ON mca.beneficiary_ref_key = bn.unique_key
WHERE bn.is_deleted = 0;
  ''');

    return rows
        .map((e) => e['beneficiary_ref_key']?.toString())
        .where((id) => id != null && id.isNotEmpty)
        .cast<String>()
        .toSet();
  }

  static Future<Map<String, int>> _getDeliveryOutcomeCount() async {
    final db = await DatabaseProvider.instance.database;
    const ancRefKey = 'bt7gs9rl1a5d26mz';
    const deliveryOutcomeKey = '4r7twnycml3ej1vg';

    final rows = await db.rawQuery('''
    WITH LatestForms AS (
      SELECT
        f.beneficiary_ref_key,
        ROW_NUMBER() OVER (
          PARTITION BY f.beneficiary_ref_key
          ORDER BY f.created_date_time DESC, f.id DESC
        ) AS rn
      FROM followup_form_data f
      WHERE
        f.forms_ref_key = '$ancRefKey'
        AND f.is_deleted = 0
        AND f.form_json LIKE '%"gives_birth_to_baby":"Yes"%'
    )
    SELECT beneficiary_ref_key
    FROM (
      SELECT beneficiary_ref_key
      FROM LatestForms
      WHERE rn = 1

      UNION

      SELECT mca.beneficiary_ref_key
      FROM mother_care_activities mca
      WHERE
        mca.mother_care_state = 'delivery_outcome'
        AND mca.is_deleted = 0
    ) t
    WHERE beneficiary_ref_key NOT IN (
      SELECT beneficiary_ref_key
      FROM followup_form_data
      WHERE
        forms_ref_key = '$deliveryOutcomeKey'
        AND is_deleted = 0
    )
  ''');

    final Set<String> countedBeneficiaries = {};
    int syncedCount = 0;

    for (final row in rows) {
      final beneficiaryRefKey = row['beneficiary_ref_key']?.toString();
      if (beneficiaryRefKey == null || beneficiaryRefKey.isEmpty) continue;

      countedBeneficiaries.add(beneficiaryRefKey);

      final syncRows = await db.rawQuery('''
      SELECT 1
      FROM mother_care_activities
      WHERE beneficiary_ref_key = ?
        AND is_synced = 1
      LIMIT 1
    ''', [beneficiaryRefKey]);

      if (syncRows.isNotEmpty) {
        syncedCount++;
      }
    }

    print('✅ Delivery outcome total count: ${countedBeneficiaries.length}');
    print('🔄 Delivery outcome synced count: $syncedCount');

    // ✅ ONLY RETURN CHANGED
    return {
      'total': countedBeneficiaries.length,
      'synced': syncedCount,
    };
  }

  static Future<Map<String, int>> _getHBNCCount() async {
    final db = await DatabaseProvider.instance.database;
    const deliveryOutcomeKey = '4r7twnycml3ej1vg';

    try {
      // First, get all beneficiary_ref_keys that have either pnc_mother or hbnc_visit state
      final validBeneficiaries = await db.rawQuery('''
    SELECT DISTINCT mca.beneficiary_ref_key,
           MAX(CASE WHEN mca.is_synced = 1 THEN 1 ELSE 0 END) as has_synced
    FROM mother_care_activities mca
    WHERE mca.mother_care_state IN ('pnc_mother', 'hbnc_visit')
    AND mca.is_deleted = 0
    GROUP BY mca.beneficiary_ref_key
  ''');

      if (validBeneficiaries.isEmpty) {
        print('ℹ️ No beneficiaries found with pnc_mother or hbnc_visit state');
        return {'total': 0, 'synced': 0};
      }

      final beneficiaryKeys = validBeneficiaries.map((e) => e['beneficiary_ref_key'] as String).toList();
      final placeholders = List.filled(beneficiaryKeys.length, '?').join(',');

      // Get delivery outcome records only for valid beneficiaries
      final deliveryOutcomeBeneficiaries = await db.rawQuery('''
    SELECT DISTINCT beneficiary_ref_key 
    FROM followup_form_data ffd
    INNER JOIN beneficiaries_new bn
      ON bn.unique_key = ffd.beneficiary_ref_key
    WHERE ffd.forms_ref_key = ? 
    AND ffd.is_deleted = 0
    AND ffd.beneficiary_ref_key IN ($placeholders)
  ''', [deliveryOutcomeKey, ...beneficiaryKeys]);

      // Create a set of beneficiaries with delivery outcomes
      final deliveryOutcomeBeneficiarySet = {
        for (var e in deliveryOutcomeBeneficiaries)
          e['beneficiary_ref_key'] as String
      };

      // Count synced records from the valid beneficiaries that also have delivery outcomes
      int syncedCount = 0;
      for (final beneficiary in validBeneficiaries) {
        final beneficiaryRefKey = beneficiary['beneficiary_ref_key'] as String;
        final hasSynced = (beneficiary['has_synced'] as int) == 1;

        if (deliveryOutcomeBeneficiarySet.contains(beneficiaryRefKey) && hasSynced) {
          syncedCount++;
        }
      }

      final totalCount = deliveryOutcomeBeneficiarySet.length;
      print('✅ HBNC total processed count: $totalCount');
      print('🔄 HBNC synced count: $syncedCount');

      return {
        'total': totalCount,
        'synced': syncedCount,
      };
    } catch (e) {
      print('❌ Error in _getHBNCCount: $e');
      return {'total': 0, 'synced': 0};
    }
  }

  static Future<int> getMotherCareSyncedTotalCount() async {
    try {
      final ancResult = await _loadAncVisitCount();
      final deliveryOutcomeResult = await _getDeliveryOutcomeCount();
      final hbncResult = await _getHBNCCount();

      final ancSynced = ancResult['synced'] ?? 0;
      final deliveryOutcomeSynced = deliveryOutcomeResult['synced'] ?? 0;
      final hbncSynced = hbncResult['synced'] ?? 0;

      final totalSynced =
          ancSynced + deliveryOutcomeSynced + hbncSynced;

      print('''
Mother Care Synced Counts:
  ANC Synced: $ancSynced
  Delivery Outcome Synced: $deliveryOutcomeSynced
  HBNC Synced: $hbncSynced
  Total Synced: $totalSynced
''');

      return totalSynced;
    } catch (e) {
      print('Error in getMotherCareSyncedTotalCount: $e');
      return 0;
    }
  }


}
