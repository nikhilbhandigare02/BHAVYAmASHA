import 'dart:convert' show jsonDecode, jsonEncode;

import 'package:sqflite/sqflite.dart';

class DbMigration {
  static Future<void> runUserTableMigration(Database db) async {
    try {
      await db.rawInsert('''
  INSERT INTO users (
      user_name,
      password,
      role_id,
      details,
      created_date_time,
      modified_date_time,
      is_deleted
  )
  SELECT 
      a.user_name,
      a.password,
      a.app_user_role_ref,
      a.details,
      a.created_date_time,
      a.modified_date_time,
      a.is_deleted
  FROM appUsers a
  WHERE NOT EXISTS (
      SELECT 1 
      FROM users u 
      WHERE 
         (u.user_name = a.user_name) OR 
         (u.user_name IS NULL AND a.user_name IS NULL)
  );
''');
    } catch (e) {
      print("❌ Migration error: $e");
    }
  }


  final Map<String, String> keyMapping = {
    "beneficiaryType": "type_of_beneficiary",

    // 🔹 Basic identity
    "memberType": "ben_type",
    "relation": "relaton_with_family_head",
    "relation_to_head": "relaton_with_family_head",
    "name": "member_name",
    "memberName": "member_name",
    "motherName": "mother_name",
    "headName": "mother_name",
    "fatherName": "father_name",
    "spouseName": "father_or_spouse_name",

    // 🔹 Age / DOB
    "dob": "date_of_birth",
    "dob_day": "dob_day",
    "dob_month": "dob_month",
    "dob_year": "dob_year",
    "approxAge": "formated_age",
    "years": "dob_year",
    "months": "dob_month",
    "days": "dob_day",
    "birthOrder": "birth_order",

    // 🔹 Contact details
    "mobileNo": "mobile_no",
    "mobileOwner": "whose_mob_no",

    // 🔹 Marriage
    "maritalStatus": "marital_status",
    "ageAtMarriage": "age_at_marrige",

    // 🔹 Gender
    "gender": "gender",

    // 🔹 Education / Work
    "education": "education",
    "occupation": "occupation",

    // 🔹 Social identity
    "religion": "religion",
    "category": "category",

    // 🔹 Children
    "hasChildren": "have_children",
    "children": "total_children",

    // 🔹 Pregnancy / Women-specific
    "isPregnant": "is_pregnant",
    "lmp": "lmp",
    "edd": "edd",

    // 🔹 Address
    "houseNo": "house_no",
    "village": "village_name",
    "ward": "ward_name",
    "wardNo": "ward_no",
    "mohalla": "mohalla_name",
    "mohallaTola": "mohalla_name",

    // 🔹 ABHA / Health IDs
    "abhaNumber": "abha_no",
    "personalHealthId": "personal_health_id",
    "phId": "personal_health_id",

    // 🔹 Banking
    "bankAccountNumber": "account_number",
    "ifscCode": "ifsc_code",

    // 🔹 Voter & Ration
    "voterId": "voter_id",
    "rationCardId": "ration_card_id",

    // 🔹 Status
    "memberStatus": "member_status",
  };
  static Future<void> runBeneficiaryTableMigration(Database db) async {
    try {
      final List<Map<String, dynamic>> oldRows = await db.query("beneficiaries");

      const List<String> beneficiaryKeys = [
        "houseNo",
        "headName",
        "fatherName",
        "motherName",
        "spouseName",
        "name",
        "memberName",
        "relation",
        "relation_to_head",
        "gender",
        "dob",
        "approxAge",
        "years",
        "months",
        "days",
        "mobileNo",
        "mobileOwner",
        "maritalStatus",
        "ageAtMarriage",
        "education",
        "occupation",
        "religion",
        "category",
        "hasChildren",
        "isPregnant",
        "lmp",
        "edd",
        "village",
        "ward",
        "wardNo",
        "mohalla",
        "mohallaTola",
        "beneficiaryType",
        "abhaNumber",
        "voterId",
        "rationCardId",
        "phId",
        "personalHealthId",
        "bankAccountNumber",
        "ifscCode",
        "memberType",
        "memberStatus",
        "birthOrder",
        "children",
        "isFamilyhead",
        "isFamilyheadWife",
        "weight",
        "birthWeight",
      ];
      // weight
      // weight_at_birth

      final Map<String, String> keyMapping = {
        "beneficiaryType": "type_of_beneficiary",
        "memberType": "ben_type",
        "relation": "relaton_with_family_head",
        "relation_to_head": "relaton_with_family_head",
        "name": "member_name",
        "memberName": "member_name",
        "motherName": "mother_name",
        "fatherName": "father_name",
        "spouseName": "father_or_spouse_name",
        "dob": "date_of_birth",
        "years": "dob_year",
        "months": "dob_month",
        "days": "dob_day",
        "approxAge": "formated_age",
        "birthOrder": "birth_order",
        "mobileNo": "mobile_no",
        "mobileOwner": "whose_mob_no",
        "maritalStatus": "marital_status",
        "ageAtMarriage": "age_at_marrige",
        "education": "education",
        "occupation": "occupation",
        "religion": "religion",
        "category": "category",
        "hasChildren": "have_children",
        "children": "total_children",
        "isPregnant": "is_pregnant",
        "lmp": "lmp_date",
        "edd": "edd_date",
        "houseNo": "house_no",
        "village": "village_name",
        "ward": "ward_name",
        "wardNo": "ward_no",
        "mohalla": "mohalla_name",
        "mohallaTola": "mohalla_name",
        "abhaNumber": "abha_no",
        "personalHealthId": "personal_health_id",
        "phId": "personal_health_id",
        "bankAccountNumber": "account_number",
        "ifscCode": "ifsc_code",
        "voterId": "voter_id",
        "rationCardId": "ration_card_id",
        "memberStatus": "member_status",
        "isFamilyhead": "isFamilyhead",
        "isFamilyheadWife": "isFamilyheadWife",
        "weight": "weight",
        "birthWeight": "weight_at_birth"
      };

      for (final row in oldRows) {
        final form = row["form_json"] != null ? jsonDecode(row["form_json"]) : {};

        final Map<String, dynamic> finalJson = {};
        for (final key in beneficiaryKeys) {
          if (form[key] != null &&
              form[key].toString().isNotEmpty &&
              form[key].toString() != "null") {
            finalJson[key] = form[key];
            continue;
          }

          if (keyMapping.containsKey(key)) {
            final mapped = keyMapping[key]!;
            if (form[mapped] != null &&
                form[mapped].toString().isNotEmpty &&
                form[mapped].toString() != "null") {
              finalJson[key] = form[mapped];
            }
          }
        }

        // First, get the direct column values from the old database
        int isDeath = (row["is_death"] == 1) ? 1 : 0;
        int isMigrated = (row["is_migrated"] == 1) ? 1 : 0;

        dynamic resolvedDeathDate;

        final dynamic rawDeathDate =
            row["date_of_death"] ?? form["date_of_death"];

        if (rawDeathDate != null &&
            rawDeathDate.toString().trim().isNotEmpty &&
            rawDeathDate.toString() != "null") {
          resolvedDeathDate = rawDeathDate;
        } else {
          resolvedDeathDate = row["created_date_time"];
        }
        Map<String, dynamic>? deathDetailsMap;

        final String reasonOfCloser =
        (row["reason_of_closer"] ?? form["reason_of_closer"] ?? "")
            .toString()
            .trim()
            .toLowerCase();

        if (reasonOfCloser.isNotEmpty) {
          deathDetailsMap = {
            "reason_of_closer": reasonOfCloser,
            "date_of_death": resolvedDeathDate,
            "cause_of_death": row["cause_of_death"] ?? form["cause_of_death"],
            "death_place": row["death_place"] ?? form["death_place"],
            "remark": form["remark"],
          };

          if (reasonOfCloser == "death") {
            isDeath = 1;
          } else if (reasonOfCloser == "migrate_out" || reasonOfCloser == "migration") {
            isMigrated = 1;
          }
        }



        final existing = await db.query(
          "beneficiaries_new",
          where: "unique_key = ?",
          whereArgs: [row["unique_key"]],
        );

        if (existing.isEmpty) {
          final Map<String, dynamic> insertData = {
            "server_id": row["_id"],
            "household_ref_key": row["household_registrations_ref_key"],
            "unique_key": row["unique_key"],
            "beneficiary_info": jsonEncode(finalJson),
            "spouse_key": row["spouse_ben_key"],
            "mother_key": row["mother_ben_key"],
            "father_key": row["father_ben_key"],
            "is_family_planning": row["is_family_planning"],
            "is_adult": row["is_adult"],
            "is_guest": row["is_guest"],
            "is_death": isDeath,
            "death_details": deathDetailsMap != null ? jsonEncode(deathDetailsMap) : null,
            "is_migrated": isMigrated,
            "current_user_key": row["added_by"],
            "created_date_time": row["created_date_time"],
            "modified_date_time": row["modified_date_time"],
            "is_synced": row["is_synced"],
            "is_deleted": row["is_deleted"],
            "is_separated": row["is_separated"],
          };

          // Print the data being inserted
          print('\n📌 Inserting beneficiary:');
          print('----------------------------------------');
          print('🔑 Unique Key: ${insertData['unique_key']}');
          print('🏠 Household Ref: ${insertData['household_ref_key']}');
          print('👤 Name: ${finalJson['name'] ?? finalJson['member_name']}');
          print('👨‍👩‍👧‍👦 Relation: ${finalJson['relation'] ?? finalJson['relaton_with_family_head']}');
          print('🎂 DOB: ${finalJson['dob']}');
          print('📱 Mobile: ${finalJson['mobileNo']}');
          print('💀 Is Death: ${insertData['is_death']}');
          print('✈️ Is Migrated: ${insertData['is_migrated']}');
          if (deathDetailsMap != null) {
            print('⚰️ Death Details:');
            deathDetailsMap.forEach((key, value) {
              if (value != null) print('   • $key: $value');
            });
          }
          print('----------------------------------------\n');

          await db.insert("beneficiaries_new", insertData);
        }
      }

      print("✅ Beneficiary migration completed (old table driven)");
    } catch (e, st) {
      print("❌ Beneficiary Migration Error: $e");
      print(st);
    }
  }


