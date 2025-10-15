import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import '../../../core/utils/enums.dart';

part 'reset_password_event.dart';
part 'reset_password_state.dart';

class ResetPasswordBloc extends Bloc<ResetPasswordEvent, ResetPasswordState> {
  ResetPasswordBloc() : super(const ResetPasswordState()) {
    on<UsernameChanged>(_onUsernameChange);
    on<CurrentPasswordChange>(_onCurrentPassChange);
    on<NewPasswordChange>(_onNewPassChange);
    on<ReEnterPasswordChange>(_onReEnterPassChange);
    on<ResetPasswordButton>(_onResetPassButton);
  }

  void _onUsernameChange(UsernameChanged event, Emitter<ResetPasswordState> emit) {
    debugPrint('Username: ${event.username}');
    emit(state.copyWith(username: event.username));
  }

  void _onCurrentPassChange(CurrentPasswordChange event, Emitter<ResetPasswordState> emit) {
    debugPrint('Current Password: ${event.currentPassword}');
    emit(state.copyWith(currentPassword: event.currentPassword));
  }

  void _onNewPassChange(NewPasswordChange event, Emitter<ResetPasswordState> emit) {
    debugPrint('New Password: ${event.newPassword}');
    emit(state.copyWith(newPasswordPassword: event.newPassword));
  }

  void _onReEnterPassChange(ReEnterPasswordChange event, Emitter<ResetPasswordState> emit) {
    debugPrint('Re-enter Password: ${event.reEnterPassword}');
    emit(state.copyWith(reEnterPassword: event.reEnterPassword));
  }

  Future<void> _onResetPassButton(
      ResetPasswordButton event, Emitter<ResetPasswordState> emit) async {
    emit(state.copyWith(postApiStatus: PostApiStatus.loading));

    try {
      const validUsername = 'A10000555';
      const validCurrentPassword = 'Temp@123';
      const validNewPassword = 'Temp@1234';

      await Future.delayed(const Duration(seconds: 1));

      if (state.username.trim() == validUsername &&
          state.currentPassword.trim() == validCurrentPassword && state.currentPassword.trim() == validNewPassword) {
        emit(state.copyWith(
          postApiStatus: PostApiStatus.success,
          error: '',
        ));
      } else {
        emit(state.copyWith(
          postApiStatus: PostApiStatus.error,
          error: 'Invalid username or password',
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        postApiStatus: PostApiStatus.error,
        error: 'Something went wrong',
      ));
    }
  }
}
