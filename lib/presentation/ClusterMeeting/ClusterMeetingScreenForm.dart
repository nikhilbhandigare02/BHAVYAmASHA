import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/config/themes/CustomColors.dart';
import '../../core/utils/device_info_utils.dart';
import '../../core/utils/id_generator_utils.dart';
import '../../core/widgets/AppHeader/AppHeader.dart';
import '../../core/widgets/DatePicker/DatePicker.dart';
import '../../core/widgets/Dropdown/Dropdown.dart';
import '../../core/widgets/SnackBar/app_snackbar.dart';
import '../../core/widgets/TextField/TextField.dart';
import '../../data/Database/local_storage_dao.dart';
import '../../l10n/app_localizations.dart';
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
  State<ClusterMeetingScreenForm> createState() => _ClusterMeetingScreenFormState();
}
class _ClusterMeetingScreenFormState extends State<ClusterMeetingScreenForm> {
  int clusterMeetingsCount = 0;
  Set<String> _selectedTopics = {};
  final List<DiscussionTopic> discussionTopics = [
  const DiscussionTopic(id: 1, name: "Immunization"),
  const DiscussionTopic(id: 2, name: "Pregnant Women"),
  const DiscussionTopic(id: 3, name: "Deliveries"),
  const DiscussionTopic(id: 4, name: "PNC (Post Natal Care)"),
  const DiscussionTopic(id: 5, name: "Maternal & Child Health"),
  const DiscussionTopic(id: 6, name: "Home Visit"),
  const DiscussionTopic(id: 7, name: "New Born Care"),
  const DiscussionTopic(id: 8, name: "Deaths"),
  const DiscussionTopic(id: 9, name: "Adolescent Health"),
  const DiscussionTopic(id: 10, name: "Family Planning"),
  const DiscussionTopic(id: 11, name: "Other Public Health Program"),
  const DiscussionTopic(id: 12, name: "Administrative"),
  const DiscussionTopic(id: 13, name: "Training and Support"),
  const DiscussionTopic(id: 14, name: "Other"),
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
    int selectedMonth = _selectedMonthYear?.month ?? DateTime.now().month;
    int selectedYear = _selectedMonthYear?.year ?? DateTime.now().year;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text("Select Month & Year", textAlign: TextAlign.center),
        content: SizedBox(
          width: 280,
          height: 240,
          child: Row(
            children: [
              // Month Column (1 to 12)
              Expanded(
                child: ListWheelScrollView.useDelegate(
                  itemExtent: 50,
                  perspective: 0.005,
                  diameterRatio: 1.8,
                  physics: const FixedExtentScrollPhysics(),
                  onSelectedItemChanged: (index) => selectedMonth = index + 1,
                  childDelegate: ListWheelChildBuilderDelegate(
                    childCount: 12,
                    builder: (context, index) {
                      final month = (index + 1).toString().padLeft(2, '0');
                      return Center(
                        child: Text(
                          month,
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text("-", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              ),
              // Year Column (2025 → 1925)
              Expanded(
                child: ListWheelScrollView.useDelegate(
                  itemExtent: 50,
                  perspective: 0.005,
                  diameterRatio: 1.8,
                  physics: const FixedExtentScrollPhysics(),
                  onSelectedItemChanged: (index) => selectedYear = 2025 - index,
                  childDelegate: ListWheelChildBuilderDelegate(
                    childCount: 101, // 2025 to 1925 = 101 years
                    builder: (context, index) {
                      final year = 2025 - index;
                      return Center(
                        child: Text(
                          year.toString(),
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
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
            child: Text("Cancel", style: TextStyle(color: AppColors.primary)),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _selectedMonthYear = DateTime(selectedYear, selectedMonth);
              });
              Navigator.pop(context);
            },
            child: Text("OK", style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
  Future<void> _selectTime(BuildContext context, bool isFromTime) async {
    int selectedHour = isFromTime
        ? (_fromTime?.hour ?? TimeOfDay.now().hour)
        : (_toTime?.hour ?? TimeOfDay.now().hour);
    int selectedMinute = isFromTime
        ? (_fromTime?.minute ?? 0)
        : (_toTime?.minute ?? 0);

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(isFromTime ? "From Time" : "To Time", textAlign: TextAlign.center),
        content: SizedBox(
          width: 280,
          height: 240,
          child: Row(
            children: [
              // Hours Column
              Expanded(
                child: ListWheelScrollView.useDelegate(
                  itemExtent: 50,
                  perspective: 0.005,
                  diameterRatio: 1.8,
                  physics: const FixedExtentScrollPhysics(),
                  onSelectedItemChanged: (index) => selectedHour = index,
                  childDelegate: ListWheelChildBuilderDelegate(
                    childCount: 24,
                    builder: (context, index) => Center(
                      child: Text(
                        index.toString().padLeft(2, '0'),
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Text(":", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              ),
              // Minutes Column
              Expanded(
                child: ListWheelScrollView.useDelegate(
                  itemExtent: 50,
                  perspective: 0.005,
                  diameterRatio: 1.8,
                  physics: const FixedExtentScrollPhysics(),
                  onSelectedItemChanged: (index) => selectedMinute = index * 5, // 5-minute steps
                  childDelegate: ListWheelChildLoopingListDelegate(
                    children: List.generate(12, (i) => i * 5)
                        .map((min) => Center(
                      child: Text(
                        min.toString().padLeft(2, '0'),
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
                      ),
                    ))
                        .toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel", style: TextStyle(fontWeight:FontWeight.normal,color: AppColors.primary)),
          ),
          TextButton(
            onPressed: () {
              final time = TimeOfDay(hour: selectedHour, minute: selectedMinute);
              setState(() {
                if (isFromTime) {
                  _fromTime = time;
                } else {
                  _toTime = time;
                }
              });
              Navigator.pop(context);
            },
            child: Text("Ok", style: TextStyle(fontWeight:FontWeight.normal,color: AppColors.primary)),
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
  final List<Day> days = [
    const Day(id: 1, name: 'Monday'),
    const Day(id: 2, name: 'Tuesday'),
    const Day(id: 3, name: 'Wednesday'),
    const Day(id: 4, name: 'Thursday'),
    const Day(id: 5, name: 'Friday'),
    const Day(id: 6, name: 'Saturday'),
    const Day(id: 7, name: 'Sunday'),
  ];
  String? uniqueKey;

  @override
  void initState() {
    super.initState();
    print("📌 ClusterMeetingScreenForm → Received uniqueKey: ${widget.uniqueKey}");
    print("📌 Is Edit Mode: ${widget.isEditMode}");
    if (widget.isEditMode && widget.uniqueKey != null) {
      _loadExistingMeeting();
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

  Future<void> _showTopicsDialog() async {
    final current = Set<String>.from(_selectedTopics);
    final otherTopicText = _otherTopicController.text;
    final otherTopicController = TextEditingController(text: otherTopicText);
    bool showOtherField = current.contains('Other');

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
              backgroundColor: Colors.white,
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Select Discussion Topics",
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w400,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Divider(
                    color: Colors.grey.shade400,
                    thickness: 0.8,
                    height: 0,
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final topic in discussionTopics)
                      Column(
                        children: [
                          StatefulBuilder(
                            builder: (ctx2, _) {
                              final isChecked = current.contains(topic.name);
                              return Padding(
                                padding: const EdgeInsets.only(left: 6.0),
                                child: Transform.scale(
                                  scale: 1.0,
                                  child: CheckboxListTile(
                                    dense: true,
                                    visualDensity: const VisualDensity(vertical: -2),
                                    contentPadding: EdgeInsets.zero,
                                    title: Text(
                                      topic.name,
                                      style: const TextStyle(fontSize: 12.5),
                                    ),
                                    value: isChecked,
                                    controlAffinity: ListTileControlAffinity.leading,
                                    onChanged: (checked) {
                                      setStateDialog(() {
                                        if (checked == true) {
                                          current.add(topic.name);
                                          if (topic.name == 'Other') {
                                            showOtherField = true;
                                          }
                                        } else {
                                          current.remove(topic.name);
                                          if (topic.name == 'Other') {
                                            showOtherField = false;
                                            otherTopicController.clear();
                                          }
                                        }
                                      });
                                    },
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _selectedTopics = current;
                      _otherTopicController.text = otherTopicController.text;
                      _showOtherTopicField = current.contains('Other');
                    });
                    Navigator.of(ctx).pop();
                  },
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _loadExistingMeeting() async {
    try {
      final row = await LocalStorageDao.instance.getClusterMeetingById(widget.uniqueKey!);

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
        _ashaFacilitatorNameController.text = formJson["asha_facilitator_name"] ?? "";
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
        clusterMeetingsCount = int.tryParse(formJson["cluster_meetings_this_month"]?.toString() ?? "0") ?? 0;

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

        // Topics
        final topicsStr = formJson["discussion_topics"];
        if (topicsStr != null && topicsStr is String) {
          _selectedTopics = topicsStr.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toSet();
        }
        
        // Other Topic Details
        final otherTopic = formJson["other_topic_details"];
        if (otherTopic != null && otherTopic.isNotEmpty) {
          _otherTopicController.text = otherTopic;
          _showOtherTopicField = _selectedTopics.contains('Other');
        }
      });
    } catch (e) {
      print("Error loading meeting: $e");
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
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isEdit = widget.isEditMode;
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppHeader(
        screenTitle: "ASHA Facilitator Cluster Meeting",
        showBack: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CustomTextField(
                controller: _phcNameController,
                labelText: "PHC Name",
                hintText: "PHC Name",
                readOnly: false,
              ),
              Divider(color: AppColors.divider, thickness: 0.5),

              // Subcenter Name
              CustomTextField(
                controller: _subcenterNameController,
                labelText: "Subcenter Name",
                hintText: "Subcenter Name",
              ),
              Divider(color: AppColors.divider, thickness: 0.5),

              // ASHA Facilitator Name (pre-filled)
              CustomTextField(
                controller: _ashaFacilitatorNameController,
                labelText: "ASHA Facilitator Name",
                hintText: "ASHA Facilitator Name",
              ),
              Divider(color: AppColors.divider, thickness: 0.5),

              // ASHA Incharge Name
              CustomTextField(
                controller: _ashaInchargeNameController,
                labelText: "ASHA Incharge Name",
                hintText: "ASHA Incharge Name",
              ),
              Divider(color: AppColors.divider, thickness: 0.5),

              // AWW Name
              CustomTextField(
                controller: _awwNameController,
                labelText: "AWW Name",
                hintText: "AWW Name",
              ),
              Divider(color: AppColors.divider, thickness: 0.5),

              // AWC Number (Numeric)
              CustomTextField(
                controller: _awcNumberController,
                labelText: "AWC Number",
                hintText: "AWC Number",
                keyboardType: TextInputType.number,
              ),
              Divider(color: AppColors.divider, thickness: 0.5),

              // Village Name
              CustomTextField(
                controller: _villageNameController,
                labelText: "Village Name",
                hintText: "Village Name",
              ),
              Divider(color: AppColors.divider, thickness: 0.5),

              // Ward Name
              CustomTextField(
                controller: _wardNameController,
                labelText: "Ward Name",
                hintText: "Ward Name",
              ),
              Divider(color: AppColors.divider, thickness: 0.5),

              // Ward Number (Numeric)
              CustomTextField(
                controller: _wardNumberController,
                labelText: "Ward Number",
                hintText: "Ward Number",
                keyboardType: TextInputType.number,
              ),
              Divider(color: AppColors.divider, thickness: 0.5),

              // Block Name
              CustomTextField(
                controller: _blockNameController,
                labelText: "Block Name",
                hintText: "Block Name",
              ),
              Divider(color: AppColors.divider, thickness: 0.5),

              // Date of the Meeting
              CustomDatePicker(
                labelText: "Date of the Meeting *",
                hintText: "Date of the Meeting",
                initialDate: _meetingDate,
                onDateChanged: (date) {
                  setState(() {
                    _meetingDate = date;
                  });
                },
              ),
              Divider(color: AppColors.divider, thickness: 0.5),
              ApiDropdown<Day>(
                labelText: "Day",
                items: days,
                value: selectedDay,
                getLabel: (day) => day.name,
                hintText: "Select Day",
                onChanged: (Day? newValue) {
                  setState(() {
                    selectedDay = newValue;
                  });
                },
              ),
              Divider(color: AppColors.divider, thickness: 0.5),
              // From Time Field
              GestureDetector(
                onTap: () => _selectTime(context, true),
                child: AbsorbPointer(
                  child: CustomTextField(
                    labelText: "From (HH:MM)",
                    hintText: "From (hh:mm)",
                    initialValue: _fromTime != null ? _fromTime!.format(context) : "",
                    readOnly: true,
                  ),
                ),
              ),
              Divider(color: AppColors.divider, thickness: 0.5),
// To Time Field
              GestureDetector(
                onTap: () => _selectTime(context, false),
                child: AbsorbPointer(
                  child: CustomTextField(
                    labelText: "To (HH:MM)",
                    hintText: "To (hh:mm)",
                    initialValue: _toTime != null ? _toTime!.format(context) : "",
                    readOnly: true,
                  ),
                ),
              ),
              Divider(color: AppColors.divider, thickness: 0.5),
// 1. No. of hours
              // No. of hours (Auto-calculated)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                   Expanded(
                    child: Text(
                      "No. of hours",
                      style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
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
                      style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
              Divider(color: AppColors.divider, thickness: 0.5),
// 2. Total no. of ASHA under facilitator
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                   Expanded(
                    child: Text(
                      "Total no. of ASHA under facilitator",
                      style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
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
                    child:  Text(
                      "0",
                      style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
              Divider(color: AppColors.divider, thickness: 0.5),
// 3. No. of ASHA present in this meeting
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                   Expanded(
                    child: Text(
                      "No. of ASHA present in this meeting",
                      style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
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
                    child:  Text(
                      "0",
                      style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
              Divider(color: AppColors.divider, thickness: 0.5),
// 4. No. of ASHA absent in this meeting
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                   Expanded(
                    child: Text(
                      "No. of ASHA absent in this meeting",
                      style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
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
                    child:  Text(
                      "0",
                      style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500),
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
                      "No. of cluster meetings conducted in this month",
                      style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
                    ),
                  ),

                  Row(
                    children: [
                      // Minus Button
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            if (clusterMeetingsCount > 0) clusterMeetingsCount--;
                          });
                        },
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: clusterMeetingsCount > 0 ? AppColors.primary : Colors.grey.shade200,
                            border: Border.all(color: AppColors.divider),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                            Icons.remove,
                            size: 18,
                            color: clusterMeetingsCount > 0 ? Colors.white : Colors.white,
                          ),
                        ),
                      ),

                      const SizedBox(width: 8),

                      // Count Box
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.divider),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          clusterMeetingsCount.toString(),
                          style:  TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),

                      const SizedBox(width: 8),

                      // Plus Button
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
                    labelText: "Month",
                    hintText: "mm-yyyy",
                    initialValue: _selectedMonthYear != null
                        ? "${_selectedMonthYear!.month.toString().padLeft(2, '0')}-${_selectedMonthYear!.year}"
                        : "",
                    readOnly: true,
                  ),
                ),
              ),
              Divider(color: AppColors.divider, thickness: 0.5),
              GestureDetector(
                onTap: _showTopicsDialog,
                child: AbsorbPointer(
                  child: Stack(
                    alignment: Alignment.centerRight,
                    children: [
                      CustomTextField(
                        labelText: "Discussion Topic/Program",
                        hintText: _selectedTopics.isEmpty 
                            ? "Select Topics" 
                            : _selectedTopics.join(", "),
                        readOnly: true,
                      ),
                      const Positioned(
                        right: 12,
                        child: Icon(Icons.arrow_drop_down, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
              Divider(color: AppColors.divider, thickness: 0.5),

              if (_showOtherTopicField) ...[
                Padding(
                  padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
                  child: CustomTextField(
                    controller: _otherTopicController,
                    labelText: "Discussion Sub Topic/Program",
                    hintText: "Discussion Sub Topic/Program",
                    onChanged: (value) {
                      setState(() {});
                    },
                  ),
                ),
                Divider(color: AppColors.divider, thickness: 0.5),
              ],

              // Decision Taken During the Meeting
              CustomTextField(
                controller: _decisionTakenController,
                labelText: "Decision Taken During the Meeting",
                hintText: "Decision Taken During the Meeting",
              ),            ],
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SizedBox(
          height: 34,
          child: ElevatedButton(
            onPressed: () async {
              if (_meetingDate == null) {
                showAppSnackBar(context, "Please select Date of the Meeting");
                return;
              }

              final formData = {
                'phc_name': _phcNameController.text.trim(),
                'subcenter_name': _subcenterNameController.text.trim(),
                'asha_facilitator_name': _ashaFacilitatorNameController.text.trim(),
                'asha_incharge_name': _ashaInchargeNameController.text.trim(),
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
                'asha_present': "0",
                'asha_absent': "0",
                'cluster_meetings_this_month': clusterMeetingsCount,
                'month_year': _selectedMonthYear != null
                    ? "${_selectedMonthYear!.month.toString().padLeft(2, '0')}-${_selectedMonthYear!.year}"
                    : null,
                'discussion_topics': _selectedTopics.join(", "),
                'other_topic_details': _otherTopicController.text.trim(),
                'decision_taken': _decisionTakenController.text.trim(),
                'saved_at': DateTime.now().toIso8601String(),
              };

              try {
                if (widget.isEditMode && uniqueKey != null) {
                  await LocalStorageDao.instance.updateClusterMeeting(
                    uniqueKey: uniqueKey!,
                    formJson: formData,
                  );

                  showAppSnackBar(context, "Updated successfully!");
                } else {
                  final deviceInfo = await DeviceInfo.getDeviceInfo();
                  final newUniqueKey = await IdGenerator.generateUniqueId(deviceInfo);

                  await LocalStorageDao.instance.insertClusterMeeting({
                    'unique_key': newUniqueKey,
                    'form_json': jsonEncode(formData),
                    'created_by': 'current_user',
                  });

                  showAppSnackBar(context, "Saved successfully!");
                }

                // Go back and refresh list
                if (mounted) Navigator.pop(context);
              } catch (e) {
                showAppSnackBar(context, "Error: $e");
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            ),
            child: Text(
              isEdit ? "UPDATE" : "SAVE",
              style:  TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w600, color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }
}