  static Future<void> runHouseholdTableMigration(Database db) async {
    final households = await db.query("household_registrations");

    for (var house in households) {
      try {
        // ---------- Household Key ----------
        final String? householdKey =
        (house["unique_key"] as String?)?.trim().isNotEmpty == true
            ? house["unique_key"] as String
            : house["_id"] as String?;

        if (householdKey == null) {
          print("⚠️ Skipped household (no key): ${house["_id"]}");
          continue;
        }

        // ---------- Fetch Members ----------
        final members = await db.query(
          "beneficiaries_new",
          where: "household_ref_key = ?",
          whereArgs: [householdKey],
        );

        if (members.isEmpty) continue;

        List<Map<String, dynamic>> heads = [];

        for (var member in members) {
          final infoJson = member["beneficiary_info"] as String?;
          if (infoJson == null) continue;

          final Map<String, dynamic> data = jsonDecode(infoJson);

          final bool isFamilyHead =
              data["isFamilyhead"] == true ||
                  data["isFamilyhead"] == "true" ||
                  data["isFamilyhead"] == 1;

          // relation_to_head check
          final String? relation =
          data["relation_to_head"]?.toString().toLowerCase().trim();

          final bool isRelationHead =
              relation == "self" ||
                  relation == "head" ||
                  relation == "household_head" ||
                  relation == "hoh";

          if (isFamilyHead || isRelationHead) {
            heads.add(member);
          }
        }

        // ---------- Fallback ----------
        if (heads.isEmpty && members.isNotEmpty) {
          heads = [members.first];
        }

        // ---------- Insert Household ----------
        for (var head in heads) {
          final String? headId = head["unique_key"] as String?;
          if (headId == null) {
            print("⚠️ Head missing unique_key for household $householdKey");
            continue;
          }

          final existing = await db.query(
            "households",
            where: "unique_key = ?",
            whereArgs: [householdKey],
          );

          if (existing.isNotEmpty) continue;

          await db.insert("households", {
            "server_id": house["_id"],
            "unique_key": householdKey,
            "head_id": headId,
            "household_info": house["form_json"],
            "current_user_key": house["added_by"],
            "created_date_time": house["created_date_time"],
            "modified_date_time": house["modified_date_time"],
            "parent_user": house["parent_added_by"],
            "is_synced": house["is_synced"],
            "is_deleted": house["is_deleted"],
          });
        }
      } catch (e) {
        print("❌ Household migration failed (${house["unique_key"]}): $e");
      }
    }

    print("✅ Household migration completed");
  }


