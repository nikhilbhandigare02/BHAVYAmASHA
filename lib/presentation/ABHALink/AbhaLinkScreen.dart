import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:medixcel_new/core/widgets/AppHeader/AppHeader.dart';
import 'package:medixcel_new/core/widgets/RoundButton/RoundButton.dart';
import 'package:medixcel_new/l10n/app_localizations.dart';
import '../ABHALink/bloc/abhalink_bloc.dart';

class Abhalinkscreen extends StatefulWidget {
  const Abhalinkscreen({super.key});

  @override
  State<Abhalinkscreen> createState() => _AbhalinkscreenState();
}

class _AbhalinkscreenState extends State<Abhalinkscreen> {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AbhalinkBloc(),
      child: Scaffold(
        appBar: AppHeader(
          screenTitle: AppLocalizations.of(context)!.linkHealthRecordsTitle,
          showBack: true,
        ),
        body: SafeArea(
          child: BlocConsumer<AbhalinkBloc, AbhaLinkState>(
            listenWhen: (p, c) =>
            p.errorMessage != c.errorMessage || p.success != c.success,
            listener: (context, state) {
              if (state.errorMessage != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(state.errorMessage!)),
                );
              }
              if (state.success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(AppLocalizations.of(context)!.linkedSuccessfully)),
                );
                Navigator.of(context).pop(true);
              }
            },
            builder: (context, state) {
              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _AbhaInput(address: state.address ?? ''),
                    const Spacer(),

                    // ✅ Bottom-right Proceed button (no Stack)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        SizedBox(
                          height: 44,
                          width: 140,
                          child: RoundButton(
                            title: AppLocalizations.of(context)!.proceedButton,
                            borderRadius: 8,
                            isLoading: state.submitting,
                            color: Colors.green,
                            icon: Icons.inbox_outlined,
                            onPress: () => context
                                .read<AbhalinkBloc>()
                                .add(const AbhaSubmitPressed()),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _AbhaInput extends StatelessWidget {
  final String address;
  const _AbhaInput({required this.address});

  @override
  Widget build(BuildContext context) {
    final controller = TextEditingController(text: address);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(color: Colors.grey.shade300),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: (v) => context
                  .read<AbhalinkBloc>()
                  .add(AbhaAddressChanged(v.trim())),
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.abhaAddressLabel,
                border: InputBorder.none,
              ),
            ),
          ),

          Text(
            '@abdm',
            style: TextStyle(
              color: Colors.grey.shade800,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
