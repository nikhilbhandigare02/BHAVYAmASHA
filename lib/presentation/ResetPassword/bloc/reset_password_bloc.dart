import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:medixcel_new/data/repositories/Auth_Repository/auth_repository.dart';
import '../../../core/utils/enums.dart';

part 'reset_password_event.dart';
part 'reset_password_state.dart';

class ResetPasswordBloc extends Bloc<ResetPasswordEvent, ResetPasswordState> {
  final AuthRepository _authRepository;

  ResetPasswordBloc({required AuthRepository authRepository})
      : _authRepository = authRepository,
        super(const ResetPasswordState()) {
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
    emit(state.copyWith(postApiStatus: PostApiStatus.loading, error: ''));

    try {
      final response = await _authRepository.changePassword(
        username: state.username,
        currentPassword: state.currentPassword,
        newPassword: state.newPasswordPassword,
        confirmNewPassword: state.reEnterPassword,
      );

      debugPrint('Change Password API Response: $response');

      final success = response['success'] == true;
      final message = (response['msg'] ?? response['message'] ?? '').toString();

      if (success) {
        emit(state.copyWith(
          postApiStatus: PostApiStatus.success,
          error: '',
        ));
      } else {
        emit(state.copyWith(
          postApiStatus: PostApiStatus.error,
          error: message.isNotEmpty ? message : 'Failed to change password',
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        postApiStatus: PostApiStatus.error,
        error: e.toString(),
      ));
    }
  }
}
