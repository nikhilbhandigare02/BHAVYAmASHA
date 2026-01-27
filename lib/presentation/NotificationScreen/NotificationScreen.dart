import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/config/themes/CustomColors.dart';
import '../../core/widgets/AppHeader/AppHeader.dart';
import '../../data/Database/local_storage_dao.dart';
import '../../data/repositories/NotificationRepository/Notification_Repository.dart';
import '../../l10n/app_localizations.dart';

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
      debugPrint(
          'NotificationScreen: error while fetching notifications → $e');
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
        return DateFormat("dd-MM-yyyy").parse(value.toString());
      } catch (_) {
        try {
          return DateFormat("yyyy-MM-dd HH:mm:ss")
              .parse(value.toString());
        } catch (_) {
          return DateTime.now();
        }
      }
    }
  }

  String stripHtmlTags(String htmlText) {
    final exp =
    RegExp(r'<[^>]*>', multiLine: true, caseSensitive: false);
    return htmlText.replaceAll(exp, '').trim();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context);
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppHeader(
          screenTitle: l10n.notifications,
          showBack: true,
        ),
        body: FutureBuilder<List<Map<String, dynamic>>>(
          future: _notificationFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState ==
                ConnectionState.waiting) {
              return const Center(
                  child: CircularProgressIndicator());
            }

            final allNotifications = snapshot.data ?? [];
            final now = DateTime.now();

            final notifications = allNotifications.where((n) {
              final start =
              _parseDate(n['announcement_start_period']);
              final end =
              _parseDate(n['announcement_end_period']);
              return !now.isBefore(start) &&
                  !now.isAfter(end);
            }).toList();

            if (notifications.isEmpty) {
              return Center(
                child: Text(
                  l10n.noNotificationsFound ??
                      "No notifications found.",
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final n = notifications[index];

                return NotificationCard(
                  title: n['title_en'] ?? '',
                  content:
                  stripHtmlTags(n['content_en'] ?? ''),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class NotificationCard extends StatelessWidget {
  final String title;
  final String content;

  const NotificationCard({
    Key? key,
    required this.title,
    required this.content,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 1,
            spreadRadius: 0.5,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
        ),
        child: ExpansionTile(
          dense: true,
          visualDensity:
          const VisualDensity(horizontal: -4, vertical: -4),

          tilePadding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          childrenPadding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 6),

          iconColor: AppColors.primary,
          collapsedIconColor: AppColors.primary,

          // 🚫 REMOVE TOP & BOTTOM BORDERS
          shape: const RoundedRectangleBorder(
            side: BorderSide.none,
          ),
          collapsedShape: const RoundedRectangleBorder(
            side: BorderSide.none,
          ),

          title: Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                content,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[700],
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
