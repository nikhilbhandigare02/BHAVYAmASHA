import 'package:flutter/material.dart';
import 'package:medixcel_new/core/config/themes/CustomColors.dart';
import 'package:medixcel_new/core/widgets/AppHeader/AppHeader.dart';
import 'package:medixcel_new/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final phones = const [
      '+91 7620593008',
      '+91 8809581888',
      '+91 8809624888',
      '+91 8809104888',
    ];

    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppHeader(screenTitle: l10n.help, showBack: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(color: Color(0x1A000000), blurRadius: 10, offset: Offset(0, 2)),
            ],
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.helpInstructions,
                style: const TextStyle(fontSize: 14, color: Colors.black87),
              ),
              const SizedBox(height: 12),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: phones.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final number = phones[index];
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE6EEF7)),
                      boxShadow: const [
                        BoxShadow(color: Color(0x0F000000), blurRadius: 6, offset: Offset(0, 1)),
                      ],
                    ),
                    child: ListTile(
                      dense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      leading: Text('${index + 1}.', style: const TextStyle(fontWeight: FontWeight.w600)),
                      title: Text(number, style: const TextStyle(fontSize: 15)),
                      trailing: Container(
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.call, color: AppColors.primary),
                          onPressed: () => _callNumber(context, number),
                        ),
                      ),
                      onTap: () => _callNumber(context, number),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 10),
              Row(
                children: [
                  Text(l10n.emailLabel + '  ', style: const TextStyle(fontWeight: FontWeight.w600)),
                  const Expanded(
                    child: Text(
                      'helpdesk.bhavya@bihar.gov.in',
                      style: TextStyle(color: Colors.black87),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}


Future<void> _callNumber(BuildContext context, String number) async {
  final raw = number.replaceAll(' ', '');
  final candidates = <Uri>[
    Uri(scheme: 'tel', path: raw),
    Uri(scheme: 'tel', path: raw.replaceAll('+', '')), // some platforms reject '+' in path
  ];

  for (final uri in candidates) {
    if (await canLaunchUrl(uri)) {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (ok) return;
    }
  }

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Unable to open dialer on this device.')),
  );
}

