part of 'annoucement_bloc.dart';

class AnnouncementItem extends Equatable {
  final String titleKey;
  final String date;
  final String bodyKey;
  const AnnouncementItem({required this.titleKey, required this.date, required this.bodyKey});
  @override
  List<Object?> get props => [titleKey, date, bodyKey];
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
