import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:medixcel_new/core/widgets/AppHeader/AppHeader.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:medixcel_new/core/locale/bloc/locale_bloc.dart';
import 'package:medixcel_new/core/locale/bloc/locale_state.dart';
import 'package:medixcel_new/core/locale/bloc/locale_event.dart';
import 'package:medixcel_new/core/widgets/RoundButton/RoundButton.dart';
import 'package:medixcel_new/l10n/app_localizations.dart';
import 'package:medixcel_new/core/config/themes/CustomColors.dart';
import 'package:medixcel_new/core/widgets/SnackBar/app_snackbar.dart';

class Setting extends StatefulWidget {
  const Setting({super.key});

  @override
  State<Setting> createState() => _SettingState();
}

class _SettingState extends State<Setting> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppHeader(screenTitle: l10n.drawerSettings, showBack: true,),
      body: Column(
        children: [
          BlocBuilder<LocaleBloc, LocaleState>(
            builder: (context, state) {
              final current = state.languageCode;
              final currentLabel = current == 'hi' ? l10n.hindi : l10n.english;
              return InkWell(
                onTap: () => _showLanguageDialog(context, current),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  child: Row(
                    children: [
                      Expanded(child: Text(l10n.settingsAppLanguage, style: const TextStyle(fontSize: 16))),
                      Text(currentLabel, style: TextStyle(fontSize: 16, color: AppColors.onSurfaceVariant)),
                      const SizedBox(width: 6),
                      Icon(Icons.arrow_drop_down, color: AppColors.onSurfaceVariant),
                    ],
                  ),
                ),
              );
            },
          ),
          Divider(color: AppColors.divider, thickness: 0.5),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.settingsCheckForUpdates,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
                SizedBox(
                  width: 100, // fixed width for the button
                  height: 30, // optional
                  child: RoundButton(
                    title: l10n.settingsCheck,
                    color: AppColors.primary,
                    onPress: () {
                      showAppSnackBar(context, 'Your Bhavya m-ASHA application is up to date.');
                    },
                  ),
                ),
              ],
            ),

          ),
        ],
      ),
    );
  }

  void _showLanguageDialog(BuildContext context, String currentCode) {
    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (ctx) {
        String selected = currentCode;
        return StatefulBuilder(
          builder: (ctx, setStateDialog) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              title: Align(
                alignment: Alignment.centerLeft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.settingsAppLanguage,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Divider(height: 10),
                  ],
                ),
              ),
              content: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 240),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      RadioListTile<String>(
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        value: 'en',
                        groupValue: selected,
                        title: Text('English', style: const TextStyle(fontSize: 16)),
                        onChanged: (val) => setStateDialog(() => selected = val!),
                        visualDensity: const VisualDensity(vertical: -4),
                      ),
                      RadioListTile<String>(
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        value: 'hi',
                        groupValue: selected,
                        title: Text('हिंदी', style: const TextStyle(fontSize: 16)),
                        onChanged: (val) => setStateDialog(() => selected = val!),
                        visualDensity: const VisualDensity(vertical: -4),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                const Divider(height: 0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text(
                        'CANCEL',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        if (selected != currentCode) {
                          context.read<LocaleBloc>().add(ChangeLocale(selected));
                        }
                        Navigator.pop(ctx);
                      },
                      child: Text(
                        'OK',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }
}
