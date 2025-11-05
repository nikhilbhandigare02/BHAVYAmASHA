import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'database_provider.dart';

class MigrationProcess {
  static final DatabaseProvider _dbProvider = DatabaseProvider.instance;

  /// Get a beneficiary by its unique key
  static Future<Map<String, dynamic>?> getBeneficiaryByUniqueKey(String uniqueKey) async {
    try {
      final db = await _dbProvider.database;
      final List<Map<String, dynamic>> results = await db.query(
        'beneficiaries',
        where: 'unique_key = ? AND is_deleted = 0',
        whereArgs: [uniqueKey],
        limit: 1,
      );

      if (results.isNotEmpty) {
        final beneficiary = Map<String, dynamic>.from(results.first);

        if (beneficiary['beneficiary_info'] is String) {
          try {
            beneficiary['beneficiary_info'] = jsonDecode(beneficiary['beneficiary_info']);
          } catch (e) {
            debugPrint('Error parsing beneficiary_info: $e');
          }
        }
        return beneficiary;
      }
      return null;
    } catch (e) {
      debugPrint('Error getting beneficiary by unique key: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> getParentDetails(String? parentKey) async {
    if (parentKey == null || parentKey.isEmpty) return null;

    try {
      final beneficiary = await getBeneficiaryByUniqueKey(parentKey);
      if (beneficiary == null) return null;

      final info = (beneficiary['beneficiary_info'] is Map)
          ? beneficiary['beneficiary_info']
          : {};

      final headDetails = (info['head_details'] is Map)
          ? info['head_details']
          : {};

      return {
        'id': beneficiary['id'],
        'unique_key': beneficiary['unique_key'],
        'name': headDetails['headName'] ?? 'Unknown',
        'age': headDetails['age'] ?? '',
        'gender': headDetails['gender'] ?? '',
        'relation': headDetails['relation'] ?? 'Parent',
      };
    } catch (e) {
      debugPrint('Error getting parent details: $e');
      return null;
    }
  }

  /// Get both mother and father details for a beneficiary
  static Future<Map<String, dynamic>> getParentsDetails(
      String? motherKey,
      String? fatherKey
      ) async {
    final mother = await getParentDetails(motherKey);
    final father = await getParentDetails(fatherKey);

    return {
      'mother': mother,
      'father': father,
    };
  }
}