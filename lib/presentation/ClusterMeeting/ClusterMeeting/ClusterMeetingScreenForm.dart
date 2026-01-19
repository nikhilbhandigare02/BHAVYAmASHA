import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/config/themes/CustomColors.dart';
import '../../../core/utils/device_info_utils.dart';
import '../../../core/utils/id_generator_utils.dart';
import '../../../core/widgets/AppHeader/AppHeader.dart';
import '../../../core/widgets/DatePicker/DatePicker.dart';
import '../../../core/widgets/Dropdown/Dropdown.dart';
import '../../../core/widgets/SnackBar/app_snackbar.dart';
import '../../../core/widgets/TextField/TextField.dart';
import '../../../data/Database/local_storage_dao.dart';

import '../../../data/SecureStorage/SecureStorage.dart';
import '../../../l10n/app_localizations.dart';
import 'ClusterMeetingScreen.dart';

class DiscussionTopic {
  final int id;
  final String name;

  const DiscussionTopic({required this.id, required this.name});
}

class Day {
  final int id;
  final String name;

  const Day({required this.id, required this.name});
}

class ClusterMeetingScreenForm extends StatefulWidget {
  final String? uniqueKey;
  final bool isEditMode;

  const ClusterMeetingScreenForm({
    super.key,
    this.uniqueKey,
    this.isEditMode = false,
  });

  @override
  State<ClusterMeetingScreenForm> createState() =>
      _ClusterMeetingScreenFormState();
}

class _ClusterMeetingScreenFormState extends State<ClusterMeetingScreenForm> {
  List<dynamic> _ashaList = [];
  List<bool> _presentList = [];

  int get presentCount =>
      _presentList
          .where((e) => e == true)
          .length;

  int get absentCount =>
      _presentList
          .where((e) => e == false)
          .length;
  int _ashaPresentCount = 0;
  int _ashaAbsentCount = 0;

  List<TableRow> _buildAshaRows() {
    return List.generate(_ashaList.length, (index) {
      final item = _ashaList[index];
      final name = item['asha_name']?.toString() ?? '—';

      return TableRow(
        children: [
          _tableCell((index + 1).toString()),
          _tableCell(name),
          _checkBoxCell(index),
        ],
      );
    });
  }

  String format24Hour(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Widget _tableHeaderCell(String text) {
    return Container(
      alignment: Alignment.center,
      padding: EdgeInsets.symmetric(
        vertical: 2,
        horizontal: 2,
      ), // very small space
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
      ),
    );
  }

