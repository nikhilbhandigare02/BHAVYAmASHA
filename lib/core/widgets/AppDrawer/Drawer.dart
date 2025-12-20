import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:medixcel_new/core/config/routes/Route_Name.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../data/SecureStorage/SecureStorage.dart';
import '../../../data/sync/sync_api_call.dart';
import '../../../presentation/HomeScreen/HomeScreen.dart';
import '../../utils/app_version.dart';
import '../ConfirmationDialogue/ConfirmationDialogue.dart';
import 'package:medixcel_new/l10n/app_localizations.dart';
import 'package:sizer/sizer.dart';
import 'dart:convert';
import 'package:medixcel_new/data/sync/sync_service.dart';
import 'package:medixcel_new/core/widgets/SnackBar/app_snackbar.dart';

class CustomDrawer extends StatefulWidget {
  final VoidCallback? onSyncCompleted;

  const CustomDrawer({super.key, this.onSyncCompleted});

  @override
  State<CustomDrawer> createState() => _CustomDrawerState();
}

class _CustomDrawerState extends State<CustomDrawer> {
  Map<String, dynamic>? userData;
  bool isLoading = true;
  bool isSyncing = false;

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
  int? _appRoleId;
  Future<void> _loadUserData() async {
    if (mounted) {
      setState(() => isLoading = true);
    }

    try {
      developer.log('Loading user data from secure storage...', name: 'Drawer');

      // Fetch user data
      Map<String, dynamic>? data = await SecureStorageService.getCurrentUserData();

      // If not found, try legacy format
      if (data == null || data.isEmpty) {
        final legacy = await SecureStorageService.getUserData();
        if (legacy != null && legacy.isNotEmpty) {
          data = jsonDecode(legacy) as Map<String, dynamic>?;
        }
      }

      int extractedRoleId = 0;

      try {
        extractedRoleId = int.tryParse(data?['app_role_id']?.toString() ?? "") ?? 0;

        developer.log("APP ROLE ID = $extractedRoleId", name: "Drawer");

        if (mounted) {
          setState(() {
            _appRoleId = extractedRoleId;
          });
        }
      } catch (e) {
        developer.log("Error reading app_role_id: $e", name: "Drawer");
      }

      // Set user data and stop loader
      if (mounted) {
        setState(() {
          userData = data;
          isLoading = false;
        });
      }

    } catch (e) {
      developer.log('Error in _loadUserData: $e', name: 'Drawer', error: e);
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }
  Future<void> openInChrome(String url) async {
    final Uri uri = Uri.parse(url);

    if (await canLaunchUrl(uri)) {
      await launchUrl(
        uri,
        mode: LaunchMode.inAppWebView,
        webViewConfiguration: const WebViewConfiguration(
          enableJavaScript: true,
          enableDomStorage: true,
        ),
      );
    } else {
      await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
    }
  }
  String _getFullName() {
    if (userData == null) return '-';
    try {
      // Handle different possible structures
      if (userData!['name'] is Map) {
        final name = userData!['name'] as Map;
        return [
          name['first_name'],
          name['middle_name'],
          name['last_name']
        ].where((part) => part != null).join(' ').trim();
      }

      // Try direct fields
      return [
        userData!['first_name'],
        userData!['middle_name'],
        userData!['last_name'],
        userData!['name']  // Fallback to name if it's a string
      ].where((part) => part != null && part is String).join(' ').trim();
    } catch (e) {
      developer.log('Error getting full name: $e', name: 'Drawer');
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


  Widget _buildLoadingState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 2.h),
        child: CircularProgressIndicator(strokeWidth: 2.0),
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 1.h),
      child: Text(
        message,
        style: TextStyle(
          color: Colors.orange,
          fontSize: 12.sp,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final width = MediaQuery.of(context).size.width;
    final bool isTablet = width >= 600;
    print("DRAWER → Current appRoleId: $_appRoleId");
// Set responsive drawer width
    final double drawerWidth = isTablet ? width * 0.55 : width * 0.69;
    return SizedBox(
        width: drawerWidth,
        child: Drawer(
          backgroundColor: Colors.white,
          child: SafeArea(
            bottom: true,
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
                    padding: EdgeInsets.only(bottom: 0), // Remove bottom padding
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

                      if (_appRoleId == 4)
                        _buildMenuItem(
                          context,
                          'assets/images/id-card.png',
                          l10n.report,// ?? "Report",
                          onTap: () {
                            openInChrome(
                              "https://ashadashboarduat.medixcel.in/#/auth/login?token=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VybmFtZSI6IkYwMDAwMDAwMSIsImRpc3RyaWN0X2lkIjoiMSIsInVuaXF1ZV9rZXkiOiJNNVhTQ0VNMVk4RiIsImhzY19pZCI6InVuZGVmaW5lZCIsImlhdCI6MTc2NTQzMjc1MywiZXhwIjoxNzY1NTE5MTUzfQ.Rea0VNzimIFjJU6hUYDp227ae9P1tY-7ObGdikxi8uM",
                            );
                          },
                        ),
                      _buildMenuItem(context, 'assets/images/notes.png', l10n.drawerMisReport, onTap: () {
                        Navigator.pushNamed(context, Route_Names.MISScreen);
                      }),
                      _buildMenuItem(context, 'assets/images/rupee.png', l10n.drawerIncentivePortal, onTap: () {
                        Navigator.pushNamed(context, Route_Names.incentivePortal);
                      }),
                      _buildMenuItem(context, 'assets/images/fetch.png', l10n.drawerFetchData, onTap: () async {
                        final onCompleted = widget.onSyncCompleted;
                        if (isSyncing) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Sync already in progress')),
                          );
                          return;
                        }
                        setState(() {
                          isSyncing = true;
                        });

                        final scaffoldMessenger = ScaffoldMessenger.of(context);
                        scaffoldMessenger.hideCurrentSnackBar();
                        final controller = scaffoldMessenger.showSnackBar(
                          const SnackBar(
                            content: Text('Data is being fetched...'),
                            duration: Duration(seconds: 5), // Show for 20 seconds
                            behavior: SnackBarBehavior.floating,
                          ),
                        );

                        try { 
                          // Start the sync operation
                          // await SyncService.instance.runFullSyncOnce();
                          await SyncApiCall.allGetApicall();

                          // If still mounted and sync completed successfully
                          if (mounted) {
                            // Remove the loading snackbar if still showing
                            scaffoldMessenger.hideCurrentSnackBar();

                            // Show success message
                            scaffoldMessenger.showSnackBar(
                              const SnackBar(
                                content: Text('Data sync completed'),
                                duration: Duration(seconds: 3),
                              ),
                            );

                            // Close drawer if it's open
                            final scaffoldState = Scaffold.maybeOf(context);
                            if (scaffoldState != null && scaffoldState.isDrawerOpen) {
                              Navigator.pop(context);
                            }
                          }

                          // Notify parent (HomeScreen)
                          onCompleted?.call();
                        } catch (e) {
                          if (!mounted) return;

                          // Remove loading snackbar and show error
                          scaffoldMessenger
                            ..hideCurrentSnackBar()
                            ..showSnackBar(
                              SnackBar(
                                content: Text('Sync failed: ${e.toString()}'),
                                duration: const Duration(seconds: 4),
                              ),
                            );
                        } finally {
                          if (mounted) {
                            setState(() {
                              isSyncing = false;
                            });
                          }
                        }
                      }),
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
                              _buildLoadingState()
                            else if (userData != null && userData!.isNotEmpty)
                              ...[
                                _UserInfoRow(
                                  label: l10n.userNameLabel,
                                  value: _getFullName(),
                                ),
                                _UserInfoRow(
                                  label: l10n.userRoleLabel,
                                  value: _appRoleId == 4 ? 'ASHA Facilitator' : 'ASHA Worker',
                                ),
                                if (_appRoleId != 4) ...[
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
                                ],
                              ]
                            else
                              _buildErrorState('User data not available'),
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
                    ],
                  ),
                ),
                Container(
                  margin: EdgeInsets.only(top: 0), // Remove any top margin
                  width: double.infinity,
                  height: 4.5.h,
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
                          // Clear all secure storage data
                          await SecureStorageService.clearAll();
                          // Set login flag to 0
                          await SecureStorageService.setLoginFlag(0);

                          if (mounted) {
                            Navigator.pushNamedAndRemoveUntil(
                              context,
                              Route_Names.loginScreen,
                                  (Route<dynamic> route) => false,
                            );
                          }
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
                )],
            ),
          ),
        ));
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
