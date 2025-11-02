import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:medixcel_new/core/config/themes/CustomColors.dart';
import 'package:medixcel_new/core/widgets/AppHeader/AppHeader.dart';

class PreviousVisitsScreen extends StatelessWidget {
  const PreviousVisitsScreen({super.key});

  @override
  Widget build(BuildContext context) {


    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppHeader(
        screenTitle: 'Previous Visits',
        showBack: false,
       // showClose: true, // close icon at right
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 2.h),
        child: Card(
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
            child: Column(
            //  crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Table Header
                Container(
                  padding: EdgeInsets.symmetric(vertical: 1.h),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.grey.shade300, width: 1),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: Text(
                          'Sr No.',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13.sp,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          'Visit Date',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13.sp,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 1.h),


              ],
            ),
          ),
        ),
      ),
    );
  }
}