  static Future<void> runFollowUpTableMigration(Database db) async {
    try {
      await db.rawInsert('''
      INSERT INTO followup_form_data (     
        server_id,
        forms_ref_key,
        form_json,
        household_ref_key,
        beneficiary_ref_key,
        is_synced,
        created_date_time,
        current_user_key,
        modified_date_time,
        parent_user,
        is_deleted
      )
      SELECT 
        a._id,
        a.forms_ref_key,
        a.form_json,
        a.household_registration_ref_key,
        a.beneficiaries_registration_ref_key,
        a.is_synced,
        a.created_date_time,
        a.created_by,
        a.modified_date_time,

        -- JSON object for parent_user
        ('{' ||
          '"app_role_id":' || ifnull(a.app_role_id, 0) ||
          ',"is_guest":' || ifnull(a.is_guest, 0) ||
          ',"parent_added_by":"' || ifnull(a.parent_added_by, '') || '"' ||
          ',"created_by":"' || ifnull(a.created_by, '') || '"' ||
          ',"modified_by":"' || ifnull(a.modified_by, '') || '"' ||
        '}'),
        a.is_deleted

      FROM followup_forms_data a
      WHERE NOT EXISTS (
        SELECT 1 
        FROM followup_form_data b
        WHERE b.household_ref_key = a.household_registration_ref_key
      );
    ''');
    } catch (e) {
      print("❌ Migration error: $e");
    }
  }


