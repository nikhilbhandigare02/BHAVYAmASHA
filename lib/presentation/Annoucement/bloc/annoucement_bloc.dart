import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

part 'annoucement_event.dart';
part 'annoucement_state.dart';

class AnnoucementBloc extends Bloc<AnnoucementEvent, AnnoucementState> {
  AnnoucementBloc() : super(const AnnoucementState()) {
    on<AnLoad>((event, emit) async {
      // Mock data list
      const items = [
        AnnouncementItem(
          title: 'Distribution: Smart phones given to ASHA workers',
          date: '02-01-2023',
          body:
              'In the local primary health center, smart phones were given to the ASHA workers of the block area for health related work... The mobile is specially designed for health related programs.',
        ),
        AnnouncementItem(
          title: 'Bihar ASHA Worker Vacancy 2023: Great opportunity',
          date: '19-02-2023',
          body: 'If you are a resident of Bihar and you are a woman, then...',
        ),
        AnnouncementItem(
          title: 'ASHA Workers of Bihar Demand Better Wages, Work Environment',
          date: '07-03-2023',
          body: 'ASHA Workers have been at the forefront of the fight against...',
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
