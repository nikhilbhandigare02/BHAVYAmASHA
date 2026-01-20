import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:medixcel_new/core/widgets/AppDrawer/Drawer.dart';
import 'package:medixcel_new/core/widgets/AppHeader/AppHeader.dart';
import 'package:medixcel_new/data/Database/database_provider.dart';
import 'package:sizer/sizer.dart';

import '../../../data/Database/tables/followup_form_data_table.dart';
import '../../../l10n/app_localizations.dart';

class PreviousVisitsScreen extends StatefulWidget {
  final String beneficiaryRefKey;

  const PreviousVisitsScreen({super.key, required this.beneficiaryRefKey});

  @override
  State<PreviousVisitsScreen> createState() => _PreviousVisitsScreenState();
}

class _PreviousVisitsScreenState extends State<PreviousVisitsScreen> {
  List<Map<String, dynamic>> _visits = [];
  bool _isLoading = true;
  String _errorMessage = '';
  final Set<int> _expanded = {};
  late final l10n = AppLocalizations.of(context);

  late final Map<String, String> fpMethodMap = {
    "antra_injection": l10n?.atraInjection ?? "Antra Injection",
    "copper_t": l10n?.copperT  ?? "Copper - T (IUCD)",
    "condom": l10n?.condom ?? "Condom",
    "mala_n_daily": l10n?.malaN ?? "Mala - N(Daily contraceptive pill)",
    "chhaya_weekly": l10n?.chhaya ?? "Chhaya(Weekly contraceptive pill)",
    "ecp": l10n?.ecp ?? "ECP(Emergency Contraceptive Pill)",
    "male_sterilization": l10n?.maleSterilization ?? "Male Sterilization",
    "female_sterilization": l10n?.femaleSterilization ?? "Female Sterilization",
    "any_other_specify": l10n?.anyOtherSpecifyy ?? "Any Other Specify",
  };

  @override
  void initState() {
    super.initState();
    _initializeDatabaseAndLoadVisits();
  }

