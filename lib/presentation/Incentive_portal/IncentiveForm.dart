import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:medixcel_new/core/config/themes/CustomColors.dart';
import 'package:medixcel_new/core/widgets/AppHeader/AppHeader.dart';
import 'package:medixcel_new/l10n/app_localizations.dart';

class IncentiveForm extends StatefulWidget {
  const IncentiveForm({super.key});

  @override
  State<IncentiveForm> createState() => _IncentiveFormState();
}

class _IncentiveFormState extends State<IncentiveForm> {
  String? selectedCategoryType;
  String? selectedCategory;
  String? selectedRegisterName;
  String? selectedVolume;

  final TextEditingController workCodeController = TextEditingController();
  final TextEditingController workController = TextEditingController();
  final TextEditingController beneficiaryCountController =
  TextEditingController();
  final TextEditingController workAmountController = TextEditingController();
  final TextEditingController claimedAmountController = TextEditingController();
  final TextEditingController completionDateController =
  TextEditingController();
  final TextEditingController registerDateController = TextEditingController();
  final TextEditingController remarkController = TextEditingController();

  final List<String> categoryTypes = ['C - सामुदायिक', 'I - संस्थागत'];
  final List<String> categories = ['Category A', 'Category B', 'Category C'];
  final List<String> registerNames = ['Register 1', 'Register 2', 'Register 3'];
  final List<String> volumes = ['1', '2', '3', '4'];

