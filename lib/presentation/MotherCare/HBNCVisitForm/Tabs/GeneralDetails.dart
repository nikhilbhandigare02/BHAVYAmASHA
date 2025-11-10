import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:medixcel_new/core/config/themes/CustomColors.dart';
import 'package:medixcel_new/core/widgets/Dropdown/dropdown.dart';
import 'package:medixcel_new/core/widgets/DatePicker/DatePicker.dart';
import 'package:medixcel_new/data/SecureStorage/SecureStorage.dart';
import 'package:medixcel_new/presentation/MotherCare/HBNCVisitForm/bloc/hbcn_visit_bloc.dart';
import 'package:medixcel_new/presentation/MotherCare/HBNCVisitForm/bloc/hbcn_visit_state.dart';
import 'package:medixcel_new/presentation/MotherCare/HBNCVisitForm/bloc/hbcn_visit_event.dart';
import 'package:medixcel_new/l10n/app_localizations.dart';

class GeneralDetailsTab extends StatelessWidget {
  final String beneficiaryId;
  
  const GeneralDetailsTab({super.key, required this.beneficiaryId});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HbncVisitBloc, HbncVisitState>(
      builder: (context, state) {
        final t = AppLocalizations.of(context)!;
        final visitMap = state.visitDetails;
        final dynamic dayRaw = visitMap['visitNumber'];
        final int? selectedDay = dayRaw is int ? dayRaw : int.tryParse('$dayRaw');
        // Set default visit date to current date if not already set
        final DateTime currentDate = DateTime.now();
        final DateTime visitDate = visitMap['visitDate'] as DateTime? ?? currentDate;
        
        // If visitDate was null, update it with current date
        if (visitMap['visitDate'] == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            context.read<HbncVisitBloc>().add(
              VisitDetailsChanged(field: 'visitDate', value: currentDate),
            );
          });
        }

        return ListView(
          padding: const EdgeInsets.all(8),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FutureBuilder<int>(
                    future: SecureStorageService.getVisitCount(beneficiaryId),
                    builder: (context, snapshot) {
                      final baseCount = snapshot.data ?? 1;
                      final visitCount = baseCount + 2; // ✅ increment by 2
                      final int displayDay;

                      if (selectedDay != null && selectedDay > 1) {
                        displayDay = selectedDay;
                      } else {
                        displayDay = visitCount;
                        if (visitCount > 0 && visitCount <= 7) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            context.read<HbncVisitBloc>().add(
                              VisitDetailsChanged(field: 'visitNumber', value: visitCount),
                            );
                          });
                        }
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),
                          ApiDropdown<int>(
                            labelText: t.homeVisitDayLabel,
                            items: List.generate(7, (index) => index + 1),
                            getLabel: (v) => v.toString(),
                            value: displayDay,
                            onChanged: (val) {
                              if (val != null) {
                                context.read<HbncVisitBloc>().add(
                                  VisitDetailsChanged(field: 'visitNumber', value: val),
                                );
                              }
                            },
                          ),
                        ],
                      );
                    },
                  ),
                  const Divider(),
                  CustomDatePicker(
                    labelText: t.dateOfHomeVisitLabel,
                    hintText: t.dateOfHomeVisitLabel,
                    initialDate: visitDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                    onDateChanged: (date) {
                      context.read<HbncVisitBloc>().add(
                            VisitDetailsChanged(field: 'visitDate', value: date),
                          );
                    },
                  ),
                  const Divider(),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

