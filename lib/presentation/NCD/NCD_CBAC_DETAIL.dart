import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:medixcel_new/core/widgets/AppHeader/AppHeader.dart';
import 'package:medixcel_new/core/config/themes/CustomColors.dart';
import 'package:medixcel_new/core/widgets/Loader/Loader.dart';
import 'package:sizer/sizer.dart';
import 'package:intl/intl.dart';

import '../../data/Database/database_provider.dart';
import '../../data/Database/tables/followup_form_data_table.dart' as ffd;
import '../../l10n/app_localizations.dart';

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
    final l10n = AppLocalizations.of(context);

    if (_isLoading) {
      return Scaffold(
        appBar: AppHeader(
          screenTitle: l10n?.cbacFormDetails ?? 'CBAC Form Details',
          showBack: true,
          onBackTap: () => Navigator.pop(context),
        ),
        body: const CenterBoxLoader(),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Scaffold(
        appBar: AppHeader(
          screenTitle: l10n?.cbacFormDetails ?? 'CBAC Form Details',
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
        screenTitle: l10n?.cbacFormDetails ?? 'CBAC Form Details',
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
                l10n?.basicInformation ?? 'Basic Information',
                [
                  _buildInfoRow(context,l10n?.formId ?? 'Form ID', widget.formId.toString()),
                  _buildInfoRow(context,l10n?.registrationDate ?? 'Registration Date', _registrationDate),
                  _buildInfoRow(context,l10n?.householdId ?? 'Household ID', _householdId),
                  _buildInfoRow(context,l10n?.beneficiaryId ?? 'Beneficiary ID', _beneficiaryId),
                  _buildInfoRow(context,l10n?.nameLabel ?? 'Name', _getValue(_formData['name'])),
                  _buildInfoRow(context,l10n?.fathersName ??'Father\'s Name', _getValue(_formData['father'])),
                  _buildInfoRow(context,l10n?.age ?? 'Age', _getValue(_formData['age'])),
                  _buildInfoRow(context,l10n?.gender ?? 'Gender', _getValue(_formData['gender'])),
                  _buildInfoRow(context,l10n?.mobile ?? 'Mobile', _getValue(_formData['mobile'])),
                  _buildInfoRow(context,l10n?.address ?? 'Address', _getValue(_formData['address'])),
                  _buildInfoRow(context,l10n?.village ?? 'Village', _getValue(_formData['village'])),
                  _buildInfoRow(context,l10n?.idType ?? 'ID Type', _getValue(_formData['id_type'])),
                  _buildInfoRow(context,l10n?.hasConditions ?? 'Has Conditions', _getValue(_formData['has_conditions'])),
                  _buildInfoRow(context,l10n?.disability ?? 'Disability', _getValue(_formData['disability'])),
                ],
              ),

              const SizedBox(height: 16),

              // Healthcare Provider Information
              _buildSectionCard(
                context,
                l10n?.healthcareProviderInformation ?? 'Healthcare Provider Information',
                [
                  _buildInfoRow(context,l10n?.ashaName ?? 'ASHA Name', _getValue(_formData['asha_name'])),
                  _buildInfoRow(context,l10n?.anmName ?? 'ANM Name', _getValue(_formData['anm_name'])),
                  _buildInfoRow(context,l10n?.phc ?? 'PHC', _getValue(_formData['phc'])),
                  _buildInfoRow(context,l10n?.hsc ?? 'HSC', _getValue(_formData['hsc'])),
                ],
              ),

              const SizedBox(height: 16),

              // Part A - Risk Factors
              _buildSectionCard(
                context,
                l10n?.partA_riskFactors ?? 'Part A - Risk Factors',
                [
                  _buildInfoRow(context,l10n?.ageGroup ?? 'Age Group', _getValue(_formData['partA_age'])),
                  _buildInfoRow(context,l10n?.tobaccoUse ?? 'Tobacco Use', _getValue(_formData['partA_tobacco'])),
                  _buildInfoRow(context,l10n?.alcoholConsumption ?? 'Alcohol Consumption', _getValue(_formData['partA_alcohol'])),
                  _buildInfoRow(context,l10n?.physicalActivity ?? 'Physical Activity', _getValue(_formData['partA_activity'])),
                  _buildInfoRow(context,l10n?.waistMeasurement ?? 'Waist Measurement', _getValue(_formData['partA_waist'])),
                  _buildInfoRow(context,l10n?.familyHistory ?? 'Family History', _getValue(_formData['partA_family_history'])),
                ],
              ),

              const SizedBox(height: 16),

              // Part B1 - General Symptoms
              _buildSectionCard(
                context,
                l10n?.partB1GeneralSymptoms ?? 'Part B1 - General Symptoms',
                [
                  _buildInfoRow(context,l10n?.shortnessOfBreath ?? 'Shortness of Breath', _getValue(_formData['partB_b1_breath'])),
                  _buildInfoRow(context,l10n?.cough2Weeks ?? 'Cough for 2+ Weeks', _getValue(_formData['partB_b1_cough2w'])),
                  _buildInfoRow(context,l10n?.bloodInMucus ?? 'Blood in Mucus', _getValue(_formData['partB_b1_blood_mucus'])),
                  _buildInfoRow(context,l10n?.fever2Weeks ?? 'Fever for 2+ Weeks', _getValue(_formData['partB_b1_fever2w'])),
                  _buildInfoRow(context,l10n?.weightLoss ?? 'Weight Loss', _getValue(_formData['partB_b1_weight_loss'])),
                  _buildInfoRow(context,l10n?.nightSweats ?? 'Night Sweats', _getValue(_formData['partB_b1_night_sweat'])),
                  _buildInfoRow(context,l10n?.seizures ?? 'Seizures', _getValue(_formData['partB_b1_seizures'])),
                  _buildInfoRow(context,l10n?.difficultyOpeningMouth ?? 'Difficulty Opening Mouth', _getValue(_formData['partB_b1_open_mouth'])),
                  _buildInfoRow(context,l10n?.ulcers ?? 'Ulcers', _getValue(_formData['partB_b1_ulcers'])),
                  _buildInfoRow(context,l10n?.swellingInMouth ?? 'Swelling in Mouth', _getValue(_formData['partB_b1_swelling_mouth'])),
                  _buildInfoRow(context,l10n?.rashInMouth ?? 'Rash in Mouth', _getValue(_formData['partB_b1_rash_mouth'])),
                  _buildInfoRow(context,l10n?.painWhileChewing ?? 'Pain While Chewing', _getValue(_formData['partB_b1_chew_pain'])),
                  _buildInfoRow(context,l10n?.drugUse ?? 'Drug Use', _getValue(_formData['partB_b1_druggs'])),
                  _buildInfoRow(context,l10n?.tuberculosis ?? 'Tuberculosis', _getValue(_formData['partB_b1_tuberculosis'])),
                  _buildInfoRow(context,l10n?.medicalHistory ?? 'Medical History', _getValue(_formData['partB_b1_history'])),
                  _buildInfoRow(context,l10n?.palmsSolesIssues ?? 'Palms/Soles Issues', _getValue(_formData['partB_b1_palms'])),
                  _buildInfoRow(context,l10n?.tinglingSensation ?? 'Tingling Sensation', _getValue(_formData['partB_b1_tingling'])),
                  _buildInfoRow(context,l10n?.blurredVision ?? 'Blurred Vision', _getValue(_formData['partB_b1_vision_blurred'])),
                  _buildInfoRow(context,l10n?.readingDifficulty ?? 'Reading Difficulty', _getValue(_formData['partB_b1_reading_difficulty'])),
                  _buildInfoRow(context,l10n?.eyePain ?? 'Eye Pain', _getValue(_formData['partB_b1_eye_pain'])),
                  _buildInfoRow(context,l10n?.eyeRedness ?? 'Eye Redness', _getValue(_formData['partB_b1_eye_redness'])),
                  _buildInfoRow(context,l10n?.hearingDifficulty ?? 'Hearing Difficulty', _getValue(_formData['partB_b1_hearing_difficulty'])),
                  _buildInfoRow(context,l10n?.voiceChange ?? 'Voice Change', _getValue(_formData['partB_b1_change_voice'])),
                ],
              ),

              const SizedBox(height: 16),

              // Part B1 - Skin Symptoms
              _buildSectionCard(
                context,
                l10n?.partB1_skinSensorySymptoms ?? 'Part B1 - Skin & Sensory Symptoms',
                [
                  _buildInfoRow(context,l10n?.skinRashDiscoloration ?? 'Skin Rash/Discoloration', _getValue(_formData['partB_b1_skin_rash_discolor'])),
                  _buildInfoRow(context,l10n?.thickSkin ?? 'Thick Skin', _getValue(_formData['partB_b1_skin_thick'])),
                  _buildInfoRow(context,l10n?.skinLump ?? 'Skin Lump', _getValue(_formData['partB_b1_skin_lump'])),
                  _buildInfoRow(context,l10n?.numbnessHotCold ?? 'Numbness (Hot/Cold)', _getValue(_formData['partB_b1_numbness_hot_cold'])),
                  _buildInfoRow(context,l10n?.scratchesCracks ?? 'Scratches/Cracks', _getValue(_formData['partB_b1_scratches_cracks'])),
                  _buildInfoRow(context,l10n?.tinglingNumbness ?? 'Tingling/Numbness', _getValue(_formData['partB_b1_tingling_numbness'])),
                  _buildInfoRow(context,l10n?.eyelidClosingDifficulty ?? 'Eyelid Closing Difficulty', _getValue(_formData['partB_b1_close_eyelids_difficulty'])),
                  _buildInfoRow(context,l10n?.holdingDifficulty ?? 'Holding Difficulty', _getValue(_formData['partB_b1_holding_difficulty'])),
                  _buildInfoRow(context,l10n?.legWeaknessWalk ?? 'Leg Weakness/Walk', _getValue(_formData['partB_b1_leg_weakness_walk'])),
                ],
              ),

              const SizedBox(height: 16),

              // Part B2 - Women's Health
              _buildSectionCard(
                context,
                l10n?.partB2_womenHealthSymptoms ?? 'Part B2 - Women\'s Health Symptoms',
                [
                  _buildInfoRow(context,l10n?.breastLump ?? 'Breast Lump', _getValue(_formData['partB_b2_breast_lump'])),
                  _buildInfoRow(context,l10n?.nippleBleeding ?? 'Nipple Bleeding', _getValue(_formData['partB_b2_nipple_bleed'])),
                  _buildInfoRow(context,l10n?.breastShapeDifference ?? 'Breast Shape Difference', _getValue(_formData['partB_b2_breast_shape_diff'])),
                  _buildInfoRow(context,l10n?.excessiveBleeding ?? 'Excessive Bleeding', _getValue(_formData['partB_b2_excess_bleeding'])),
                  _buildInfoRow(context,l10n?.depression ?? 'Depression', _getValue(_formData['partB_b2_depression'])),
                  _buildInfoRow(context,l10n?.uterusProlapse ?? 'Uterus Prolapse', _getValue(_formData['partB_b2_uterus_prolapse'])),
                  _buildInfoRow(context,l10n?.postMenopauseBleeding ?? 'Post Menopause Bleeding', _getValue(_formData['partB_b2_post_menopause_bleed'])),
                  _buildInfoRow(context,l10n?.postIntercourseBleeding ??'Post Intercourse Bleeding', _getValue(_formData['partB_b2_post_intercourse_bleed'])),
                  _buildInfoRow(context,l10n?.smellyDischarge ??'Smelly Discharge', _getValue(_formData['partB_b2_smelly_discharge'])),
                  _buildInfoRow(context,l10n?.irregularPeriods ?? 'Irregular Periods', _getValue(_formData['partB_b2_irregular_periods'])),
                  _buildInfoRow(context,l10n?.jointPain ?? 'Joint Pain', _getValue(_formData['partB_b2_joint_pain'])),
                ],
              ),

              const SizedBox(height: 16),

              // Part C - Environmental Factors
              _buildSectionCard(
                context,
                l10n?.partC_environmentalFactors ?? 'Part C - Environmental Factors',
                [
                  _buildInfoRow(context,l10n?.cookingFuel ?? 'Cooking Fuel', _getValue(_formData['partC_cooking_fuel'])),
                  _buildInfoRow(context,l10n?.businessRisk ?? 'Business Risk', _getValue(_formData['partC_business_risk'])),
                ],
              ),

              const SizedBox(height: 16),

              // Part D - Mental Health
              _buildSectionCard(
                context,
                l10n?.partD_mentalHealthAssessment ?? 'Part D - Mental Health Assessment',
                [
                  _buildInfoRow(context,l10n?.question1 ?? 'Question 1', _getValue(_formData['partD_q1'])),
                  _buildInfoRow(context,l10n?.question2 ?? 'Question 2', _getValue(_formData['partD_q2'])),
                ],
              ),

              const SizedBox(height: 16),

              // Scores Section
              _buildSectionCard(
                context,
                l10n?.assessmentScores ?? 'Assessment Scores',
                [
                  _buildInfoRow(context,l10n?.partAScore ?? 'Part A Score', _getValue(_formData['score_partA'])),
                  _buildInfoRow(context,l10n?.partDScore ?? 'Part D Score', _getValue(_formData['score_partD'])),
                  _buildInfoRow(context,l10n?.totalScore ?? 'Total Score', _getValue(_formData['score_total'])),
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
    final l10n = AppLocalizations.of(context);

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

  Widget _buildInfoRow(BuildContext context,String label, String value) {
    final l10n = AppLocalizations.of(context);

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