  Future<void> _selectDate(
      BuildContext context, TextEditingController controller) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      locale: const Locale('hi', 'IN'),
    );
    if (picked != null) {
      controller.text = DateFormat('dd-MM-yyyy').format(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppHeader(
        screenTitle: l10n?.incentiveFormTitle ?? 'Incentive Form',
        showBack: true,
      ),
      body: SafeArea(
        bottom: true,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _infoBox(
                      (l10n?.incentiveFinancialYear ?? 'वित्तीय वर्ष:'),
                      '2024-2025',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _infoBox(
                      (l10n?.incentiveFinancialMonth ?? 'वित्तीय महीना:'),
                      'June',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
        
              _labelField(
                l10n?.incentiveFormWorkCodeLabel ?? 'कार्य कोड :',
                _textField(
                  l10n?.incentiveFormWorkCodeHint ?? 'कार्य कोड डाले',
                  workCodeController,
                ),
              ),
              const SizedBox(height: 16),
        
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.white,
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _dropdownField(
                              l10n?.incentiveFormCategoryTypeLabel ?? 'श्रेणी का प्रकार : [*]', categoryTypes, selectedCategoryType,
                                  (val) {
                                setState(() {
                                  selectedCategoryType = val;
                                });
                              },context),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _dropdownField(
                              l10n?.incentiveFormCategoryLabel ?? 'कार्य की श्रेणी : [*]', categories, selectedCategory,
                                  (val) {
                                setState(() {
                                  selectedCategory = val;
                                });
                              },context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _labelField(
                      l10n?.incentiveFormWorkLabel ?? 'कार्य : [*]',
                      _textField(
                        l10n?.incentiveFormWorkHint ?? 'कार्य चुनें',
                        workController,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _labelField(
                      l10n?.incentiveFormBeneficiaryCountLabel ?? 'लाभार्थी की संख्या : [*]',
                      _textField(
                        l10n?.incentiveFormBeneficiaryCountHint ?? 'लाभार्थियों की संख्या',
                        beneficiaryCountController,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _labelField(
                            l10n?.incentiveFormWorkAmountLabel ?? 'कार्य की राशि : [*]',
                            _textField(
                              l10n?.incentiveFormWorkAmountHint ?? 'कार्य की राशि',
                              workAmountController,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _labelField(
                            l10n?.incentiveFormClaimedAmountLabel ?? 'दावा की गई राशि : [*]',
                            _textField(
                              l10n?.incentiveFormClaimedAmountHint ?? 'दावा की गई राशि',
                              claimedAmountController,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _labelField(
                      l10n?.incentiveFormCompletionDateLabel ?? 'कार्य पूर्ण की तिथि : [*]',
                      GestureDetector(
                        onTap: () =>
                            _selectDate(context, completionDateController),
                        child: AbsorbPointer(
                          child: _textField(
                              l10n?.incentiveFormCompletionDateHint ?? 'तिथि चुनें',
                              completionDateController,
                            ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
        
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.white,
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _dropdownField(
                              l10n?.incentiveFormRegisterNameLabel ?? 'पंजी का नाम : [*]', registerNames,
                              selectedRegisterName, (val) {
                                setState(() {
                                  selectedRegisterName = val;
                                });
                              },context),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _dropdownField(
                              l10n?.incentiveFormVolumeLabel ?? 'खंड/Volume : [*]', volumes,
                              selectedVolume, (val) {
                                setState(() {
                                  selectedVolume = val;
                                });
                              },
                          context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _labelField(
                      l10n?.incentiveFormRegisterDateLabel ?? 'पंजी की दिनांक : [*]',
                      GestureDetector(
                        onTap: () => _selectDate(context, registerDateController),
                        child: AbsorbPointer(
                          child: _textField(
                              l10n?.incentiveFormRegisterDateHint ?? 'दिनांक चुनें',
                              registerDateController,
                            ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _labelField(
                      l10n?.incentiveFormRemarkLabel ?? 'अभियुक्ति/Remark : [*]',
                      _textField(
                        l10n?.incentiveFormRemarkHint ?? 'अभियुक्ति/Remark',
                        remarkController,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
        
              SizedBox(
                width: double.infinity,
                height: 45,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                  ),
                  onPressed: () {},
                  child: Text(
                    l10n?.finalizeSave ?? 'संरक्षित करे',
                    style: const TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoBox(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 6),
          Text(value),
        ],
      ),
    );
  }

  Widget _labelField(String label, Widget field) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style:
            const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        const SizedBox(height: 4),
        field,
      ],
    );
  }

  Widget _textField(String hintText, TextEditingController controller) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hintText,
        isDense: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 12, vertical: 5),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }


  Widget _dropdownField(String label, List<String> items, String? selectedValue,
      Function(String?) onChanged, BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        const SizedBox(height: 4),
        DropdownButtonFormField<String>(
          value: selectedValue,
          items: items
              .map(
                (e) => DropdownMenuItem<String>(
              value: e,
              child: Text(getLocalizedDropdownLabel(context, e)),
            ),
          )
              .toList(),
          onChanged: onChanged,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
            contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            filled: true,
            fillColor: Colors.white,
            isDense: true,
          ),
        ),
      ],
    );
  }

  String getLocalizedDropdownLabel(BuildContext context, String value) {
    final l10n = AppLocalizations.of(context)!;

    // Mapping known values to localization keys
    switch (value) {
      case 'C - सामुदायिक':
        return l10n.communityC;
      case 'I - संस्थागत':
        return l10n.institutionalI;

      case 'Category A':
        return l10n.categoryA;
      case 'Category B':
        return l10n.categoryB;
      case 'Category C':
        return l10n.categoryC;

      case 'Register 1':
        return l10n.register1;
      case 'Register 2':
        return l10n.register2;
      case 'Register 3':
        return l10n.register3;

      default:
        return value; // if not matched, show original value
    }
  }



/* Widget _dropdownField(String label, List<String> items, String? selectedValue,
      Function(String?) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style:
            const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        const SizedBox(height: 4),
        DropdownButtonFormField<String>(
          value: selectedValue,
          items: items
              .map((e) => DropdownMenuItem<String>(
            value: e,
            child: Text(e),
          ))
              .toList(),
          onChanged: onChanged,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            filled: true,
            fillColor: Colors.white,
            isDense: true,
          ),
        ),
      ],
    );
  }*/
}
