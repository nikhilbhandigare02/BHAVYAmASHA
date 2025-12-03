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
  int completed = 0;
  int pending = 0;


  int? detectSlice(Offset local) {
    const size = Size(220, 220);
    final center = Offset(size.width / 2, size.height / 2);

    final dx = local.dx - center.dx;
    final dy = local.dy - center.dy;

    final radius = math.sqrt(dx * dx + dy * dy);
    final maxRadius = size.width / 2;

    if (radius > maxRadius) return null;

    final total = (completed + pending);
    if (total == 0) return null;

    double angle = math.atan2(dy, dx);
    if (angle < 0) angle += 2 * math.pi;

    const start = -math.pi / 2;
    double rel = (angle - start) % (2 * math.pi);
    if (rel < 0) rel += 2 * math.pi;

    final sweepCompleted = (completed / total) * (2 * math.pi);

    if (completed > 0 && rel <= sweepCompleted) {
      return 0;
    }

    if (pending > 0) {
      return 1;
    }

    return null;
  }

  int? _selectedSlice;
  int? _selectedSliceFromLegend;
  int? _selectedSliceFromPie;
  Future<void> _loadCountsFromStorage(TodaysWorkBloc bloc) async {
    try {
      final stored = await SecureStorageService.getTodayWorkCounts();
      final toDo = stored['toDo'] ?? 0;
      final completed = stored['completed'] ?? 0;
      // final toDo = 4;
      // final completed = 3;
      if (!mounted) return;

      bloc.add(TwUpdateCounts(toDo: toDo, completed: completed));
    } catch (_) {
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
        backgroundColor: Colors.white,
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
                            _kv('${l10n!.toDoVisits} :', state.toDo.toString()),
                            _kv('${l10n.completedVisits} :', state.completed.toString()),
                            _kv('${l10n.pendingVisits} :', state.pending.toString()),
                            _kv('${l10n.progress} :', '$percent%'),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _legend(
                                  color: Colors.green,
                                  label: l10n.completed,
                                  sliceIndex: 0,
                                ),
                                const SizedBox(width: 16),
                                _legend(
                                  color: AppColors.primary,
                                  label: l10n.pending,
                                  sliceIndex: 1,
                                ),
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
                                          const size = Size(220, 220);
                                          final center = Offset(size.width / 2, size.height / 2);
                                          final local = details.localPosition;
                                          int? tappedSlice = detectSlice(details.localPosition);
                                          final dx = local.dx - center.dx;
                                          final dy = local.dy - center.dy;
                                          final radius = math.sqrt(dx * dx + dy * dy);
                                          final maxRadius = size.width / 2;

                                          int? newSelected;

                                          if (radius <= maxRadius) {
                                            final total = (state.completed + state.pending).clamp(0, 1 << 31);
                                            if (total > 0) {
                                              double angle = math.atan2(dy, dx);
                                              if (angle < 0) angle += 2 * math.pi;

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
                                            //   _selectedSliceFromLegend = null;

                                            // These drive the tooltip
                                            _selectedSliceFromPie = tappedSlice;
                                            _selectedSlice = tappedSlice;                                            // Toggle if tapping same slice, otherwise select new slice
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
                                            legendSelected: _selectedSliceFromLegend,
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
                                          if (_selectedSlice == 0) {
                                            final midAngle = start + completedSweep / 2;

                                            const radiusLabel = 220 / 4;
                                            final dx = math.cos(midAngle) * radiusLabel;
                                            final dy = math.sin(midAngle) * radiusLabel;

                                            return Transform.translate(
                                              offset: Offset(dx, dy),
                                              child: _insideLabel(
                                                color: Colors.green,
                                                label: 'Completed',
                                                count: state.completed,
                                              ),
                                            );
                                          }
                                          if (_selectedSlice == 1) {
                                            final midAngle = start + completedSweep + remainingSweep / 2;
                                            const radiusLabel = 220 / 4;
                                            final dx = math.cos(midAngle) * radiusLabel;
                                            final dy = math.sin(midAngle) * radiusLabel;

                                            return Transform.translate(
                                              offset: Offset(dx, dy),
                                              child: _insideLabel(
                                                color: AppColors.primary,
                                                label: l10n.pending,
                                                count: state.pending,
                                              ),
                                            );
                                          }
                                          return const SizedBox.shrink();
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
              style:  TextStyle(fontSize: 15.sp, color: AppColors.primary),
            ),
          ),
          Text(
            v,
            style:  TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _legend({
    required Color color,
    required String label,
    required int sliceIndex, // 0=completed, 1=pending
  }) {
    final bool isStriked =
    (_selectedSliceFromLegend == sliceIndex || _selectedSliceFromLegend == 2);

    return GestureDetector(
      onTap: () {
        setState(() {
          if (_selectedSliceFromLegend == sliceIndex) {
            _selectedSliceFromLegend = null;
          }

          else if (_selectedSliceFromLegend == null) {
            _selectedSliceFromLegend = sliceIndex;
          }

          else if (_selectedSliceFromLegend != sliceIndex &&
              _selectedSliceFromLegend != 2) {
            _selectedSliceFromLegend = 2;
          }


          else if (_selectedSliceFromLegend == 2) {
            _selectedSliceFromLegend = sliceIndex;
          }

          _selectedSliceFromPie = null;
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
              decoration:
              isStriked ? TextDecoration.lineThrough : TextDecoration.none,
              decorationThickness: 2,
            ),
          ),
        ],
      ),
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
  final int? legendSelected; // NEW

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

    if (legendSelected == 0) {
      canvas.drawArc(rect, start, full, true, Paint()..color = Colors.green);
      return;
    }

    if (legendSelected == 1) {
      canvas.drawArc(rect, start, full, true, Paint()..color = AppColors.primary);
      return;
    }

    if (legendSelected == 2) {
      canvas.drawArc(rect, start, full, true, Paint()..color = Colors.white);
      return;
    }

    final total = completed + pending;
    if (total == 0) return;

    final sweepCompleted = (completed / total) * full;

    final paintPending = Paint()..color = AppColors.primary;
    final paintCompleted = Paint()..color = Colors.green;

    canvas.drawArc(rect, start, full, true, paintPending);

    if (completed > 0) {
      canvas.drawArc(rect, start, sweepCompleted, true, paintCompleted);
    }
  }

  @override
  bool shouldRepaint(covariant _PiePainter old) =>
      old.completed != completed ||
          old.pending != pending ||
          old.legendSelected != legendSelected;
}

