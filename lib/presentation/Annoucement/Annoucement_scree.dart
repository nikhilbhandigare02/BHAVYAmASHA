import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:medixcel_new/core/widgets/AppHeader/AppHeader.dart';
import 'package:medixcel_new/l10n/app_localizations.dart';
import '../Annoucement/bloc/annoucement_bloc.dart';

class AnnoucementScree extends StatefulWidget {
  const AnnoucementScree({super.key});

  @override
  State<AnnoucementScree> createState() => _AnnoucementScreeState();
}

class _AnnoucementScreeState extends State<AnnoucementScree> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocProvider(
      create: (_) => AnnoucementBloc()..add(const AnLoad()),
      child: Scaffold(
        appBar: AppHeader(screenTitle: l10n?.announcement ?? 'Announcements List', showBack: true),
        body: SafeArea(
          child: BlocBuilder<AnnoucementBloc, AnnoucementState>(
            builder: (context, state) {
              return ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: state.items.length,
                itemBuilder: (context, index) {
                  final item = state.items[index];
                  final expanded = state.expanded.contains(index);
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 2)),
                      ],
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () => context.read<AnnoucementBloc>().add(AnToggleExpand(index)),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    item.title,
                                    style: const TextStyle(
                                      color: Color(0xFF1976D2),
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  item.date,
                                  style: const TextStyle(color: Colors.black54, fontSize: 12),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              item.body,
                              maxLines: expanded ? null : 2,
                              overflow: expanded ? TextOverflow.visible : TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.black87, height: 1.3),
                            ),
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                expanded ? 'Read less' : 'Read more',
                                style: const TextStyle(color: Color(0xFF1976D2), fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
