part of 'annoucement_bloc.dart';

class AnnouncementItem extends Equatable {
  final String title;
  final String date;
  final String body;
  const AnnouncementItem({required this.title, required this.date, required this.body});
  @override
  List<Object?> get props => [title, date, body];
}

class AnnoucementState extends Equatable {
  const AnnoucementState({this.items = const [], this.expanded = const {}});

  final List<AnnouncementItem> items;
  final Set<int> expanded; // indexes expanded

  AnnoucementState copyWith({List<AnnouncementItem>? items, Set<int>? expanded}) {
    return AnnoucementState(
      items: items ?? this.items,
      expanded: expanded ?? this.expanded,
    );
  }

  @override
  List<Object?> get props => [items, expanded];
}