  Future<void> _initializeDatabaseAndLoadVisits() async {
    try {
      final db = await DatabaseProvider.instance.database;
      _loadVisits();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to initialize database: $e';
      });
    }
  }

  Future<void> _loadVisits() async {
    try {
      final db = await DatabaseProvider.instance.database;

      // First, check if the table exists
      final tables = await db.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name='followup_form_data'");

      if (tables.isEmpty) {
        throw Exception('followup_form_data table does not exist');
      }

      final formsRefKey = FollowupFormDataTable.formUniqueKeys[
      FollowupFormDataTable.eligibleCoupleTrackingDue] ??
          '';
      final visits = await db.query(
        FollowupFormDataTable.table,
        where:
        'beneficiary_ref_key = ? AND forms_ref_key = ? AND is_deleted = 0',
        whereArgs: [widget.beneficiaryRefKey, formsRefKey],
        orderBy: 'created_date_time ASC',
      );

      final parsedVisits = visits.map((visit) {
        try {
          final formJson = jsonDecode(visit['form_json'] as String? ?? '{}');

          return {
            ...visit,
            'form_data': formJson is Map ? formJson : {},
            'created_date_time':
            visit['created_date_time'] ?? visit['created_at']
          };
        } catch (e, stackTrace) {
          print('Error parsing form data: $e');
          print('Stack trace: $stackTrace');
          return {
            ...visit,
            'form_type': 'Unknown',
            'form_data': {},
            'error': 'Failed to parse form data: $e'
          };
        }
      }).toList();

      if (mounted) {
        setState(() {
          _visits = parsedVisits;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Error loading visits: $e';
        });
      }
    }
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'N/A';
    try {
      final date = DateTime.tryParse(dateString);
      return date != null
          ? '${_twoDigits(date.day)}-${_twoDigits(date.month)}-${date.year}'
          : dateString;
    } catch (e) {
      return dateString;
    }
  }

  String _twoDigits(int n) => n.toString().padLeft(2, '0');

  // Helper method to format the value for display
  String _formatValue(dynamic value) {
    if (value == null) return 'N/A';
    if (value is String) return value.isNotEmpty ? value : 'N/A';
    if (value is Map || value is List) return jsonEncode(value);
    return value.toString();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppHeader(
        screenTitle: l10n?.previousVisits ?? 'Previous Visits',
        showBack: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
          ? Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            _errorMessage,
            style: const TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
        ),
      )
          : Column(
        children: [
          // Table Header
          Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 3,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Sr No.',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 6,
                    child: Text(
                      'Visit Date',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Visit List
          Expanded(
            child: _visits.isEmpty
                ? Center(
              child: Text(
                l10n?.noPreviousVisits ??
                    'No previous visits found',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _visits.length,
              itemBuilder: (context, index) {
                final visit = _visits[index];
                final formData = visit['form_data'] is Map
                    ? visit['form_data'] as Map<String, dynamic>
                    : <String, dynamic>{};

                // Extract inner form_data
                final formValues = formData['form_data'] is Map
                    ? formData['form_data']
                as Map<String, dynamic>
                    : <String, dynamic>{};

                // Extract basic info
                final visitDate =
                _formatDate(visit['created_date_time']);
                final serialNumber = (index + 1).toString();

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.2),
                        spreadRadius: 1,
                        blurRadius: 3,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Theme(
                    data: Theme.of(context).copyWith(
                      dividerColor: Colors.transparent,
                    ),
                    child: ExpansionTile(
                      tilePadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 4),
                      childrenPadding: const EdgeInsets.all(0),
                      onExpansionChanged: (open) {
                        setState(() {
                          if (open) {
                            _expanded.add(index);
                          } else {
                            _expanded.remove(index);
                          }
                        });
                      },
                      title: Row(
                        children: [
                          // Ensure alignment under header
                          Expanded(
                            flex: 1,
                            child: Text(
                              serialNumber,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: _expanded.contains(index)
                                    ? Colors.blue
                                    : Colors.black,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              visitDate,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: _expanded.contains(index)
                                    ? Colors.blue
                                    : Colors.black,
                              ),
                            ),
                          ),
                        ],
                      ),
                      trailing: const Icon(
                        Icons.keyboard_arrow_down,
                        color: Colors.grey,
                      ),
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: const BoxDecoration(
                            color: Color(0xFF5B9BD5),
                            borderRadius: BorderRadius.only(
                              bottomLeft: Radius.circular(8),
                              bottomRight: Radius.circular(8),
                            ),
                          ),
                          child: Builder(builder: (context) {
                            final alt = formData[
                            'eligible_couple_tracking_due_from']
                            is Map
                                ? formData[
                            'eligible_couple_tracking_due_from']
                            as Map<String, dynamic>
                                : <String, dynamic>{};

                            final fpAdoptingRaw =
                                formValues['fp_adopting'] ??
                                    alt['is_family_planning'];
                            bool fpAdopting = (fpAdoptingRaw ==
                                true) ||
                                (fpAdoptingRaw
                                    ?.toString()
                                    .toLowerCase() ==
                                    'true') ||
                                (fpAdoptingRaw
                                    ?.toString()
                                    .toLowerCase() ==
                                    'yes') ||
                                (fpAdoptingRaw?.toString() ==
                                    '1');

                            final methodRaw =
                                formValues['fp_method'] ??
                                    alt['method_of_contraception'];

                            final hasMethod = methodRaw != null &&
                                methodRaw
                                    .toString()
                                    .trim()
                                    .isNotEmpty;

                            if (!fpAdopting && hasMethod) {
                              fpAdopting = true;
                            }

                            final familyPlanningValue =
                            fpAdopting ? 'Yes' : 'No';

                            // --- Updated Logic for methodValue ---
                            String methodValue;
                            if (fpAdopting) {
                              if (methodRaw == null ||
                                  (methodRaw is String &&
                                      methodRaw
                                          .toString()
                                          .isEmpty)) {
                                methodValue = 'Not Available';
                              } else {
                                // Check if the raw value exists in our map
                                final key = methodRaw.toString();
                                // Use the local map 'fpMethodMap' instead of _fpMethodMap
                                if (fpMethodMap
                                    .containsKey(key)) {
                                  methodValue = fpMethodMap[key]!;
                                } else {
                                  // Fallback to raw value
                                  methodValue =
                                      _formatValue(methodRaw);
                                }
                              }
                            } else {
                              methodValue = 'Not Available';
                            }
                            // -------------------------------------

                            return Row(
                              children: [
                                Expanded(
                                  flex: 1,
                                  child: Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Family planning',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight:
                                          FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        familyPlanningValue,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  flex: 1,
                                  child: Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Method Of Contraception',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight:
                                          FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        methodValue,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          }),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
