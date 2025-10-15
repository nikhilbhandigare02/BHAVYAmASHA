import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

class LocaleState extends Equatable {
  final Locale locale;
  const LocaleState({required this.locale});

  LocaleState copyWith({Locale? locale}) => LocaleState(locale: locale ?? this.locale);

  String get languageCode => locale.languageCode;

  @override
  List<Object?> get props => [locale.languageCode];
}
