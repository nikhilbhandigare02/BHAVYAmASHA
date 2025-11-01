import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:medixcel_new/core/config/themes/CustomColors.dart';
import 'package:medixcel_new/core/widgets/AppHeader/AppHeader.dart';
import 'package:medixcel_new/core/widgets/RoundButton/RoundButton.dart';
import 'package:sizer/sizer.dart';

import '../../../core/widgets/TextField/TextField.dart';
import 'bloc/leprosy_bloc/leprosy_bloc.dart';

class LeprosyScreen extends StatelessWidget {
  const LeprosyScreen({super.key});

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
      create: (_) => LeprosyBloc(),
      child: BlocBuilder<LeprosyBloc, LeprosyState>(
        builder: (context, state) {
          final bloc = context.read<LeprosyBloc>();

          // ✅ Questions for Leprosy Screening
          final List<Map<String, dynamic>> questions = [
            {
              'question': '1. क्या आपको शरीर के किसी भाग में सफेद या लाल रंग के धब्बे है?',
              'hint': 'हाँ/नहीं',
            },
            {
              'question': '2. क्या आपको शरीर के किसी भाग में सुन्नपन या झुनझुनी का अनुभव होता है?',
              'hint': 'हाँ/नहीं',
            },
            {
              'question': '3. क्या आपको किसी अंग में कमजोरी या लकवा का अनुभव हुआ है?',
              'hint': 'हाँ/नहीं',
            },
            {
              'question': '4. क्या आपके परिवार में किसी को कुष्ठ रोग हुआ है?',
              'hint': 'हाँ/नहीं',
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
              screenTitle: 'कुष्ठ रोग स्क्रीनिंग',
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
                              'स्क्रीनिंग दिनांक: $formattedDate',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 2.h),
                      ...List.generate(
                        questions.length,
                        (index) => Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 3.w,
                            vertical: 1.h,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                width: 6.w,
                                alignment: Alignment.center,
                                child: Text(
                                  '${index + 1}.'
                                ),
                              ),
                              SizedBox(width: 1.w),
                              Expanded(
                                child: Text(
                                  questions[index]['question'].toString().replaceFirst('${index + 1} ', '').trim(),
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                              SizedBox(width: 2.w),
                              Container(
                                width: 10.w,
                                child: CustomTextField(
                                  hintText: questions[index]['hint'],
                                  onChanged: (value) {
                                    bloc.add(UpdateLeprosyField(index, value));
                                  },
                                  initialValue: state.values[index],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 3.h),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 3.w),
                        child: RoundButton(
                          onPress: () {
                            bloc.add(const SaveLeprosyData());
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('स्क्रीनिंग डेटा सफलतापूर्वक सहेजा गया!'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          },
                          title: 'सबमिट करें',
                          isLoading: false,
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
