import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:medixcel_new/core/widgets/AppDrawer/Drawer.dart';
import 'package:medixcel_new/core/widgets/AppHeader/AppHeader.dart';
import 'package:medixcel_new/core/widgets/RoundButton/RoundButton.dart';
import 'package:sizer/sizer.dart';
import '../../../core/config/routes/Route_Name.dart';
import '../../../core/config/themes/CustomColors.dart';
import 'package:medixcel_new/l10n/app_localizations.dart';
import '../../../data/Local_Storage/database_provider.dart';
import '../RegisterChildDueListForm/RegisterChildDueListForm.dart';

class RegisterChildDueList extends StatefulWidget {
  const RegisterChildDueList({super.key});

  @override
  State<RegisterChildDueList> createState() => _RegisterChildDueListState();
}

class _RegisterChildDueListState extends State<RegisterChildDueList> {
  final TextEditingController _searchCtrl = TextEditingController();
  List<Map<String, dynamic>> _childBeneficiaries = [];
  late List<Map<String, dynamic>> _filtered;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _filtered = [];
    _childBeneficiaries = [];
    _loadChildBeneficiaries();
    _searchCtrl.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchCtrl.removeListener(_onSearchChanged);
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadChildBeneficiaries() async {
    if (!mounted) return;
    
    setState(() => _isLoading = true);

    try {
      final db = await DatabaseProvider.instance.database;
      final List<Map<String, dynamic>> rows = await db.query(
        'beneficiaries',
        where: 'is_deleted = ?',
        whereArgs: [0],
      );

      final childBeneficiaries = <Map<String, dynamic>>[];

      for (final row in rows) {
        final rowHhId = row['household_ref_key']?.toString();
        if (rowHhId == null) continue;

        final info = row['beneficiary_info'] is String
            ? jsonDecode(row['beneficiary_info'] as String)
            : row['beneficiary_info'];

        if (info is! Map) continue;

        final head = info['head_details'] is Map ? info['head_details'] : {};
        final spouse = info['spouse_details'] is Map ? info['spouse_details'] : {};
        final children = info['children_details'] is Map ? info['children_details'] : {};
        final members = info['member_details'] is List ? info['member_details'] : [];

        // Process children from member_details where memberType is "Child"
        if (members.isNotEmpty && members is List) {
          for (final member in members) {
            if (member is Map) {
              final memberType = member['memberType']?.toString() ?? '';
              
              // Only process if memberType is "Child"
              if (memberType == 'Child') {
                final memberData = Map<String, dynamic>.from(member);
                
                // Get name from multiple possible fields
                final name = memberData['memberName']?.toString() ?? 
                            memberData['name']?.toString() ??
                            memberData['member_name']?.toString() ??
                            memberData['memberNameLocal']?.toString() ??
                            '';
                
                if (name.isEmpty) {
                  debugPrint('⚠️ Skipping member with empty name');
                  continue;
                }
                
                debugPrint('\n🔎 Processing child: $name in household: $rowHhId');
                
                // Check if this child is already registered
                final isAlreadyRegistered = await _isChildRegistered(db, rowHhId, name);
                
                if (isAlreadyRegistered) {
                  debugPrint('⏭️ Child already registered: $name in household: $rowHhId - SKIPPING');
                  continue; // Skip this child, don't add to list
                }
                
                debugPrint('✅ Child NOT registered yet: $name - ADDING TO LIST');
                
                // Get father's name (from member data or head)
                final fatherName = memberData['fatherName']?.toString() ?? 
                                  memberData['father_name']?.toString() ??
                                  head['headName']?.toString() ?? 
                                  head['memberName']?.toString() ?? '';
                
                // Get mother's name (from member data or spouse)
                final motherName = memberData['motherName']?.toString() ?? 
                                  memberData['mother_name']?.toString() ??
                                  spouse['memberName']?.toString() ?? 
                                  spouse['headName']?.toString() ?? '';
                
                // Get mobile number
                final mobileNo = memberData['mobileNo']?.toString() ?? 
                                memberData['mobile']?.toString() ??
                                memberData['mobile_number']?.toString() ??
                                head['mobileNo']?.toString() ?? '';
                
                // Get RCH ID
                final richId = memberData['RichIDChanged']?.toString() ?? 
                              memberData['richIdChanged']?.toString() ?? 
                              memberData['richId']?.toString() ?? '';
                
                final card = <String, dynamic>{
                  'hhId': rowHhId,
                  'RegitrationDate': _formatDate(row['created_date_time']?.toString()),
                  'RegitrationType': 'Child',
                  'BeneficiaryID': memberData['unique_key']?.toString() ?? row['id']?.toString() ?? '',
                  'RchID': richId,
                  'Name': name,
                  'Age|Gender': _formatAgeGender(memberData['dob'], memberData['gender']),
                  'Mobileno.': mobileNo,
                  'FatherName': fatherName,
                  'MotherName': motherName,
                  '_raw': row,
                  '_memberData': memberData,
                };
                
                childBeneficiaries.add(card);
              }
            }
          }
        }
      }

      if (mounted) {
        setState(() {
          _childBeneficiaries = List<Map<String, dynamic>>.from(childBeneficiaries);
          _filtered = List<Map<String, dynamic>>.from(childBeneficiaries);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading child beneficiaries: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<bool> _isChildRegistered(Database db, String hhId, String childName) async {
    try {
      // Normalize the search name by trimming and converting to lowercase
      final normalizedSearchName = childName.trim().toLowerCase();
      debugPrint('\n🔍 Checking registration for: "$childName" (normalized: "$normalizedSearchName") in household: "$hhId"');
      
      // Query all followup_form_data records for this household
      final results = await db.query(
        'followup_form_data',
        where: 'household_ref_key = ?',
        whereArgs: [hhId],
      );

      debugPrint('📊 Found ${results.length} form records for household: $hhId');

      if (results.isEmpty) {
        debugPrint('⚠️ No records found in followup_form_data for household: $hhId');
        return false;
      }

      for (int i = 0; i < results.length; i++) {
        final row = results[i];
        try {
          final formJson = row['form_json'] as String?;
          if (formJson == null || formJson.isEmpty) {
            debugPrint('⚠️ Record $i: Empty form_json');
            continue;
          }

          debugPrint('\n📄 Record $i form_json: $formJson');

          final formData = jsonDecode(formJson);
          final formType = (formData['form_type']?.toString() ?? '').toLowerCase();
          
          // Skip if this isn't a child registration form
          if (formType != 'child_registration_due') {
            debugPrint('⏭️ Record $i: Not a child registration form (type: $formType)');
            continue;
          }
          
          // Validate form_data structure
          if (formData['form_data'] == null || formData['form_data'] is! Map) {
            debugPrint('⚠️ Record $i: Missing or invalid form_data');
            continue;
          }
          
          final formDataMap = formData['form_data'] as Map<String, dynamic>;
          final childNameInForm = formDataMap['child_name']?.toString() ?? '';
          
          if (childNameInForm.isEmpty) {
            debugPrint('⚠️ Record $i: Empty child_name in form data');
            continue;
          }
          
          // Normalize the stored name
          final normalizedStoredName = childNameInForm.trim().toLowerCase();

          debugPrint('📋 Record $i - Form Type: "$formType"');
          debugPrint('📋 Record $i - Child Name in DB: "$childNameInForm" (normalized: "$normalizedStoredName")');
          debugPrint('📋 Record $i - Comparing: "$normalizedStoredName" (DB) vs "$normalizedSearchName" (searching)');
          debugPrint('📋 Record $i - Match: ${normalizedStoredName == normalizedSearchName}');

          // Check for name match
          if (normalizedStoredName == normalizedSearchName) {
            debugPrint('✅ MATCH FOUND! Existing registration: "$childName" in $hhId');
            debugPrint('   - Original names - DB: "$childNameInForm" vs Search: "$childName"');
            debugPrint('   - Normalized match: "$normalizedStoredName" == "$normalizedSearchName"');
            return true;
          }
        } catch (e) {
          debugPrint('❌ Error parsing form data in record $i: $e');
          debugPrint('Form JSON: ${row['form_json']}');
          continue;
        }
      }
      
      debugPrint('❌ No registration found for: "$childName" in "$hhId"');
      return false;
    } catch (e) {
      debugPrint('❌ Error checking if child is registered: $e');
      return false;
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return 'N/A';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
    } catch (e) {
      return dateStr!;
    }
  }

  String _formatAgeGender(dynamic dobRaw, dynamic genderRaw) {
    String age = 'N/A';
    String gender = (genderRaw?.toString().toLowerCase() ?? '');
    
    if (dobRaw != null && dobRaw.toString().isNotEmpty) {
      try {
        String dateStr = dobRaw.toString();
        DateTime? dob;
        
        dob = DateTime.tryParse(dateStr);
        
        if (dob == null) {
          final timestamp = int.tryParse(dateStr);
          if (timestamp != null && timestamp > 0) {
            dob = DateTime.fromMillisecondsSinceEpoch(
              timestamp > 1000000000000 ? timestamp : timestamp * 1000,
              isUtc: true,
            );
          }
        }
        
        if (dob != null) {
          final now = DateTime.now();
          int years = now.year - dob.year;
          
          if (now.month < dob.month || (now.month == dob.month && now.day < dob.day)) {
            years--;
          }
          
          age = years >= 0 ? years.toString() : '0';
        }
      } catch (e) {
        debugPrint('Error parsing date of birth: $e');
      }
    }
    
    String displayGender;
    switch (gender) {
      case 'm':
      case 'male':
        displayGender = 'Male';
        break;
      case 'f':
      case 'female':
        displayGender = 'Female';
        break;
      default:
        displayGender = 'Other';
    }
    
    return '$age Y | $displayGender';
  }

  void _onSearchChanged() {
    final q = _searchCtrl.text.trim().toLowerCase();
    setState(() {
      if (q.isEmpty) {
        _filtered = List<Map<String, dynamic>>.from(_childBeneficiaries);
      } else {
        _filtered = _childBeneficiaries.where((e) {
          return (e['hhId']?.toString().toLowerCase() ?? '').contains(q) ||
              (e['Name']?.toString().toLowerCase() ?? '').contains(q) ||
              (e['Mobileno.']?.toString().toLowerCase() ?? '').contains(q) ||
              (e['FatherName']?.toString().toLowerCase() ?? '').contains(q) ||
              (e['BeneficiaryID']?.toString().toLowerCase() ?? '').contains(q) ||
              (e['RchID']?.toString().toLowerCase() ?? '').contains(q);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppHeader(
        screenTitle:  l10n?.childRegisteredDueListTitle ?? 'Register Child Due List',
        showBack: true,

      ),
      drawer: const CustomDrawer(),
      body: Column(
        children: [

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText:  l10n?.searchHintRegisterChildDueList ?? ' ',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: AppColors.background,
                contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColors.outlineVariant),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Theme.of(context).primaryColor),
                ),
              ),
            ),
          ),



                    Expanded(
                    child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filtered.isEmpty
                    ? Center(
                        child: Text(
                             'No children found',
                          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(5, 0, 5, 12),
                        itemCount: _filtered.length,
                        itemBuilder: (context, index) {
                          final data = _filtered[index];
                          return _householdCard(context, data);
                        },
                      ),
          ),


        ],
      ),
    );
  }

   Widget _householdCard(BuildContext context, Map<String, dynamic> data) {
    final l10n = AppLocalizations.of(context);
    final Color primary = Theme.of(context).primaryColor;

    return InkWell(
      onTap: () {
        // Extract the required data from the card
        final name = data['Name'] ?? '';
        final ageGender = data['Age|Gender']?.toString().split(' | ') ?? [];
        final gender = ageGender.length > 1 ? ageGender[1] : '';
        final mobile = data['Mobileno.'] ?? '';
        final hhId = data['hhId']?.toString() ?? '';
        final rchId = data['RchID'] ?? '';
        final fatherName = data['FatherName'] ?? '';
        final beneficiaryId = data['BeneficiaryID']?.toString() ?? '';
        
        debugPrint('Navigating with data:');
        debugPrint('- Name: $name');
        debugPrint('- Gender: $gender');
        debugPrint('- Mobile: $mobile');
        debugPrint('- HHID: $hhId');
        debugPrint('- RCH ID: $rchId');

        debugPrint('Sending navigation data:');
        final args = <String, dynamic>{
          'hhId': hhId,
          'name': name,
          'gender': gender,
          'mobile': mobile,
          'rchId': rchId,
          'fatherName': fatherName,
          'beneficiaryId': beneficiaryId,
        };
        debugPrint(args.toString());
        
        // Navigate using the route method
        final route = RegisterChildDueListFormScreen.route(
          RouteSettings(
            name: Route_Names.RegisterChildDueListFormScreen,
            arguments: args,
          ),
        );
        Navigator.push(context, route).then((result) {
          if (result != null && result is Map<String, dynamic>) {
            if (result['saved'] == true) {
              debugPrint('✅ Form saved successfully! Reloading list...');
              // Reload the list to reflect the saved registration
              _loadChildBeneficiaries();
            }
          }
        });
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
        height: 180, // Increased height
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 3,
              spreadRadius: 1,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Row
            Container(
              decoration: const BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.home, color: AppColors.primary, size: 16),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      (data['hhId'] != null && data['hhId'].toString().length > 11)
                          ? data['hhId'].toString().substring(data['hhId'].toString().length - 11)
                          : (data['hhId']?.toString() ?? ''),
                      style: TextStyle(
                        color: primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.asset(
                      'assets/images/sync.png', // Make sure this asset exists
                      width: 24,
                      height: 24,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => 
                          const Icon(Icons.sync, size: 24, color: Colors.grey),
                    ),
                  ),
                ],
              ),
            ),

            // Card Body
            Container(
              decoration: BoxDecoration(
                color: primary.withOpacity(0.95),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(4)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: _rowText(l10n?.registrationDateLabel ?? 'Registration Date', data['RegitrationDate'] ?? 'N/A')),
                      const SizedBox(width: 8),
                      Expanded(child: _rowText(l10n?.registrationTypeLabel ?? 'Registration Type', data['RegitrationType'] ?? 'Child')),
                      const SizedBox(width: 8),
                      Expanded(child: _rowText(l10n?.beneficiaryIdLabel ?? 'Beneficiary ID', 
                        (data['BeneficiaryID']?.toString().length ?? 0) > 11 
                          ? data['BeneficiaryID'].toString().substring(data['BeneficiaryID'].toString().length - 11) 
                          : (data['BeneficiaryID']?.toString() ?? 'N/A'))),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: _rowText(l10n?.nameLabelSimple ?? 'Name', data['Name'] ?? 'N/A')),
                      const SizedBox(width: 8),
                      Expanded(child: _rowText(l10n?.ageGenderLabel ?? 'Age | Gender', data['Age|Gender'] ?? 'N/A')),
                      const SizedBox(width: 8),
                      Expanded(child: _rowText(
                        l10n?.rchIdLabel ?? 'RCH ID', 
                        data['RchID']?.isNotEmpty == true ? data['RchID'] : 'N/A',
                      )),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _rowText(
                          l10n?.mobileLabelSimple ?? 'Mobile No.',
                          data['Mobileno.']?.isNotEmpty == true ? data['Mobileno.'] : 'N/A',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _rowText(
                          l10n?.fatherNameLabel ?? 'Father\'s Name',
                          data['FatherName']?.isNotEmpty == true ? data['FatherName'] : 'N/A',
                        ),
                      ),
                    ],
                  ),

                ],
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _rowText(String title, String value) {
    final Color primary = Theme.of(context).primaryColor;
    final bool isLight = primary.computeLuminance() > 0.5;
    final textColor = isLight ? Colors.black87 : Colors.white;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: textColor.withOpacity(0.9),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.w400,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
