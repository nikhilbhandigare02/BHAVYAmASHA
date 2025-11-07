import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:medixcel_new/core/widgets/AppHeader/AppHeader.dart';
import 'package:medixcel_new/core/widgets/RoundButton/RoundButton.dart';
import 'package:sizer/sizer.dart';
import 'package:medixcel_new/data/Local_Storage/database_provider.dart';
import 'package:medixcel_new/core/config/themes/CustomColors.dart';
import 'package:medixcel_new/l10n/app_localizations.dart';

class RegisterChildScreen extends StatefulWidget {
  const RegisterChildScreen({super.key});

  @override
  State<RegisterChildScreen> createState() => _RegisterChildScreenState();
}

class _RegisterChildScreenState extends State<RegisterChildScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  bool _isLoading = true;
  List<Map<String, dynamic>> _childMembers = [];
  List<Map<String, dynamic>> _filteredChildMembers = [];

  @override
  void initState() {
    super.initState();
    _loadChildMembers();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }
  
  void _onSearchChanged(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredChildMembers = List<Map<String, dynamic>>.from(_childMembers);
      });
      return;
    }
    
    final searchTerm = query.toLowerCase();
    setState(() {
      _filteredChildMembers = _childMembers.where((child) {
        return (child['Name']?.toString().toLowerCase().contains(searchTerm) ?? false) ||
               (child['hhId']?.toString().toLowerCase().contains(searchTerm) ?? false) ||
               (child['BeneficiaryID']?.toString().toLowerCase().contains(searchTerm) ?? false);
      }).toList();
    });
  }

  Future<void> _loadChildMembers() async {
    try {
      final db = await DatabaseProvider.instance.database;
      final List<Map<String, dynamic>> rows = await db.query(
        'beneficiaries',
        where: 'is_deleted = 0', // Only non-deleted records
      );

      final List<Map<String, dynamic>> childMembers = [];

      for (final row in rows) {
        try {
          final info = row['beneficiary_info'] is String 
              ? jsonDecode(row['beneficiary_info'] as String) 
              : row['beneficiary_info'];

          if (info is! Map) continue;

          // Check if this is a child member
          final memberDetails = info['member_details'] as List? ?? [];
          for (final member in memberDetails) {
            if (member is Map && 
                member['memberType']?.toString().toLowerCase() == 'child') {
              
              final head = info['head_details'] is Map ? info['head_details'] : {};
              final spouse = info['spouse_details'] is Map ? info['spouse_details'] : {};
              
              childMembers.add({
                'hhId': row['household_ref_key']?.toString() ?? '',
                'RegitrationDate': row['created_date_time']?.toString() ?? '',
                'RegitrationType': 'Child',
                'BeneficiaryID': member['memberId']?.toString() ?? '',
                'Name': member['memberName']?.toString() ?? '',
                'Age|Gender': _formatAgeGender(member['dob'], member['gender']),
                'FatherName': head['headName']?.toString() ?? '',
                'MotherName': spouse['memberName']?.toString() ?? '',
                'Gender': member['gender']?.toString() ?? '',
                'DOB': member['dob']?.toString() ?? '',
                '_raw': row,
                '_memberData': member,
              });
            }
          }
        } catch (e) {
          debugPrint('Error processing beneficiary: $e');
        }
      }

      if (mounted) {
        setState(() {
          _childMembers = childMembers;
          _filteredChildMembers = List.from(childMembers);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading child members: $e');
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
        final dob = DateTime.tryParse(dobRaw.toString());
        if (dob != null) {
          final now = DateTime.now();
          int years = now.year - dob.year;
          int months = now.month - dob.month;
          
          if (months < 0 || (months == 0 && now.day < dob.day)) {
            years--;
            months += 12;
          }
          
          age = years > 0 ? '$years Y' : '$months M';
        }
      } catch (_) {}
    }
    
    String displayGender = gender == 'm' || gender == 'male'
        ? 'Male'
        : gender == 'f' || gender == 'female'
            ? 'Female'
            : 'Other';
            
    return '$age | $displayGender';
  }




  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_childMembers.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Child Registration'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.child_care_outlined,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'No child records found',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 16),
              RoundButton(
                title: 'Refresh',
                onPress: () {
                  setState(() => _isLoading = true);
                  _loadChildMembers();
                },
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppHeader(
        screenTitle: l10n?.childRegisteredBeneficiaryListTitle ?? 'Register child beneficiary list',
        showBack: true,
      ),
      body: Column(
        children: [
          // Search Field
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: l10n?.search ?? 'Search by name or ID...',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 4),
              ),
              style: const TextStyle(fontSize: 14),
            ),
          ),

          // List of Children
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadChildMembers,
              child: _filteredChildMembers.isEmpty
                  ? Center(
                      child: Text(
                          'No matching children found',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 16,
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.only(bottom: 20),
                      itemCount: _filteredChildMembers.length,
                      itemBuilder: (context, index) {
                        final child = _filteredChildMembers[index];
                        return _childCard(context, child);
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // Original Card Design
  Widget _childCard(BuildContext context, Map<String, dynamic> child) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header with blue background
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
            ),
            child: Row(
              children: [
                const Icon(Icons.child_care, color: Colors.blue, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Child ID: ${child['BeneficiaryID'] ?? 'N/A'}',
                    style: const TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Card content
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // First row: Name and Age|Gender
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Name',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            child['Name'] ?? 'N/A',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Age | Gender',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            child['Age|Gender'] ?? 'N/A',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // Second row: Father and Mother
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Father',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            child['FatherName'] ?? 'N/A',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Mother',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            child['MotherName'] ?? 'N/A',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // Registration Date
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Registration Date',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      child['RegitrationDate'] ?? 'N/A',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
