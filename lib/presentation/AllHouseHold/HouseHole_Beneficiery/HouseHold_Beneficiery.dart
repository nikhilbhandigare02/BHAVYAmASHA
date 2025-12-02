import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:medixcel_new/core/widgets/AppHeader/AppHeader.dart';
import 'package:medixcel_new/core/widgets/RoundButton/RoundButton.dart';
import 'package:sizer/sizer.dart';
import '../../../core/config/routes/Route_Name.dart';
import '../../../core/config/themes/CustomColors.dart';
import 'package:medixcel_new/l10n/app_localizations.dart';
import '../../../data/Database/local_storage_dao.dart';
import '../../../data/Database/database_provider.dart';
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
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh data when screen is navigated to
    if (ModalRoute.of(context)?.isCurrent ?? false) {
      _loadBeneficiaries();
    }
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
        'beneficiaries_new',
        where: widget.hhId != null ? 'household_ref_key = ? AND is_migrated = 0' : 'is_migrated = 0',
        whereArgs: widget.hhId != null ? [widget.hhId] : null,
      );

      if (widget.hhId != null) {
        print('=== ALL RECORDS FOR HOUSEHOLD ${widget.hhId} ===');
        for (var row in rows) {
          try {
            final info = row['beneficiary_info'] is String
                ? jsonDecode(row['beneficiary_info'] as String)
                : row['beneficiary_info'];
                
            print('--- Record ---');
            print('ID: ${row['id']}');
            print('Unique Key: ${row['unique_key']}');
            print('Spouse Key: ${row['spouse_key']}');
            print('Household Ref Key: ${row['household_ref_key']}');
            print('Name: ${info['name'] ?? info['memberName'] ?? info['headName']}');
            print('Relation: ${info['relation'] ?? info['relation_to_head']}');
            print('Gender: ${info['gender']}');
            print('DOB: ${info['dob']}');
            print('Mobile: ${info['mobileNo'] ?? info['mobile']}');
            print('Is Death: ${row['is_death']}');
            print('Is Migrated: ${row['is_migrated']}');
            print('-------------');
          } catch (e) {
            print('Error parsing record: $e');
            print('Raw row data: $row');
          }
        }
        print('=== TOTAL RECORDS: ${rows.length} ===');
      }

      if (widget.hhId != null) {
        print('=== HOUSEHOLD RECORDS FOR HH_ID: ${widget.hhId} ===');
        for (var row in rows) {
          try {
            final info = row['beneficiary_info'] is String
                ? jsonDecode(row['beneficiary_info'] as String)
                : row['beneficiary_info'];
                
            print('--- Record ---');
            print('ID: ${row['id']}');
            print('Unique Key: ${row['unique_key']}');
            print('Spouse Key: ${row['spouse_key']}');
            print('Household Ref Key: ${row['household_ref_key']}');
            print('Name: ${info['name'] ?? info['memberName'] ?? info['headName']}');
            print('Relation: ${info['relation'] ?? info['relation_to_head']}');
            print('Gender: ${info['gender']}');
            print('DOB: ${info['dob']}');
            print('Mobile: ${info['mobileNo'] ?? info['mobile']}');
            print('-------------');
          } catch (e) {
            print('Error parsing record: $e');
            print('Raw row data: $row');
          }
        }
    
      }

      final beneficiaries = <Map<String, dynamic>>[];
      String? headerVillage;
      String? headerMohalla;

      // Process all records and add them to beneficiaries list
      for (final row in rows) {
        final rowHhId = row['household_ref_key']?.toString();
        if (rowHhId == null) continue;

        final info = row['beneficiary_info'] is String
            ? jsonDecode(row['beneficiary_info'] as String)
            : row['beneficiary_info'];

        if (info is! Map) continue;

        // Get basic info from record
        final gender = (info['gender']?.toString().toLowerCase() ?? '');
        final isFemale = gender == 'female' || gender == 'f';
        final richId = info['RichIDChanged']?.toString() ?? 
                       info['richIdChanged']?.toString() ?? 
                       info['richId']?.toString() ?? 
                       info['Rich_id']?.toString() ?? '';
        
        // Get name from multiple possible fields
        final name = info['memberName']?.toString() ?? 
                    info['name']?.toString() ??
                    info['headName']?.toString() ?? 
                    info['member_name']?.toString() ??
                    info['memberNameLocal']?.toString() ??
                    '';
        
        // Get relation
        final relation = info['relation']?.toString() ?? 
                        info['relation_to_head']?.toString() ?? 
                        'Member';
        
        // Create card for this record
        final card = <String, dynamic>{
          'hhId': rowHhId,
          'RegitrationDate': row['created_date_time']?.toString() ?? '',
          'RegitrationType': 'General',
          'BeneficiaryID': row['id']?.toString() ?? '',
          'Name': name,
          'Age|Gender': _formatAgeGender(info['dob'], info['gender']),
          'Mobileno.': info['mobileNo']?.toString() ?? 
                      info['mobile']?.toString() ??
                      info['mobile_number']?.toString() ??
                      '',
          'Relation': relation,
          'MaritalStatus': info['maritalStatus']?.toString() ?? 
                         info['marital_status']?.toString() ??
                         '',
          'FatherName': info['fatherName']?.toString() ?? 
                       info['father_name']?.toString() ??
                       '',
          'MotherName': info['motherName']?.toString() ?? 
                       info['mother_name']?.toString() ??
                       '',
          '_raw': row,
          '_memberData': info,
        };

        // Add RICH ID for females
        if (isFemale) {
          card['Rich_id'] = richId;
        }
        
        beneficiaries.add(card);

        headerVillage ??= info['village']?.toString();
        headerMohalla ??= info['mohalla']?.toString();
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
        onIcon1Tap: () {
          if (widget.hhId != null) {
            print('Navigating to MigrationSplitScreen with HHID: ${widget.hhId}');
            Navigator.pushNamed(
              context, 
              Route_Names.MigrationSplitOption,
              arguments: {'hhid': widget.hhId},
            );
          } else {
            print('Warning: No HHID available for navigation');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Household ID not available')),
            );
          }
        },
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


                    String formatGender(dynamic gender) {
                      if (gender == null) return 'Other';
                      final g = gender.toString().toLowerCase();
                      if (g == 'm' || g == 'male') return 'Male';
                      if (g == 'f' || g == 'female') return 'Female';
                      return 'Other';
                    }
                    

                    final head = _beneficiaries.firstWhere(
                      (b) => b['Relation'] == 'Head',
                      orElse: () => {'Name': '', 'Gender': '', 'Mobileno.': '', '_memberData': {}},
                    );
                    final spouse = _beneficiaries.firstWhere(
                      (b) => b['Relation'] == 'Spouse',
                      orElse: () => {'Name': '', 'Gender': '', 'Mobileno.': '', '_memberData': {}},
                    );

                    Navigator.pushNamed(
                      context, 
                      Route_Names.addFamilyMember,
                      arguments: {
                        'hhId': widget.hhId,
                        'headName': head['Name']?.toString() ?? '',
                        'headGender': formatGender(head['Gender']),
                        'spouseName': spouse['Name']?.toString() ?? '',
                        'spouseGender': formatGender(spouse['Gender']),
                        // Direct add-from-household flow: save immediately on Add.
                        'isMemberDetails': true,
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

  String _formatDate(String dateString) {
    if (dateString.isEmpty) return '';
    
    try {
      // First try parsing ISO format (yyyy-mm-dd)
      DateTime? date = DateTime.tryParse(dateString);
      
      // If that fails, try parsing other common formats
      if (date == null && dateString.contains('-')) {
        final parts = dateString.split(' ');
        final datePart = parts[0]; // Get just the date part
        final dateSegments = datePart.split('-');
        
        if (dateSegments.length == 3) {
          // If it's already in dd-mm-yyyy format, just return it as is
          if (dateSegments[0].length == 2 && dateSegments[2].length == 4) {
            return datePart;
          }
          // If it's in yyyy-mm-dd format, reformat it
          else if (dateSegments[0].length == 4 && dateSegments[2].length == 2) {
            return '${dateSegments[2]}-${dateSegments[1]}-${dateSegments[0]}';
          }
        }
      }
      
      // If we have a valid date, format it
      if (date != null) {
        final day = date.day.toString().padLeft(2, '0');
        final month = date.month.toString().padLeft(2, '0');
        final year = date.year.toString();
        return '$day-$month-$year';
      }
      
      // If all else fails, return the original string
      return dateString;
    } catch (e) {
      return dateString; // Return original if parsing/formatting fails
    }
  }

  Widget _householdCard(BuildContext context, Map<String, dynamic> data) {
    final l10n = AppLocalizations.of(context);
    final Color primary = Theme.of(context).primaryColor;

    // Get head and spouse info within this household
    final head = _beneficiaries.firstWhere(
      (b) => b['Relation'] == 'Head',
      orElse: () => {'Name': '', 'Gender': '', 'Mobileno.': '', 'Age|Gender': ''},
    );
    final spouse = _beneficiaries.firstWhere(
      (b) => b['Relation'] == 'Spouse',
      orElse: () => {'Name': '', 'Gender': '', 'Age|Gender': ''},
    );

    // Determine head's gender from Age|Gender field
    final headGenderStr = head['Age|Gender']?.toString().toLowerCase() ?? '';
    final isHeadMale = headGenderStr.contains('male');

    // Compute complete beneficiary ID from raw row (unique_key) if available
    final Map<String, dynamic>? raw =
        (data['_raw'] is Map<String, dynamic>) ? data['_raw'] as Map<String, dynamic> : null;
    final String completeBeneficiaryId =
        raw?['unique_key']?.toString() ?? data['BeneficiaryID']?.toString() ?? '';

    return InkWell(
      onTap: () async {
        await Navigator.pushNamed(
          context,
          Route_Names.addFamilyMember,
          arguments: {
            'isBeneficiary': true,
            'isEdit': true,
            'isMemberDetails': true,  // Add this flag to match AllBeneficiary behavior
            'beneficiaryId': completeBeneficiaryId,
            'hhId': data['hhId']?.toString() ?? '',
            // Use the overall head & spouse information for consistency
            'headName': head['Name']?.toString() ?? '',
            'headGender': isHeadMale ? 'Male' : 'Female',
            'spouseName': spouse['Name']?.toString() ?? '',
            'spouseGender': isHeadMale ? 'Female' : 'Male',
            // Relation of the tapped member inside the household
            'relation': data['Relation']?.toString() ?? '',
            // Village & Tola/Mohalla from header (if available), otherwise from data
            'village': _village?.toString() ?? '',
            'tolaMohalla': _mohalla?.toString() ?? '',
            // Raw card data for any additional use
            'householdData': data,
          },
        );

        debugPrint('=== Navigation to AddFamilyMember ===');
        debugPrint('   HHID: ${data['hhId']}');
        debugPrint('   Complete Beneficiary ID: $completeBeneficiaryId');
        debugPrint('   isEdit: true');
        debugPrint('   isMemberDetails: true');
        debugPrint('   Head Name: ${head['Name']}');
        debugPrint('   Spouse Name: ${spouse['Name']}');
        debugPrint('   Relation: ${data['Relation']}');
        debugPrint('   Village: ${_village}');
        debugPrint('   Tola/Mohalla: ${_mohalla}');
        debugPrint('===================================');

        await _loadBeneficiaries();
        _onSearchChanged();
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
                    children: [Expanded(
                        child: _rowText('Registration Date', _formatDate(data['RegitrationDate']?.toString() ?? '')),
                      ),                      const SizedBox(width: 12),
                      Expanded(child: _rowText('Registration Type', 
                        (data['_memberData']?['memberType']?.toString().toLowerCase() == 'child')
                            ? 'Child' 
                            : (data['RegitrationType'] ?? '')
                      )),
                      const SizedBox(width: 12),
                      Expanded(child: _rowText('Beneficiary ID',
                        (data['_raw']?['unique_key']?.toString().length ?? 0) > 11 
                            ? data['_raw']['unique_key'].toString().substring(data['_raw']['unique_key'].toString().length - 11) 
                            : (data['_raw']?['unique_key']?.toString() ?? '')
                      )),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _rowText('Name', data['Name'] ?? ''),
                            // Show RICH ID in same row for female children
                            if ((data['Age|Gender']?.toString().toLowerCase().contains('female') ?? false) && 
                                (data['Relation'] == 'Child') && 
                                (data['Rich_id']?.toString().isNotEmpty ?? false))
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: _rowText('RICH ID', data['Rich_id'] ?? ''),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: _rowText('Age | Gender', data['Age|Gender'] ?? '')),
                      const SizedBox(width: 12),
                      Expanded(child: _rowText('Mobile no.', data['Mobileno.'] ?? '')),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Show Father's name for children
                  if (data['Relation'] == 'Child')
                    _rowText(
                      'Father\'s Name',
                      data['FatherName']?.isNotEmpty == true ? data['FatherName'] : 'Not Available',
                    ),
                  
                  // Show Mother's name for children if available
                  if (data['Relation'] == 'Child' && data['MotherName']?.isNotEmpty == true)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: _rowText(
                        'Mother\'s Name',
                        data['MotherName'] ?? 'Not Available',
                      ),
                    ),
                  
                  // For Head cards, show spouse name with appropriate label based on gender
                  if (data['Relation'] == 'Head' && spouse['Name']?.isNotEmpty == true)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: _rowText(
                        isHeadMale ? 'Wife\'s Name' : 'Husband\'s Name',
                        spouse['Name']?.toString() ?? 'Not Available'
                      ),
                    ),
                  
                  // For Spouse cards, show head's name with appropriate label based on gender
                  if (data['Relation'] == 'Spouse' && head['Name']?.isNotEmpty == true)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: _rowText(
                        isHeadMale ? 'Husband\'s Name' : 'Wife\'s Name',
                        head['Name']?.toString() ?? 'Not Available'
                      ),
                    ),
                  
                  // For other members who are not head or spouse, show father's name if available
                  if (data['Relation'] != 'Head' && data['Relation'] != 'Spouse' && data['Relation'] != 'Child')
                    if (data['FatherName']?.isNotEmpty == true)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: _rowText(
                          'Father\'s Name',
                          data['FatherName'] ?? 'Not Available',
                        ),
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
