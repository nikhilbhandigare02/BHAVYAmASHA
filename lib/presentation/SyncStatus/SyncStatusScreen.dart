import 'package:flutter/material.dart';
import 'package:medixcel_new/core/config/themes/CustomColors.dart';
import 'package:sizer/sizer.dart';
import 'package:medixcel_new/data/Database/local_storage_dao.dart';

class SyncStatusScreen extends StatefulWidget {
  const SyncStatusScreen({super.key});

  @override
  State<SyncStatusScreen> createState() => _SyncStatusScreenState();
}

class _SyncStatusScreenState extends State<SyncStatusScreen> {
  bool _isLoading = true;

  int _householdTotal = 0;
  int _householdSynced = 0;
  int _beneficiaryTotal = 0;
  int _beneficiarySynced = 0;
  int _followupTotal = 0;
  int _followupSynced = 0;
  int _eligibleCoupleTotal = 0;
  int _eligibleCoupleSynced = 0;
  int _motherCareTotal = 0;
  int _motherCareSynced = 0;
  int _childCareTotal = 0;
  int _childCareSynced = 0;

  @override
  void initState() {
    super.initState();
    _loadCounts();
  }

  Future<void> _loadCounts() async {
    try {
      final dao = LocalStorageDao.instance;

      final householdTotal = await dao.getHouseholdTotalCountLocal();
      final householdSynced = await dao.getHouseholdSyncedCountLocal();

      final beneficiaryTotal = await dao.getBeneficiaryTotalCountLocal();
      final beneficiarySynced = await dao.getBeneficiarySyncedCountLocal();

      final followupTotal = await dao.getFollowupTotalCountLocal();
      final followupSynced = await dao.getFollowupSyncedCountLocal();

      final eligibleTotal = await dao.getEligibleCoupleTotalCountLocal();
      final eligibleSynced = await dao.getEligibleCoupleSyncedCountLocal();

      final motherTotal = await dao.getMotherCareTotalCountLocal();
      final motherSynced = await dao.getMotherCareSyncedCountLocal();

      final childTotal = await dao.getChildCareTotalCountLocal();
      final childSynced = await dao.getChildCareSyncedCountLocal();

      if (!mounted) return;

      setState(() {
        _householdTotal = householdTotal;
        _householdSynced = householdSynced;
        _beneficiaryTotal = beneficiaryTotal;
        _beneficiarySynced = beneficiarySynced;
        _followupTotal = followupTotal;
        _followupSynced = followupSynced;
        _eligibleCoupleTotal = eligibleTotal;
        _eligibleCoupleSynced = eligibleSynced;
        _motherCareTotal = motherTotal;
        _motherCareSynced = motherSynced;
        _childCareTotal = childTotal;
        _childCareSynced = childSynced;
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Sizer(
      builder: (context, orientation, deviceType) {
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.primary,
            elevation: 0,
            title:  Text(
              'Sync Status',
              style: TextStyle(fontWeight: FontWeight.w600, color:AppColors.background),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(3.w),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Padding(
                  padding: EdgeInsets.all(3.w),
                  child: _isLoading
                      ? Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 4.h),
                            child: const CircularProgressIndicator(color: Colors.white),
                          ),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
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

                            GridView.count(
                              crossAxisCount: 2,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              mainAxisSpacing: 1.5.h,
                              crossAxisSpacing: 3.w,
                              childAspectRatio: 1.5,
                              children: [
                                SyncCard(title: 'Household', total: _householdTotal, synced: _householdSynced),
                                SyncCard(title: 'Beneficiary', total: _beneficiaryTotal, synced: _beneficiarySynced),
                                SyncCard(title: 'Follow Up', total: _followupTotal, synced: _followupSynced),
                                SyncCard(title: 'Eligible Couple', total: _eligibleCoupleTotal, synced: _eligibleCoupleSynced),
                                SyncCard(title: 'Mother Care', total: _motherCareTotal, synced: _motherCareSynced),
                                SyncCard(title: 'Child Care', total: _childCareTotal, synced: _childCareSynced),
                              ],
                            ),

                            SizedBox(height: 2.h),
                            Row(
                              children: [
                                Text(
                                  'Last synced at: 29-10-2025 10:38am',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(Icons.check_circle, color: Colors.white, size: 18),
                              ],
                            ),
                          ],
                        ),
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
      color: Colors.white,
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
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 0.8.h),
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: 'Total: ',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Colors.blue[800],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  TextSpan(
                    text: '$total',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Colors.black,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 0.5.h),
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: 'Synced: ',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Colors.blue[800],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  TextSpan(
                    text: '$synced',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Colors.black,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            )

          ],
        ),
      ),
    );
  }
}
