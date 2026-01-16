import 'dart:async';
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:medixcel_new/core/config/routes/Route_Name.dart';
import 'package:medixcel_new/core/config/routes/Routes.dart' as AppRoutes;
import 'package:medixcel_new/core/config/themes/CustomColors.dart';
import 'package:sizer/sizer.dart';
import 'package:sqflite/sqflite.dart';

import '../../core/config/Constant/constant.dart';
import '../../core/widgets/AppDrawer/Drawer.dart';
import '../../core/widgets/AppHeader/AppHeader.dart';
import '../../core/widgets/ConfirmationDialogue/ConfirmationDialogue.dart';
import '../../data/Database/User_Info.dart';
import '../../data/Database/local_storage_dao.dart';
import '../../data/Database/database_provider.dart';
import '../../data/Database/tables/followup_form_data_table.dart' as ffd;
import '../../data/SecureStorage/SecureStorage.dart';

import '../../data/models/AbhaCreated/AbhaCreated.dart';
import '../../data/models/ExistingAbhaCreated/ExistingAbhaCreated.dart';
import '../../data/models/TimeStamp/Timestamp_Response.dart';
import '../../data/repositories/AbhaCreated/AbhaCreated.dart';
import '../../data/repositories/ExistingAbha/ExistingAbha.dart';
import '../../data/repositories/TimeStamp/time_stamp.dart';
import '../../data/repositories/AddBeneficiary/BeneficiaryRepository.dart';
import '../../data/sync/sync_service.dart';
import '../../l10n/app_localizations.dart';
import '../ChildCare/child_care_count_provider.dart';
import '../GuestBeneficiarySearch/GuestBeneficiarySearch.dart';
import 'TodaysProgramm.dart';
import 'AshaDashboardSection.dart';
import '../../data/repositories/NotificationRepository/Notification_Repository.dart';
import '../../core/utils/anc_utils.dart';

class HomeScreen extends StatefulWidget {
  final int initialTabIndex;

  const HomeScreen({super.key, this.initialTabIndex = 0});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with RouteAware {
  int selectedIndex = 0;
  int? selectedGridIndex;

  Map<String, List<String>> apiData = {
    "Family Survey List": [],
    "Eligible Couple Due List": [],
    "ANC List": [],
    "HBNC List": [],
    "Routine Immunization (RI)": [],
  };

  int? appRoleId;

  bool isLoading = true;
  int householdCount = 0;
  int beneficiariesCount = 0;
  int eligibleCouplesCount = 0;
  int pregnantWomenCount = 0;
  int ancVisitCount = 0;
  int childRegisteredCount = 0;
  int highRiskCount = 0;
  int notificationCount = 0;
  int ncdCount = 0;

  final ChildCareCountProvider _childCareCountProvider =
      ChildCareCountProvider();
  Timer? _uiRefreshTimer;
  Future<void> _loadUserRoleAndData() async {
    try {
      final userData = await UserInfo.getCurrentUser();
      if (userData == null || userData.isEmpty) {
        setState(() => appRoleId = 0);
        return;
      }

      dynamic details = userData['details'];
      if (details is String) {
        details = jsonDecode(details);
      }

      final roleId = details['app_role_id'];
      final parsedRoleId = int.tryParse(roleId.toString()) ?? 0;

      print("FETCHED APP ROLE ID: $parsedRoleId");

      if (mounted) {
        setState(() {
          appRoleId = parsedRoleId;
        });
      }
    } catch (e) {
      print("Error loading app_role_id: $e");
      if (mounted) setState(() => appRoleId = 0);
    }
  }

  @override
  void initState() {
    super.initState();
    _loadUserRoleAndData();

    selectedIndex = widget.initialTabIndex;
    fetchApiData();
    _loadHouseholdCount();
    _loadBeneficiariesCount();
    _loadEligibleCouplesCount();
    // _loadPregnantWomenCount();
    _loadAncVisitCount();
    _loadChildRegisteredCount();
    _loadHighRiskCount();
    _loadNotificationCount();
    _loadNcdCount();
    _fetchTimeStamp();
    Future.microtask(() async {
      try {
        final alreadyFetched = await SecureStorageService.isAbhaFetched();
        if (!alreadyFetched) {
          await _fetchAbhaCreated();
          await _fetchExistingAbhaCreated();
          await SecureStorageService.setAbhaFetched();
        }
      } catch (_) {}
    });
    SyncService.instance.start(interval: const Duration(minutes: 1));

    Future.delayed(const Duration(seconds: 5), () async {
      if (!mounted) return;
      await _loadHouseholdCount();
      await _loadBeneficiariesCount();
      await _loadEligibleCouplesCount();
      // await _loadPregnantWomenCount();
      await _loadAncVisitCount();
      await _loadChildRegisteredCount();
      await _loadHighRiskCount();
      await _loadNotificationCount();
      await _loadNcdCount();
    });
    _uiRefreshTimer?.cancel();
    _uiRefreshTimer = Timer.periodic(const Duration(minutes: 5), (_) async {
      if (!mounted) return;
      await _loadHouseholdCount();
      await _loadBeneficiariesCount();
      await _loadEligibleCouplesCount();
      // await _loadPregnantWomenCount();
      await _loadAncVisitCount();
      await _loadChildRegisteredCount();
      await _loadHighRiskCount();
      await _loadNotificationCount();
      await _loadNcdCount();
    });
    Future.microtask(() async {
      try {
        //await SyncService.instance.fetchFollowupFormsFromServer();

        if (mounted) {
          _loadHouseholdCount();
          _loadBeneficiariesCount();
          _loadEligibleCouplesCount();
          // _loadPregnantWomenCount();
          _loadAncVisitCount();
          _loadChildRegisteredCount();
          _loadHighRiskCount();
          _loadNotificationCount();
          _loadNcdCount();
        }
      } catch (e) {
        print('HomeScreen: error pulling followup forms on init -> $e');
      }
    });
  }

  @override
  void dispose() {
    _uiRefreshTimer?.cancel();
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      AppRoutes.Routes.routeObserver.unsubscribe(this);
    }
    super.dispose();
  }

