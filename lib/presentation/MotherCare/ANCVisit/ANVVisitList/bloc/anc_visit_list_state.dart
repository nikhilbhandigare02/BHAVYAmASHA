part of 'anc_visit_list_bloc.dart';

abstract class AncVisitListState extends Equatable {
  const AncVisitListState();

  @override
  List<Object> get props => [];
}

class AncVisitListInitial extends AncVisitListState {}

class AncVisitListLoading extends AncVisitListState {}

class AncVisitListLoaded extends AncVisitListState {
  final List<Map<String, dynamic>> beneficiaries;

  const AncVisitListLoaded({required this.beneficiaries});

  @override
  List<Object> get props => [beneficiaries];
}

class AncVisitListError extends AncVisitListState {
  final String message;

  const AncVisitListError({required this.message});

  @override
  List<Object> get props => [message];
}
