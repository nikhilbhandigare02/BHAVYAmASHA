import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/config/themes/CustomColors.dart';
import '../../data/Local_Storage/local_storage_dao.dart';
import '../../data/repositories/NotificationRepository/Notification_Repository.dart';

class Notificationscreen extends StatefulWidget {
  const Notificationscreen({super.key});

  @override
  State<Notificationscreen> createState() => _NotificationscreenState();
}

class _NotificationscreenState extends State<Notificationscreen> {
  late Future<List<Map<String, dynamic>>> _notificationFuture;

  @override
  void initState() {
    super.initState();
    _notificationFuture = Future.value([]);
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      await NotificationRepository().fetchAndSaveNotifications();
    } catch (e) {
      // Log the error but do not crash the screen
      debugPrint('NotificationScreen: error while fetching notifications → $e');
    }
    setState(() {
      _notificationFuture = LocalStorageDao.instance.getNotifications();
    });
  }

  DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();

    try {
      return DateTime.parse(value.toString());
    } catch (_) {
      try {
        return DateFormat("dd-MM-yyyy").parse(value);
      } catch (_) {
        try {
          return DateFormat("yyyy-MM-dd HH:mm:ss").parse(value);
        } catch (_) {
          return DateTime.now(); // Last fallback
        }
      }
    }
  }

  String stripHtmlTags(String htmlText) {
    final exp = RegExp(r'<[^>]*>', multiLine: true, caseSensitive: false);
    return htmlText.replaceAll(exp, '').trim();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context);
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          title: const Text("Notifications", style: TextStyle(color: Colors.white)),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: FutureBuilder<List<Map<String, dynamic>>>(
          future: _notificationFuture,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final notifications = snapshot.data ?? [];

            if (notifications.isEmpty) {
              return const Center(child: Text("No notifications found."));
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final n = notifications[index];
                final plainText = stripHtmlTags(n["content_en"] ?? "");

                return NotificationCard(          // ← NEW CARD
                  title: n["title_en"] ?? "",
                  content: plainText,
                  date: _parseDate(n["announcement_start_period"]),

                );
              },
            );
          },
        ),
      ),
    );
  }

  String _truncateText(String text, int maxLines) {
    const int charsPerLine = 80;
    final int maxChars = maxLines * charsPerLine;
    if (text.length <= maxChars) return text;
    return text.substring(0, maxChars).trim() + "...";
  }
}

class NotificationCard extends StatefulWidget {
  final String title;
  final String content;
  final DateTime date;

  const NotificationCard({
    Key? key,
    required this.title,
    required this.content,
    required this.date,
  }) : super(key: key);

  @override
  State<NotificationCard> createState() => _NotificationCardState();
}

class _NotificationCardState extends State<NotificationCard> {
  bool isExpanded = false;

  static const int maxLinesCollapsed = 2;

  @override
  Widget build(BuildContext context) {
    final bool needReadMore = widget.content.length > 80;

    final String formattedDate =
    DateFormat('dd-MM-yyyy').format(widget.date);

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            spreadRadius: 1,
            offset: Offset(0, 2),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                 widget.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              SizedBox(width: 2),
              IntrinsicWidth(
                child: Text(
                  formattedDate,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.primary,
                  ),
                  overflow: TextOverflow.visible,
                ),
              ),
            ],
          ),
           SizedBox(height: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                isExpanded ? widget.content : widget.content,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                  height: 1.5,
                ),
                maxLines: isExpanded ? null : 1,
                overflow: isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              if (needReadMore)
                GestureDetector(
                  onTap: () => setState(() => isExpanded = !isExpanded),
                  child: Text(
                    isExpanded ? "Read less" : "Read more",
                    style:  TextStyle(
                      color:Colors.grey[500],
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          )
        ],
      ),
    );
  }

  // Truncate to N lines
  String _truncateText(String text, int lines) {
    const int charsPerLine = 70;
    final int maxChars = charsPerLine * lines;

    if (text.length <= maxChars) return text;
    return text.substring(0, maxChars).trim() + "...";
  }
}
