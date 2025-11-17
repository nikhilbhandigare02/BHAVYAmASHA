import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:medixcel_new/core/widgets/AppHeader/AppHeader.dart';
import 'package:medixcel_new/core/config/themes/CustomColors.dart';
import 'package:medixcel_new/core/widgets/Loader/Loader.dart';
import 'package:sizer/sizer.dart';
import 'package:intl/intl.dart';

import '../../data/Local_Storage/database_provider.dart';
import '../../data/Local_Storage/tables/followup_form_data_table.dart' as ffd;

class CBACDetailScreen extends StatefulWidget {
  final int formId;

  const CBACDetailScreen({
    super.key,
    required this.formId,
  });

  @override
  State<CBACDetailScreen> createState() => _CBACDetailScreenState();
}

class _CBACDetailScreenState extends State<CBACDetailScreen> {
  bool _isLoading = true;
  Map<String, dynamic> _formData = {};
  String _registrationDate = 'N/A';
  String _beneficiaryId = 'N/A';
  String _householdId = 'N/A';
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadFormData();
  }

  Future<void> _loadFormData() async {
    try {
      final db = await DatabaseProvider.instance.database;
      final List<Map<String, dynamic>> result = await db.query(
        ffd.FollowupFormDataTable.table,
        where: 'id = ?',
        whereArgs: [widget.formId],
      );

      if (result.isNotEmpty) {
        final formRecord = result.first;
        final formJson = jsonDecode(formRecord['form_json']);

        debugPrint('Form ID: ${widget.formId}');
        debugPrint('Form Data: $formJson');

        // Extract form_data
        final formData = formJson['form_data'] ?? {};

        // Format registration date from created_at
        String registrationDate = 'N/A';
        if (formJson['created_at'] != null) {
          try {
            DateTime dateTime = DateTime.parse(formJson['created_at'].toString());
            registrationDate = DateFormat('dd-MM-yyyy').format(dateTime);
          } catch (e) {
            debugPrint('Error parsing created_at: $e');
          }
        }

        setState(() {
          _formData = formData;
          _registrationDate = registrationDate;
          _beneficiaryId = formJson['beneficiary_id']?.toString() ?? 'N/A';
          _householdId = formJson['household_ref_key']?.toString() ?? 'N/A';
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Form not found';
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading form data: $e');
      setState(() {
        _errorMessage = 'Error loading form data: $e';
        _isLoading = false;
      });
    }
  }

  String _getValue(dynamic value) {
    if (value == null || value.toString().trim().isEmpty) {
      return 'N/A';
    }
    return value.toString();
  }

  @override
  Widget build(BuildContext context) {
    final Color primary = Theme.of(context).primaryColor;

    if (_isLoading) {
      return Scaffold(
        appBar: AppHeader(
          screenTitle: 'CBAC Form Details',
          showBack: true,
          onBackTap: () => Navigator.pop(context),
        ),
        body: const CenterBoxLoader(),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Scaffold(
        appBar: AppHeader(
          screenTitle: 'CBAC Form Details',
          showBack: true,
          onBackTap: () => Navigator.pop(context),
        ),
        body: Center(
          child: Text(
            _errorMessage,
            style: TextStyle(fontSize: 16.sp, color: Colors.red),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppHeader(
        screenTitle: 'CBAC Form Details',
        showBack: true,
        onBackTap: () => Navigator.pop(context),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Basic Information Section
              _buildSectionCard(
                context,
                'Basic Information',
                [
                  _buildInfoRow('Form ID', widget.formId.toString()),
                  _buildInfoRow('Registration Date', _registrationDate),
                  _buildInfoRow('Household ID', _householdId),
                  _buildInfoRow('Beneficiary ID', _beneficiaryId),
                  _buildInfoRow('Name', _getValue(_formData['name'])),
                  _buildInfoRow('Father\'s Name', _getValue(_formData['father'])),
                  _buildInfoRow('Age', _getValue(_formData['age'])),
                  _buildInfoRow('Gender', _getValue(_formData['gender'])),
                  _buildInfoRow('Mobile', _getValue(_formData['mobile'])),
                  _buildInfoRow('Address', _getValue(_formData['address'])),
                  _buildInfoRow('Village', _getValue(_formData['village'])),
                  _buildInfoRow('ID Type', _getValue(_formData['id_type'])),
                  _buildInfoRow('Has Conditions', _getValue(_formData['has_conditions'])),
                  _buildInfoRow('Disability', _getValue(_formData['disability'])),
                ],
              ),

              const SizedBox(height: 16),

              // Healthcare Provider Information
              _buildSectionCard(
                context,
                'Healthcare Provider Information',
                [
                  _buildInfoRow('ASHA Name', _getValue(_formData['asha_name'])),
                  _buildInfoRow('ANM Name', _getValue(_formData['anm_name'])),
                  _buildInfoRow('PHC', _getValue(_formData['phc'])),
                  _buildInfoRow('HSC', _getValue(_formData['hsc'])),
                ],
              ),

              const SizedBox(height: 16),

              // Part A - Risk Factors
              _buildSectionCard(
                context,
                'Part A - Risk Factors',
                [
                  _buildInfoRow('Age Group', _getValue(_formData['partA_age'])),
                  _buildInfoRow('Tobacco Use', _getValue(_formData['partA_tobacco'])),
                  _buildInfoRow('Alcohol Consumption', _getValue(_formData['partA_alcohol'])),
                  _buildInfoRow('Physical Activity', _getValue(_formData['partA_activity'])),
                  _buildInfoRow('Waist Measurement', _getValue(_formData['partA_waist'])),
                  _buildInfoRow('Family History', _getValue(_formData['partA_family_history'])),
                ],
              ),

              const SizedBox(height: 16),

              // Part B1 - General Symptoms
              _buildSectionCard(
                context,
                'Part B1 - General Symptoms',
                [
                  _buildInfoRow('Shortness of Breath', _getValue(_formData['partB_b1_breath'])),
                  _buildInfoRow('Cough for 2+ Weeks', _getValue(_formData['partB_b1_cough2w'])),
                  _buildInfoRow('Blood in Mucus', _getValue(_formData['partB_b1_blood_mucus'])),
                  _buildInfoRow('Fever for 2+ Weeks', _getValue(_formData['partB_b1_fever2w'])),
                  _buildInfoRow('Weight Loss', _getValue(_formData['partB_b1_weight_loss'])),
                  _buildInfoRow('Night Sweats', _getValue(_formData['partB_b1_night_sweat'])),
                  _buildInfoRow('Seizures', _getValue(_formData['partB_b1_seizures'])),
                  _buildInfoRow('Difficulty Opening Mouth', _getValue(_formData['partB_b1_open_mouth'])),
                  _buildInfoRow('Ulcers', _getValue(_formData['partB_b1_ulcers'])),
                  _buildInfoRow('Swelling in Mouth', _getValue(_formData['partB_b1_swelling_mouth'])),
                  _buildInfoRow('Rash in Mouth', _getValue(_formData['partB_b1_rash_mouth'])),
                  _buildInfoRow('Pain While Chewing', _getValue(_formData['partB_b1_chew_pain'])),
                  _buildInfoRow('Drug Use', _getValue(_formData['partB_b1_druggs'])),
                  _buildInfoRow('Tuberculosis', _getValue(_formData['partB_b1_tuberculosis'])),
                  _buildInfoRow('Medical History', _getValue(_formData['partB_b1_history'])),
                  _buildInfoRow('Palms/Soles Issues', _getValue(_formData['partB_b1_palms'])),
                  _buildInfoRow('Tingling Sensation', _getValue(_formData['partB_b1_tingling'])),
                  _buildInfoRow('Blurred Vision', _getValue(_formData['partB_b1_vision_blurred'])),
                  _buildInfoRow('Reading Difficulty', _getValue(_formData['partB_b1_reading_difficulty'])),
                  _buildInfoRow('Eye Pain', _getValue(_formData['partB_b1_eye_pain'])),
                  _buildInfoRow('Eye Redness', _getValue(_formData['partB_b1_eye_redness'])),
                  _buildInfoRow('Hearing Difficulty', _getValue(_formData['partB_b1_hearing_difficulty'])),
                  _buildInfoRow('Voice Change', _getValue(_formData['partB_b1_change_voice'])),
                ],
              ),

              const SizedBox(height: 16),

              // Part B1 - Skin Symptoms
              _buildSectionCard(
                context,
                'Part B1 - Skin & Sensory Symptoms',
                [
                  _buildInfoRow('Skin Rash/Discoloration', _getValue(_formData['partB_b1_skin_rash_discolor'])),
                  _buildInfoRow('Thick Skin', _getValue(_formData['partB_b1_skin_thick'])),
                  _buildInfoRow('Skin Lump', _getValue(_formData['partB_b1_skin_lump'])),
                  _buildInfoRow('Numbness (Hot/Cold)', _getValue(_formData['partB_b1_numbness_hot_cold'])),
                  _buildInfoRow('Scratches/Cracks', _getValue(_formData['partB_b1_scratches_cracks'])),
                  _buildInfoRow('Tingling/Numbness', _getValue(_formData['partB_b1_tingling_numbness'])),
                  _buildInfoRow('Eyelid Closing Difficulty', _getValue(_formData['partB_b1_close_eyelids_difficulty'])),
                  _buildInfoRow('Holding Difficulty', _getValue(_formData['partB_b1_holding_difficulty'])),
                  _buildInfoRow('Leg Weakness/Walk', _getValue(_formData['partB_b1_leg_weakness_walk'])),
                ],
              ),

              const SizedBox(height: 16),

              // Part B2 - Women's Health
              _buildSectionCard(
                context,
                'Part B2 - Women\'s Health Symptoms',
                [
                  _buildInfoRow('Breast Lump', _getValue(_formData['partB_b2_breast_lump'])),
                  _buildInfoRow('Nipple Bleeding', _getValue(_formData['partB_b2_nipple_bleed'])),
                  _buildInfoRow('Breast Shape Difference', _getValue(_formData['partB_b2_breast_shape_diff'])),
                  _buildInfoRow('Excessive Bleeding', _getValue(_formData['partB_b2_excess_bleeding'])),
                  _buildInfoRow('Depression', _getValue(_formData['partB_b2_depression'])),
                  _buildInfoRow('Uterus Prolapse', _getValue(_formData['partB_b2_uterus_prolapse'])),
                  _buildInfoRow('Post Menopause Bleeding', _getValue(_formData['partB_b2_post_menopause_bleed'])),
                  _buildInfoRow('Post Intercourse Bleeding', _getValue(_formData['partB_b2_post_intercourse_bleed'])),
                  _buildInfoRow('Smelly Discharge', _getValue(_formData['partB_b2_smelly_discharge'])),
                  _buildInfoRow('Irregular Periods', _getValue(_formData['partB_b2_irregular_periods'])),
                  _buildInfoRow('Joint Pain', _getValue(_formData['partB_b2_joint_pain'])),
                ],
              ),

              const SizedBox(height: 16),

              // Part C - Environmental Factors
              _buildSectionCard(
                context,
                'Part C - Environmental Factors',
                [
                  _buildInfoRow('Cooking Fuel', _getValue(_formData['partC_cooking_fuel'])),
                  _buildInfoRow('Business Risk', _getValue(_formData['partC_business_risk'])),
                ],
              ),

              const SizedBox(height: 16),

              // Part D - Mental Health
              _buildSectionCard(
                context,
                'Part D - Mental Health Assessment',
                [
                  _buildInfoRow('Question 1', _getValue(_formData['partD_q1'])),
                  _buildInfoRow('Question 2', _getValue(_formData['partD_q2'])),
                ],
              ),

              const SizedBox(height: 16),

              // Scores Section
              _buildSectionCard(
                context,
                'Assessment Scores',
                [
                  _buildInfoRow('Part A Score', _getValue(_formData['score_partA'])),
                  _buildInfoRow('Part D Score', _getValue(_formData['score_partD'])),
                  _buildInfoRow('Total Score', _getValue(_formData['score_total'])),
                ],
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard(BuildContext context, String title, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            ),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13.sp,
                color: value == 'N/A' ? Colors.grey : Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }
}