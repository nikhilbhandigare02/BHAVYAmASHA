import 'dart:convert';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:medixcel_new/data/repositories/Auth_Repository/auth_repository.dart';
import '../../../core/utils/enums.dart';
import '../../../l10n/app_localizations.dart';

part 'reset_password_event.dart';
part 'reset_password_state.dart';

class ResetPasswordBloc extends Bloc<ResetPasswordEvent, ResetPasswordState> {
  final AuthRepository _authRepository;
  final AppLocalizations l10n;

  ResetPasswordBloc({
    required AuthRepository authRepository,
    required this.l10n,
  }) : _authRepository = authRepository,
        super(const ResetPasswordState()) {
    on<UsernameChanged>(_onUsernameChange);
    on<CurrentPasswordChange>(_onCurrentPassChange);
    on<NewPasswordChange>(_onNewPassChange);
    on<ReEnterPasswordChange>(_onReEnterPassChange);
    on<ResetPasswordButton>(_onResetPassButton);
  }

  void _onUsernameChange(
    UsernameChanged event,
    Emitter<ResetPasswordState> emit,
  ) {
    debugPrint('Username: ${event.username}');
    emit(state.copyWith(
      username: event.username,
      postApiStatus: PostApiStatus.initial,
      error: '',
      successMessage: '',
    ));
  }

  void _onCurrentPassChange(
    CurrentPasswordChange event,
    Emitter<ResetPasswordState> emit,
  ) {
    debugPrint('Current Password: ${event.currentPassword}');
    emit(state.copyWith(
      currentPassword: event.currentPassword,
      postApiStatus: PostApiStatus.initial,
      error: '',
      successMessage: '',
    ));
  }

  void _onNewPassChange(
    NewPasswordChange event,
    Emitter<ResetPasswordState> emit,
  ) {
    debugPrint('New Password: ${event.newPassword}');
    emit(state.copyWith(
      newPasswordPassword: event.newPassword,
      postApiStatus: PostApiStatus.initial,
      error: '',
      successMessage: '',
    ));
  }

  void _onReEnterPassChange(
    ReEnterPasswordChange event,
    Emitter<ResetPasswordState> emit,
  ) {
    debugPrint('Re-enter Password: ${event.reEnterPassword}');
    emit(state.copyWith(
      reEnterPassword: event.reEnterPassword,
      postApiStatus: PostApiStatus.initial,
      error: '',
      successMessage: '',
    ));
  }

  // Update the _onResetPassButton method in reset_password_bloc.dart
  Future<void> _onResetPassButton(
    ResetPasswordButton event,
    Emitter<ResetPasswordState> emit,
  ) async {
    emit(
      state.copyWith(
        postApiStatus: PostApiStatus.loading,
        error: '',
        successMessage: '',
      ),
    );

    // ---- VALIDATIONS (Same order as OLD APP) ----

    if (state.username.trim().isEmpty) {
      emit(
        state.copyWith(
          postApiStatus: PostApiStatus.error,
          error: l10n?.validateEmptyUsername ?? 'Please enter the username',
        ),
      );
      return;
    }

    if (state.currentPassword.trim().isEmpty) {
      emit(
        state.copyWith(
          postApiStatus: PostApiStatus.error,
          error: l10n?.validateEmptyCP ?? 'Please enter the current password',
        ),
      );
      return;
    }

    if (state.newPasswordPassword.trim().isEmpty) {
      emit(
        state.copyWith(
          postApiStatus: PostApiStatus.error,
          error: l10n?.validateEmptyNP ?? 'Please enter the new password',
        ),
      );
      return;
    }

    if (state.currentPassword.trim() == state.newPasswordPassword.trim()) {
      emit(
        state.copyWith(
          postApiStatus: PostApiStatus.error,
          error:
              l10n?.cpAndNPNotSame ??
              'The Current password and the new password can not be same.',
        ),
      );
      return;
    }

    if (state.reEnterPassword.trim().isEmpty) {
      emit(
        state.copyWith(
          postApiStatus: PostApiStatus.error,
          error: l10n?.validateEmptyRRP ?? 'Please re-enter the new password',
        ),
      );
      return;
    }

    if (state.newPasswordPassword.trim() != state.reEnterPassword.trim()) {
      emit(
        state.copyWith(
          postApiStatus: PostApiStatus.error,
          error:
              l10n?.npAndRRPValidation ??
              'The new password and the re-entered password must be the same.',
        ),
      );
      return;
    }

    // ---- ALL VALIDATIONS PASSED → CALL API ----

    emit(state.copyWith(postApiStatus: PostApiStatus.loading));

    try {
      final response = await _authRepository.changePassword(
        username: state.username,
        currentPassword: state.currentPassword,
        newPassword: state.newPasswordPassword,
        confirmNewPassword: state.reEnterPassword,
      );

      debugPrint('Change Password API Response: $response');

      if (response is Map<String, dynamic>) {
        final success = response['success'] == true;
        final message =
            (response['msg'] ??
                    response['message'] ??
                    (success
                        ? l10n?.successUpdatePassMsg ??
                              'Your password has been changed successfully'
                        : l10n?.failUpdatePassMsg ??
                              'Failed to update password'))
                .toString();

        if (success) {
          emit(
            state.copyWith(
              postApiStatus: PostApiStatus.success,
              successMessage: message,
              error: '',
            ),
          );
        } else {
          final lm = message.toLowerCase();
          final friendly = (lm.contains('unauthorized') || lm.contains('invalid auth') || lm.contains('authentication'))
              ? 'Please enter the correct password'
              : message;
          emit(
            state.copyWith(
              postApiStatus: PostApiStatus.error,
              error: friendly,
              successMessage: '',
            ),
          );
        }
      } else {
        emit(
          state.copyWith(
            postApiStatus: PostApiStatus.error,
            error: 'Unexpected response format',
            successMessage: '',
          ),
        );
      }
    } catch (e) {
      final raw = e.toString();
      String err = raw;
      try {
        final match = RegExp(r'\{[\s\S]*\}').firstMatch(raw);
        if (match != null) {
          final jsonStr = match.group(0)!;
          final map = jsonDecode(jsonStr) as Map<String, dynamic>;
          final apiMsg = (map['msg'] ?? map['message'] ?? '').toString();
          if (apiMsg.isNotEmpty) {
            err = apiMsg;
          }
        } else if (raw.contains('"msg":"')) {
          final start = raw.indexOf('"msg":"') + 7;
          final end = raw.indexOf('"', start);
          if (start >= 7 && end > start) {
            err = raw.substring(start, end);
          }
        }
      } catch (_) {}

      final lower = err.toLowerCase();
      if (lower.contains('unauthorized') || lower.contains('invalid auth') || lower.contains('authentication')) {
        err = 'Please enter the correct current password';
      } else if (err.isEmpty) {
        err = l10n?.errorMsg ?? 'An error occurred. Please try again.';
      }

      emit(
        state.copyWith(
          postApiStatus: PostApiStatus.error,
          error: err,
          successMessage: '',
        ),
      );
    }
  }
}
