import 'package:flutter/material.dart';
import 'package:medixcel_new/core/widgets/DatePicker/DatePicker.dart';
import 'package:medixcel_new/core/widgets/Dropdown/dropdown.dart';
import 'package:medixcel_new/core/widgets/TextField/TextField.dart';
import 'package:medixcel_new/core/config/themes/CustomColors.dart';
import 'package:medixcel_new/l10n/app_localizations.dart';

class CaseClosureWidget extends StatefulWidget {
  final bool isCaseClosureChecked;
  final String? selectedClosureReason;
  final String? migrationType;
  final DateTime? dateOfDeath;
  final String? probableCauseOfDeath;
  final String? deathPlace;
  final String? reasonOfDeath;
  final bool showOtherCauseField;
  final TextEditingController otherCauseController;
  final TextEditingController otherReasonController;
  final Function(bool) onCaseClosureChanged;
  final Function(String?) onClosureReasonChanged;
  final Function(String?) onMigrationTypeChanged;
  final Function(DateTime?) onDateOfDeathChanged;
  final Function(String?) onProbableCauseChanged;
  final Function(String?) onDeathPlaceChanged;
  final Function(String?) onReasonOfDeathChanged;
  final Function(bool) onShowOtherCauseFieldChanged;

  const CaseClosureWidget({
    Key? key,
    required this.isCaseClosureChecked,
    required this.selectedClosureReason,
    required this.migrationType,
    required this.dateOfDeath,
    required this.probableCauseOfDeath,
    required this.deathPlace,
    required this.reasonOfDeath,
    required this.showOtherCauseField,
    required this.otherCauseController,
    required this.otherReasonController,
    required this.onCaseClosureChanged,
    required this.onClosureReasonChanged,
    required this.onMigrationTypeChanged,
    required this.onDateOfDeathChanged,
    required this.onProbableCauseChanged,
    required this.onDeathPlaceChanged,
    required this.onReasonOfDeathChanged,
    required this.onShowOtherCauseFieldChanged,
  }) : super(key: key);

  @override
  State<CaseClosureWidget> createState() => _CaseClosureWidgetState();
}

class _CaseClosureWidgetState extends State<CaseClosureWidget> {
  List<String> _closureReasons(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return [
      l.death,
      l.migratedOut,
      l.other,
    ];
  }

  List<String> _migrationTypes(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return [
      l.temporary,
      l.permanent
    ];
  }

  List<String> _probableCauses(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return [
      l.measles,
      l.lowBirthWeight,
      l.highFever,
      l.diarrhoea,
      l.pneumonia,
      l.anyOtherSpecify,
    ];
  }

  List<String> _deathPlaces(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return [
      l.migratedOut,
      l.home,
      l.onTheWay,
      l.facility,
      l.other
    ];
  }

  List<String> _deathReasons(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return [
      l.ph,
      l.pph,
      l.severeAnaemia,
      l.sepsis,
      l.obstructLabour,
      l.malpresentation,
      l.eclampsia_severe_hypertension,
      l.unsafeAbortion,
      l.surgicalComplication,
      l.other_reason_not_maternal_complication,
      l.otherSpecify
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Checkbox(
              value: widget.isCaseClosureChecked,
              activeColor: Colors.blue,
              onChanged: (bool? value) {
                widget.onCaseClosureChanged(value ?? false);
              },
            ),
            Text(
              l.caseClosure,
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
        if (widget.isCaseClosureChecked) ...[
          const SizedBox(height: 16),
          // Reason of Closure Dropdown
          ApiDropdown<String>(
            labelText: l.reasonOfClosure,
            items: _closureReasons(context),
            value: widget.selectedClosureReason,
            getLabel: (value) => value,
            onChanged: (value) {
              if (value != null) {
                widget.onClosureReasonChanged(value);
                if (value != l.death) {
                  widget.onDateOfDeathChanged(null);
                  widget.onProbableCauseChanged(null);
                  widget.onDeathPlaceChanged(null);
                  widget.onReasonOfDeathChanged(null);
                  widget.onShowOtherCauseFieldChanged(false);
                  widget.otherCauseController.clear();
                }
              }
            },
          ),
          const Divider(thickness: 0.5, height: 1, color: AppColors.divider),

          // Migration Type Dropdown
          if (widget.selectedClosureReason == l.migratedOut) ...[
            ApiDropdown<String>(
              labelText: l.migrationType,
              items: _migrationTypes(context),
              value: widget.migrationType,
              getLabel: (value) => value,
              onChanged: widget.onMigrationTypeChanged,
            ),
            const Divider(thickness: 0.5, height: 1, color: AppColors.divider),
          ],

          // Other Reason TextField
          if (widget.selectedClosureReason == l.other) ...[
            CustomTextField(
              labelText: l.specifyReason,
              hintText: l.enterReasonForClosure,
              controller: widget.otherReasonController,
              maxLines: 2,
              onChanged: (value) {},
            ),
            const Divider(thickness: 0.5, height: 1, color: AppColors.divider),
          ],

          // Death Related Fields
          if (widget.selectedClosureReason == l.death) ...[
            // Date of Death
            CustomDatePicker(
              labelText: l.dateOfDeathLabel,
              initialDate: widget.dateOfDeath,
              lastDate: DateTime.now(),
              onDateChanged: widget.onDateOfDeathChanged,
            ),
            const Divider(thickness: 0.5, height: 1, color: AppColors.divider),

            // Probable Cause of Death
            ApiDropdown<String>(
              labelText: l.probableCauseOfDeath,
              items: _probableCauses(context),
              value: widget.probableCauseOfDeath,
              getLabel: (value) => value,
              onChanged: (value) {
                widget.onProbableCauseChanged(value);
                final showOtherField = (value == l.anyOtherSpecify);
                widget.onShowOtherCauseFieldChanged(showOtherField);
                if (!showOtherField) {
                  widget.otherCauseController.clear();
                }
              },
            ),
            const Divider(thickness: 0.5, height: 1, color: AppColors.divider),

            if (widget.showOtherCauseField) ...[
              CustomTextField(
                labelText: l.specifyCauseOfDeath,
                controller: widget.otherCauseController,
                onChanged: (value) {},
              ),

            ],
            const Divider(thickness: 0.5, height: 1, color: AppColors.divider),
            // Death Place
            ApiDropdown<String>(
              labelText: l.deathPlace,
              items: _deathPlaces(context),
              value: widget.deathPlace,
              getLabel: (value) => value,
              onChanged: widget.onDeathPlaceChanged,
            ),
            const Divider(thickness: 0.5, height: 1, color: AppColors.divider),

            // Reason of Death
            ApiDropdown<String>(
              labelText: l.reasonOfDeath,
              items: _deathReasons(context),
              value: widget.reasonOfDeath,
              getLabel: (value) => value,
              onChanged: (value) {
                widget.onReasonOfDeathChanged(value);
                if (value != l.otherSpecify) {
                  widget.otherReasonController.clear();
                }
              },
              convertToTitleCase: false,  
            ),
            const Divider(thickness: 0.5, height: 1, color: AppColors.divider),
            // Other Reason of Death TextField
            if (widget.reasonOfDeath == l.otherSpecify) ...[
              CustomTextField(
                labelText: l.otherReasonOfDeath,
                controller: widget.otherReasonController,
                onChanged: (value) {},
              ),
            ],
            const Divider(thickness: 0.5, height: 1, color: AppColors.divider),
          ],
        ],
      ], 
    );
  }
}
