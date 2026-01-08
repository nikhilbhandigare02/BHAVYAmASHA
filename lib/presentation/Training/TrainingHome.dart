import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:medixcel_new/core/widgets/AppHeader/AppHeader.dart';
import 'package:medixcel_new/core/widgets/AppDrawer/Drawer.dart';
import 'package:medixcel_new/core/config/themes/CustomColors.dart';
import 'package:medixcel_new/core/config/routes/Route_Name.dart';
import 'package:medixcel_new/l10n/app_localizations.dart';
import 'package:sizer/sizer.dart';

import '../../core/widgets/RoundButton/RoundButton.dart';
import '../../data/Database/local_storage_dao.dart';

class TrainingHomeScreen extends StatefulWidget {
  const TrainingHomeScreen({super.key});

  @override
  State<TrainingHomeScreen> createState() => _TrainingHomeScreenState();
}

class _TrainingHomeScreenState extends State<TrainingHomeScreen> {
  List<Map<String, dynamic>> _allData = [];
  List<Map<String, dynamic>> _filtered = [];
  @override
  void initState() {
    super.initState();
    _loadTrainingData();
  }

  Future<void> _loadTrainingData() async {
    try {
      final rows = await LocalStorageDao.instance.fetchTrainingList();

      final List<Map<String, dynamic>> parsed = [];
      for (final row in rows) {
        try {
          final formJson = row['form_json'];
          if (formJson is! Map) continue;

          final data = formJson['form_data'];
          if (data is! Map) continue;

          final trainingType = (data['training_type'] ?? '').toString();

          // Keep both Received & Providing
          if (trainingType != 'Providing' && trainingType != 'Receiving') continue;

          final trainingName = (data['training_name'] ?? '').toString();
          final rawDate = data['training_date']?.toString();

          String dateStr = '';
          if (rawDate != null && rawDate.isNotEmpty) {
            final parsedDate = DateTime.tryParse(rawDate);
            if (parsedDate != null) {
              dateStr = DateFormat('dd-MM-yyyy').format(parsedDate);
            } else {
              dateStr = rawDate;
            }
          }

          final hhIdRaw = (row['household_ref_key'] ?? '').toString();
          final hhId = hhIdRaw.isNotEmpty ? hhIdRaw : 'N/A';
          final displayHhId =
          hhId.length > 11 ? hhId.substring(hhId.length - 11) : hhId;

          parsed.add({
            'trainingType': trainingType,  // 🔥 Added
            'hhId': displayHhId,
            'trainingName': trainingName,
            'Date': dateStr,
          });
        } catch (_) {
          continue;
        }
      }

      if (!mounted) return;
      setState(() {
        _allData = parsed;
        _filtered = List.from(parsed);
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    final double totalHorizontalPadding = 12 * 2;
    final double spacingBetweenCards = 8;
    final double cardWidth = (MediaQuery.of(context).size.width -
        totalHorizontalPadding -
        spacingBetweenCards) /
        3;
    final receivedCount =
        _allData.where((x) => x['trainingType'] == 'Receiving').length;


    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppHeader(
        screenTitle: l10n?.trainingTitle ?? 'Training',
        showBack: true,
      ),
      drawer: const CustomDrawer(),

      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: SizedBox(
          width: double.infinity,
          height: 45,
          child: RoundButton(
            title: (l10n?.addNewTrainingButton ?? 'Add New Training')
                .toUpperCase(),
            color: AppColors.primary,
            borderRadius: 8,
            onPress: () async {
              final result = await Navigator.pushNamed(context, Route_Names.Trainingform);
              if (result == true) {
                _loadTrainingData();
              }
            },
          ),
        ),
      ),
      body: SafeArea(
        bottom: true,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _FeatureCard(
                    width: cardWidth,
                    title: (l10n?.trainingReceivedTitle ?? 'Training Received')
                        .toString(),
                    image: 'assets/images/id-card.png',
                    count: receivedCount,
                    onClick: () {
                      Navigator.pushNamed(context, Route_Names.TrainingReceived);
                    },
                  ),
                  SizedBox(width: 8),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final String title;
  final int count;
  final String image;
  final VoidCallback onClick;
  final double width;

  const _FeatureCard({
    required this.title,
    required this.count,
    required this.image,
    required this.onClick,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    final primary = AppColors.primary;
    final double cardHeight = MediaQuery.of(context).orientation == Orientation.portrait
        ? 15.h
        : 22.h;
    final scaleFactor = MediaQuery.of(context).textScaleFactor;
    return InkWell(
      onTap: onClick,
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: width,
        height: cardHeight,
        child: Card(
          elevation: 3,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          child: Padding(
            padding: EdgeInsets.all(1.h),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Image.asset(
                      image,
                      width: 28 * scaleFactor,
                      height: 28 * scaleFactor,
                      fit: BoxFit.contain,
                    ),
                    const Spacer(),
                    Text(
                      '$count',
                      style: TextStyle(
                        color: primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 14.sp,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 1.5.h),
                Text(
                  title,
                  textAlign: TextAlign.left,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: AppColors.outline,
                    fontSize: 14.sp,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
