import 'package:flutter/material.dart';
import 'package:medixcel_new/core/config/themes/CustomColors.dart';
import 'package:medixcel_new/core/widgets/AppHeader/AppHeader.dart';
import 'package:medixcel_new/l10n/app_localizations.dart';

class PreviousVisitScreen extends StatefulWidget {
  const PreviousVisitScreen({super.key});

  @override
  State<PreviousVisitScreen> createState() => _PreviousVisitScreenState();
}

class _PreviousVisitScreenState extends State<PreviousVisitScreen> {
  // Sample data for previous visits
  final List<Map<String, dynamic>> _visits = [
    {
      'visitDate': '16-10-2025',
      'visitType': 'PNC',
      'visitStatus': 'Completed',
      'visitDetails': 'Post Natal Care visit for routine checkup',
      'healthWorker': 'Dr. Smith',
    },
    {
      'visitDate': '10-10-2025',
      'visitType': 'HBNC',
      'visitStatus': 'Completed',
      'visitDetails': 'Home Based Newborn Care visit',
      'healthWorker': 'Nurse Johnson',
    },
    {
      'visitDate': '05-10-2025',
      'visitType': 'ANC',
      'visitStatus': 'Completed',
      'visitDetails': 'Antenatal Care visit',
      'healthWorker': 'Dr. Williams',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    
    return Scaffold(
      appBar: AppHeader(
        screenTitle: l10n?.previousVisits ?? 'Previous Visits',
        showBack: true,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _visits.length,
        itemBuilder: (context, index) {
          final visit = _visits[index];
          return _buildVisitCard(visit, context);
        },
      ),
    );
  }

  Widget _buildVisitCard(Map<String, dynamic> visit, BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final Color statusColor = visit['visitStatus'] == 'Completed' 
        ? Colors.green 
        : Colors.orange;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Visit header with date and status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${l10n?.visitDateLabel ?? 'Visit Date'}: ${visit['visitDate']}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor.withOpacity(0.5)),
                  ),
                  child: Text(
                    visit['visitStatus'],
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Visit type
            _buildInfoRow(
              l10n?.visitTypeLabel ?? 'Visit Type',
              visit['visitType'],
              Icons.medical_services_outlined,
            ),
            const SizedBox(height: 8),
            
            // Visit details
            _buildInfoRow(
              l10n?.detailsLabel ?? 'Details',
              visit['visitDetails'],
              Icons.description_outlined,
            ),
            const SizedBox(height: 8),
            
            // Health worker
            _buildInfoRow(
              l10n?.healthWorkerLabel ?? 'Health Worker',
              visit['healthWorker'],
              Icons.person_outline,
            ),
            
            const SizedBox(height: 12),
            
            // View details button
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  // Handle view details
                },
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).primaryColor,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: Theme.of(context).primaryColor),
                  ),
                ),
                child: Text(l10n?.viewDetails ?? 'View Details'),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
