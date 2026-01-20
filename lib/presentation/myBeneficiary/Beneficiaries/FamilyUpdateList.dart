import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:medixcel_new/core/widgets/AppDrawer/Drawer.dart';
import 'package:medixcel_new/core/widgets/AppHeader/AppHeader.dart';
import 'package:sizer/sizer.dart';
import '../../../core/config/themes/CustomColors.dart';
import 'package:medixcel_new/l10n/app_localizations.dart';

import '../../../data/Database/database_provider.dart';
import '../../../data/Database/local_storage_dao.dart';
import '../../../data/SecureStorage/SecureStorage.dart';
import '../../AllHouseHold/HouseHole_Beneficiery/HouseHold_Beneficiery.dart';

class FamliyUpdate extends StatefulWidget {
  const FamliyUpdate({super.key});

  @override
  State<FamliyUpdate> createState() => _FamliyUpdateState();
}

class _FamliyUpdateState extends State<FamliyUpdate> {
  final TextEditingController _searchCtrl = TextEditingController();
  List<Map<String, dynamic>> _items = [];
  List<Map<String, dynamic>> _filtered = [];
  bool _isLoading = true;
  List<Map<String, dynamic>> _households = []; // Store households data for fallback

  // Helper method to extract house number from household address
  String _extractHouseNumberFromAddress(Map<String, dynamic> addressData) {
    if (addressData.isEmpty) return '';
    
    // Try common house number fields in address data
    final houseNoFields = [
      'houseNo',
      'house_no',
      'houseNumber',
      'house_number',
      'houseno',
      'building_no',
      'buildingNumber',
      'building_no',
      'address_line1',
      'addressLine1',
    ];
    
    for (final field in houseNoFields) {
      final value = addressData[field]?.toString().trim();
      if (value != null && value.isNotEmpty) {
        return value;
      }
    }
    
    final fullAddress = addressData['full_address']?.toString() ??
                       addressData['address']?.toString() ?? 
                       addressData['complete_address']?.toString() ?? '';
    
    if (fullAddress.isNotEmpty) {
      // Try to extract house number from the beginning of address
      final lines = fullAddress.split(',');
      for (final line in lines) {
        final trimmed = line.trim();
        // Look for patterns like "House No: 123", "H.No. 123", "123", etc.
        if (RegExp(r'^\d+').hasMatch(trimmed) || 
            RegExp(r'(?i)house\s*(no|number)?\s*[:\-]?\s*\d+').hasMatch(trimmed) ||
            RegExp(r'(?i)h\.?\.?\s*no\.?\s*[:\-]?\s*\d+').hasMatch(trimmed)) {
          return trimmed;
        }
      }
    }
    
    return '';
  }

  // Helper method to get house number with fallback logic
  String _getHouseNumber(Map<String, dynamic> data, List<Map<String, dynamic>> households) {
    // First try to get from beneficiary_new table
    final beneficiaryHouseNo = data['houseNo']?.toString() ?? 
                              data['_raw']['beneficiary_info']?['houseNo']?.toString() ?? '';
    
    if (beneficiaryHouseNo.isNotEmpty && beneficiaryHouseNo != '0') {
      return beneficiaryHouseNo;
    }
    
    // If not found in beneficiary_new, try households table
    final householdRefKey = data['_raw']['household_ref_key']?.toString() ?? '';
    if (householdRefKey.isNotEmpty) {
      for (final household in households) {
        if (household['unique_key']?.toString() == householdRefKey) {
          final addressData = household['address'] as Map<String, dynamic>?;
          if (addressData != null) {
            final houseNoFromAddress = _extractHouseNumberFromAddress(addressData);
            if (houseNoFromAddress.isNotEmpty) {
              return houseNoFromAddress;
            }
          }
        }
      }
    }
    
    return '';
  }

