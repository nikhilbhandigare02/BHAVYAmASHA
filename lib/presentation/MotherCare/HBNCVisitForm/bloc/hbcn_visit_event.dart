import 'package:equatable/equatable.dart';

abstract class HbncVisitEvent extends Equatable {
  const HbncVisitEvent();

  @override
  List<Object?> get props => [];
}

class TabChanged extends HbncVisitEvent {
  final int tabIndex;
  
  const TabChanged(this.tabIndex);

  @override
  List<Object?> get props => [tabIndex];
}

class MotherDetailsChanged extends HbncVisitEvent {
  final String field;
  final dynamic value;

  const MotherDetailsChanged({required this.field, required this.value});

  @override
  List<Object?> get props => [field, value];
}

class NewbornDetailsChanged extends HbncVisitEvent {
  final String field;
  final dynamic value;

  const NewbornDetailsChanged({required this.field, required this.value});

  @override
  List<Object?> get props => [field, value];
}

class VisitDetailsChanged extends HbncVisitEvent {
  final String field;
  final dynamic value;

  const VisitDetailsChanged({required this.field, required this.value});

  @override
  List<Object?> get props => [field, value];
}

class SubmitHbncVisit extends HbncVisitEvent {
  final Map<String, dynamic>? beneficiaryData;
  
  const SubmitHbncVisit({this.beneficiaryData});
  
  @override
  List<Object?> get props => [beneficiaryData];
}

class ResetHbncVisitForm extends HbncVisitEvent {}

class SaveHbncVisit extends HbncVisitEvent {
  final Map<String, dynamic>? beneficiaryData;
  
  const SaveHbncVisit({this.beneficiaryData});
  
  @override
  List<Object?> get props => [beneficiaryData];
}

class ValidateSection extends HbncVisitEvent {
  final int index;
  final bool isSave;
  const ValidateSection(this.index, {this.isSave = false});

  @override
  List<Object?> get props => [index, isSave];
}
