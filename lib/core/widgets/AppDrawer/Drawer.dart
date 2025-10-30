import 'package:flutter/material.dart';
import 'package:medixcel_new/core/config/routes/Route_Name.dart';
import '../../../presentation/HomeScreen/HomeScreen.dart';
import '../ConfirmationDialogue/ConfirmationDialogue.dart';
import '../RoundButton/RoundButton.dart';
import 'package:medixcel_new/l10n/app_localizations.dart';
import 'package:sizer/sizer.dart';

class CustomDrawer extends StatelessWidget {
  const CustomDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 2.w),
          child: Column(
            children: [
              // Top logo
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 0.5.h),
                child: Column(
                  children: [
                    Image.asset(
                      'assets/images/bhabya-logo.png',
                      width: 30.w,
                      height: 13.h,
                      fit: BoxFit.contain,
                    ),
                  ],
                ),
              ),
              Divider(color: Theme.of(context).colorScheme.primary, thickness: 0.8),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    _buildMenuItem(context, 'assets/images/home.png', l10n.drawerHome, onTap: () {Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => HomeScreen(initialTabIndex: 1),
                      ),
                    );}),
                    _buildMenuItem(context, 'assets/images/sam_mgmt.png', l10n.drawerProfile, onTap: () {Navigator.pushNamed(context, Route_Names.profileScreen);}),
                    _buildMenuItem(context, 'assets/images/notes.png', l10n.drawerMisReport, onTap: () {Navigator.pushNamed(context, Route_Names.MISScreen);}),
                    _buildMenuItem(context, 'assets/images/rupee.png', l10n.drawerIncentivePortal, onTap: () {Navigator.pushNamed(context, Route_Names.incentivePortal);}),
                    _buildMenuItem(context, 'assets/images/fetch.png', l10n.drawerFetchData, onTap: () {}),
                    _buildMenuItem(context, 'assets/images/refresh-button.png', l10n.drawerSyncedData, onTap: () {Navigator.pushNamed(context, Route_Names.SyncStatusScreen);}),
                    _buildMenuItem(context, 'assets/images/reset_password.png', l10n.drawerResetPassword, onTap: () {Navigator.pushNamed(context, Route_Names.Resetpassword);}),
                    _buildMenuItem(context, 'assets/images/setting.png', l10n.drawerSettings, onTap: () {Navigator.pushNamed(context, Route_Names.setting);}),
                    _buildMenuItem(context, 'assets/images/information.png', l10n.drawerAboutUs, onTap: () {Navigator.pushNamed(context, Route_Names.aboutUs);}),
                    Divider(color: Theme.of(context).colorScheme.primary, thickness: 0.8),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4.w),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _UserInfoRow(label: l10n.userNameLabel, value: "Rohit Chavan"),
                          _UserInfoRow(label: l10n.userRoleLabel, value: "Bhavya ASHA"),
                          _UserInfoRow(label: l10n.userVillageLabel, value: "-"),
                          _UserInfoRow(label: l10n.userHscLabel, value: "HSC Baank"),
                          _UserInfoRow(label: l10n.userHfrIdLabel, value: "IN1010001604"),
                          SizedBox(height: 0.5.h),
                          Text("V 7.8.10", style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13.sp)),
                        ],
                      ),
                    ),
                    SizedBox(height: 2.h),
                  ],
                ),
              ),

              Padding(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 1.h),
                child: SizedBox(
                  width: double.infinity,
                  height: 4.5.h,
                  child: RoundButton(
                    title: l10n.drawerLogout,
                    onPress: () {
                      showConfirmationDialog(
                        context: context,
                        title: l10n.logoutTitle,
                        message: l10n.logoutMessage,
                        yesText: l10n.yes,
                        noText: l10n.no,
                        onYes: () {
                          Navigator.pushNamedAndRemoveUntil(context, Route_Names.loginScreen, (Route<dynamic> route) => false,);
                        },
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, String imagePath, String title, {VoidCallback? onTap}) {
    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 0.5.h),
      dense: true,
      visualDensity: VisualDensity(vertical: -2),
      minLeadingWidth: 6.w,
      leading: Image.asset(
        imagePath,
        width: 8.w,
        height: 8.w,
        fit: BoxFit.contain,
      ),
      title: Text(
        title,
        style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500),
      ),
      onTap: onTap,
    );
  }
}

class _UserInfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _UserInfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 0.3.h),
      child: Row(
        children: [
          SizedBox(
            width: 30.w,
            child: Text(
              label,
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontSize: 13.sp,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 13.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
