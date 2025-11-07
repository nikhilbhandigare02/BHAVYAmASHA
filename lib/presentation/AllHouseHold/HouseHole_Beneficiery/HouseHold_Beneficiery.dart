import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:medixcel_new/core/widgets/AppHeader/AppHeader.dart';
import 'package:medixcel_new/core/widgets/RoundButton/RoundButton.dart';
import 'package:sizer/sizer.dart';
import '../../../core/config/routes/Route_Name.dart';
import '../../../core/config/themes/CustomColors.dart';
import 'package:medixcel_new/l10n/app_localizations.dart';
import '../../../data/Local_Storage/local_storage_dao.dart';
import '../../../data/Local_Storage/database_provider.dart';
import '../../HomeScreen/HomeScreen.dart';
import '../MigrtionSplitScreen/MigrationSplitScreen.dart';

class HouseHold_BeneficiaryScreen extends StatefulWidget {
  final String? houseNo;
  final String? hhId;
  
  const HouseHold_BeneficiaryScreen({
    super.key,
    this.houseNo,
    this.hhId,
  });

  @override
  State<HouseHold_BeneficiaryScreen> createState() =>
      _HouseHold_BeneficiaryScreenState();
}

class _HouseHold_BeneficiaryScreenState
    extends State<HouseHold_BeneficiaryScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  late List<Map<String, dynamic>> _filtered;
  List<Map<String, dynamic>> _beneficiaries = [];
  bool _isLoading = true;
  String? _village;
  String? _mohalla;

  @override
  void initState() {
    super.initState();
    _filtered = [];
    _beneficiaries = [];
    _loadBeneficiaries();
    _searchCtrl.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchCtrl.removeListener(_onSearchChanged);
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadBeneficiaries() async {
    if (!mounted) return;
    
    setState(() => _isLoading = true);

    try {
      final db = await DatabaseProvider.instance.database;
      final List<Map<String, dynamic>> rows = await db.query(
        'beneficiaries',
        where: widget.hhId != null ? 'household_ref_key = ?' : null,
        whereArgs: widget.hhId != null ? [widget.hhId] : null,
      );

      final beneficiaries = <Map<String, dynamic>>[];
      String? headerVillage;
      String? headerMohalla;

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

        headerVillage ??= info['village']?.toString();
        headerMohalla ??= info['mohalla']?.toString();

        // Helper function to create a card
        void addCard(Map<String, dynamic> person, String relation, {bool isChild = false}) {
          if (person.isEmpty) return;
          
          final gender = (person['gender']?.toString().toLowerCase() ?? '');
          final isFemale = gender == 'female' || gender == 'f';
          final richId = person['RichIDChanged']?.toString() ?? 
                         person['richIdChanged']?.toString() ?? 
                         person['richId']?.toString() ?? '';
          
          // Format the card data to match the existing format
          // Get name from multiple possible fields
          final name = person['memberName']?.toString() ?? 
                      person['name']?.toString() ??
                      person['headName']?.toString() ?? // For head
                      person['member_name']?.toString() ??
                      person['memberNameLocal']?.toString() ??
                      '';
          
          final card = <String, dynamic>{
            'hhId': rowHhId,
            'RegitrationDate': row['created_date_time']?.toString() ?? '',
            'RegitrationType': isChild ? 'Child' : 'General',
            'BeneficiaryID': row['id']?.toString() ?? '',
            'Name': name,
            'Age|Gender': _formatAgeGender(person['dob'], person['gender']),
            'Mobileno.': person['mobileNo']?.toString() ?? 
                        person['mobile']?.toString() ??
                        person['mobile_number']?.toString() ??
                        '',
            'Relation': relation,
            'MaritalStatus': person['maritalStatus']?.toString() ?? 
                           person['marital_status']?.toString() ??
                           '',
            'FatherName': person['fatherName']?.toString() ?? 
                         person['father_name']?.toString() ??
                         (relation == 'Head' ? '' : head['headName']?.toString() ?? ''),
            'MotherName': person['motherName']?.toString() ?? 
                         person['mother_name']?.toString() ??
                         (relation == 'Spouse' ? '' : spouse['memberName']?.toString() ?? ''),
            '_raw': row,  // Keep the raw row data for reference
            '_memberData': person,  // Store the full member data
          };

          // For children, show father's name from head if not available
          if (isChild && person['fatherName'] == null) {
            card['FatherName'] = head['headName']?.toString() ?? '';
          }

          // For children, show mother's name from spouse if not available
          if (isChild && person['motherName'] == null) {
            card['MotherName'] = spouse['memberName']?.toString() ?? '';
          }

          // Add RICH ID for females and children
          if (isFemale || isChild) {
            card['Rich_id'] = richId;
          }
          
          // Set relation name for spouse display
          if (relation == 'Head' && spouse.isNotEmpty) {
            card['RelationName'] = spouse['memberName']?.toString() ?? spouse['name']?.toString() ?? '';
          } else if (relation == 'Spouse' && head.isNotEmpty) {
            card['RelationName'] = head['headName']?.toString() ?? head['name']?.toString() ?? '';
          }
          
          beneficiaries.add(card);
        }

        // Add head of household
        if (head.isNotEmpty) {
          addCard(head, 'Head');
        }
        
        // Add spouse
        if (spouse.isNotEmpty) {
          addCard(spouse, 'Spouse');
        }
        
        // Add children from children_details
        if (children.isNotEmpty) {
          final totalChildren = (children['totalLive'] is num ? children['totalLive'] : 0) as int;
          if (totalChildren > 0) {
            for (int i = 0; i < totalChildren; i++) {
              final child = {
                'name': 'Child ${i + 1}',
                'gender': i < (children['totalMale'] ?? 0) ? 'Male' : 'Female',
                'fatherName': head['headName']?.toString() ?? '',
                'motherName': spouse['memberName']?.toString() ?? '',
                'memberType': 'Child',
                'dob': null, // Add default values for required fields
                'mobileNo': '',
                'maritalStatus': '',
              };
              addCard(child, 'Child', isChild: true);
            }
          }
        }
        
        // Add other family members from member_details
        if (members.isNotEmpty && members is List) {
          for (final member in members) {
            if (member is Map) {
              final memberData = Map<String, dynamic>.from(member);
              // Ensure all required fields exist
              memberData['memberName'] = memberData['memberName'] ?? memberData['name'] ?? '';
              memberData['gender'] = memberData['gender'] ?? '';
              memberData['dob'] = memberData['dob'] ?? '';
              memberData['mobileNo'] = memberData['mobileNo'] ?? '';
              memberData['maritalStatus'] = memberData['maritalStatus'] ?? '';
              
              addCard(
                memberData,
                memberData['memberType'] == 'Child' ? 'Child' : 'Member',
                isChild: memberData['memberType'] == 'Child',
              );
            }
          }
        }
      }

      if (mounted) {
        setState(() {
          _beneficiaries = List<Map<String, dynamic>>.from(beneficiaries);
          _filtered = List<Map<String, dynamic>>.from(beneficiaries);
          _isLoading = false;
          _village = headerVillage;
          _mohalla = headerMohalla;
        });
      }
    } catch (e) {
      debugPrint('Error loading beneficiaries: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }


  String _formatAgeGender(dynamic dobRaw, dynamic genderRaw) {
    String age = 'N/A';
    String gender = (genderRaw?.toString().toLowerCase() ?? '');
    
    if (dobRaw != null && dobRaw.toString().isNotEmpty) {
      try {
        // Handle different date formats
        String dateStr = dobRaw.toString();
        DateTime? dob;
        
        // Try parsing as DateTime first (for ISO format)
        dob = DateTime.tryParse(dateStr);
        
        // If that fails, try parsing as timestamp (milliseconds since epoch)
        if (dob == null) {
          final timestamp = int.tryParse(dateStr);
          if (timestamp != null && timestamp > 0) {
            // If the number is too large, it's probably in milliseconds, otherwise seconds
            dob = DateTime.fromMillisecondsSinceEpoch(
              timestamp > 1000000000000 ? timestamp : timestamp * 1000,
              isUtc: true,
            );
          }
        }
        
        // If we have a valid date, calculate age
        if (dob != null) {
          final now = DateTime.now();
          int years = now.year - dob.year;
          
          // Adjust for month and day to handle cases where birthday hasn't occurred yet this year
          if (now.month < dob.month || (now.month == dob.month && now.day < dob.day)) {
            years--;
          }
          
          // Don't show negative ages
          age = years >= 0 ? years.toString() : '0';
        }
      } catch (e) {
        debugPrint('Error parsing date of birth: $e');
      }
    }
    
    // Format gender
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
    if (!mounted) return;
    
    final q = _searchCtrl.text.trim().toLowerCase();
    setState(() {
      if (q.isEmpty) {
        _filtered = List<Map<String, dynamic>>.from(_beneficiaries);
      } else {
        _filtered = _beneficiaries.where((e) {
          return (e['hhId']?.toString().toLowerCase() ?? '').contains(q) ||
              (e['Name']?.toString().toLowerCase() ?? '').contains(q) ||
              (e['Mobileno.']?.toString().toLowerCase() ?? '').contains(q) ||
              (e['BeneficiaryID']?.toString().toLowerCase() ?? '').contains(q);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (!mounted) return const SizedBox.shrink();
    
    return Scaffold(
      appBar: AppHeader(
        screenTitle: widget.houseNo != null
            ? '${l10n?.householdBeneficiaryTitle ?? 'Household'} '
            : l10n?.householdBeneficiaryTitle ?? 'Household Beneficiary',
        showBack: true,
        icon1Image: 'assets/images/left-right-arrow.png',
        onIcon1Tap: () =>
            Navigator.pushNamed(context, Route_Names.MigrationSplitOption),
        icon3Image: 'assets/images/home.png',
        onIcon3Tap: () => Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomeScreen(initialTabIndex: 1),
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: l10n?.householdBeneficiarySearch ??
                    'Household Beneficiary Search',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: AppColors.background,
                contentPadding:
                const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(4),
              ),
              padding:
              const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _infoColumn(
                      l10n?.villageLabel ?? 'Village',
                      ((_village != null && _village!.trim().isNotEmpty)
                          ? _village!
                          : (l10n?.notAvailable ?? 'Not Available'))),
                  _infoColumn(
                      l10n?.mohallaTolaNameLabel ?? 'Tola/Mohalla',
                      ((_mohalla != null && _mohalla!.trim().isNotEmpty)
                          ? _mohalla!
                          : (l10n?.notAvailable ?? 'Not Available'))),
                ],
              ),
            ),
          ),

          // List
          _isLoading
              ? const Expanded(
              child: Center(child: CircularProgressIndicator()))
              : _filtered.isEmpty
              ? Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  _beneficiaries.isEmpty
                      ? 'No beneficiaries found. Add a new beneficiary to get started.'
                      : 'No matching beneficiaries found.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 16, color: Colors.grey[600]),
                ),
              ),
            ),
          )
              : Expanded(
            child: RefreshIndicator(
              onRefresh: _loadBeneficiaries,
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                itemCount: _filtered.length,
                itemBuilder: (context, index) {
                  final data = _filtered[index];
                  return _householdCard(context, data);
                },
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding:
              const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8),
              child: SizedBox(
                width: double.infinity,
                height: 35,
                child: RoundButton(
                  title: (l10n?.addNewBeneficiaryButton ??
                      'Add New Beneficiary')
                      .toUpperCase(),
                  color: AppColors.primary,
                  borderRadius: 8,
                  height: 50,
                  onPress: () {
                    final head = _beneficiaries.firstWhere(
                      (b) => b['Relation'] == 'Head',
                      orElse: () => {'Name': '', 'Gender': '', 'Mobileno.': ''},
                    );
                    final spouse = _beneficiaries.firstWhere(
                      (b) => b['Relation'] == 'Spouse',
                      orElse: () => {'Name': '', 'Gender': ''},
                    );
                    
                    // Format gender to standard format (Male/Female/Other)
                    String formatGender(dynamic gender) {
                      if (gender == null) return 'Other';
                      final g = gender.toString().toLowerCase();
                      if (g == 'm' || g == 'male') return 'Male';
                      if (g == 'f' || g == 'female') return 'Female';
                      return 'Other';
                    }
                    
                    Navigator.pushNamed(
                      context, 
                      Route_Names.addFamilyMember,
                      arguments: {
                        'hhId': widget.hhId,
                      },
                    );
                  },
                ),
              ),
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
        final head = _beneficiaries.firstWhere(
          (b) => b['Relation'] == 'Head',
          orElse: () => {'Name': '', 'Gender': '', 'Mobileno.': ''},
        );
        final spouse = _beneficiaries.firstWhere(
          (b) => b['Relation'] == 'Spouse',
          orElse: () => {'Name': '', 'Gender': ''},
        );

        // Format gender to standard format (Male/Female/Other)
        String formatGender(dynamic gender) {
          if (gender == null) return 'Other';
          final g = gender.toString().toLowerCase();
          if (g == 'm' || g == 'male') return 'Male';
          if (g == 'f' || g == 'female') return 'Female';
          return 'Other';
        }


        final memberId = int.tryParse(widget.hhId ?? '0') ?? 0;

        Navigator.pushNamed(
          context,
          Route_Names.updateMemberDetail,
          arguments: {
            'memberId': memberId, // Pass the parsed integer ID
            'isEdit': true, // Set to true for editing existing member
          },
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 2,
              spreadRadius: 1,
              offset: const Offset(0, 2),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 2,
              spreadRadius: 1,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              decoration: const BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
              ),
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  Row(
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
                            fontSize: 13.sp,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.asset(
                          'assets/images/sync.png',
                          width: 6.w,
                          height: 6.w,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: primary.withOpacity(0.95),
                borderRadius:
                const BorderRadius.vertical(bottom: Radius.circular(4)),
              ),
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: _rowText('Registration Date', data['RegitrationDate'] ?? '')),
                      const SizedBox(width: 12),
                      Expanded(child: _rowText('Registration Type', data['RegitrationType'] ?? '')),
                      const SizedBox(width: 12),
                      Expanded(child: _rowText('Beneficiary ID',
  data['Relation'] == 'Head'
    ? ((data['_raw']['unique_key']?.toString().length ?? 0) > 11 ? data['_raw']['unique_key'].toString().substring(data['_raw']['unique_key'].toString().length - 11) : (data['_raw']['unique_key']?.toString() ?? ''))
    : ((data['_raw']['spouse_key']?.toString().length ?? 0) > 11 ? data['_raw']['spouse_key'].toString().substring(data['_raw']['spouse_key'].toString().length - 11) : (data['_raw']['spouse_key']?.toString() ?? ''))
)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: _rowText('Name', data['Name'] ?? '')),
                      const SizedBox(width: 12),
                      Expanded(child: _rowText('Age | Gender', data['Age|Gender'] ?? '')),
                      const SizedBox(width: 12),
                      Expanded(child: _rowText('Mobile no.', data['Mobileno.'] ?? '')),
                    ],
                  ),
                  if (((data['Relation'] == 'Head' || data['Relation'] == 'Spouse') && ((data['Age|Gender']?.toString().toLowerCase().contains('female') ?? false) || (data['RegitrationType']?.toString().toLowerCase() == 'child'))))
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: _rowText('Rich_id', data['Rich_id'] ?? ''),
                    ),
                  const SizedBox(height: 10),
                  // Show Father's name for children, otherwise show spouse name
                  if (data['Relation'] == 'Child')
                    _rowText(
                      'Father\'s Name',
                      data['FatherName']?.isNotEmpty == true ? data['FatherName'] : 'N/A',
                    ),
                  if (data['Relation'] == 'Child' && data['MotherName']?.isNotEmpty == true)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: _rowText(
                        'Mother\'s Name',
                        data['MotherName'] ?? 'N/A',
                      ),
                    ),
                  if (data['Relation'] == 'Head' && data['RelationName']?.isNotEmpty == true)
                    _rowText('Wife\'s Name', data['RelationName'] ?? 'N/A'),
                  if (data['Relation'] == 'Spouse' && data['RelationName']?.isNotEmpty == true)
                    _rowText('Husband\'s Name', data['RelationName'] ?? 'N/A'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _rowText(String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: AppColors.background,
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: AppColors.background,
            fontWeight: FontWeight.w400,
            fontSize: 13.sp,
          ),
        ),
      ],
    );
  }
  Widget _infoColumn(String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 13.sp,
            color: AppColors.background,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.background,
          ),
        ),
      ],
    );
  }

}
