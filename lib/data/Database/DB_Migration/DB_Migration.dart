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
        "isFamilyheadWife"
      ];

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
        "lmp": "lmp",
        "edd": "edd",
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
        "isFamilyhead":"isFamilyhead",
        "isFamilyheadWife":"isFamilyheadWife"
      };

      for (var row in oldRows) {
        final form = row["form_json"] != null ? jsonDecode(row["form_json"]) : {};
        final Map<String, dynamic> finalJson = {};

        for (final key in beneficiaryKeys) {
          if (form.containsKey(key) && form[key] != null) {
            finalJson[key] = form[key];
            continue;
          }

          if (keyMapping.containsKey(key)) {
            final sourceKey = keyMapping[key]!;
            if (form.containsKey(sourceKey) && form[sourceKey] != null) {
              finalJson[key] = form[sourceKey];
            }
          }
        }

        // ❌ Check if the record already exists
        final existing = await db.query(
          "beneficiaries_new",
          where: "unique_key = ?",
          whereArgs: [row["unique_key"]],
        );

        if (existing.isEmpty) {
          await db.insert(
            "beneficiaries_new",
            {
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
              "is_death": row["is_death"],
              "is_migrated": row["is_migrated"],
              "current_user_key": row["added_by"],
              "created_date_time": row["created_date_time"],
              "modified_date_time": row["modified_date_time"],
              "is_synced": row["is_synced"],
              "is_deleted": row["is_deleted"],
              "is_separated": row["is_separated"],
            },
          );
        }
      }
    } catch (e) {
      print("❌ Beneficiary Migration Error: $e");
    }
  }


  static Future<void> runHouseholdTableMigration(Database db) async {
    try {
      final households = await db.query("household_registrations");

      for (var house in households) {
        String? householdKey = house["unique_key"] as String?;

        // Fetch all members of this household
        final members = await db.query(
          "beneficiaries_new",
          where: "household_ref_key = ?",
          whereArgs: [householdKey],
        );

        if (members.isEmpty) continue;

        // Find all heads
        List<Map<String, dynamic>> heads = [];

        for (var member in members) {
          final infoJson = member["beneficiary_info"] as String?;
          if (infoJson == null) continue;

          final data = jsonDecode(infoJson);

          if (data["isFamilyhead"] == true) {
            heads.add(member);
          }
        }

        // If no head found → take first member as head
        // if (heads.isEmpty) {
        //   heads = [members.first];
        // }

        // Insert 1 household record per head
        for (var head in heads) {
          String headId = head["unique_key"];

          // Household unique key must be unique → append head id
          final newHouseholdKey = "${householdKey}";

          // Check if already exists
          final existing = await db.query(
            "households",
            where: "unique_key = ?",
            whereArgs: [newHouseholdKey],
          );

          if (existing.isNotEmpty) continue;

          await db.insert(
            "households",
            {
              "server_id": house["_id"] as String?,
              "unique_key": newHouseholdKey,
              "head_id": headId,
              "household_info": house["form_json"] as String?,
              "current_user_key": house["added_by"] as String?,
              "created_date_time": house["created_date_time"] as String?,
              "modified_date_time": house["modified_date_time"] as String?,
              "parent_user": house["parent_added_by"] as String?,
              "is_synced": house["is_synced"] as int?,
              "is_deleted": house["is_deleted"] as int?,
            },
          );
        }
      }
    } catch (e) {
      print("❌ Household Migration Error: $e");
    }
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


  // static Future<void> runEligibleChildTableMigration(Database db) async {
  //   try {
  //     await db.rawInsert('''
  //     INSERT INTO child_care_activities (
  //       server_id,
  //       beneficiary_ref_key,
  //       child_care_state,
  //       mother_key,
  //       created_date_time,
  //       current_user_key,
  //       modified_date_time,
  //       parent_user,
  //       is_synced,
  //       is_deleted
  //     )
  //     SELECT
  //       _id,
  //       beneficiaries_registration_ref_key,
  //       mother_ben_key,
  //       child_care_type,
  //       created_date_time,
  //       created_by,
  //

  //       json_object(
  //           'app_role_id', a.app_role_id,
  //           'is_guest', a.is_guest,
  //           'parent_added_by', a.parent_added_by,
  //           'created_by', a.created_by,
  //           'modified_by', a.modified_by
  //         ),
  //       is_synced,
  //       is_deleted
  //     FROM child_care a
  //     WHERE NOT EXISTS (
  //       SELECT 1
  //       FROM child_care_activities b
  //       WHERE b.beneficiary_ref_key = a.beneficiaries_registration_ref_key
  //     );
  //   ''');
  //   } catch (e) {
  //     print("❌ Migration error: $e");
  //   }
  // }



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
