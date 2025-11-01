import 'package:flutter/material.dart';
import 'package:medixcel_new/core/widgets/AppHeader/AppHeader.dart';
import 'package:medixcel_new/l10n/app_localizations.dart';

class IncentiveForm extends StatefulWidget {
  const IncentiveForm({super.key});

  @override
  State<IncentiveForm> createState() => _IncentiveFormState();
}

class _IncentiveFormState extends State<IncentiveForm> {
  final TextEditingController _workCodeController = TextEditingController();
  final TextEditingController _beneficiaryCountController = TextEditingController();
  final TextEditingController _workAmountController = TextEditingController();
  final TextEditingController _claimAmountController = TextEditingController();
  final TextEditingController _remarkController = TextEditingController();

  String? _selectedCategoryType;
  String? _selectedWorkCategory;
  String? _selectedWork;
  String? _selectedCompletionDate;
  String? _selectedVillageName;
  String? _selectedVolume;
  String? _selectedRegistryDate;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppHeader(
        screenTitle: 'Incentive Form',
        showBack: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Financial Year and Month Row
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE3F2FD),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'वित्तीय वर्ष: 2024-2025',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE3F2FD),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'वित्तीय महीना: June',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // कार्य कोड
            _buildLabel('कार्य कोड'),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _workCodeController,
              hint: 'कार्य कोड डालें',
            ),
            const SizedBox(height: 20),

            // श्रेणी का प्रकार and कार्य की श्रेणी Row
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('श्रेणी का प्रकार : [*]'),
                      const SizedBox(height: 8),
                      _buildDropdown(
                        value: _selectedCategoryType,
                        hint: '-Select-',
                        onChanged: (value) {
                          setState(() {
                            _selectedCategoryType = value;
                          });
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('कार्य की श्रेणी : [*]'),
                      const SizedBox(height: 8),
                      _buildDropdown(
                        value: _selectedWorkCategory,
                        hint: '-None-',
                        onChanged: (value) {
                          setState(() {
                            _selectedWorkCategory = value;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // कार्य
            _buildLabel('कार्य : [*]'),
            const SizedBox(height: 8),
            _buildDropdown(
              value: _selectedWork,
              hint: '',
              onChanged: (value) {
                setState(() {
                  _selectedWork = value;
                });
              },
            ),
            const SizedBox(height: 20),

            // लाभार्थी की संख्या
            _buildLabel('लाभार्थी की संख्या : [*]'),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _beneficiaryCountController,
              hint: 'लाभार्थियों की संख्या',
            ),
            const SizedBox(height: 20),

            // कार्य की राशी and दावा की गई राशी Row
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('कार्य की राशी : [*]'),
                      const SizedBox(height: 8),
                      _buildTextField(
                        controller: _workAmountController,
                        hint: 'कार्य की राशी',
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('दावा की गई राशी : [*]'),
                      const SizedBox(height: 8),
                      _buildTextField(
                        controller: _claimAmountController,
                        hint: 'दावा की गई राशी',
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // कार्य पूर्ण की तिथि
            _buildLabel('कार्य पूर्ण की तिथि : [*]'),
            const SizedBox(height: 8),
            _buildDropdown(
              value: _selectedCompletionDate,
              hint: '',
              onChanged: (value) {
                setState(() {
                  _selectedCompletionDate = value;
                });
              },
            ),
            const SizedBox(height: 20),

            // पंजी का नाम and खंड/Volume Row
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('पंजी का नाम : [*]'),
                      const SizedBox(height: 8),
                      _buildDropdown(
                        value: _selectedVillageName,
                        hint: '',
                        onChanged: (value) {
                          setState(() {
                            _selectedVillageName = value;
                          });
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('खंड/Volume : [*]'),
                      const SizedBox(height: 8),
                      _buildDropdown(
                        value: _selectedVolume,
                        hint: '',
                        onChanged: (value) {
                          setState(() {
                            _selectedVolume = value;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // पंजी की दिनांक
            _buildLabel('पंजी की दिनांक : [*]'),
            const SizedBox(height: 8),
            _buildDropdown(
              value: _selectedRegistryDate,
              hint: '',
              onChanged: (value) {
                setState(() {
                  _selectedRegistryDate = value;
                });
              },
            ),
            const SizedBox(height: 20),

            // अभिधुक्ति/Remark
            _buildLabel('अभिधुक्ति/Remark : [*]'),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _remarkController,
              hint: 'अभिधुक्ति/Remark',
              maxLines: 4,
            ),
            const SizedBox(height: 30),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  // Handle form submission
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2196F3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'संरक्षित करे',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        color: Colors.black87,
        fontWeight: FontWeight.w400,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(
            color: Color(0xFFBDBDBD),
            fontSize: 14,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown({
    String? value,
    required String hint,
    required Function(String?) onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          hint: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              hint,
              style: const TextStyle(
                color: Color(0xFFBDBDBD),
                fontSize: 14,
              ),
            ),
          ),
          icon: const Padding(
            padding: EdgeInsets.only(right: 12),
            child: Icon(Icons.keyboard_arrow_down, color: Colors.black54),
          ),
          items: const [], // Add your dropdown items here
          onChanged: onChanged,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _workCodeController.dispose();
    _beneficiaryCountController.dispose();
    _workAmountController.dispose();
    _claimAmountController.dispose();
    _remarkController.dispose();
    super.dispose();
  }
}