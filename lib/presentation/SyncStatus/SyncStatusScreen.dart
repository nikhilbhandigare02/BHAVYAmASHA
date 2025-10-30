import 'package:flutter/material.dart';
import 'package:medixcel_new/core/config/themes/CustomColors.dart';
import 'package:sizer/sizer.dart';

class SyncStatusScreen extends StatelessWidget {
  const SyncStatusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Sizer(
      builder: (context, orientation, deviceType) {
        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: AppColors.primary,
            elevation: 0,
            title: const Text(
              'Sync Status',
              style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: Padding(
            padding: EdgeInsets.all(3.w),
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color:AppColors.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: EdgeInsets.all(2.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sync Status',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 2.h),

                    // Compact Grid
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 1.5.h,
                      crossAxisSpacing: 3.w,
                      childAspectRatio: 1.5, // 🔹 reduces height of grid boxes
                      children: const [
                        SyncCard(title: 'Household', total: 22, synced: 22),
                        SyncCard(title: 'Beneficiary', total: 52, synced: 52),
                        SyncCard(title: 'Follow Up', total: 18, synced: 3),
                        SyncCard(title: 'Eligible Couple', total: 19, synced: 19),
                        SyncCard(title: 'Mother Care', total: 14, synced: 14),
                        SyncCard(title: 'Child Care', total: 0, synced: 0),
                      ],
                    ),

                    SizedBox(height: 3.h),
                    Row(
                      children: [
                        Text(
                          'Last synced at: 29-10-2025 10:38am ',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Icon(Icons.check_circle, color: Colors.white, size: 18),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class SyncCard extends StatelessWidget {
  final String title;
  final int total;
  final int synced;

  const SyncCard({
    super.key,
    required this.title,
    required this.total,
    required this.synced,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.5.h),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15.sp,
                color: Colors.blue[800],
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 0.9.h),
            Text(
              'Total: $total',
              style: TextStyle(
                fontSize: 15.sp,
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 0.9.h),

            Text(
              'Synced: $synced',
              style: TextStyle(
                fontSize: 15.sp,
                color: Colors.blue[800],
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
