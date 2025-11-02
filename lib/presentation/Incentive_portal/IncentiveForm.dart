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
        screenTitle: 'Incentive Form',
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
                    child: _infoBox('वित्तीय वर्ष:', '2024-2025'),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _infoBox('वित्तीय महीना:', 'June'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
        
              _labelField('कार्य कोड :', _textField('कार्य कोड डाले', workCodeController)),
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
                              'श्रेणी का प्रकार : [*]', categoryTypes, selectedCategoryType,
                                  (val) {
                                setState(() {
                                  selectedCategoryType = val;
                                });
                              }),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _dropdownField(
                              'कार्य की श्रेणी : [*]', categories, selectedCategory,
                                  (val) {
                                setState(() {
                                  selectedCategory = val;
                                });
                              }),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _labelField('कार्य : [*]',
                        _textField('कार्य चुनें', workController)),
                    const SizedBox(height: 12),
                    _labelField('लाभार्थी की संख्या : [*]',
                        _textField('लाभार्थियों की संख्या', beneficiaryCountController)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _labelField('कार्य की राशि : [*]',
                              _textField('कार्य की राशि', workAmountController)),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _labelField('दावा की गई राशि : [*]',
                              _textField('दावा की गई राशि', claimedAmountController)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _labelField(
                      'कार्य पूर्ण की तिथि : [*]',
                      GestureDetector(
                        onTap: () =>
                            _selectDate(context, completionDateController),
                        child: AbsorbPointer(
                          child: _textField(
                              'तिथि चुनें', completionDateController),
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
                          child: _dropdownField('पंजी का नाम : [*]', registerNames,
                              selectedRegisterName, (val) {
                                setState(() {
                                  selectedRegisterName = val;
                                });
                              }),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _dropdownField('खंड/Volume : [*]', volumes,
                              selectedVolume, (val) {
                                setState(() {
                                  selectedVolume = val;
                                });
                              }),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _labelField(
                      'पंजी की दिनांक : [*]',
                      GestureDetector(
                        onTap: () => _selectDate(context, registerDateController),
                        child: AbsorbPointer(
                          child: _textField(
                              'दिनांक चुनें', registerDateController),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _labelField('अभियुक्ति/Remark : [*]',
                        _textField('अभियुक्ति/Remark', remarkController)),
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
                  child: const Text(
                    'संरक्षित करे',
                    style: TextStyle(fontSize: 16, color: Colors.white),
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
  }
}
