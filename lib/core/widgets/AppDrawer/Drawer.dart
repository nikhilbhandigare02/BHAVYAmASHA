import 'package:flutter/material.dart';
import 'package:medixcel_new/core/config/routes/Route_Name.dart';
import '../RoundButton/RoundButton.dart';
import 'package:medixcel_new/l10n/app_localizations.dart';

class CustomDrawer extends StatelessWidget {
  const CustomDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(left: 8.0, right: 8),
          child: Column(
            children: [
              // Top logo
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Column(
                  children: [
                    Image.asset(
                      'assets/images/bhabya-logo.png',
                      width: 120,
                      height: 120,
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
                    _buildMenuItem(context, 'assets/images/home.png', l10n.drawerHome, onTap: () {}),
                    _buildMenuItem(context, 'assets/images/sam_mgmt.png', l10n.drawerProfile, onTap: () {Navigator.pushNamed(context, Route_Names.profileScreen);} ),
                    _buildMenuItem(context, 'assets/images/notes.png', l10n.drawerMisReport, onTap: () {Navigator.pushNamed(context, Route_Names.MISScreen);}),
                    _buildMenuItem(context, 'assets/images/rupee.png', l10n.drawerIncentivePortal, onTap: () {Navigator.pushNamed(context, Route_Names.incentivePortal);}),
                    _buildMenuItem(context, 'assets/images/fetch.png', l10n.drawerFetchData, onTap: () {}),
                    _buildMenuItem(context, 'assets/images/refresh-button.png', l10n.drawerSyncedData, onTap: () {}),
                    _buildMenuItem(context, 'assets/images/reset_password.png', l10n.drawerResetPassword, onTap: () {Navigator.pushNamed(context, Route_Names.Resetpassword);}),
                    _buildMenuItem(context, 'assets/images/setting.png', l10n.drawerSettings, onTap: () {Navigator.pushNamed(context, Route_Names.setting);}),
                    _buildMenuItem(context, 'assets/images/information.png', l10n.drawerAboutUs, onTap: () {Navigator.pushNamed(context, Route_Names.aboutUs);}),
                    Divider(color: Theme.of(context).colorScheme.primary, thickness: 0.8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _UserInfoRow(label: l10n.userNameLabel, value: "Rohit Chavan"),
                          _UserInfoRow(label: l10n.userRoleLabel, value: "Bhavya ASHA"),
                          _UserInfoRow(label: l10n.userVillageLabel, value: "-"),
                          _UserInfoRow(label: l10n.userHscLabel, value: "HSC Baank"),
                          _UserInfoRow(label: l10n.userHfrIdLabel, value: "IN1010001604"),
                          const SizedBox(height: 4),
                          Text("V 7.8.10", style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12)),
                        ],
                      ),
                    ),
                    SizedBox(height: 16),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8),
                child: SizedBox(
                  width: double.infinity,
                  height: 45,
                  child: RoundButton(
                    title: l10n.drawerLogout,
                    onPress: () {},
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      dense: true,
      visualDensity: const VisualDensity(vertical: -1),
      minLeadingWidth: 24,
      leading: Image.asset(
        imagePath,
        width: 24,
        height: 24,
      ),
      title: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(color: Theme.of(context).colorScheme.primary),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            ),
          ),
        ],
      ),
    );
  }
}
