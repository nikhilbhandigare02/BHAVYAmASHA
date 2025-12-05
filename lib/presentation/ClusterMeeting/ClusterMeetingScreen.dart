import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sizer/sizer.dart';
import '../../core/widgets/AppHeader/AppHeader.dart';
import '../../data/Database/local_storage_dao.dart';
import '../../l10n/app_localizations.dart';
import 'ClusterMeetingScreenForm.dart';

class ClusterMeetingScreen extends StatefulWidget {
  const ClusterMeetingScreen({super.key});

  @override
  State<ClusterMeetingScreen> createState() => _ClusterMeetingScreenState();
}

class _ClusterMeetingScreenState extends State<ClusterMeetingScreen> {


  List<Map<String, dynamic>> meetings = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMeetings();
  }


  Map<String, dynamic> normalizeFormJson(dynamic raw) {
    if (raw == null) return {};

    // Case 1: already a Map
    if (raw is Map<String, dynamic>) return raw;

    // Case 2: JSON string
    if (raw is String) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) return decoded;
      } catch (e) {
        print("Failed to decode form_json: $e");
      }
      return {};
    }

    // Case 3: unexpected type
    try {
      return jsonDecode(raw.toString());
    } catch (e) {
      return {};
    }
  }

  Future<void> _loadMeetings() async {
    final data = await LocalStorageDao.instance.getAllClusterMeetings();

    meetings = data.map((row) {
      // FIX: Decode the JSON string to Map
      Map<String, dynamic> form = {};
      try {
        form = normalizeFormJson(row["form_json"]);
      } catch (e) {
        print("Error decoding form_json: $e");
        form = {};
      }

      // Format meeting date to dd-MM-yyyy
      String formattedDate = "No date";
      if (form["meeting_date"] != null) {
        try {
          DateTime dt = DateTime.parse(form["meeting_date"]);
          formattedDate = DateFormat('dd-MM-yyyy').format(dt);
        } catch (e) {
          formattedDate = form["meeting_date"].toString();
        }
      }

      // Get the full unique key
      final fullKey = row["unique_key"]?.toString() ?? "";
      // Show only last 11 digits, or full key if shorter than 11 characters
      final displayKey = fullKey.length <= 11 ? fullKey : fullKey.substring(fullKey.length - 11);
      
      return {
        "title": displayKey,
        "fullTitle": fullKey, // Keep full key in case it's needed elsewhere
        "date": formattedDate,
        "facilitator": form["asha_facilitator_name"]?.toString() ?? "Not specified",
      };
    }).toList();

    setState(() {
      isLoading = false;
    });
  }
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppHeader(
        screenTitle:  l10n?.ashaFacilitatorClusterMeetingList ?? "ASHA Facilitator Cluster Meeting List",
        showBack: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : meetings.isEmpty
          ? Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(height: 20), // space below app bar
          Center(
            child: Text(
              l10n?.noRecordFound ?? "No Record Found",
              style: TextStyle(
                fontSize: 15.sp,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade500,
              ),
            ),
          ),
        ],
      )
          : Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              itemCount: meetings.length,
              itemBuilder: (context, index) {
                return _meetingCard(context, meetings[index]);
              },
            ),
          ),
        ],
      ),




      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SizedBox(
          height: 34,
          child: ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ClusterMeetingScreenForm()),
              ).then((_) {
                setState(() => isLoading = true); // show loader immediately

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _loadMeetings(); // reload list
                });
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            child:  Text(
             l10n?.addNewClusterMeeting ??  "ADD NEW CLUSTER MEETING",
              style: TextStyle(
                fontSize: 15.sp,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _meetingCard(BuildContext context, Map<String, dynamic> data) {
    final Color primary = Theme.of(context).primaryColor;
    final l10n = AppLocalizations.of(context);

    return InkWell(  // Makes it clickable with ripple effect
      borderRadius: BorderRadius.circular(4),
      onTap: () {
        final String uniqueKey = data["fullTitle"];
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ClusterMeetingScreenForm(
              uniqueKey: uniqueKey,        // Only pass the ID
              isEditMode: true,
            ),
          ),
        ).then((_) {
        setState(() => isLoading = true); // show loader immediately

        WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadMeetings();
        });
        });
        // Refresh list after edit
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 1, spreadRadius: 1, offset: const Offset(0, 1)),
            BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 1, spreadRadius: 1, offset: const Offset(0, -1)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              ),
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Icon(Icons.home, color: primary, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    data["title"],
                    style: TextStyle(color: primary, fontWeight: FontWeight.w600, fontSize: 14.sp),
                  ),
                ],
              ),
            ),
            // Body
            Container(
              decoration: BoxDecoration(
                color: primary.withOpacity(0.95),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(4)),
              ),
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _rowSingle(data["facilitator"].toString().isNotEmpty
                      ? data["facilitator"]
                      : (l10n?.facilitatorNotSpecified ?? "Facilitator not specified")),
                  const SizedBox(height: 4),
                  _row("${l10n?.dateLabel ?? "Date"}:", data["date"]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _rowSingle(String text) {
    return Text(
      text,
      style:  TextStyle(
        fontSize: 14.sp,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
    );
  }
  Widget _row(String title, String value) {
    return Row(
      children: [
        Text(
          title,
          style:  TextStyle(
            fontSize: 13.sp,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style:  TextStyle(
              fontSize: 13.sp,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

}
