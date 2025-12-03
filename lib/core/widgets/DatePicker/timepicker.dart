import 'package:flutter/material.dart';

class ScrollableTimePicker extends StatefulWidget {
  final String? initialTime; // Format: "hh:mm"
  final Function(String) onTimeSelected;
  final bool use24Hour;

  const ScrollableTimePicker({
    Key? key,
    this.initialTime,
    required this.onTimeSelected,
    this.use24Hour = true,
  }) : super(key: key);

  @override
  State<ScrollableTimePicker> createState() => _ScrollableTimePickerState();
}

class _ScrollableTimePickerState extends State<ScrollableTimePicker> {
  late FixedExtentScrollController hourController;
  late FixedExtentScrollController minuteController;

  int selectedHour = 0;
  int selectedMinute = 0;

  @override
  void initState() {
    super.initState();

    // Parse initial time
    if (widget.initialTime != null && widget.initialTime!.isNotEmpty) {
      final parts = widget.initialTime!.split(':');
      if (parts.length == 2) {
        selectedHour = int.tryParse(parts[0]) ?? 0;
        selectedMinute = int.tryParse(parts[1]) ?? 0;
      }
    }

    hourController = FixedExtentScrollController(initialItem: selectedHour);
    minuteController = FixedExtentScrollController(initialItem: selectedMinute);
  }

  @override
  void dispose() {
    hourController.dispose();
    minuteController.dispose();
    super.dispose();
  }

  String _formatTime() {
    return '${selectedHour.toString().padLeft(2, '0')}:${selectedMinute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final maxHours = widget.use24Hour ? 24 : 12;

    return Container(
      height: 320,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel', style: TextStyle(fontSize: 16)),
                ),
                Text(
                  'Select Time',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () {
                    widget.onTimeSelected(_formatTime());
                    Navigator.pop(context);
                  },
                  child: Text('Done', style: TextStyle(fontSize: 16)),
                ),
              ],
            ),
          ),

          Divider(height: 1),

          // Time Pickers
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Hour Picker
                SizedBox(
                  width: 80,
                  child: _buildNumberPicker(
                    controller: hourController,
                    itemCount: maxHours,
                    onSelectedItemChanged: (index) {
                      setState(() => selectedHour = index);
                    },
                  ),
                ),

                // Separator
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    ':',
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                  ),
                ),

                // Minute Picker
                SizedBox(
                  width: 80,
                  child: _buildNumberPicker(
                    controller: minuteController,
                    itemCount: 60,
                    onSelectedItemChanged: (index) {
                      setState(() => selectedMinute = index);
                    },
                  ),
                ),
              ],
            ),
          ),

          // Current Selection Display
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              _formatTime(),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNumberPicker({
    required FixedExtentScrollController controller,
    required int itemCount,
    required Function(int) onSelectedItemChanged,
  }) {
    return ListWheelScrollView.useDelegate(
      controller: controller,
      itemExtent: 50,
      perspective: 0.005,
      diameterRatio: 1.2,
      physics: FixedExtentScrollPhysics(),
      onSelectedItemChanged: onSelectedItemChanged,
      childDelegate: ListWheelChildBuilderDelegate(
        childCount: itemCount,
        builder: (context, index) {
          final isSelected = (controller.hasClients &&
              controller.selectedItem == index);

          return Center(
            child: Text(
              index.toString().padLeft(2, '0'),
              style: TextStyle(
                fontSize: isSelected ? 22 : 16,
                fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                color: isSelected
                    ? Colors.black
                    : Colors.grey,
              ),
            ),
          );
        },
      ),
    );
  }
}

// Usage Example:
class TimePickerExample extends StatefulWidget {
  @override
  State<TimePickerExample> createState() => _TimePickerExampleState();
}

class _TimePickerExampleState extends State<TimePickerExample> {
  String? selectedTime;

  void _showTimePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => ScrollableTimePicker(
        initialTime: selectedTime,
        use24Hour: true,
        onTimeSelected: (time) {
          setState(() => selectedTime = time);
          // Call your bloc event here:
          // bloc.add(DischargeTimeChanged(time));
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Time Picker Demo')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: _showTimePicker,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.access_time),
                    SizedBox(width: 10),
                    Text(
                      selectedTime ?? 'Select Time',
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
            if (selectedTime != null)
              Text(
                'Selected: $selectedTime',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
          ],
        ),
      ),
    );
  }
}