  Widget _tableCell(String text) {
    return Container(
      width: double.infinity, // makes full cell width available
      alignment: Alignment.center, // centers text horizontally & vertically
      padding: EdgeInsets.symmetric(vertical: 7, horizontal: 2),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
      ),
    );
  }

  Widget _checkBoxCell(int index) {
    final bool value = index < _presentList.length
        ? _presentList[index]
        : false;

    return Container(
      alignment: Alignment.center,
      padding: EdgeInsets.zero, // remove inner spacing
      child: Checkbox(
        materialTapTargetSize:
        MaterialTapTargetSize.shrinkWrap,
        // small checkbox
        visualDensity: VisualDensity.compact,
        // reduce padding around checkbox
        value: value,

        fillColor: MaterialStateProperty.resolveWith<Color>((states) {
          if (states.contains(MaterialState.selected)) {
            return Colors.blue.shade200; // checked background
          }
          return Colors.black; // unchecked background
        }),

        // ✔ Tick color
        checkColor: Colors.black,

        // ⬛ Border (important)
        side: const BorderSide(color: Colors.grey, width: 1.5),
        onChanged: (val) {
          setState(() {
            if (index < _presentList.length) {
              _presentList[index] = val ?? false;
            }
          });
        },
      ),
    );
  }

  int _ashaCount = 0;
  int clusterMeetingsCount = 0;
  Set<String> _selectedTopics = {};
  List<DiscussionTopic> discussionTopics = [
    // const DiscussionTopic(id: 1, name: "Immunization"),
    // const DiscussionTopic(id: 2, name: "Pregnant Women"),
    // const DiscussionTopic(id: 3, name: "Deliveries"),
    // const DiscussionTopic(id: 4, name: "PNC (Post Natal Care)"),
    // const DiscussionTopic(id: 5, name: "Maternal & Child Health"),
    // const DiscussionTopic(id: 6, name: "Home Visit"),
    // const DiscussionTopic(id: 7, name: "New Born Care"),
    // const DiscussionTopic(id: 8, name: "Deaths"),
    // const DiscussionTopic(id: 9, name: "Adolescent Health"),
    // const DiscussionTopic(id: 10, name: "Family Planning"),
    // const DiscussionTopic(id: 11, name: "Other Public Health Program"),
    // const DiscussionTopic(id: 12, name: "Administrative"),
    // const DiscussionTopic(id: 13, name: "Training and Support"),
    // const DiscussionTopic(id: 14, name: "Other"),
  ];

  // Add this variable in your state
  DiscussionTopic? selectedTopic;
  final _phcNameController = TextEditingController();
  final _subcenterNameController = TextEditingController();
  final _ashaFacilitatorNameController = TextEditingController();
  final _ashaInchargeNameController = TextEditingController();
  final _awwNameController = TextEditingController();
  final _awcNumberController = TextEditingController();
  final _villageNameController = TextEditingController();
  final _wardNameController = TextEditingController();
  final _wardNumberController = TextEditingController();
  final _blockNameController = TextEditingController();
  final _decisionTakenController = TextEditingController();
  final _otherTopicController = TextEditingController();
  bool _showOtherTopicField = false;
  Day? selectedDay;
  DateTime? _meetingDate;
  TimeOfDay? _fromTime;
  TimeOfDay? _toTime;
  DateTime? _selectedMonthYear;

  Future<void> _selectMonthYear(BuildContext context) async {
    int selectedMonth = _selectedMonthYear?.month ?? DateTime
        .now()
        .month;
    int selectedYear = _selectedMonthYear?.year ?? DateTime
        .now()
        .year;
    final l10n = AppLocalizations.of(context);
    final currentYear = DateTime
        .now()
        .year;
    // Month Column index
    int monthIndex = selectedMonth - 1;

    // Year Column index
    int yearIndex = currentYear - selectedYear;
    final monthController = FixedExtentScrollController(
      initialItem: monthIndex,
    );
    final yearController = FixedExtentScrollController(initialItem: yearIndex);

    await showDialog(
      context: context,
      builder: (context) =>
          AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            title: Text(
              l10n?.selectMonthYear ?? "Select Month & Year",
              textAlign: TextAlign.center,
            ),
            content: SizedBox(
              width: 280,
              height: 240,
              child: Row(
                children: [
                  // Month Column (1 to 12)
                  Expanded(
                    child: ListWheelScrollView.useDelegate(
                      itemExtent: 50,
                      controller: monthController,
                      perspective: 0.005,
                      diameterRatio: 1.8,
                      physics: const FixedExtentScrollPhysics(),
                      onSelectedItemChanged: (index) =>
                      selectedMonth = index + 1,
                      childDelegate: ListWheelChildBuilderDelegate(
                        childCount: 12,
                        builder: (context, index) {
                          final month = (index + 1).toString().padLeft(2, '0');
                          return Center(
                            child: Text(
                              month,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      "-",
                      style: TextStyle(
                          fontSize: 28, fontWeight: FontWeight.bold),
                    ),
                  ),
                  // Year Column (2025 → 1925)
                  Expanded(
                    child: ListWheelScrollView.useDelegate(
                      itemExtent: 50,
                      controller: yearController,
                      perspective: 0.005,
                      diameterRatio: 1.8,
                      physics: const FixedExtentScrollPhysics(),
                      onSelectedItemChanged: (index) =>
                      selectedYear = currentYear - index,
                      childDelegate: ListWheelChildBuilderDelegate(
                        childCount: 101,
                        builder: (context, index) {
                          final year = currentYear - index;
                          return Center(
                            child: Text(
                              year.toString(),
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  l10n?.cancel ?? "Cancel",
                  style: TextStyle(color: AppColors.primary),
                ),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _selectedMonthYear = DateTime(selectedYear, selectedMonth);
                  });
                  Navigator.pop(context);
                },
                child: Text(
                  l10n?.ok ?? "OK",
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
    );
  }

  Future<void> _selectTime(BuildContext context, bool isFromTime) async {
    int selectedHour = isFromTime
        ? (_fromTime?.hour ?? TimeOfDay
        .now()
        .hour)
        : (_toTime?.hour ?? TimeOfDay
        .now()
        .hour);
    int selectedMinute = isFromTime
        ? (_fromTime?.minute ?? TimeOfDay
        .now()
        .minute)
        : (_toTime?.minute ?? TimeOfDay
        .now()
        .minute);
    final l10n = AppLocalizations.of(context);

    // Use controllers for exact initial position
    final hourController = FixedExtentScrollController(
      initialItem: selectedHour,
    );
    final minuteController = FixedExtentScrollController(
      initialItem: selectedMinute,
    );

    await showDialog(
      context: context,
      builder: (context) =>
          AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            title: Text(
              isFromTime
                  ? (l10n?.fromTimeLabel ?? "From Time")
                  : (l10n?.toTimeLabel ?? "To Time"),
              textAlign: TextAlign.center,
            ),
            content: SizedBox(
              width: 280,
              height: 240,
              child: Row(
                children: [
                  // Hour Wheel
                  Expanded(
                    child: ListWheelScrollView.useDelegate(
                      controller: hourController,
                      itemExtent: 50,
                      perspective: 0.005,
                      diameterRatio: 1.8,
                      physics: const FixedExtentScrollPhysics(),
                      onSelectedItemChanged: (index) => selectedHour = index,
                      childDelegate: ListWheelChildBuilderDelegate(
                        childCount: 24,
                        builder: (context, index) =>
                            Center(
                              child: Text(
                                index.toString().padLeft(2, '0'),
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                      ),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text(
                      ":",
                      style: TextStyle(
                          fontSize: 28, fontWeight: FontWeight.bold),
                    ),
                  ),
                  // Minute Wheel
                  Expanded(
                    child: ListWheelScrollView.useDelegate(
                      controller: minuteController,
                      itemExtent: 50,
                      perspective: 0.005,
                      diameterRatio: 1.8,
                      physics: const FixedExtentScrollPhysics(),
                      onSelectedItemChanged: (index) => selectedMinute = index,
                      childDelegate: ListWheelChildBuilderDelegate(
                        childCount: 60, // 0 to 59 minutes
                        builder: (context, index) =>
                            Center(
                              child: Text(
                                index.toString().padLeft(2, '0'),
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  l10n?.cancel ?? "Cancel",
                  style: TextStyle(
                    fontWeight: FontWeight.normal,
                    color: AppColors.primary,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  final time = TimeOfDay(
                    hour: selectedHour,
                    minute: selectedMinute,
                  );
                  setState(() {
                    if (isFromTime) {
                      _fromTime = time;
                    } else {
                      _toTime = time;
                    }
                  });
                  Navigator.pop(context);
                },
                child: Text(
                  l10n?.ok ?? "Ok",
                  style: TextStyle(
                    fontWeight: FontWeight.normal,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
    );
  }

  String _calculateHours() {
    if (_fromTime == null || _toTime == null) return "0";
    final fromMinutes = _fromTime!.hour * 60 + _fromTime!.minute;
    final toMinutes = _toTime!.hour * 60 + _toTime!.minute;
    int durationMinutes;
    if (toMinutes < fromMinutes) {
      // Overnight meeting (e.g., 10 PM to 6 AM)
      durationMinutes = (toMinutes + 1440) - fromMinutes;
    } else {
      durationMinutes = toMinutes - fromMinutes;
    }
    final hours = (durationMinutes / 60).floor(); // Only whole hours
    return hours.toString();
  }

  List<Day> days = [
    // const Day(id: 1, name: 'Monday'),
    // const Day(id: 2, name: 'Tuesday'),
    // const Day(id: 3, name: 'Wednesday'),
    // const Day(id: 4, name: 'Thursday'),
    // const Day(id: 5, name: 'Friday'),
    // const Day(id: 6, name: 'Saturday'),
    // const Day(id: 7, name: 'Sunday'),
  ];
  String? uniqueKey; // To store existing unique_key when editing
  Map<String, dynamic>? userData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();

    print("ClusterMeetingScreenForm → Received uniqueKey: ${widget.uniqueKey}");
    print("Is Edit Mode: ${widget.isEditMode}");

    _loadUserData().then((_) {
      if (!widget.isEditMode) {
        _applyUserDataToForm();
      }

      // Then load existing data if in edit mode → this will safely override defaults
      if (widget.isEditMode && widget.uniqueKey != null) {
        _loadExistingMeeting();
      }
    });
  }

  void _applyUserDataToForm() {
    if (userData == null) return;

    final nameData = userData!['name'] as Map<String, dynamic>?;
    final workingLocation =
    userData!['working_location'] as Map<String, dynamic>?;

    final firstName = nameData?['first_name']?.toString().trim() ?? '';
    final middleName = nameData?['middle_name']?.toString().trim() ?? '';
    final lastName = nameData?['last_name']?.toString().trim() ?? '';

    final fullName = [
      firstName,
      lastName,
    ].where((part) => part.isNotEmpty).join(' ');

    final villageName = workingLocation?['village']?.toString().trim() ?? '';
    final blockName = workingLocation?['block']?.toString().trim() ?? '';

    // Only fill if the field is currently empty
    if (_ashaFacilitatorNameController.text
        .trim()
        .isEmpty) {
      _ashaFacilitatorNameController.text = fullName;
    }
    if (_villageNameController.text
        .trim()
        .isEmpty) {
      _villageNameController.text = villageName;
    }
    // if (_blockNameController.text.trim().isEmpty) {
    //   _blockNameController.text = blockName;
    // }
  }

  Future<void> _loadUserData() async {
    if (mounted) {
      setState(() => isLoading = true);
    }

    try {
      developer.log('Loading user data from secure storage...', name: 'Drawer');

      Map<String, dynamic>? data =
      await SecureStorageService.getCurrentUserData();

      if (data == null || data.isEmpty) {
        developer.log(
          'No current user data found, trying legacy format...',
          name: 'Drawer',
        );
        final legacyData = await SecureStorageService.getUserData();
        if (legacyData != null && legacyData.isNotEmpty) {
          try {
            data = jsonDecode(legacyData) as Map<String, dynamic>?;
          } catch (e) {
            developer.log(
              'Error parsing legacy user data: $e',
              name: 'Drawer',
              error: e,
            );
          }
        }
      }

      /// 🔥 PRINT YOUR COMPLETE USER DATA HERE
      developer.log('USER DATA: ${jsonEncode(data)}', name: 'Drawer');

      if (mounted) {
        setState(() {
          userData = data;

          final ashaList = data?['asha_list'] as List<dynamic>? ?? [];
          _ashaList = ashaList;
          _ashaCount = ashaList.length;

          // THIS IS CRITICAL — Rebuild present list with correct size
          _presentList = List<bool>.filled(_ashaList.length, false);
          developer.log(
            "TOTAL ASHA COUNT → $_ashaCount",
            name: "ClusterMeeting",
          );
          isLoading = false;
        });
      }
    } catch (e) {
      developer.log('Error in _loadUserData: $e', name: 'Drawer', error: e);
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Map<String, dynamic> _safeDecode(dynamic raw) {
    if (raw == null) return {};

    try {
      // Case 1: Already a Map
      if (raw is Map<String, dynamic>) return raw;

      // Case 2: String containing JSON
      if (raw is String) {
        raw = raw.trim();

        // First decode
        final first = jsonDecode(raw);

        // If first decode returns a string → decode AGAIN (double-encoded)
        if (first is String) {
          final second = jsonDecode(first);
          if (second is Map<String, dynamic>) return second;
        }

        if (first is Map<String, dynamic>) return first;
      }
    } catch (e) {
      print("Decode error: $e");
    }

    return {};
  }

  Future<void> _loadExistingMeeting() async {
    try {
      final row = await LocalStorageDao.instance.getClusterMeetingById(
        widget.uniqueKey!,
      );

      if (row == null) {
        showAppSnackBar(context, "Meeting not found!");
        return;
      }

      final rawJson = row["form_json"];
      final formJson = _safeDecode(rawJson);
      print("DECODED JSON: $formJson");

      setState(() {
        uniqueKey = row["unique_key"].toString();

        _phcNameController.text = formJson["phc_name"] ?? "";
        _subcenterNameController.text = formJson["subcenter_name"] ?? "";
        _ashaFacilitatorNameController.text =
            formJson["asha_facilitator_name"] ?? "";
        _ashaInchargeNameController.text = formJson["asha_incharge_name"] ?? "";
        _awwNameController.text = formJson["aww_name"] ?? "";
        _awcNumberController.text = formJson["awc_number"] ?? "";
        _villageNameController.text = formJson["village_name"] ?? "";
        _wardNameController.text = formJson["ward_name"] ?? "";
        _wardNumberController.text = formJson["ward_number"] ?? "";
        _blockNameController.text = formJson["block_name"] ?? "";
        _decisionTakenController.text = formJson["decision_taken"] ?? "";

        // Date
        final dateStr = formJson["meeting_date"];
        if (dateStr != null) _meetingDate = DateTime.tryParse(dateStr);

        // Day
        final dayName = formJson["day_of_week"];
        if (dayName != null) {
          selectedDay = days.firstWhere(
                (d) => d.name.toLowerCase() == dayName.toString().toLowerCase(),
            orElse: () => days[0],
          );
        }

        // Time
        final fromStr = formJson["from_time"];
        final toStr = formJson["to_time"];
        if (fromStr != null) _fromTime = _parseTimeOfDay(fromStr);
        if (toStr != null) _toTime = _parseTimeOfDay(toStr);

        // Count
        clusterMeetingsCount =
            int.tryParse(
              formJson["cluster_meetings_this_month"]?.toString() ?? "0",
            ) ??
                0;

        // Month-Year
        final monthYearStr = formJson["month_year"];
        if (monthYearStr != null && monthYearStr.contains("-")) {
          final parts = monthYearStr.split("-");
          if (parts.length == 2) {
            final m = int.tryParse(parts[0]);
            final y = int.tryParse(parts[1]);
            if (m != null && y != null) _selectedMonthYear = DateTime(y, m);
          }
        }

        // Topics - Load topic names
        final topicsStr = formJson["discussion_topics"];
        if (topicsStr != null && topicsStr is String) {
          _selectedTopics = topicsStr
              .split(',')
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toSet();
        }

        // Load sub-topics from saved data
        _selectedSubTopics = {};
        final immunizationSubTopic = formJson["immunization_discussion_topic"];
        if (immunizationSubTopic != null && immunizationSubTopic
            .toString()
            .isNotEmpty) {
          _selectedSubTopics[1] = immunizationSubTopic.toString();
        }
        final pregnantWomenSubTopic = formJson["pregnant_women_discussion_topic"];
        if (pregnantWomenSubTopic != null && pregnantWomenSubTopic
            .toString()
            .isNotEmpty) {
          _selectedSubTopics[2] = pregnantWomenSubTopic.toString();
        }
        final deathsSubTopic = formJson["deaths_discussion_topic"];
        if (deathsSubTopic != null && deathsSubTopic
            .toString()
            .isNotEmpty) {
          _selectedSubTopics[8] = deathsSubTopic.toString();
        }
        final familyPlanningSubTopic = formJson["family_planning_discussion_topic"];
        if (familyPlanningSubTopic != null && familyPlanningSubTopic
            .toString()
            .isNotEmpty) {
          _selectedSubTopics[10] = familyPlanningSubTopic.toString();
        }
        final otherPublicHealthSubTopic = formJson["other_public_health_program_discussion_topic"];
        if (otherPublicHealthSubTopic != null && otherPublicHealthSubTopic
            .toString()
            .isNotEmpty) {
          _selectedSubTopics[11] = otherPublicHealthSubTopic.toString();
        }
        final administrativeSubTopic = formJson["administrative_discussion_topic"];
        if (administrativeSubTopic != null && administrativeSubTopic
            .toString()
            .isNotEmpty) {
          _selectedSubTopics[12] = administrativeSubTopic.toString();
        }
        final trainingSupportSubTopic = formJson["training_and_support_discussion_topic"];
        if (trainingSupportSubTopic != null && trainingSupportSubTopic
            .toString()
            .isNotEmpty) {
          _selectedSubTopics[13] = trainingSupportSubTopic.toString();
        }

        // Other Topic Details
        final otherTopic = formJson["other_topic_details"];
        if (otherTopic != null && otherTopic.isNotEmpty) {
          _otherTopicController.text = otherTopic;
        }

        final savedPresentList =
            formJson['asha_present_list'] as List<dynamic>? ?? [];

        List<bool> restored = List<bool>.filled(_ashaList.length, false);

        for (
        int i = 0;
        i < savedPresentList.length && i < _ashaList.length;
        i++
        ) {
          restored[i] = savedPresentList[i] == true;
        }
        _presentList = restored;
        _ashaPresentCount = _presentList
            .where((e) => e)
            .length;
        _ashaAbsentCount = _presentList
            .where((e) => !e)
            .length;
      });

      // Convert topic names to IDs after build completes (since discussionTopics is populated in build())
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _convertTopicNamesToIds();
      });
    } catch (e) {
      print("Error loading meeting: $e");
    }
  }

  void _convertTopicNamesToIds() {
    if (_selectedTopics.isEmpty || discussionTopics.isEmpty) return;

    final topicIds = <int>{};
    for (final topicName in _selectedTopics) {
      final topic = discussionTopics.firstWhere(
            (t) => t.name.toLowerCase() == topicName.toLowerCase(),
        orElse: () => const DiscussionTopic(id: -1, name: ''),
      );
      if (topic.id != -1) {
        topicIds.add(topic.id);
      }
    }

    if (topicIds.isNotEmpty) {
      setState(() {
        _selectedTopicIds = topicIds;
        _showOtherTopicField = _selectedTopicIds.contains(14);
      });
    }
  }

  TimeOfDay _parseTimeOfDay(String time) {
    try {
      final format = RegExp(r'(\d+):(\d+) (AM|PM)');
      final match = format.firstMatch(time);
      if (match != null) {
        int hour = int.parse(match.group(1)!);
        final minute = int.parse(match.group(2)!);
        final period = match.group(3);
        if (period == "PM" && hour != 12) hour += 12;
        if (period == "AM" && hour == 12) hour = 0;
        return TimeOfDay(hour: hour, minute: minute);
      }
    } catch (e) {
      // fallback
    }
    return const TimeOfDay(hour: 9, minute: 0);
  }

  Set<int> _selectedTopicIds = {};
  Map<int, String> _selectedSubTopics = {};

  Future<void> showMultiSelectDialog({
    required BuildContext context,
    required String title,
    required List<String> options,
    required String? selected, // single value now
    required Function(String?) onSubmit,
  }) async {
    String? tempValue = selected;
    final l10n = AppLocalizations.of(context);

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) =>
          StatefulBuilder(
            builder: (context, setStateDialog) =>
                AlertDialog(
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4)),

                  title: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      const Divider(height: 2),
                    ],
                  ),

                  content: ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 350),
                    child: SingleChildScrollView(
                      child: Column(
                        children: options.map((e) {
                          return RadioListTile<String>(
                            title: Text(
                                e, style: const TextStyle(fontSize: 14)),
                            value: e,
                            groupValue: tempValue,
                            dense: true,
                            visualDensity: const VisualDensity(vertical: -4),
                            onChanged: (val) {
                              setStateDialog(() {
                                tempValue = val;
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ),
                  ),

                  actions: [
                    const Divider(height: 1),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            l10n?.cancel ?? 'CANCEL',
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                              color: Theme
                                  .of(context)
                                  .primaryColor,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            onSubmit(tempValue);
                            Navigator.pop(context);
                          },
                          child: Text(
                            l10n?.ok ?? 'OK',
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                              color: Theme
                                  .of(context)
                                  .primaryColor,
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


  Future<void> _showTopicsDialog(BuildContext context) async {
    final currentIds = Set<int>.from(_selectedTopicIds);
    final l10n = AppLocalizations.of(context);

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) =>
          StatefulBuilder(
            builder: (context, setStateDialog) =>
                AlertDialog(
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4)),
                  title: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n?.discussionTopicProgram ??
                            "Select Discussion Topics",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      const Divider(height: 2),
                    ],
                  ),

                  /// 🔹 CONTENT WITH HEIGHT LIMIT
                  content: ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 350),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: discussionTopics.map((topic) {
                          final isChecked = currentIds.contains(topic.id);

                          return CheckboxListTile(
                            title: Text(
                              topic.name,
                              style: const TextStyle(fontSize: 14),
                            ),
                            value: isChecked,
                            dense: true,
                            visualDensity: const VisualDensity(vertical: -4),
                            controlAffinity: ListTileControlAffinity.leading,
                            onChanged: (checked) {
                              setStateDialog(() {
                                if (checked == true) {
                                  currentIds.add(topic.id);
                                } else {
                                  currentIds.remove(topic.id);
                                  _selectedSubTopics.remove(topic.id);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ),
                  ),

                  /// 🔹 DIVIDER + BUTTON ROW (LIKE OLD APP)
                  actions: [
                    const Divider(height: 1),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () {
                            FocusManager.instance.primaryFocus?.unfocus();
                            Navigator.pop(context);
                          },
                          child: Text(
                            l10n?.cancel ?? 'CANCEL',
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                              color: Theme
                                  .of(context)
                                  .primaryColor,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _selectedTopicIds = currentIds;
                              _showOtherTopicField = _selectedTopicIds.contains(
                                14,
                              ); // Other
                            });
                            FocusManager.instance.primaryFocus?.unfocus();
                            Navigator.pop(context);
                          },
                          child: Text(
                            l10n?.ok ?? 'OK',
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                              color: Theme
                                  .of(context)
                                  .primaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
          ),
    );

    FocusManager.instance.primaryFocus?.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isEdit = widget.isEditMode;

    days = [
      Day(id: 1, name: l10n?.monday ?? 'Monday'),
      Day(id: 2, name: l10n?.tuesday ?? 'Tuesday'),
      Day(id: 3, name: l10n?.wednesday ?? 'Wednesday'),
      Day(id: 4, name: l10n?.thursday ?? 'Thursday'),
      Day(id: 5, name: l10n?.friday ?? 'Friday'),
      Day(id: 6, name: l10n?.saturday ?? 'Saturday'),
      Day(id: 7, name: l10n?.sunday ?? 'Sunday'),
    ];

    discussionTopics = [
      DiscussionTopic(id: 1, name: l10n?.immunization ?? "Immunization"),
      DiscussionTopic(id: 2, name: l10n?.pregnantWomen ?? "Pregnant Women"),
      DiscussionTopic(id: 3, name: l10n?.deliveries ?? "Deliveries"),
      DiscussionTopic(id: 4, name: l10n?.pnc ?? "PNC (Post Natal Care)"),
      DiscussionTopic(
        id: 5,
        name: l10n?.maternalChildHealth ?? "Maternal & Child Health",
      ),
      DiscussionTopic(id: 6, name: l10n?.homeVisit ?? "Home Visit"),
      DiscussionTopic(id: 7, name: l10n?.newBornCare ?? "New Born Care"),
      DiscussionTopic(id: 8, name: l10n?.deaths ?? "Deaths"),
      DiscussionTopic(
        id: 9,
        name: l10n?.adolescentHealth ?? "Adolescent Health",
      ),
      DiscussionTopic(id: 10, name: l10n?.familyPlanning ?? "Family Planning"),
      DiscussionTopic(
        id: 11,
        name: l10n?.otherPublicHealthProgram ?? "Other Public Health Program",
      ),
      DiscussionTopic(id: 12, name: l10n?.administrative ?? "Administrative"),
      DiscussionTopic(
        id: 13,
        name: l10n?.trainingSupport ?? "Training and Support",
      ),
      DiscussionTopic(id: 14, name: l10n?.other ?? "Other"),
    ];

    final Map<int, List<String>> subTopicsByTopicId = {
      1: [ // Immunization
        l10n.immunizationDueListPreparation,
        l10n.immunizationVHSND,
        l10n.immunizationVHSC,
        l10n.immunizationDropoutChildren,
        l10n.immunizationLeftoutChildren,
        l10n.immunizationZerodoseChildren,
        l10n.immunizationImmunizationInPrivate,
        l10n.immunizationDocumentation,
        l10n.immunizationOther,
      ],
      2: [ // Pregnant Women
        l10n.pregnantWomenANC,
        l10n.pregnantWomenRegistartionForANC,
        l10n.pregnantWomenDangerSigns,
        l10n.pregnantWomenOther,
      ],
      8: [
        l10n.deathMaternalDeath,
        l10n.deathChild,
        l10n.deathNowBorn,
        l10n.deathInfant,
        l10n.deathDocumentation,
        l10n.deathNotification,
        l10n.deathOther,
      ],
      10: [ // Family Planning
        l10n.familyPlanningEligibleCouple,
      ],
      11: [ // Other Public Health Program
        l10n.otherPublicHealthProgramTuberculosis,
        l10n.otherPublicHealthProgramLeprosy,
        l10n.otherPublicHealthProgramMalnutrition,
        l10n.otherPublicHealthProgramAnemia,
        l10n.otherPublicHealthProgramDiarrhea,
        l10n.otherPublicHealthProgramNCD,
        l10n.otherPublicHealthProgramPolio,
        l10n.otherPublicHealthProgramKalaAzar,
        l10n.otherPublicHealthProgramAES,
        l10n.otherPublicHealthProgramCovid19,
        l10n.otherPublicHealthProgramCholera,
        l10n.otherPublicHealthProgramDengue,
        l10n.otherPublicHealthProgramDogBite,
        l10n.otherPublicHealthProgramKilkari,
      ],
      12: [ // Administrative
        l10n.administrativeRegisters,
        l10n.administrativeDrugs,
        l10n.administrativeEquipement,
        l10n.administrativePlanning,
        l10n.administrativeCounselingMaterialFlipbooksCards,
        l10n.administrativeImmunizationCardsMCPCards,
        l10n.administrativeHealthPromotionalMaterial,
      ],
      13: [ // Training and Support
        l10n.trainingAndSupportTrainingSupport,
        l10n.trainingAndSupportMentoringSupport,
        l10n.trainingAndSupportFieldSupport,
        l10n.trainingAndSupportASHAWorkPlanning,
        l10n.trainingAndSupportHomeVisits,
        l10n.trainingAndSupportMobileAcademy,
      ],
    };

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppHeader(
        screenTitle:
        l10n?.ashaFacilitatorClusterMeeting ??
            "ASHA Facilitator Cluster Meeting",
        showBack: true,
      ),
      body: Column(
        children: [
          // Scrollable form content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  CustomTextField(
                    controller: _phcNameController,
                    labelText: l10n?.phcName ?? "PHC Name",
                    hintText: l10n?.phcName ?? "PHC Name",
                    readOnly: false,
                  ),
                  Divider(color: AppColors.divider, thickness: 0.5),

                  CustomTextField(
                    controller: _subcenterNameController,
                    labelText: l10n?.subcenterName ?? "Subcenter Name",
                    hintText: l10n?.subcenterName ?? "Subcenter Name",
                  ),
                  Divider(color: AppColors.divider, thickness: 0.5),

                  CustomTextField(
                    controller: _ashaFacilitatorNameController,
                    labelText: l10n?.ashaFacilitatorName ??
                        "ASHA Facilitator Name",
                    hintText: l10n?.ashaFacilitatorName ??
                        "ASHA Facilitator Name",
                  ),
                  Divider(color: AppColors.divider, thickness: 0.5),

                  CustomTextField(
                    controller: _ashaInchargeNameController,
                    labelText: l10n?.ashaInchargeName ?? "ASHA Incharge Name",
                    hintText: l10n?.ashaInchargeName ?? "ASHA Incharge Name",
                  ),
                  Divider(color: AppColors.divider, thickness: 0.5),

                  CustomTextField(
                    controller: _awwNameController,
                    labelText: l10n?.awwName ?? "AWW Name",
                    hintText: l10n?.awwName ?? "AWW Name",
                  ),
                  Divider(color: AppColors.divider, thickness: 0.5),

                  CustomTextField(
                    controller: _awcNumberController,
                    labelText: l10n?.awcNumber ?? "AWC Number",
                    hintText: l10n?.awcNumber ?? "AWC Number",
                    keyboardType: TextInputType.number,
                  ),
                  Divider(color: AppColors.divider, thickness: 0.5),

                  CustomTextField(
                    controller: _villageNameController,
                    labelText: l10n?.villageName ?? "Village Name",
                    hintText: l10n?.villageName ?? "Village Name",
                  ),
                  Divider(color: AppColors.divider, thickness: 0.5),

                  CustomTextField(
                    controller: _wardNameController,
                    labelText: l10n?.wardName ?? "Ward Name",
                    hintText: l10n?.wardName ?? "Ward Name",
                  ),
                  Divider(color: AppColors.divider, thickness: 0.5),

                  CustomTextField(
                    controller: _wardNumberController,
                    labelText: l10n?.wardNumber ?? "Ward Number",
                    hintText: l10n?.wardNumber ?? "Ward Number",
                    keyboardType: TextInputType.number,
                  ),
                  Divider(color: AppColors.divider, thickness: 0.5),

                  CustomTextField(
                    controller: _blockNameController,
                    labelText: l10n?.blockName ?? "Block Name",
                    hintText: l10n?.blockName ?? "Block Name",
                  ),
                  Divider(color: AppColors.divider, thickness: 0.5),

                  CustomDatePicker(
                    labelText: "${l10n?.dateOfMeeting} *",
                    hintText: l10n?.dateHint ?? "dd-mm-yyyy",
                    initialDate: _meetingDate,
                    onDateChanged: (date) {
                      setState(() {
                        _meetingDate = date;
                      });
                    },
                  ),
                  Divider(color: AppColors.divider, thickness: 0.5),

                  ApiDropdown<Day>(
                    labelText: l10n?.day ?? "Day",
                    items: days,
                    value: selectedDay,
                    getLabel: (day) => day.name,
                    hintText: l10n?.day ?? "Day",
                    onChanged: (Day? newValue) {
                      setState(() {
                        selectedDay = newValue;
                      });
                    },
                  ),
                  Divider(color: AppColors.divider, thickness: 0.5),

                  GestureDetector(
                    onTap: () => _selectTime(context, true),
                    child: AbsorbPointer(
                      child: CustomTextField(
                        labelText: l10n?.fromTime ?? "From (HH:MM)",
                        hintText: l10n?.deliveryTimeHint,
                        initialValue: _fromTime != null
                            ? format24Hour(_fromTime!)
                            : "",
                        readOnly: true,
                      ),
                    ),
                  ),
                  Divider(color: AppColors.divider, thickness: 0.5),

                  GestureDetector(
                    onTap: () => _selectTime(context, false),
                    child: AbsorbPointer(
                      child: CustomTextField(
                        labelText: l10n?.toTime ?? "To (HH:MM)",
                        hintText: l10n?.deliveryTimeHint,
                        initialValue: _toTime != null
                            ? format24Hour(_toTime!)
                            : "",
                        readOnly: true,
                      ),
                    ),
                  ),
                  Divider(color: AppColors.divider, thickness: 0.5),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          l10n?.noOfHours ?? "No. of hours",
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.divider),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          _calculateHours(),
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Divider(color: AppColors.divider, thickness: 0.5),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          l10n?.totalAshaUnderFacilitator ??
                              "Total Number of ASHA's under the Facilitator",
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.divider),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          _ashaList.length.toString(),
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Divider(color: AppColors.divider, thickness: 0.5),

                  Container(
                    margin: EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Table(
                      columnWidths: const {
                        0: FixedColumnWidth(60),
                        1: FlexColumnWidth(),
                        2: FixedColumnWidth(90),
                      },
                      border: TableBorder(
                        horizontalInside: BorderSide(color: Colors.grey),
                        verticalInside: BorderSide(color: Colors.grey),
                      ),
                      children: [
                        TableRow(
                          children: [
                            _tableHeaderCell(l10n?.sr_No ?? "Sr.No."),
                            _tableHeaderCell(l10n?.nameLabel ?? "Name"),
                            _tableHeaderCell(l10n?.present ?? "Present?"),
                          ],
                        ),
                        ..._buildAshaRows(),
                      ],
                    ),
                  ),
                  Divider(color: AppColors.divider, thickness: 0.5),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          l10n?.ashaPresentCount ??
                              "No. of ASHA present in this meeting",
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.divider),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          presentCount.toString(),
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Divider(color: AppColors.divider, thickness: 0.5),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          l10n?.noOfASHAAbsentInThisMeeting ??
                              "No. of ASHA absent in this meeting",
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.divider),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          absentCount.toString(),
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Divider(color: AppColors.divider, thickness: 0.5),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          l10n?.clusterMeetingsCountThisMonth ??
                              "No. of cluster meetings conducted in this month",
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                if (clusterMeetingsCount > 0)
                                  clusterMeetingsCount--;
                              });
                            },
                            child: Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                color: clusterMeetingsCount > 0
                                    ? AppColors.primary
                                    : Colors.grey.shade200,
                                border: Border.all(color: AppColors.divider),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              alignment: Alignment.center,
                              child: Icon(
                                Icons.remove,
                                size: 18,
                                color: clusterMeetingsCount > 0
                                    ? Colors.white
                                    : Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 2),
                          Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              border: Border.all(color: AppColors.divider),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              clusterMeetingsCount.toString(),
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 2),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                clusterMeetingsCount++;
                              });
                            },
                            child: Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                border: Border.all(color: AppColors.divider),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              alignment: Alignment.center,
                              child: const Icon(
                                Icons.add,
                                size: 18,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Divider(color: AppColors.divider, thickness: 0.5),

                  GestureDetector(
                    onTap: () => _selectMonthYear(context),
                    child: AbsorbPointer(
                      child: CustomTextField(
                        labelText: l10n?.month ?? "Month",
                        hintText: "mm-yyyy",
                        initialValue: _selectedMonthYear != null
                            ? "${_selectedMonthYear!.month.toString().padLeft(
                            2, '0')}-${_selectedMonthYear!.year}"
                            : "",
                        readOnly: true,
                      ),
                    ),
                  ),
                  Divider(color: AppColors.divider, thickness: 0.5),

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: () => _showTopicsDialog(context),
                        child: AbsorbPointer(
                          child: Stack(
                            alignment: Alignment.centerRight,
                            children: [
                              CustomTextField(
                                labelText:
                                l10n?.discussionTopicProgram ??
                                    "Discussion Topic/Program",
                                hintText: l10n?.selectOptionLabel ?? "Select",
                                initialValue: _selectedTopicIds.isEmpty
                                    ? null
                                    : discussionTopics
                                    .where(
                                      (e) => _selectedTopicIds.contains(e.id),
                                )
                                    .map((e) => e.name)
                                    .join(", "),
                                textStyle: TextStyle(
                                  color: _selectedTopicIds.isEmpty
                                      ? Colors.grey
                                      : Colors.black,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Positioned(
                                right: 12,
                                child: Icon(
                                  Icons.arrow_drop_down,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Divider(color: AppColors.divider, thickness: 0.5),

                      Column(
                        children: _selectedTopicIds.map((topicId) {
                          final topic = discussionTopics.firstWhere((e) =>
                          e.id == topicId);
                          final subTopics = subTopicsByTopicId[topicId];

                          if (subTopics == null) return const SizedBox.shrink();

                          return Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: GestureDetector(
                                  onTap: () {
                                    showMultiSelectDialog(
                                      context: context,
                                      title: "${topic.name}_${l10n
                                          .discussionTopic}",
                                      options: subTopics,
                                      selected: _selectedSubTopics[topicId],
                                      onSubmit: (val) {
                                        setState(() {
                                          _selectedSubTopics[topicId] =
                                              val ?? '';
                                        });
                                      },
                                    );
                                  },
                                  child: AbsorbPointer(
                                    child: CustomTextField(
                                      labelText: "${topic.name}_${l10n
                                          .discussionTopic}",
                                      hintText: l10n?.select ?? "Select",
                                      initialValue: _selectedSubTopics[topicId] ??
                                          '',
                                    ),
                                  ),
                                ),
                              ),
                              const Divider(
                                color: AppColors.divider,
                                thickness: 0.5,
                              ),
                            ],
                          );
                        }).toList(),
                      ),

                      if (_showOtherTopicField) ...[
                        const SizedBox(height: 8),
                        CustomTextField(
                          controller: _otherTopicController,
                          labelText:
                          l10n?.otherDiscussionSubTopicProgram ??
                              "Other_Discussion Sub Topic/Program",
                          hintText: l10n?.select,
                          onChanged: (_) => setState(() {}),
                        ),
                        Divider(color: AppColors.divider, thickness: 0.5),
                      ],
                    ],
                  ),

                  CustomTextField(
                    controller: _decisionTakenController,
                    labelText:
                    l10n?.decisionTakenDuringMeeting ??
                        "Decision Taken During the Meeting",
                    hintText:
                    l10n?.decisionTakenDuringMeeting ??
                        "Decision Taken During the Meeting",
                  ),

                  // Add bottom padding to prevent content being hidden behind button
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),

          // Fixed bottom button
          Container(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 10,
              bottom: 10 + MediaQuery
                  .of(context)
                  .padding
                  .bottom,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SizedBox(
              height: 35,
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  if (_meetingDate == null) {
                    showAppSnackBar(
                        context, "Please select Date of the Meeting");
                    return;
                  }

                  final formData = {
                    'phc_name': _phcNameController.text.trim(),
                    'subcenter_name': _subcenterNameController.text.trim(),
                    'asha_facilitator_name': _ashaFacilitatorNameController.text
                        .trim(),
                    'asha_incharge_name': _ashaInchargeNameController.text
                        .trim(),
                    'aww_name': _awwNameController.text.trim(),
                    'awc_number': _awcNumberController.text.trim(),
                    'village_name': _villageNameController.text.trim(),
                    'ward_name': _wardNameController.text.trim(),
                    'ward_number': _wardNumberController.text.trim(),
                    'block_name': _blockNameController.text.trim(),
                    'meeting_date': _meetingDate?.toIso8601String(),
                    'day_of_week': selectedDay?.name,
                    'from_time': _fromTime?.format(context),
                    'to_time': _toTime?.format(context),
                    'no_of_hours': _calculateHours(),
                    'total_asha_under_facilitator': "0",
                    'asha_present': presentCount.toString(),
                    'asha_absent': absentCount.toString(),
                    'asha_present_list': _presentList,
                    'cluster_meetings_this_month': clusterMeetingsCount,
                    'month_year': _selectedMonthYear != null
                        ? "${_selectedMonthYear!.month.toString().padLeft(
                        2, '0')}-${_selectedMonthYear!.year}"
                        : null,
                    'discussion_topics': _selectedTopicIds.map((id) {
                      final topic = discussionTopics.firstWhere(
                            (t) => t.id == id,
                        orElse: () => const DiscussionTopic(id: -1, name: ''),
                      );
                      return topic.id != -1 ? topic.name : '';
                    }).where((name) => name.isNotEmpty).join(", "),
                    'immunization_discussion_topic': _selectedSubTopics[1] ??
                        '',
                    'pregnant_women_discussion_topic': _selectedSubTopics[2] ??
                        '',
                    'deaths_discussion_topic': _selectedSubTopics[8] ?? '',
                    'family_planning_discussion_topic': _selectedSubTopics[10] ??
                        '',
                    'other_public_health_program_discussion_topic': _selectedSubTopics[11] ??
                        '',
                    'administrative_discussion_topic': _selectedSubTopics[12] ??
                        '',
                    'training_and_support_discussion_topic': _selectedSubTopics[13] ??
                        '',
                    'other_topic_details': _otherTopicController.text.trim(),
                    'decision_taken': _decisionTakenController.text.trim(),
                    'saved_at': DateTime.now().toIso8601String(),
                  };

                  print("Form Data to Save: ${jsonEncode(formData)}");

                  try {
                    if (widget.isEditMode && uniqueKey != null) {
                      await LocalStorageDao.instance.updateClusterMeeting(
                        uniqueKey: uniqueKey!,
                        formJson: formData,
                      );
                      showAppSnackBar(
                          context, l10n.householdUpdatedSuccessfully);
                    } else {
                      final deviceInfo = await DeviceInfo.getDeviceInfo();
                      final newUniqueKey = await IdGenerator.generateUniqueId(
                          deviceInfo);

                      await LocalStorageDao.instance.insertClusterMeeting({
                        'unique_key': newUniqueKey,
                        'form_json': jsonEncode(formData),
                        'created_by': 'current_user',
                      });
                      showAppSnackBar(context, l10n.saveSuccess);
                    }

                    if (mounted) Navigator.pop(context);
                    Navigator.pop(context);
                  } catch (e) {
                    showAppSnackBar(context, "Error: $e");
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme
                      .of(context)
                      .colorScheme
                      .primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  isEdit
                      ? (l10n?.updateButton ?? "UPDATE")
                      : (l10n?.saveButton ?? "SAVE"),
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
