import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:medixcel_new/core/widgets/Dropdown/dropdown.dart';
import 'package:medixcel_new/core/widgets/DatePicker/DatePicker.dart';
import 'package:medixcel_new/presentation/MotherCare/HBNCVisitForm/bloc/hbcn_visit_bloc.dart';
import 'package:medixcel_new/presentation/MotherCare/HBNCVisitForm/bloc/hbcn_visit_state.dart';
import 'package:medixcel_new/presentation/MotherCare/HBNCVisitForm/bloc/hbcn_visit_event.dart';
import 'package:medixcel_new/l10n/app_localizations.dart';

class GeneralDetailsTab extends StatelessWidget {
  const GeneralDetailsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HbncVisitBloc, HbncVisitState>(
      builder: (context, state) {
        final t = AppLocalizations.of(context)!;
        final visitMap = state.visitDetails;
        final dynamic dayRaw = visitMap['visitNumber'];
        final int? selectedDay = dayRaw is int ? dayRaw : int.tryParse('$dayRaw');
        final DateTime? visitDate = visitMap['visitDate'] as DateTime?;

        return ListView(
          padding: const EdgeInsets.all(12),
          children: [
            Card(
              elevation: 0,
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ApiDropdown<int>(
                      labelText: t.homeVisitDayLabel,
                      items: const [1, 2, 3, 4, 5, 6, 7],
                      getLabel: (v) => v.toString(),
                      value: selectedDay,
                      onChanged: (val) {
                        context.read<HbncVisitBloc>().add(
                              VisitDetailsChanged(field: 'visitNumber', value: val),
                            );
                      },
                    ),
                    const Divider(),
                    CustomDatePicker(
                      labelText: t.dateOfHomeVisitLabel,
                      initialDate: visitDate,
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
            ),
          ],
        );
      },
    );
  }
}

