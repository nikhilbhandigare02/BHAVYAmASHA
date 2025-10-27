import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:medixcel_new/core/config/themes/CustomColors.dart';
import 'package:medixcel_new/core/widgets/AppHeader/AppHeader.dart';
import 'package:medixcel_new/presentation/MotherCare/HBNCVisitForm/bloc/hbcn_visit_bloc.dart';
import 'package:medixcel_new/presentation/MotherCare/HBNCVisitForm/bloc/hbcn_visit_event.dart';
import 'package:medixcel_new/presentation/MotherCare/HBNCVisitForm/bloc/hbcn_visit_state.dart';
import 'package:medixcel_new/presentation/MotherCare/HBNCVisitForm/Tabs/GeneralDetails.dart';
import 'package:medixcel_new/presentation/MotherCare/HBNCVisitForm/Tabs/MotherDetails.dart';
import 'package:medixcel_new/presentation/MotherCare/HBNCVisitForm/Tabs/ChildDetails.dart';
import 'package:medixcel_new/core/widgets/RoundButton/RoundButton.dart';
import 'package:medixcel_new/l10n/app_localizations.dart';

class HbncVisitScreen extends StatefulWidget {
  const HbncVisitScreen({super.key});

  @override
  State<HbncVisitScreen> createState() => _HbncVisitScreenState();
}

class _HbncVisitScreenState extends State<HbncVisitScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();

  // Validation is handled by the BLoC via ValidateSection event.

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => HbncVisitBloc(),
      child: Builder(
        builder: (context) => Scaffold(
          body: BlocListener<HbncVisitBloc, HbncVisitState>(
            listenWhen: (previous, current) => previous.validationTick != current.validationTick,
            listener: (context, state) {
              final idx = _tabController.index;
              if (state.lastValidatedIndex == idx) {
                if (state.validationErrors.isNotEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(state.validationErrors.first)),
                  );
                } else {
                  if (state.lastValidationWasSave) {
                    context.read<HbncVisitBloc>().add(SaveHbncVisit());
                  } else {
                    final newIndex = idx + 1;
                    _tabController.animateTo(newIndex);
                    context.read<HbncVisitBloc>().add(TabChanged(newIndex));
                  }
                }
              }
            },
            child: Column(
              children: [
                AppHeader(screenTitle: 'HBNC Visit Form', showBack: true),

                TabBar(
                  controller: _tabController,
                  tabs: const [
                    Tab(text: 'General Details'),
                    Tab(text: 'Mother Details'),
                    Tab(text: 'Newborn Details'),
                  ],
                  onTap: (index) => context.read<HbncVisitBloc>().add(TabChanged(index)),
                ),
            

            Expanded(
              child: Form(
                key: _formKey,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    const GeneralDetailsTab(),
                    const MotherDetailsTab(),
                    const ChildDetailsTab(),
                  ],
                ),
              ),
            ),

            // Navigation buttons: Previous / Next
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: AnimatedBuilder(
                animation: _tabController,
                builder: (context, _) {
                  final idx = _tabController.index;
                  final isLast = idx >= _tabController.length - 1;
                  final t = AppLocalizations.of(context)!;
                  return Row(
                    children: [
                      Expanded(
                        child: RoundButton(
                          title: t.previousButton,
                          onPress: () {
                            final newIndex = idx - 1;
                            _tabController.animateTo(newIndex);
                            context.read<HbncVisitBloc>().add(TabChanged(newIndex));
                          },
                          disabled: idx == 0,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: isLast
                            ? BlocBuilder<HbncVisitBloc, HbncVisitState>(
                                builder: (context, state) {
                                  return RoundButton(
                                    title: t.saveButton,
                                    isLoading: state.isSaving,
                                    onPress: () {
                                      if (_formKey.currentState?.validate() ?? true) {
                                        context
                                            .read<HbncVisitBloc>()
                                            .add(ValidateSection(2, isSave: true));
                                      }
                                    },
                                  );
                                },
                              )
                            : RoundButton(
                                title: t.nextButton,
                                onPress: () {
                                  context.read<HbncVisitBloc>().add(ValidateSection(idx));
                                },
                              ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
      ),

    ));
  }

}
