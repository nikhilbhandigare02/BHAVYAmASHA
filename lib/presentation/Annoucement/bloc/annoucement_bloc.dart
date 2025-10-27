import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

part 'annoucement_event.dart';
part 'annoucement_state.dart';

class AnnoucementBloc extends Bloc<AnnoucementEvent, AnnoucementState> {
  AnnoucementBloc() : super(const AnnoucementState()) {
    on<AnLoad>((event, emit) async {
      const items = [
        AnnouncementItem(
          titleKey: 'announcementItem1Title',
          date: '02-01-2023',
          bodyKey: 'announcementItem1Body',
        ),
        AnnouncementItem(
          titleKey: 'announcementItem2Title',
          date: '19-02-2023',
          bodyKey: 'announcementItem2Body',
        ),
        AnnouncementItem(
          titleKey: 'announcementItem3Title',
          date: '07-03-2023',
          bodyKey: 'announcementItem3Body',
        ),
      ];
      await Future<void>.delayed(const Duration(milliseconds: 100));
      emit(state.copyWith(items: items));
    });

    on<AnToggleExpand>((event, emit) {
      final set = Set<int>.from(state.expanded);
      if (set.contains(event.index)) {
        set.remove(event.index);
      } else {
        set.add(event.index);
      }
      emit(state.copyWith(expanded: set));
    });
  }
}
