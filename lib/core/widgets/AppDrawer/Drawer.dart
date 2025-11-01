import 'package:flutter/material.dart';
import 'package:medixcel_new/core/config/routes/Route_Name.dart';
import '../../../data/SecureStorage/SecureStorage.dart';
import '../../../presentation/HomeScreen/HomeScreen.dart';
import '../../utils/app_version.dart';
import '../ConfirmationDialogue/ConfirmationDialogue.dart';
import 'package:medixcel_new/l10n/app_localizations.dart';
import 'package:sizer/sizer.dart';
import 'dart:convert';

class CustomDrawer extends StatefulWidget {
  const CustomDrawer({super.key});

  @override
  State<CustomDrawer> createState() => _CustomDrawerState();
}

class _CustomDrawerState extends State<CustomDrawer> {
  Map<String, dynamic>? userData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadAppVersion();

  }

  Future<void> _loadAppVersion() async {
    final version = await AppVersion.getAppVersion();
    if (mounted) {
      setState(() {
        _appVersion = version;
      });
    }
  }
  Future<void> _loadUserData() async {
    if (mounted) {
      setState(() => isLoading = true);
    }
    
    try {
      print('Loading user data...');
      final data = await SecureStorageService.getCurrentUserData();
      print('Loaded user data: $data');
      
      if (mounted) {
        setState(() {
          userData = data;
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error in _loadUserData: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  String _getFullName() {
    if (userData == null) return '-';
    try {
      // Try to get name from nested structure
      if (userData!['name'] is Map) {
        final name = userData!['name'] as Map;
        return '${name['first_name'] ?? ''} ${name['middle_name'] ?? ''} ${name['last_name'] ?? ''}'.trim().replaceAll('  ', ' ');
      }
      // Fallback to direct fields if not in nested structure
      return '${userData!['first_name'] ?? ''} ${userData!['middle_name'] ?? ''} ${userData!['last_name'] ?? ''}'.trim().replaceAll('  ', ' ');
    } catch (e) {
      print('Error getting full name: $e');
      return '-';
    }
  }

  String _getWorkingLocation(String key) {
    if (userData == null) return '-';
    try {
      // Try to get from nested working_location
      if (userData!['working_location'] is Map) {
        final workingLocation = userData!['working_location'] as Map;
        return workingLocation[key]?.toString() ?? '-';
      }
      return userData![key]?.toString() ?? '-';
    } catch (e) {
      print('Error getting working location ($key): $e');
      return '-';
    }
  }

  String _appVersion = ''; // Default version


  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            // 🔹 Top Logo
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 2.w),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: 0.5.h),
                    child: Image.asset(
                      'assets/images/bhabya-logo.png',
                      width: 30.w,
                      height: 13.h,
                      fit: BoxFit.contain,
                    ),
                  ),
                  Divider(
                    color: Theme.of(context).colorScheme.primary,
                    thickness: 0.8,
                  ),
                ],
              ),
            ),

            // 🔹 Drawer Items List
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _buildMenuItem(context, 'assets/images/home.png', l10n.drawerHome, onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => HomeScreen(initialTabIndex: 1),
                      ),
                    );
                  }),
                  _buildMenuItem(context, 'assets/images/sam_mgmt.png', l10n.drawerProfile, onTap: () {
                    Navigator.pushNamed(context, Route_Names.profileScreen);
                  }),
                  _buildMenuItem(context, 'assets/images/notes.png', l10n.drawerMisReport, onTap: () {
                    Navigator.pushNamed(context, Route_Names.MISScreen);
                  }),
                  _buildMenuItem(context, 'assets/images/rupee.png', l10n.drawerIncentivePortal, onTap: () {
                    Navigator.pushNamed(context, Route_Names.incentivePortal);
                  }),
                  _buildMenuItem(context, 'assets/images/fetch.png', l10n.drawerFetchData, onTap: () {}),
                  _buildMenuItem(context, 'assets/images/refresh-button.png', l10n.drawerSyncedData, onTap: () {
                    Navigator.pushNamed(context, Route_Names.SyncStatusScreen);
                  }),
                  _buildMenuItem(context, 'assets/images/reset_password.png', l10n.drawerResetPassword, onTap: () {
                    Navigator.pushNamed(context, Route_Names.Resetpassword);
                  }),
                  _buildMenuItem(context, 'assets/images/setting.png', l10n.drawerSettings, onTap: () {
                    Navigator.pushNamed(context, Route_Names.setting);
                  }),
                  _buildMenuItem(context, 'assets/images/information.png', l10n.drawerAboutUs, onTap: () {
                    Navigator.pushNamed(context, Route_Names.aboutUs);
                  }),
                  Divider(
                    color: Theme.of(context).colorScheme.primary,
                    thickness: 0.8,
                  ),

                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 0.3.h),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (isLoading)
                          const Center(child: CircularProgressIndicator())
                        else if (userData != null) ...[                          
                          _UserInfoRow(
                            label: l10n.userNameLabel, 
                            value: _getFullName(),
                          ),
                          _UserInfoRow(
                            label: l10n.userRoleLabel, 
                            value: 'ASHA Worker', // Default role, adjust as needed
                          ),
                          _UserInfoRow(
                            label: l10n.userVillageLabel, 
                            value: _getWorkingLocation('village'),
                          ),
                          _UserInfoRow(
                            label: l10n.userHscLabel, 
                            value: _getWorkingLocation('hsc_name'),
                          ),
                          _UserInfoRow(
                            label: l10n.userHfrIdLabel, 
                            value: _getWorkingLocation('hsc_hfr_id'),
                          ),
                        ] else
                          Text(
                            'Failed to load user data',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                              fontSize: 12.sp,
                            ),
                          ),
                        SizedBox(height: 1.h),
                        Text(
                          _appVersion,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                            fontSize: 14.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 2.h),
                ],
              ),
            ),

            SizedBox(
              width: double.infinity,
              height: 6.h, // responsive height
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  elevation: 0,
                  padding: EdgeInsets.zero,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(0),
                      topRight: Radius.circular(0),
                    ),
                  ),
                ),
                onPressed: () {
                  showConfirmationDialog(
                    context: context,
                    title: l10n.logoutTitle,
                    message: l10n.logoutMessage,
                    yesText: l10n.yes,
                    noText: l10n.no,
                    onYes: () async {
                      await SecureStorageService.setLoginFlag(0);

                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        Route_Names.loginScreen,
                            (Route<dynamic> route) => false,
                      );
                    },
                  );
                },
                child: Text(
                  l10n.drawerLogout,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
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
        width: 5.w,
        height: 5.w,
        fit: BoxFit.contain,
      ),
      title: Text(
        title,
        style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w500),
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
                fontSize: 14.sp,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 14.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
