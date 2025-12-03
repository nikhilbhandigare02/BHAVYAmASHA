import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:medixcel_new/core/widgets/AppHeader/AppHeader.dart';
import 'package:medixcel_new/core/config/themes/CustomColors.dart';
import 'package:medixcel_new/data/SecureStorage/SecureStorage.dart';
import 'package:medixcel_new/l10n/app_localizations.dart';
import 'package:sizer/sizer.dart';
import 'dart:math' as math;
import 'bloc/todays_work_bloc.dart';

class Todaywork extends StatefulWidget {
  const Todaywork({super.key});

  @override
  State<Todaywork> createState() => _TodayworkState();
}

class _TodayworkState extends State<Todaywork> {
  int? _selectedSlice; // selected slice for tooltip
  int? _selectedSliceFromLegend; // 0=Completed hidden, 1=Pending hidden, 2=both hidden

  Future<void> _loadCountsFromStorage(TodaysWorkBloc bloc) async {
    try {
      final stored = await SecureStorageService.getTodayWorkCounts();
      final toDo = stored['toDo'] ?? 0;
      final completed = stored['completed'] ?? 0;

      if (!mounted) return;
      bloc.add(TwUpdateCounts(toDo: toDo, completed: completed));
    } catch (_) {}
  }

  int? detectSlice(Offset local, int completed, int pending) {
    const size = Size(220, 220);
    final center = Offset(size.width / 2, size.height / 2);
    final dx = local.dx - center.dx;
    final dy = local.dy - center.dy;
    final radius = math.sqrt(dx * dx + dy * dy);
    final maxRadius = size.width / 2;
    if (radius > maxRadius) return null;
    final total = completed + pending;
    if (total == 0) return null;
    double angle = math.atan2(dy, dx);
    if (angle < 0) angle += 2 * math.pi;
    const start = -math.pi / 2;
    double rel = (angle - start) % (2 * math.pi);
    if (rel < 0) rel += 2 * math.pi;
    final sweepCompleted = (completed / total) * (2 * math.pi);
    if (completed > 0 && rel <= sweepCompleted) return 0;
    if (pending > 0) return 1;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocProvider(
      create: (_) {
        final bloc = TodaysWorkBloc()..add(const TwLoad(toDo: 0, completed: 0));
        _loadCountsFromStorage(bloc);
        return bloc;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppHeader(
          screenTitle: l10n?.todayWorkTitle ?? "Today's Work Progress",
          showBack: true,
        ),
        body: SafeArea(
          child: BlocBuilder<TodaysWorkBloc, TodaysWorkState>(
            builder: (context, state) {
              int completed = state.completed;
              int pending = state.pending;

              // Adjust for hidden slices
              if (_selectedSliceFromLegend == 0) completed = 0;
              if (_selectedSliceFromLegend == 1) pending = 0;
              if (_selectedSliceFromLegend == 2) completed = pending = 0;

              final total = completed + pending;
              final progress = state.completed + state.pending == 0
                  ? 0
                  : (state.completed / (state.completed + state.pending)) * 100;
              final percent = progress.toStringAsFixed(2);

              return ListView(
                padding: const EdgeInsets.all(12),
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _kv('To do visits :', state.toDo.toString()),
                          _kv('Completed visits :', state.completed.toString()),
                          _kv('Pending visits :', state.pending.toString()),
                          _kv('Progress :', '$percent%'),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _legend(
                                  color: Colors.green,
                                  label: 'Completed',
                                  sliceIndex: 0),
                              const SizedBox(width: 16),
                              _legend(
                                  color: AppColors.primary,
                                  label: 'Pending',
                                  sliceIndex: 1),
                            ],
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 260,
                            child: Center(
                              child: SizedBox(
                                width: 220,
                                height: 220,
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  alignment: Alignment.center,
                                  children: [
                                    GestureDetector(
                                      onTapDown: (details) {
                                        int? tappedSlice = detectSlice(
                                            details.localPosition, completed, pending);
                                        setState(() {
                                          if (_selectedSlice == tappedSlice) {
                                            _selectedSlice = null;
                                          } else {
                                            _selectedSlice = tappedSlice;
                                          }
                                        });
                                      },
                                      child: CustomPaint(
                                        size: const Size(220, 220),
                                        painter: _PiePainter(
                                          completed: completed,
                                          pending: pending,
                                          legendSelected: _selectedSliceFromLegend,
                                        ),
                                      ),
                                    ),
                                    if (_selectedSlice != null)
                                      _buildTooltip(completed, pending, _selectedSlice!),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _kv(String k, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              k,
              style: TextStyle(fontSize: 15.sp, color: AppColors.primary),
            ),
          ),
          Text(
            v,
            style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _legend({
    required Color color,
    required String label,
    required int sliceIndex,
  }) {
    // Determine if this slice is striked
    bool isStriked = false;
    if (_selectedSliceFromLegend != null) {
      if (_selectedSliceFromLegend == 2) {
        isStriked = true; // both are striked
      } else if (_selectedSliceFromLegend == sliceIndex) {
        isStriked = true;
      }
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          // Toggle this slice only
          if (_selectedSliceFromLegend == null) {
            _selectedSliceFromLegend = sliceIndex; // strike this
          } else if (_selectedSliceFromLegend == sliceIndex) {
            _selectedSliceFromLegend = null; // unstrike this
          } else if (_selectedSliceFromLegend == 2) {
            // Both are striked, toggle only this slice
            // Unstriking this slice => only the other remains
            _selectedSliceFromLegend = sliceIndex == 0 ? 1 : 0;
          } else {
            // One is already striked, toggle the other => both striked
            _selectedSliceFromLegend = 2;
          }

          // Reset pie tooltip
          _selectedSlice = null;
        });
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 24,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              border: Border.all(color: Colors.white, width: 1),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: Colors.black,
              fontSize: 15,
              decoration: isStriked ? TextDecoration.lineThrough : TextDecoration.none,
              decorationThickness: 2,
            ),
          ),
        ],
      ),
    );
  }


  /*Widget _legend({
    required Color color,
    required String label,
    required int sliceIndex,
  }) {
    final bool isStriked =
    (_selectedSliceFromLegend == sliceIndex || _selectedSliceFromLegend == 2);

    return GestureDetector(
      onTap: () {
        setState(() {
          if (_selectedSliceFromLegend == sliceIndex) {
            _selectedSliceFromLegend = null; // unstrike
          } else if (_selectedSliceFromLegend == null) {
            _selectedSliceFromLegend = sliceIndex; // strike this
          } else if (_selectedSliceFromLegend != sliceIndex && _selectedSliceFromLegend != 2) {
            _selectedSliceFromLegend = 2; // both strike
          } else if (_selectedSliceFromLegend == 2) {
            _selectedSliceFromLegend = sliceIndex; // only this remains
          }

          _selectedSlice = null; // reset tooltip
        });
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 24,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              border: Border.all(color: Colors.white, width: 1),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: Colors.black,
              fontSize: 15,
              decoration:
              isStriked ? TextDecoration.lineThrough : TextDecoration.none,
              decorationThickness: 2,
            ),
          ),
        ],
      ),
    );
  }*/

  Widget _balloonTooltip({
    required String label,
    required int count,
    required Color color,
  }) {
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.85),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 4,
              offset: const Offset(2, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: color,
                border: Border.all(color: Colors.white, width: 1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '$label: $count',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTooltip(int completed, int pending, int sliceIndex) {
    final total = completed + pending;
    if (total == 0) return const SizedBox.shrink();

    const size = 220.0;
    const center = size / 2;

    double midAngle;
    int count;
    String label;
    Color color;

    const start = -math.pi / 2;
    final full = 2 * math.pi;
    final sweepCompleted = completed / total * full;
    final remainingSweep = full - sweepCompleted;

    if (sliceIndex == 0) {
      label = "Completed";
      count = completed;
      color = Colors.green;
      midAngle = start + sweepCompleted / 2;
    } else {
      label = "Pending";
      count = pending;
      color = AppColors.primary;
      midAngle = start + sweepCompleted + remainingSweep / 2;
    }

    const radius = 90.0;
    final dx = center + math.cos(midAngle) * radius;
    final dy = center + math.sin(midAngle) * radius;

    return Positioned(
      left: dx - 40,
      top: dy - 30,
      child: _balloonTooltip(label: label, count: count, color: color),
    );
  }
}

class _PiePainter extends CustomPainter {
  final int completed;
  final int pending;
  final int? legendSelected;

  _PiePainter({
    required this.completed,
    required this.pending,
    required this.legendSelected,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    const start = -math.pi / 2;
    const full = 2 * math.pi;

    int comp = completed;
    int pend = pending;

    // Handle legend hiding
    if (legendSelected == 0) comp = 0;
    if (legendSelected == 1) pend = 0;
    if (legendSelected == 2) comp = pend = 0;

    final total = comp + pend;
    if (total == 0) return;

    final paintCompleted = Paint()..color = Colors.green;
    final paintPending = Paint()..color = AppColors.primary;

    if (comp > 0) {
      final sweep = comp / total * full;
      canvas.drawArc(rect, start, sweep, true, paintCompleted);
    }
    if (pend > 0) {
      final sweep = pend / total * full;
      final startAngle = comp > 0 ? (comp / total * full) + start : start;
      canvas.drawArc(rect, startAngle, sweep, true, paintPending);
    }
  }

  @override
  bool shouldRepaint(covariant _PiePainter old) =>
      old.completed != completed ||
          old.pending != pending ||
          old.legendSelected != legendSelected;
}