  static Future<void> runEligibleChildTableMigration(Database db) async {
    try {
      //   await db.execute('''
      //   ALTER TABLE child_care_activities ADD COLUMN unique_key TEXT;
      // ''');

      await db.rawInsert('''
      INSERT INTO child_care_activities (
        server_id,
        household_ref_key,            
        beneficiary_ref_key,
        mother_key,
        child_care_state,
        created_date_time,
        current_user_key,
        parent_user,
        is_synced,
        is_deleted
      )
      SELECT
        a._id,
        bn.household_ref_key,
        a.beneficiaries_registration_ref_key,
        a.mother_ben_key,
        a.child_care_type,
        a.created_date_time,
        a.created_by,

        '{' ||
        '"app_role_id":' || a.app_role_id || ',' ||
        '"is_guest":' || a.is_guest || ',' ||
        '"parent_added_by":' || a.parent_added_by || ',' ||
        '"created_by":' || a.created_by || ',' ||
        '"modified_by":' || a.modified_by ||
        '}',
        a.is_synced,
        a.is_deleted
      FROM child_care a
      LEFT JOIN beneficiaries_new bn
        ON bn.unique_key = a.beneficiaries_registration_ref_key
      WHERE NOT EXISTS (
        SELECT 1
        FROM child_care_activities b
        WHERE b.beneficiary_ref_key = a.beneficiaries_registration_ref_key
      );
    ''');
    } catch (e) {
      print("❌ Migration error: $e");
    }
  }




  static Future<void> runEligileCoupleTableMigration(Database db) async {
    try {
      await db.rawInsert('''
      INSERT INTO eligible_couple_activities (     
        server_id,
        household_ref_key,
        beneficiary_ref_key,
        eligible_couple_state,
        created_date_time,
        current_user_key,
        modified_date_time,
        parent_user,
        is_synced,
        is_deleted
      )
      SELECT 
        a._id,
        a.unique_key,
        a.beneficiaries_registration_ref_key,
        a.eligible_couple_type,
        a.created_date_time,
        a.created_by,
        a.modified_date_time,

        ('{' ||
          '"app_role_id":' || ifnull(a.app_role_id, 0) ||
          ',"is_guest":' || ifnull(a.is_guest, 0) ||
          ',"parent_added_by":"' || ifnull(a.parent_added_by, '') || '"' ||
          ',"created_by":"' || ifnull(a.created_by, '') || '"' ||
          ',"modified_by":"' || ifnull(a.modified_by, '') || '"' ||
        '}'),

        a.is_synced,
        a.is_deleted

      FROM eligible_couple a
      WHERE NOT EXISTS (
        SELECT 1 
        FROM eligible_couple_activities b
        WHERE b.beneficiary_ref_key = a.beneficiaries_registration_ref_key
      );
    ''');
    } catch (e) {
      print("❌ Migration error: $e");
    }
  }


  static Future<void> runMotherCareTableMigration(Database db) async {
    try {
      await db.rawInsert('''
      INSERT INTO mother_care_activities (     
        server_id,
        household_ref_key,
        beneficiary_ref_key,
        mother_care_state,
        created_date_time,
        current_user_key,
        modified_date_time,
        parent_user,
        is_synced,
        is_deleted
      )
      SELECT 
        a._id,
        a.unique_key,
        a.beneficiaries_registration_ref_key,
        a.mother_care_type,
        a.created_date_time,
        a.created_by,
        a.modified_date_time,

        -- JSON object for parent_user
        ('{' ||
          '"app_role_id":' || ifnull(a.app_role_id, 0) ||
          ',"is_guest":' || ifnull(a.is_guest, 0) ||
          ',"parent_added_by":"' || ifnull(a.parent_added_by, '') || '"' ||
          ',"created_by":"' || ifnull(a.created_by, '') || '"' ||
          ',"modified_by":"' || ifnull(a.modified_by, '') || '"' ||
        '}'),

        a.is_synced,
        a.is_deleted
      FROM mother_care a
      WHERE NOT EXISTS (
        SELECT 1 
        FROM mother_care_activities b
        WHERE b.beneficiary_ref_key = a.beneficiaries_registration_ref_key
      );
    ''');
    } catch (e) {
      print("❌ Migration error: $e");
    }
  }
}