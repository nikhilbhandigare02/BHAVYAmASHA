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
}
