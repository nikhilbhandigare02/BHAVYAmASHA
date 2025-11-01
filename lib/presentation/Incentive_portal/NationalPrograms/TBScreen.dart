import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:medixcel_new/core/config/themes/CustomColors.dart';
import 'package:medixcel_new/core/widgets/AppHeader/AppHeader.dart';
import 'package:medixcel_new/core/widgets/RoundButton/RoundButton.dart';
import 'package:sizer/sizer.dart';

import '../../../core/widgets/TextField/TextField.dart';
import 'bloc/TB_Bloc/TB_Bloc.dart';

class TbProgramScreen extends StatelessWidget {
  const TbProgramScreen({super.key});

  // ✅ Utility to calculate days in a given month
  int getDaysInMonth(int year, int month) {
    if (month == 2) {
      if (year % 4 == 0 && (year % 100 != 0 || year % 400 == 0)) {
        return 29;
      } else {
        return 28;
      }
    } else if ([4, 6, 9, 11].contains(month)) {
      return 30;
    } else {
      return 31;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => TbBloc(),
      child: BlocBuilder<TbBloc, TbState>(
        builder: (context, state) {
          final bloc = context.read<TbBloc>();

          // ✅ Only label text (no numbering inside)
          final List<String> labels = [
            'प्रथम सूचक कार्य/संपर्क खोज अभियान (नये क्षयमा मरीज को नोटिफाई करने हेतु लेन पर)',
            'ट्रीटमेंट प्रोवाइडर कार्य',
            'प्रति Drug Sensitive क्षयमा मरीज अथवा प्रति Shorter regimen के Drug Resistant क्षयमा मरीज को दवा खिलाने पर',
            'Conventional MDR इलाजरत Drug Resistant क्षयमा मरीज को दवा खिलाने (रु 2000 - Intensive Phase पर)।',
          ];

          // ✅ Date setup
          final now = DateTime.now();
          final int daysInMonth = getDaysInMonth(now.year, now.month);
          final String formattedDate =
              "${now.day.toString().padLeft(2, '0')}-${now.month.toString().padLeft(2, '0')}-${now.year}";

          return Scaffold(
            backgroundColor: Colors.grey[100],
            appBar: AppHeader(
              screenTitle: 'क्षयमा (टी.बी.) उन्मूलन कार्यक्रम',
              showBack: true,
            ),
            body: Padding(
              padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 2.h),
              child: SingleChildScrollView(
                child: Card(
                  color: AppColors.background,
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        color: AppColors.primary,
                        padding: EdgeInsets.symmetric(
                          horizontal: 3.w,
                          vertical: 1.h,
                        ),
                        child: Row(
                          children: [
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                const Icon(
                                  Icons.calendar_today,
                                  color: Colors.white,
                                  size: 24,
                                ),
                                Positioned(
                                  bottom: 2,
                                  child: Text(
                                    daysInMonth.toString(),
                                    style: TextStyle(
                                      fontSize: 13.sp,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.yellowAccent,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(width: 2.w),
                            Text(
                              formattedDate,
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),

                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 3.w,
                          vertical: 2.h,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (int i = 0; i < labels.length; i++) ...[
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${i + 1}.',
                                    style: TextStyle(
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(width: 10),

                                  Expanded(
                                    child: Text(
                                      labels[i],
                                      style: TextStyle(
                                        fontSize: 14.sp,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),

                                  SizedBox(
                                    width: 12.w,
                                    child: CustomTextField(
                                      initialValue: state.values[i],
                                      keyboardType: TextInputType.number,
                                      onChanged: (val) =>
                                          bloc.add(UpdateTbField(i, val)),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 1.5.h),
                            ],
                            SizedBox(height: 2.h),
                            Align(
                              alignment: Alignment.centerRight,
                              child: RoundButton(
                                width: 14.h,
                                title: 'संरक्षित करें',
                                onPress: () {
                                  bloc.add(SaveTbData());
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content:
                                      Text('डेटा सफलतापूर्वक सहेजा गया'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
