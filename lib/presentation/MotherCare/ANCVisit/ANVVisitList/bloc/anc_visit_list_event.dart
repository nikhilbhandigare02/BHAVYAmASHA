part of 'anc_visit_list_bloc.dart';

abstract class AncVisitListEvent extends Equatable {
  const AncVisitListEvent();

  @override
  List<Object> get props => [];
}

class FetchFamilyPlanningBeneficiaries extends AncVisitListEvent {}
