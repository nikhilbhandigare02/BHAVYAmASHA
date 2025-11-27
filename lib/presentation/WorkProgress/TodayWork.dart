import 'package:flutter/cupertino.dart';
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
  // 0 = completed slice, 1 = pending slice, null = none selected
  int? _selectedSlice;
  Future<void> _loadCountsFromStorage(TodaysWorkBloc bloc) async {
    try {
      final stored = await SecureStorageService.getTodayWorkCounts();
      final toDo = stored['toDo'] ?? 0;
      final completed = stored['completed'] ?? 0;

      if (!mounted) return;

      bloc.add(TwUpdateCounts(toDo: toDo, completed: completed));
    } catch (_) {
      // leave defaults if anything fails
    }
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
        appBar: AppHeader(screenTitle: l10n?.todayWorkTitle ?? "Today's Work Progress", showBack: true),
        body: SafeArea(
          child: BlocBuilder<TodaysWorkBloc, TodaysWorkState>(
              builder: (context, state) {
                final total = (state.completed + state.pending);
                final progress = total == 0 ? 0 : (state.completed / total) * 100;
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
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
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
                                _legend(color: Colors.green, label: 'Completed'),
                                const SizedBox(width: 16),
                                _legend(color: AppColors.primary, label: 'Pending'),
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
                                    alignment: Alignment.center,
                                    children: [
                                      GestureDetector(
                                        onTapDown: (details) {
                                          // Determine which slice (if any) was tapped
                                          const size = Size(220, 220);
                                          final center = Offset(size.width / 2, size.height / 2);
                                          final local = details.localPosition;

                                          final dx = local.dx - center.dx;
                                          final dy = local.dy - center.dy;
                                          final radius = math.sqrt(dx * dx + dy * dy);
                                          final maxRadius = size.width / 2;

                                          int? newSelected;

                                          if (radius <= maxRadius) {
                                            final total = (state.completed + state.pending).clamp(0, 1 << 31);
                                            if (total > 0) {
                                              // atan2 gives angle in range [-pi, pi]. Convert to [0, 2*pi).
                                              double angle = math.atan2(dy, dx);
                                              if (angle < 0) angle += 2 * math.pi;

                                              // Our pie starts at -pi/2 (top). Normalize tap angle relative to that.
                                              const start = -math.pi / 2;
                                              double rel = angle - start;
                                              final full = 2 * math.pi;
                                              rel = rel % full;
                                              if (rel < 0) rel += full; // ensure 0..2*pi

                                              final totalAngle = full;
                                              final completedSweep = (state.completed / total) * totalAngle;

                                              if (state.completed > 0 && rel <= completedSweep) {
                                                newSelected = 0; // completed
                                              } else if (state.pending > 0) {
                                                newSelected = 1; // pending
                                              }
                                            }
                                          }

                                          setState(() {
                                            // Toggle if tapping same slice, otherwise select new slice
                                            if (_selectedSlice == newSelected) {
                                              _selectedSlice = null;
                                            } else {
                                              _selectedSlice = newSelected;
                                            }
                                          });
                                        },
                                        child: CustomPaint(
                                          size: const Size(220, 220),
                                          painter: _PiePainter(
                                            completed: state.completed,
                                            pending: state.pending,
                                            selectedSlice: _selectedSlice,
                                          ),
                                        ),
                                      ),
                                      if (_selectedSlice != null)
                                        Builder(builder: (_) {
                                          final total = (state.completed + state.pending).clamp(0, 1 << 31);
                                          if (total == 0) {
                                            return const SizedBox.shrink();
                                          }

                                          const start = -math.pi / 2;
                                          final full = 2 * math.pi;
                                          final completedSweep = (state.completed / total) * full;
                                          final remainingSweep = full - completedSweep;

                                          double midAngle;
                                          Color color;
                                          String label;
                                          int count;

                                          if (_selectedSlice == 1) {
                                            midAngle = start + completedSweep + remainingSweep / 2;
                                            color = AppColors.primary;
                                            label = 'Pending';
                                            count = state.pending;

                                            const radiusLabel = 220 / 4;
                                            final dx = math.cos(midAngle) * radiusLabel;
                                            final dy = math.sin(midAngle) * radiusLabel;

                                            return Transform.translate(
                                              offset: Offset(dx, dy),
                                              child: _insideLabel(
                                                color: color,
                                                label: label,
                                                count: count,
                                              ),
                                            );
                                          } else {
                                            return const SizedBox.shrink();
                                          }
                                        }),
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
              }
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
              style:  TextStyle(fontSize: 14.sp, color: AppColors.primary),
            ),
          ),
          Text(
            v,
            style:  TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _legend({required Color color, required String label}) {
    return Row(
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
          style: const TextStyle(fontSize: 12, color: Colors.black),
        ),
      ],
    );
  }
  
  Widget _insideLabel({
    required Color color,
    required String label,
    required int count,
  }) {
    return Row(
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
            fontWeight: FontWeight.w500,
            fontSize: 12,
          ),
        ),
      ],
    );
  }


}
class _PiePainter extends CustomPainter {
  final int completed;
  final int pending;
  final int? selectedSlice; // 0 = completed, 1 = pending, null = none

  _PiePainter({
    required this.completed,
    required this.pending,
    required this.selectedSlice,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final total = (completed + pending).clamp(0, 1 << 31);
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);

    final bool highlightPending = selectedSlice == 1;
    final Color pendingColor = highlightPending
        ? Color.lerp(AppColors.primary, Colors.blue[900], 0.3) ?? AppColors.primary
        : AppColors.primary;
    final bgPaint = Paint()..color = pendingColor;
    canvas.drawArc(rect, -1.5708, 6.28318, true, bgPaint); // full circle pending

    // Completed slice overlay
    if (total > 0 && completed > 0) {
      final sweep = (completed / total) * 6.28318;
      final bool highlightCompleted = selectedSlice == 0;
      final Color completedColor = highlightCompleted
          ? Colors.green.shade800
          : Colors.green;
      final compPaint = Paint()..color = completedColor;
      canvas.drawArc(rect, -1.5708, sweep, true, compPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _PiePainter oldDelegate) {
    return oldDelegate.completed != completed ||
        oldDelegate.pending != pending ||
        oldDelegate.selectedSlice != selectedSlice;
  }
}