  final ExistingAbhaCreatedRepository _repositoryABHA =
      ExistingAbhaCreatedRepository();
  ExistingAbhaCreated? _existingAbhaData;
  Future<void> _fetchExistingAbhaCreated() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    print('📤 Fetching Existing ABHA Created data from HomeScreen...');

    try {
      if (_userUniqueKey == null || _userUniqueKey.isEmpty) {
        throw Exception('User unique key is missing!');
      }
      final response = await _repositoryABHA.existingAbhaCreated(
        _userUniqueKey,
      );

      print('✅ Raw API Response (HomeScreen): ${response.toJson()}');
      print('📊 ABHA Created Count: ${response.data?.abhaCreated}');

      setState(() {
        _existingAbhaData = response;
      });
    } catch (e, stackTrace) {
      print('❌ Error fetching Existing ABHA Created data: $e');
      print('🧩 Stack trace: $stackTrace');

      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  final AbhaCreatedRepository _abhaRepository = AbhaCreatedRepository();
  AbhaCreated? _abhaData;
  bool _isLoading = false;
  String? _error;
  final String _userUniqueKey = '8X0FR8NZSU7';
  final BeneficiaryRepository _benefRepo = BeneficiaryRepository();

  Future<void> _fetchAbhaCreated() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    print('📤 Fetching ABHA Created count from HomeScreen...');

    try {
      final response = await _abhaRepository.getAbhaCreated(_userUniqueKey);
      print('✅ Raw API Response (HomeScreen): ${response.toJson()}');

      setState(() {
        _abhaData = response;
      });
    } catch (e) {
      print('❌ Error fetching ABHA Created data: $e');
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  final TimeStampRepository _repository = TimeStampRepository();
  TimeStampResponce? _timeStamp;
  Future<void> _fetchTimeStamp() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    print('📤 Fetching timestamp from HomeScreen...');

    try {
      final response = await _repository.getTimeStamp();
      print('✅ Raw API Response (HomeScreen): $response');

      final parsed = TimeStampResponce.fromJson(response);
      print('🕒 Server Time: ${parsed.time}');

      if (parsed.time != null) {
        // Parse server time string
        final serverTime = DateTime.parse(parsed.time!);
        final formattedServerTime = DateFormat(
          'dd MMM yyyy, hh:mm a',
        ).format(serverTime);

        final systemTime = DateTime.now();
        final formattedSystemTime = DateFormat(
          'dd MMM yyyy, hh:mm a',
        ).format(systemTime);

        print(' Server Time: $formattedServerTime');
        print(' System Time: $formattedSystemTime');
        final difference = systemTime.difference(serverTime).inSeconds.abs();
        print('Time difference: $difference seconds');
        if (difference > 60) {
          _showTimeMismatchDialog(formattedServerTime, formattedSystemTime);
        }
        setState(() {
          _timeStamp = parsed;
        });
      }
      setState(() {
        _timeStamp = parsed;
      });
    } catch (e) {
      print('Error fetching timestamp: $e');
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showTimeMismatchDialog(String serverTime, String systemTime) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('Time Mismatch Detected'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Your device time does not match the server time.'),
              const SizedBox(height: 8),
              Text('Server Time: $serverTime'),
              Text('System Time: $systemTime'),
              const SizedBox(height: 12),
              const Text(
                'Please correct your device time to match the server time.',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
            ],
          ),
          actions: [
            Center(
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ),
          ],
        );
      },
    );
  }
  Set<String> getFinalHouseholdKeys({
    required List<Map<String, dynamic>> households,
    required List<Map<String, dynamic>> beneficiaries,
  }) {
    /// ---------- MAP HOUSEHOLD -> CONFIGURED HEAD ----------
    final Map<String, String> headKeyByHousehold = {};
    for (final hh in households) {
      final hhKey = (hh['unique_key'] ?? '').toString();
      final headId = (hh['head_id'] ?? '').toString();
      if (hhKey.isNotEmpty && headId.isNotEmpty) {
        headKeyByHousehold[hhKey] = headId;
      }
    }

    /// ---------- FAMILY HEADS FROM BENEFICIARIES ----------
    final Set<String> householdKeysFromBeneficiaries = beneficiaries.where((r) {
      try {
        final householdRefKey = (r['household_ref_key'] ?? '').toString();
        final uniqueKey = (r['unique_key'] ?? '').toString();
        if (householdRefKey.isEmpty || uniqueKey.isEmpty) return false;

        if (r['is_death'] == 1 || r['is_migrated'] == 1) return false;

        final rawInfo = r['beneficiary_info'];
        Map<String, dynamic> info;
        if (rawInfo is Map) {
          info = Map<String, dynamic>.from(rawInfo);
        } else if (rawInfo is String && rawInfo.isNotEmpty) {
          info = Map<String, dynamic>.from(jsonDecode(rawInfo));
        } else {
          info = {};
        }

        final configuredHeadKey = headKeyByHousehold[householdRefKey];
        final bool isConfiguredHead =
            configuredHeadKey != null && configuredHeadKey == uniqueKey;

        final relation =
        (info['relation_to_head'] ?? info['relation'] ?? '')
            .toString()
            .toLowerCase();

        final bool isHeadByRelation =
            relation == 'head' || relation == 'self';

        final bool isFamilyHead =
            info['isFamilyHead'] == true ||
                info['isFamilyHead']?.toString().toLowerCase() == 'true';

        return isConfiguredHead || isHeadByRelation || isFamilyHead;
      } catch (_) {
        return false;
      }
    }).map((r) {
      return (r['household_ref_key'] ?? '').toString();
    }).where((k) => k.isNotEmpty).toSet();

    /// ---------- FALLBACK HOUSEHOLDS (EXACT SAME AS _loadData) ----------
    final Set<String> householdKeysWithBeneficiaries = beneficiaries
        .map((e) => (e['household_ref_key'] ?? '').toString())
        .where((k) => k.isNotEmpty)
        .toSet();

    final Set<String> fallbackHouseholdKeys = {};

    for (final hh in households) {
      final hhRefKey = (hh['unique_key'] ?? '').toString();
      if (hhRefKey.isEmpty) continue;

      if (householdKeysWithBeneficiaries.contains(hhRefKey)) continue;

      Map<String, dynamic> hhInfo = {};
      final raw = hh['household_info'];

      if (raw is Map) {
        hhInfo = Map<String, dynamic>.from(raw);
      } else if (raw is String && raw.isNotEmpty) {
        try {
          hhInfo = Map<String, dynamic>.from(jsonDecode(raw));
        } catch (_) {}
      }

      final headRaw = hhInfo['family_head_details'];
      Map<String, dynamic> headInfo = {};

      if (headRaw is Map) {
        headInfo = Map<String, dynamic>.from(headRaw);
      } else if (headRaw is String && headRaw.isNotEmpty) {
        try {
          headInfo = Map<String, dynamic>.from(jsonDecode(headRaw));
        } catch (_) {}
      }

      final bool isHead =
          headInfo['isFamilyHead'] == true ||
              headInfo['isFamilyHead']?.toString().toLowerCase() == 'true' ||
              headInfo['isFamilyhead'] == true ||
              headInfo['isFamilyhead']?.toString().toLowerCase() == 'true';

      if (isHead) {
        fallbackHouseholdKeys.add(hhRefKey);
      }
    }

    /// ---------- FINAL EXACT MATCH ----------
    return {
      ...householdKeysFromBeneficiaries,
      ...fallbackHouseholdKeys,
    };
  }

  Future<void> _loadHouseholdCount() async {
    householdCount = 0;

    try {
      final currentUserData = await SecureStorageService.getCurrentUserData();
      final currentUserKey = currentUserData?['unique_key']?.toString() ?? '';

      if (currentUserKey.isEmpty) {
        if (mounted) {
          setState(() {
            householdCount = 0;
            Constant.householdTotal = 0;
            Constant.householdTotalSync = 0;
          });
        }
        return;
      }

      final db = await DatabaseProvider.instance.database;

      final beneficiaries = await LocalStorageDao.instance
          .getAllBeneficiaries();

      final households = await db.query(
        'households',
        where: 'is_deleted = 0 AND current_user_key = ?',
        whereArgs: [currentUserKey],
      );

     /* final finalHouseholdKeys = getFinalHouseholdKeys(
        households: households,
        beneficiaries: beneficiaries,
      );*/

       Set<String> unique_key = {};

      for (final hh in households) {
        final hhRefKey = (hh['unique_key'] ?? '').toString();
        if (hhRefKey.isEmpty) continue;
        unique_key.add(hhRefKey);
      }

      final finalHouseholdKeys = unique_key;


      /// ---------- MAP HOUSEHOLD -> CONFIGURED HEAD ----------
      final Map<String, String> headKeyByHousehold = {};
      for (final hh in households) {
        final hhKey = (hh['unique_key'] ?? '').toString();
        final headId = (hh['head_id'] ?? '').toString();
        if (hhKey.isNotEmpty && headId.isNotEmpty) {
          headKeyByHousehold[hhKey] = headId;
        }
      }

      /// ---------- FAMILY HEAD FROM BENEFICIARIES ----------
      // final Set<String> householdKeysFromBeneficiaries = beneficiaries
      //     .where((r) {
      //       try {
      //         final householdRefKey = (r['household_ref_key'] ?? '').toString();
      //         final uniqueKey = (r['unique_key'] ?? '').toString();
      //         if (householdRefKey.isEmpty || uniqueKey.isEmpty) return false;
      //
      //         if (r['is_death'] == 1 || r['is_migrated'] == 1) return false;
      //
      //         final rawInfo = r['beneficiary_info'];
      //         Map<String, dynamic> info;
      //         if (rawInfo is Map) {
      //           info = Map<String, dynamic>.from(rawInfo);
      //         } else if (rawInfo is String && rawInfo.isNotEmpty) {
      //           info = Map<String, dynamic>.from(jsonDecode(rawInfo));
      //         } else {
      //           info = {};
      //         }
      //
      //         final configuredHeadKey = headKeyByHousehold[householdRefKey];
      //
      //         final bool isConfiguredHead =
      //             configuredHeadKey != null && configuredHeadKey == uniqueKey;
      //
      //         final relation =
      //             (info['relation_to_head'] ?? info['relation'] ?? '')
      //                 .toString()
      //                 .toLowerCase();
      //
      //         final bool isHeadByRelation =
      //             relation == 'head' || relation == 'self';
      //
      //         final bool isFamilyHead =
      //             info['isFamilyHead'] == true ||
      //             info['isFamilyHead']?.toString().toLowerCase() == 'true';
      //
      //         return isConfiguredHead || isHeadByRelation || isFamilyHead;
      //       } catch (_) {
      //         return false;
      //       }
      //     })
      //     .map((r) {
      //       return (r['household_ref_key'] ?? '').toString();
      //     })
      //     .where((k) => k.isNotEmpty)
      //     .toSet();

      /// ---------- FALLBACK HOUSEHOLDS (SAME AS _loadData) ----------
      final Set<String> householdKeysWithBeneficiaries = beneficiaries
          .map((e) => (e['household_ref_key'] ?? '').toString())
          .where((k) => k.isNotEmpty)
          .toSet();

      final Set<String> fallbackHouseholdKeys = {};

      for (final hh in households) {
        final hhRefKey = (hh['unique_key'] ?? '').toString();
        if (hhRefKey.isEmpty) continue;

        // Already counted via beneficiaries
        if (householdKeysWithBeneficiaries.contains(hhRefKey)) continue;

        Map<String, dynamic> hhInfo = {};
        final raw = hh['household_info'];

        if (raw is Map) {
          hhInfo = Map<String, dynamic>.from(raw);
        } else if (raw is String && raw.isNotEmpty) {
          try {
            hhInfo = Map<String, dynamic>.from(jsonDecode(raw));
          } catch (_) {}
        }

        final headRaw = hhInfo['family_head_details'];
        Map<String, dynamic> headInfo = {};

        if (headRaw is Map) {
          headInfo = Map<String, dynamic>.from(headRaw);
        } else if (headRaw is String && headRaw.isNotEmpty) {
          try {
            headInfo = Map<String, dynamic>.from(jsonDecode(headRaw));
          } catch (_) {}
        }

        final bool isHead =
            headInfo['isFamilyHead'] == true ||
            headInfo['isFamilyHead']?.toString().toLowerCase() == 'true' ||
            headInfo['isFamilyhead'] == true ||
            headInfo['isFamilyhead']?.toString().toLowerCase() == 'true';

        if (isHead) {
          fallbackHouseholdKeys.add(hhRefKey);
        }
      }

      /// ---------- FINAL HOUSEHOLD SET ----------


      /// ---------- SYNC COUNT ----------
      final Map<String, Map<String, dynamic>> householdByKey = {};
      for (final hh in households) {
        final k = (hh['unique_key'] ?? '').toString();
        if (k.isNotEmpty) householdByKey[k] = hh;
      }

      int syncedCount = 0;
      for (final k in finalHouseholdKeys) {
        final hh = householdByKey[k];
        if (hh == null) continue;
        final s = hh['is_synced'];
        if (s == 1 || s == '1') syncedCount++;
      }

      if (mounted) {
        setState(() {
          householdCount = finalHouseholdKeys.length;
          Constant.householdTotal = householdCount;
          Constant.householdTotalSync = syncedCount;
        });
      }

      print('✅ FINAL household count (exact match): $householdCount');
    } catch (e) {
      print('❌ Error loading household count: $e');
      if (mounted) {
        setState(() {
          householdCount = 0;
          Constant.householdTotal = 0;
          Constant.householdTotalSync = 0;
        });
      }
    }
  }

  Future<void> _loadBeneficiariesCount() async {
    try {
      final rows = await LocalStorageDao.instance.getAllBeneficiaries(
        isMigrated: 0,
      );
      final count = rows.length;
      if (mounted) {
        setState(() {
          beneficiariesCount = count;
        });
      }
    } catch (e) {
      print('Error loading beneficiaries count: $e');
      if (mounted) {
        setState(() {
          beneficiariesCount = 0;
        });
      }
    }
  }

  Future<void> _loadEligibleCouplesCount() async {
    try {
      final db = await DatabaseProvider.instance.database;
      final currentUserData = await SecureStorageService.getCurrentUserData();
      final String? ashaUniqueKey = currentUserData?['unique_key']?.toString();

      if (ashaUniqueKey == null || ashaUniqueKey.isEmpty) {
        print('Error: Current user key not found');
        if (mounted) {
          setState(() {
            eligibleCouplesCount = 0;
          });
        }
        return;
      }

      final query = '''
        SELECT DISTINCT b.*, e.eligible_couple_state, 
               e.created_date_time as registration_date
        FROM beneficiaries_new b
        INNER JOIN eligible_couple_activities e ON b.unique_key = e.beneficiary_ref_key
        WHERE b.is_deleted = 0 
          AND (b.is_migrated = 0 OR b.is_migrated IS NULL)
          AND e.eligible_couple_state = 'eligible_couple'
          AND e.is_deleted = 0
          AND b.is_death = 0
          AND e.current_user_key = ?
      ''';

      final rows = await db.rawQuery(query, [ashaUniqueKey]);

      int count = 0;
      for (final row in rows) {
        try {
          final beneficiaryInfo = row['beneficiary_info']?.toString() ?? '{}';
          final Map<String, dynamic> info = beneficiaryInfo.isNotEmpty
              ? Map<String, dynamic>.from(jsonDecode(beneficiaryInfo))
              : <String, dynamic>{};

          final memberType = info['memberType']?.toString().toLowerCase() ?? '';
          if (memberType != 'child') {
            count++;
          }
        } catch (_) {
          count++;
        }
      }

      if (mounted) {
        setState(() {
          eligibleCouplesCount = count;
        });
      }
    } catch (e) {
      print('Error loading eligible couples count: $e');
      if (mounted) {
        setState(() {
          eligibleCouplesCount = 0;
        });
      }
    }
  }


  int _calculateEcAge(dynamic dobRaw) {
    if (dobRaw == null || dobRaw.toString().isEmpty) return 0;
    try {
      final dob = DateTime.tryParse(dobRaw.toString());
      if (dob == null) return 0;
      return DateTime.now().difference(dob).inDays ~/ 365;
    } catch (_) {
      return 0;
    }
  }


  Future<bool> _hasSterilizationRecord(
    Database db,
    String beneficiaryKey,
    String ashaUniqueKey,
  ) async {
    final rows = await db.query(
      ffd.FollowupFormDataTable.table,
      where: '''
      beneficiary_ref_key = ?
      AND current_user_key = ?
      AND is_deleted = 0
      AND forms_ref_key = ?
    ''',
      whereArgs: [
        beneficiaryKey,
        ashaUniqueKey,
        ffd.FollowupFormDataTable.formUniqueKeys[ffd
            .FollowupFormDataTable
            .eligibleCoupleTrackingDue],
      ],
    );

    for (final row in rows) {
      try {
        final formJsonStr = row['form_json']?.toString();
        if (formJsonStr == null || formJsonStr.isEmpty) continue;

        final Map<String, dynamic> formJson = Map<String, dynamic>.from(
          jsonDecode(formJsonStr),
        );

        final trackingDue = formJson['eligible_couple_tracking_due_from'];

        if (trackingDue is Map<String, dynamic>) {
          final method = trackingDue['method_of_contraception']
              ?.toString()
              .toLowerCase();

          if ((method == 'female_sterilization' ||
              method == 'male_sterilization' ||
              method == 'male sterilization' ||
              method == 'female sterilization')) {
            return true;
          }
        }
      } catch (_) {
        continue;
      }
    }

    return false;
  }

  Future<void> _loadAncVisitCount() async {
    try {
      /* final count = await ANCUtils.getMotherCareTotalCount();
      final countSync = await ANCUtils.getMotherCareSyncedTotalCount();*/
      await ANCUtils.loadPregnantWomen();
      if (mounted) {
        setState(() {
          ancVisitCount = Constant.motherCareTotal;
          /*Constant.motherCareTotal = count;
          Constant.motherCareSynced = countSync;*/
        });
      }
    } catch (e) {
      print('Error loading ANC visit count: $e');
    }
  }

  Future<void> _loadChildRegisteredCount() async {
    try {
      final result = await _childCareCountProvider
          .getRegisteredChildCountTotalAndSync();
      final total = result['total']!;
      final synced = result['synced']!;
      if (mounted) {
        setState(() {
          childRegisteredCount = total;
          Constant.childRegisteredtotal = total;
          Constant.childRegisteredtotalSync = synced;
        });
      }
    } catch (e) {
      print('Error loading registered child beneficiary count: $e');
    }
  }

  Future<void> _loadHighRiskCount() async {
    try {
      final dbForms = await LocalStorageDao.instance.getHighRiskANCVisits();
      if (mounted) {
        setState(() {
          highRiskCount = dbForms.length;
        });
      }
    } catch (e) {
      print('Error loading high-risk ANC visit count: $e');
    }
  }

  Future<void> _loadNcdCount() async {
    try {
      final db = await DatabaseProvider.instance.database;

      final currentUserData = await SecureStorageService.getCurrentUserData();
      String? ashaUniqueKey = currentUserData?['unique_key']?.toString();

      if (ashaUniqueKey == null || ashaUniqueKey.isEmpty) {
        debugPrint(
          'Error: ASHA Unique Key is missing. Cannot load NCD forms count.',
        );
        if (mounted) {
          setState(() {
            ncdCount = 0;
          });
        }
        return;
      }

      final List<Map<String, dynamic>> result = await db.query(
        ffd.FollowupFormDataTable.table,
        // 3. Add mandatory current_user_key condition
        where: 'forms_ref_key = ? AND current_user_key = ?',
        whereArgs: [
          ffd.FollowupFormDataTable.formUniqueKeys[ffd
              .FollowupFormDataTable
              .cbac],
          ashaUniqueKey,
        ],
      );

      if (mounted) {
        setState(() {
          ncdCount = result.length;
        });
      }
    } catch (e) {
      debugPrint('Error loading NCD forms count: $e');
    }
  }

  Future<void> _loadNotificationCount() async {
    try {
      // Keep HomeScreen notification badge in sync with the
      // Notifications screen: first fetch from server and
      // save to local DB, then read the list and count.
      try {
        await NotificationRepository().fetchAndSaveNotifications();
      } catch (e) {
        print('HomeScreen: error while fetching notifications -> $e');
      }

      final notifications = await LocalStorageDao.instance.getNotifications();
      if (mounted) {
        setState(() {
          notificationCount = notifications.length;
        });
      }
    } catch (e) {
      print('Error loading notification count: $e');
    }
  }

  Future<void> fetchApiData() async {
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      apiData = {
        l10n.listFamilySurvey: ["Family 1", "Family 2", "Family 3"],
        l10n.listEligibleCoupleDue: ["Couple 1", "Couple 2"],
        l10n.listANC: ["ANC 1", "ANC 2", "ANC 3", "ANC 4"],
        l10n.listHBNC: ["HBNC 1", "HBNC 2"],
        l10n.listRoutineImmunization: ["Child 1", "Child 2", "Child 3"],
      };
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return WillPopScope(
      onWillPop: () async {
        final shouldExit = await showConfirmationDialog(
          context: context,
          title: l10n.exitAppTitle,
          message: l10n.exitAppMessage,
          noButtonColor: AppColors.primary,
          yesButtonColor: AppColors.primary,
          yesText: l10n.yes,
          noText: l10n.no,
        );

        ///
        return shouldExit ?? false;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppHeader(
          screenTitle: l10n.homeTitle,
          showBack: false,
          icon1Image: 'assets/images/search.png',
          onIcon1Tap: () =>
              Navigator.pushNamed(context, Route_Names.GuestBeneficiarySearch),
          icon2Widget: Stack(
            clipBehavior: Clip.none,
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 12.0),
                child: Image.asset(
                  'assets/images/img_1.png',
                  height:
                      MediaQuery.of(context).orientation ==
                          Orientation.landscape
                      ? 5.h
                      : 2.7.h,
                  width:
                      MediaQuery.of(context).orientation ==
                          Orientation.landscape
                      ? 5.h
                      : 2.7.h,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
              if (notificationCount > 0)
                Positioned(
                  right: 6,
                  top: -4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Center(
                      child: Text(
                        notificationCount.toString(),
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          onIcon2Tap: () =>
              Navigator.pushNamed(context, Route_Names.notificationScreen),
          icon3Image: 'assets/images/home.png',
          onIcon3Tap: () => Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => HomeScreen(initialTabIndex: 1),
            ),
          ),
        ),
        drawer: CustomDrawer(
          onSyncCompleted: () async {
            await _loadHouseholdCount();
            await _loadBeneficiariesCount();
            await _loadEligibleCouplesCount();
            // await _loadPregnantWomenCount();
            await _loadAncVisitCount();
            await _loadChildRegisteredCount();
            await _loadHighRiskCount();
            await _loadNotificationCount();
            await _loadNcdCount();
          },
        ),
        body: Stack(
          children: [
            Positioned(
              bottom: 0,
              right: 0,
              child: Image.asset(
                'assets/images/sakhi-bg.jpg',
                width: 25.h,
                fit: BoxFit.cover,
                opacity: AlwaysStoppedAnimation(0.1),
              ),
            ),
            Column(
              children: [
                // Tabs
                Material(
                  color: AppColors.background,
                  elevation: 2,
                  borderRadius: BorderRadius.circular(8),
                  child: Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => setState(() => selectedIndex = 0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.today, color: AppColors.primary),
                                    const SizedBox(width: 8),
                                    Text(
                                      l10n.tabTodaysProgram,
                                      style: TextStyle(
                                        fontSize: 15.sp,
                                        color: selectedIndex == 0
                                            ? AppColors.primary
                                            : AppColors.outline,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                height: 3,
                                color: selectedIndex == 0
                                    ? AppColors.primary
                                    : Colors.transparent,
                              ),
                            ],
                          ),
                        ),
                      ),
                      Container(width: 1, height: 50, color: AppColors.divider),
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            setState(() => selectedIndex = 1);
                            await _loadBeneficiariesCount();
                          },
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.apps_sharp,
                                      color: AppColors.primary,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      l10n.tabAshaDashboard,
                                      style: TextStyle(
                                        fontSize: 15.sp,
                                        color: selectedIndex == 1
                                            ? AppColors.primary
                                            : AppColors.outline,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                height: 3,
                                color: selectedIndex == 1
                                    ? AppColors.primary
                                    : Colors.transparent,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                Expanded(
                  child: selectedIndex == 0
                      ? isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : SingleChildScrollView(
                                child: TodayProgramSection(
                                  selectedGridIndex: selectedGridIndex,
                                  onGridTap: (index) =>
                                      setState(() => selectedGridIndex = index),
                                  apiData: apiData,
                                ),
                              )
                      : SingleChildScrollView(
                          child: AshaDashboardSection(
                            householdCount: householdCount,
                            beneficiariesCount: beneficiariesCount,
                            eligibleCouplesCount: eligibleCouplesCount,
                            pregnantWomenCount: pregnantWomenCount,
                            ancVisitCount: ancVisitCount,
                            childRegisteredCount: childRegisteredCount,
                            highRiskCount: highRiskCount,
                            ncdCount: ncdCount,
                            selectedGridIndex: selectedGridIndex,
                            onGridTap: (index) =>
                                setState(() => selectedGridIndex = index),
                            appRoleId: appRoleId ?? 0,
                            mainGridActions: [
                              null,
                              null,
                              null,
                              null,
                              null,
                              null,
                              null,
                              () async {
                                final result = await Navigator.pushNamed(
                                  context,
                                  Route_Names.Mothercarehomescreen,
                                );
                                if (!mounted) return;
                                if (result is int) {
                                  setState(() {
                                    ancVisitCount = result;
                                  });
                                } else if (result == true) {
                                  await _loadAncVisitCount();
                                } else {
                                  await _loadAncVisitCount();
                                }
                              },
                            ],
                          ),
                        ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      AppRoutes.Routes.routeObserver.subscribe(this, route);
    }
  }

  @override
  void didPopNext() {
    _loadHouseholdCount();
    _loadBeneficiariesCount();
    _loadEligibleCouplesCount();
    // _loadPregnant/WomenCount();
    _loadAncVisitCount();
    _loadChildRegisteredCount();
    _loadHighRiskCount();
    _loadNotificationCount();
    _loadNcdCount();
  }
}
