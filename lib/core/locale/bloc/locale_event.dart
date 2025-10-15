import 'package:equatable/equatable.dart';

abstract class LocaleEvent extends Equatable {
  const LocaleEvent();
  @override
  List<Object?> get props => [];
}

class LoadSavedLocale extends LocaleEvent {
  const LoadSavedLocale();
}

class ChangeLocale extends LocaleEvent {
  final String languageCode; // e.g., 'en' or 'hi'
  const ChangeLocale(this.languageCode);

  @override
  List<Object?> get props => [languageCode];
}
