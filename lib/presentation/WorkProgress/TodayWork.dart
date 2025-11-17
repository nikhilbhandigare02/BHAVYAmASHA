import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:medixcel_new/core/widgets/AppHeader/AppHeader.dart';
import 'package:medixcel_new/core/config/themes/CustomColors.dart';
import 'package:medixcel_new/data/SecureStorage/SecureStorage.dart';
import 'package:medixcel_new/l10n/app_localizations.dart';
import 'package:sizer/sizer.dart';
import 'bloc/todays_work_bloc.dart';

class Todaywork extends StatefulWidget {
  const Todaywork({super.key});

  @override
  State<Todaywork> createState() => _TodayworkState();
}

class _TodayworkState extends State<Todaywork> {
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
                                _legend(color: Colors.blue, label: 'Pending'),
                              ],
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              height: 260,
                              child: Center(
                                child: CustomPaint(
                                  size: const Size(220, 220),
                                  painter: _PiePainter(
                                    completed: state.completed,
                                    pending: state.pending,
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
        Container(width: 24, height: 8, color: color),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
class _PiePainter extends CustomPainter {
  final int completed;
  final int pending;

  _PiePainter({required this.completed, required this.pending});

  @override
  void paint(Canvas canvas, Size size) {
    final total = (completed + pending).clamp(0, 1 << 31);
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);

    final bgPaint = Paint()..color = Colors.blue;
    canvas.drawArc(rect, -1.5708, 6.28318, true, bgPaint); // full circle pending

    if (total > 0 && completed > 0) {
      final sweep = (completed / total) * 6.28318;
      final compPaint = Paint()..color = Colors.green;
      canvas.drawArc(rect, -1.5708, sweep, true, compPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _PiePainter oldDelegate) {
    return oldDelegate.completed != completed || oldDelegate.pending != pending;
  }
}