  DateTime _resolveSortDate(Map<String, dynamic> raw) {
    dynamic value = raw['modified_date_time'];

    if (value == null || value.toString().isEmpty) {
      value = raw['created_date_time'];
    }

    if (value == null) {
      return DateTime.fromMillisecondsSinceEpoch(0);
    }

    final str = value.toString();

    // ISO 8601: 2026-01-08T13:38:14.074Z
    final parsed = DateTime.tryParse(str);
    if (parsed != null) return parsed.toUtc();

    // Timestamp (seconds or milliseconds)
    final ts = int.tryParse(str);
    if (ts != null) {
      return DateTime.fromMillisecondsSinceEpoch(
        ts > 1000000000000 ? ts : ts * 1000,
        isUtc: true,
      );
    }

    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  @override
  void initState() {
    super.initState();
    _loadData();

    LocalStorageDao.instance.getAllBeneficiaries();
    _searchCtrl.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchCtrl.removeListener(_onSearchChanged);
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final q = _searchCtrl.text.trim().toLowerCase();
    setState(() {
      if (q.isEmpty) {
        _filtered = List<Map<String, dynamic>>.from(_items);
      } else {
        _filtered = _items.where((e) {
          final hhId = (e['hhId'] ?? '').toString().toLowerCase();
          final houseNo = (e['houseNo'] ?? '').toString().toLowerCase();
          final name = (e['name'] ?? '').toString().toLowerCase();
          final mobile = (e['mobile'] ?? '').toString().toLowerCase();
          final mohalla = (e['mohalla'] ?? '').toString().toLowerCase();
          final mohallaTola = (e['mohallaTola'] ?? '').toString().toLowerCase();

          final raw = (e['_raw'] as Map<String, dynamic>? ?? const {});
          final fullHhRef = (raw['household_ref_key'] ?? '').toString();
          final searchHhRef = fullHhRef.length > 11
              ? fullHhRef.substring(fullHhRef.length - 11).toLowerCase()
              : fullHhRef.toLowerCase();

          return hhId.contains(q) ||
              houseNo.contains(q) ||
              name.contains(q) ||
              mobile.contains(q) ||
              mohalla.contains(q) ||
              mohallaTola.contains(q) ||
              searchHhRef.contains(q);
        }).toList();
      }
    });
  }

  Future<void> _loadData() async {
    if (mounted) {
      setState(() => _isLoading = true);
    }

    try {
      final db = await DatabaseProvider.instance.database;

      final currentUserData = await SecureStorageService.getCurrentUserData();
      final currentUserKey = currentUserData?['unique_key']?.toString() ?? '';

      /// ----------- BENEFICIARIES -----------
      final rows = await LocalStorageDao.instance.getAllBeneficiaries();

      /// ----------- HOUSEHOLDS -----------
      _households = await LocalStorageDao.instance.getAllHouseholds();

      final households = await db.query(
        'households',
        where: 'is_deleted = 0 AND current_user_key = ?',
        whereArgs: [currentUserKey],
      );

      final Map<String, String> headKeyByHousehold = {};
      for (final hh in households) {
        final hhKey = hh['unique_key']?.toString();
        final headId = hh['head_id']?.toString();
        if (hhKey != null && headId != null) {
          headKeyByHousehold[hhKey] = headId;
        }
      }

      final familyHeads = rows.where((r) {
        final hhKey = r['household_ref_key']?.toString();
        final uniqueKey = r['unique_key']?.toString();

        if (hhKey == null || uniqueKey == null) return false;
        if (r['is_deleted'] == 1 || r['is_migrated'] == 1 || r['is_death'] == 1) {
          return false;
        }

        Map<String, dynamic> info = {};
        try {
          final raw = r['beneficiary_info'];
          if (raw is String && raw.isNotEmpty) {
            info = jsonDecode(raw);
          } else if (raw is Map) {
            info = Map<String, dynamic>.from(raw);
          }
        } catch (_) {}


        if (info['isFamilyhead'] == true) return true;

        return headKeyByHousehold[hhKey] == uniqueKey;
      }).toList();

      /// ----------- MAP TO UI -----------
      final mapped = familyHeads.map((r) {
        final info = r['beneficiary_info'] is String
            ? jsonDecode(r['beneficiary_info'])
            : (r['beneficiary_info'] ?? {});

        final uniqueKey = r['unique_key']?.toString() ?? '';
        final headId = uniqueKey.length > 11
            ? uniqueKey.substring(uniqueKey.length - 11)
            : uniqueKey;

        final tempData = {
          'houseNo': info['houseNo'] ?? 0,
          '_raw': r,
        };

        final houseNumber = _getHouseNumber(tempData, _households);

        return {
          'name': info['headName'] ??
              info['memberName'] ??
              info['name'] ??
              '',
          'mobile': info['mobileNo'] ?? '',
          'hhId': headId,
          'houseNo': houseNumber.isNotEmpty ? houseNumber : 0,
          'mohalla': info['mohalla'] ?? '',
          'mohallaTola': info['mohallaTola'] ?? '',
          '_raw': r,
        };
      }).toList();

      /// ----------- SORT BY CREATED DATE (LATEST FIRST) -----------
      mapped.sort((a, b) {
        final ra = a['_raw'] as Map<String, dynamic>;
        final rb = b['_raw'] as Map<String, dynamic>;

        final dateA = _resolveSortDate(ra);
        final dateB = _resolveSortDate(rb);

        return dateB.compareTo(dateA);
      });

      if (mounted) {
        setState(() {
          _items = mapped;
          _filtered = List<Map<String, dynamic>>.from(mapped);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppHeader(screenTitle: l10n!.familyUpdate, showBack: true),
      drawer: const CustomDrawer(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [

                Expanded(
                  child: _filtered.isEmpty
                      ? Center(
                          child: Text(
                            l10n.noDataFound,
                            style: const TextStyle(
                              color: Colors.black54,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
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
    final Color primary = Theme.of(context).primaryColor;
    final l10n = AppLocalizations.of(context);

    return InkWell(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => HouseHold_BeneficiaryScreen(
              houseNo: data['houseNo']?.toString(),
              hhId: data['_raw']['household_ref_key']?.toString() ?? '',
            ),
          ),
        );

        if (mounted) {
          _loadData();
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 3,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 🔹 Header
            Container(
              decoration: const BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
              ),
              padding: const EdgeInsets.all(6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.home,
                        color: AppColors.primary,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        (data['_raw']['household_ref_key']?.toString().length ??
                                    0) >
                                11
                            ? data['_raw']['household_ref_key']
                                  .toString()
                                  .substring(
                                    data['_raw']['household_ref_key']
                                            .toString()
                                            .length -
                                        11,
                                  )
                            : (data['_raw']['household_ref_key']?.toString() ??
                                  ''),
                        style: TextStyle(
                          color: primary,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: primary.withOpacity(0.95),
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(8),
                ),
              ),
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            data['name'] ?? '',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14.sp,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: _infoRow(
                          "${l10n?.mobileNo} : ",
                          data['mobile']?.toString() ?? l10n!.na,
                          isWrappable: true,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _infoRow(
                          "${l10n?.mohalla} : ",
                          data['mohalla']?.toString() ??
                              data['mohallaTola']?.toString() ??
                              l10n!.na,
                          isWrappable: true,
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

  Widget _infoRow(String? title, String value, {bool isWrappable = false}) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text(
            '$title ',
            style: TextStyle(
              color: AppColors.background,
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? l10n!.na : value,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w400,
                fontSize: 13.sp,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
