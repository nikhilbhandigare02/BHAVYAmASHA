import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'locale_event.dart';
import 'locale_state.dart';

class LocaleBloc extends Bloc<LocaleEvent, LocaleState> {
  static const _storageKey = 'app_locale_code';
  final FlutterSecureStorage _storage;

  LocaleBloc({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage(),
        super(const LocaleState(locale: Locale('en'))) {
    on<LoadSavedLocale>(_onLoadSavedLocale);
    on<ChangeLocale>(_onChangeLocale);
  }

  Future<void> _onLoadSavedLocale(
    LoadSavedLocale event,
    Emitter<LocaleState> emit,
  ) async {
    try {
      final code = await _storage.read(key: _storageKey);
      if (code != null && code.isNotEmpty) {
        emit(LocaleState(locale: Locale(code)));
      }
    } catch (_) {
      // ignore storage errors; keep default
    }
  }

  Future<void> _onChangeLocale(
    ChangeLocale event,
    Emitter<LocaleState> emit,
  ) async {
    final code = event.languageCode;
    emit(LocaleState(locale: Locale(code)));
    try {
      await _storage.write(key: _storageKey, value: code);
    } catch (_) {
      // ignore storage errors
    }
  }
}
