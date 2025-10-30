import 'package:flutter/material.dart';
import 'package:medixcel_new/core/widgets/DatePicker/DatePicker.dart';
import 'package:medixcel_new/core/widgets/Dropdown/dropdown.dart';
import 'package:medixcel_new/core/widgets/TextField/TextField.dart';
import 'package:medixcel_new/core/config/themes/CustomColors.dart';

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
  final List<String> _closureReasons = [
    'Select',
    'Death',
    'Migrated out',
    'Other',
  ];

  final List<String> _migrationTypes = [
    'Select',
    'Temporary',
    'Permanent'
  ];

  final List<String> _probableCauses = [
    'Select',
    'Measles',
    'Low birth weight',
    'High fever',
    'Diarrhoea',
    'Pneumonia',
    'Any other (specify)',
  ];

  final List<String> _deathPlaces = [
    'Select',
    'Home',
    'On the way',
    'Facility',
    'Other'
  ];

  final List<String> _deathReasons = [
    'Select',
    'PH',
    'PPH',
    'Severe Anaemia',
    'Sepsis',
    'Obstruct labour',
    'Malpresentation'
  ];

  @override
  Widget build(BuildContext context) {
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
            const Text(
              'Case closure',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
        if (widget.isCaseClosureChecked) ...[
          const SizedBox(height: 16),
          // Reason of Closure Dropdown
          ApiDropdown<String>(
            labelText: 'Reason of Closure',
            items: _closureReasons,
            value: widget.selectedClosureReason,
            getLabel: (value) => value,
            onChanged: (value) {
              if (value != null) {
                widget.onClosureReasonChanged(value);
                if (value != 'Death') {
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
          if (widget.selectedClosureReason == 'Migrated out') ...[
            ApiDropdown<String>(
              labelText: 'Migration Type',
              items: _migrationTypes,
              value: widget.migrationType,
              getLabel: (value) => value,
              onChanged: widget.onMigrationTypeChanged,
            ),
            const Divider(thickness: 0.5, height: 1, color: AppColors.divider),
          ],

          // Other Reason TextField
          if (widget.selectedClosureReason == 'Other') ...[
            CustomTextField(
              labelText: 'Specify Reason',
              hintText: 'Enter reason for closure',
              controller: widget.otherReasonController,
              maxLines: 2,
              onChanged: (value) {},
            ),
            const Divider(thickness: 0.5, height: 1, color: AppColors.divider),
          ],

          // Death Related Fields
          if (widget.selectedClosureReason == 'Death') ...[
            // Date of Death
            CustomDatePicker(
              labelText: 'Date of Death',
              initialDate: widget.dateOfDeath,
              onDateChanged: widget.onDateOfDeathChanged,
            ),
            const Divider(thickness: 0.5, height: 1, color: AppColors.divider),

            // Probable Cause of Death
            ApiDropdown<String>(
              labelText: 'Probable Cause of Death',
              items: _probableCauses,
              value: widget.probableCauseOfDeath,
              getLabel: (value) => value,
              onChanged: (value) {
                widget.onProbableCauseChanged(value);
                final showOtherField = (value == 'Any other (specify)');
                widget.onShowOtherCauseFieldChanged(showOtherField);
                if (!showOtherField) {
                  widget.otherCauseController.clear();
                }
              },
            ),

            // Other Cause TextField
            if (widget.showOtherCauseField) ...[
              CustomTextField(
                labelText: 'Specify cause of death',
                controller: widget.otherCauseController,
                onChanged: (value) {},
              ),

            ],
            const Divider(thickness: 0.5, height: 1, color: AppColors.divider),
            // Death Place
            ApiDropdown<String>(
              labelText: 'Death Place',
              items: _deathPlaces,
              value: widget.deathPlace,
              getLabel: (value) => value,
              onChanged: widget.onDeathPlaceChanged,
            ),
            const Divider(thickness: 0.5, height: 1, color: AppColors.divider),

            // Reason of Death
            ApiDropdown<String>(
              labelText: 'Reason of Death',
              items: _deathReasons,
              value: widget.reasonOfDeath,
              getLabel: (value) => value,
              onChanged: widget.onReasonOfDeathChanged,
            ),
            const Divider(thickness: 0.5, height: 1, color: AppColors.divider),
          ],
        ],
      ],
    );
  }
}