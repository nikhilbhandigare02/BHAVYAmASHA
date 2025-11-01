import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:medixcel_new/core/config/themes/CustomColors.dart';
import 'package:medixcel_new/core/widgets/AppHeader/AppHeader.dart';
import 'package:medixcel_new/core/widgets/RoundButton/RoundButton.dart';
import 'package:sizer/sizer.dart';

import '../../../core/widgets/TextField/TextField.dart';
import 'bloc/Malaria_Bloc/malaria_bloc.dart';

class MalariaScreen extends StatelessWidget {
  const MalariaScreen({super.key});

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
      create: (_) => MalariaBloc(),
      child: BlocBuilder<MalariaBloc, MalariaState>(
        builder: (context, state) {
          final bloc = context.read<MalariaBloc>();

          // ✅ Questions for Malaria Screening
          final List<Map<String, dynamic>> questions = [
            {
              'question': '1. For blood smear collection and testing of fever cases (per case)',
              'hint': '0',
            },
            {
              'question': '2. For complete treatment of positive cases (per case)',
              'hint': '0',
            },
          ];

          // ✅ Date setup
          final now = DateTime.now();
          final int daysInMonth = getDaysInMonth(now.year, now.month);
          final String formattedDate =
              "${now.day.toString().padLeft(2, '0')}-${now.month.toString().padLeft(2, '0')}-${now.year}";

          return Scaffold(
            backgroundColor: Colors.grey[100],
            appBar: AppHeader(
              screenTitle: 'Malaria Screening',
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
                      // ✅ Header with full primary background
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
                              'Screening Date: $formattedDate',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // ✅ Questions
                      ...List.generate(
                        questions.length,
                        (index) => Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 3.w,
                            vertical: 1.5.h,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Question Number
                              Container(
                                width: 6.w,
                                alignment: Alignment.topCenter,
                                child: Text(
                                  '${index + 1}.',
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                              SizedBox(width: 2.w),

                              // Question Text
                              Expanded(
                                child: Text(
                                  questions[index]['question'].toString(),
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),

                              SizedBox(width: 2.w),

                              // Answer Field
                              SizedBox(
                                width: 15.w,
                                child: CustomTextField(
                                  hintText: questions[index]['hint'],
                                  onChanged: (value) {
                                    bloc.add(UpdateMalariaField(index, value));
                                  },
                                  initialValue: state.values[index],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      SizedBox(height: 3.h),

                      // ✅ Submit Button
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 3.w),
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: RoundButton(
                            width: 15.h,
                            onPress: () {
                              bloc.add(const SaveMalariaData());
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Screening data saved successfully!'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            },
                            title: 'Submit',
                            isLoading: false,
                          ),
                        ),
                      ),
                      SizedBox(height: 2.h),
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