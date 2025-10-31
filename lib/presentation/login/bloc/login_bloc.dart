import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../core/utils/enums.dart';
import '../../../data/repositories/LoginRepository.dart';

part 'login_event.dart';
part 'login_state.dart';

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  LoginRepository loginRepository = LoginRepository();

  LoginBloc() : super(LoginState()) {
    on<UsernameChanged>(_onEmailChange);
    on<PasswordChange>(_onPasswordChange);
    on<LoginButton>(_login);
    on<ShowValidationErrors>(_showValidationErrors);
  }

  void _onEmailChange(UsernameChanged event, Emitter<LoginState> emit) {
    emit(
      state.copyWith(
        username: event.username,
        postApiStatus: PostApiStatus.initial, // reset status
        error: '', // clear old error message

      )
    );
  }

  void _onPasswordChange(PasswordChange event, Emitter<LoginState> emit) {
    emit(
      state.copyWith(
        password: event.password,
        postApiStatus: PostApiStatus.initial, // reset status
        error: '',
      )
    );
  }

  void _showValidationErrors(ShowValidationErrors event, Emitter<LoginState> emit) {
    // Just show validation errors without changing other states
    emit(state.copyWith(showValidationErrors: true));
  }

  Future<void> _login(LoginButton event, Emitter<LoginState> emit) async {
    // Set loading state
    emit(state.copyWith(
      postApiStatus: PostApiStatus.loading,
      showValidationErrors: true, // Show validation errors
    ));

    try {
      const validUsername = 'A10000555';
      const validPassword = 'Temp@123';

      await Future.delayed(const Duration(seconds: 1));

      if (state.username.trim() == validUsername && state.password.trim() == validPassword) {
        emit(state.copyWith(
          postApiStatus: PostApiStatus.success,
          error: '',
          showValidationErrors: false, // Hide validation errors on success
        ));
      } else {
        emit(state.copyWith(
          postApiStatus: PostApiStatus.error,
          error: 'Invalid username or password',
          showValidationErrors: true, // Show validation errors on error
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        postApiStatus: PostApiStatus.error,
        error: 'Something went wrong',
        showValidationErrors: true, // Show validation errors on error
      ));
    }
  }

}