import 'dart:convert';

void main() {
  // Test the ANC visit count extraction logic
  print('Testing ANC visit count extraction...');
  
  // Sample followup form data from the user's example
  String sampleFormJson = '''
  {
    "anc_form": {
      "anc_visit": 1,
      "visit_type": "anc",
      "place_of_anc": "",
      "date_of_inspection": "2026-01-08 19:24:40",
      "house_no": "9282",
      "pw_name": "Sunidha",
      "husband_name": "Akshay",
      "rch_reg_no_of_pw": "",
      "lmp_date": "2025-04-08T19:24:07.544+05:30",
      "edd_date": "2026-01-10 19:24:07",
      "week_of_pregnancy": 40,
      "order_of_pregnancy": 1,
      "is_breastfeeding": "",
      "date_of_td1": "",
      "date_of_td2": "",
      "date_of_td_booster": "",
      "folic_acid_tab_quantity": "",
      "iron_and_folic_acid_tab_quantity": "",
      "calcium_and_vit_d_tab_quantity": "",
      "has_albendazole_tab_given": "",
      "pre_exist_desease": "",
      "other_pre_exist_desease": "",
      "weight": "",
      "bp_of_pw_systolic": "",
      "bp_of_pw_diastolic": "",
      "hemoglobin": "",
      "is_high_risk": "",
      "high_risk_details": [],
      "is_abortion": "",
      "date_of_abortion": "",
      "is_family_planning_counselling": "",
      "is_family_planning": "",
      "method_of_contraception": "",
      "has_pw_given_birth": "yes",
      "delivery_outcome": "live_birth",
      "live_birth": "2",
      "children_arr": [
        {
          "name": "First baby of Sunidha",
          "gender": "female",
          "weight_at_birth": "1300"
        },
        {
          "name": "Second baby of Sunidha",
          "gender": "male",
          "weight_at_birth": "1300"
        }
      ],
      "ancVisitDates": [
        {
          "from": "2025-04-08 19:24:07",
          "to": "2025-07-01 19:24:07"
        },
        {
          "from": "2025-07-02 00:00:00",
          "to": "2025-07-14 00:00:00"
        },
        {
          "from": "2025-07-15 19:24:07",
          "to": "2025-09-23 19:24:07"
        },
        {
          "from": "2025-10-07 19:24:07",
          "to": "2025-12-02 19:24:07"
        },
        {
          "from": "2025-12-16 19:24:07",
          "to": "2026-01-10 19:24:07"
        }
      ],
      "prev_visit_date": "2025-07-01 19:24:07",
      "current_stage": 4,
      "completedVisited": 4,
      "anc_visit_interval": "4",
      "next_visit_date": "2025-09-23 19:24:07",
      "is_beneficiary_absent": "yes"
    }
  }
  ''';

  try {
    final formJson = jsonDecode(sampleFormJson) as Map<String, dynamic>;
    
    // Test extraction from anc_form structure
    final ancForm = formJson['anc_form'] as Map<String, dynamic>?;
    if (ancForm != null) {
      final visitCount = ancForm['anc_visit'] as int?;
      if (visitCount != null) {
        print('✅ Successfully extracted visit count: $visitCount');
        
        // Test ANC end date calculation logic
        print('Testing ANC end date calculation...');
        
        // Simulate ANC date ranges (assuming LMP date: 2025-04-08)
        DateTime lmpDate = DateTime.parse('2025-04-08');
        
        DateTime firstEnd = lmpDate.add(Duration(days: 12 * 7)); // 12 weeks
        DateTime secondEnd = lmpDate.add(Duration(days: 24 * 7)); // 24 weeks
        DateTime thirdEnd = lmpDate.add(Duration(days: 34 * 7)); // 34 weeks
        DateTime fourthEnd = lmpDate.add(Duration(days: 40 * 7)); // 40 weeks (EDD)
        
        String formatDate(DateTime date) {
          return '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
        }
        
        DateTime? displayEndDate;
        
        if (visitCount >= 1) {
          displayEndDate = firstEnd;
        }
        if (visitCount >= 2) {
          displayEndDate = secondEnd;
        }
        if (visitCount >= 3) {
          displayEndDate = thirdEnd;
        }
        if (visitCount >= 4) {
          displayEndDate = fourthEnd;
        }
        
        if (displayEndDate != null) {
          final ancEndDate = formatDate(displayEndDate);
          print('✅ ANC end date for visit count $visitCount: $ancEndDate');
          
          // Test different visit counts
          print('\nTesting different visit counts:');
          for (int testCount = 1; testCount <= 4; testCount++) {
            DateTime? testEndDate;
            if (testCount >= 1) testEndDate = firstEnd;
            if (testCount >= 2) testEndDate = secondEnd;
            if (testCount >= 3) testEndDate = thirdEnd;
            if (testCount >= 4) testEndDate = fourthEnd;
            
            if (testEndDate != null) {
              print('Visit count $testCount -> ANC end date: ${formatDate(testEndDate)}');
            }
          }
        }
      } else {
        print('❌ No visit count found in anc_form');
      }
    } else {
      print('❌ No anc_form structure found');
    }
  } catch (e) {
    print('❌ Error parsing JSON: $e');
  }
}
