 import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:medixcel_new/core/error/Exception/app_exception.dart';
import 'package:medixcel_new/data/SecureStorage/SecureStorage.dart';
import '../../../core/utils/enums.dart';
import '../../../data/models/auth/login_response_model.dart';
import '../../../data/repositories/Auth_Repository/auth_repository.dart';

part 'login_event.dart';
part 'login_state.dart';

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  final AuthRepository _authRepository = AuthRepository();

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
    emit(state.copyWith(showValidationErrors: true));
  }


  Future<void> _login(LoginButton event, Emitter<LoginState> emit) async {
    if (state.username.isEmpty || state.password.isEmpty) {
      emit(state.copyWith(
        postApiStatus: PostApiStatus.error,
        error: 'Please enter both username and password',
        showValidationErrors: true,
      ));
      return;
    }

    emit(state.copyWith(
      postApiStatus: PostApiStatus.loading,
      showValidationErrors: true,
    ));

    try {
      print('Attempting login with username: ${state.username}');
      final response = await _authRepository.login(
        state.username.trim(),
        state.password.trim(),
      );

      final loginResponse = response['loginResponse'] as LoginResponseModel;
      final isNewUser = response['isNewUser'] as bool? ?? true;
      final userData = response['user'] as Map<String, dynamic>?;

      print('Login response received. Success: ${loginResponse.success}');
      print('Token: ${loginResponse.token}');
      print('User Data: ${loginResponse.data}');
      print('Is New User: $isNewUser');

      if (loginResponse.success) {
        await SecureStorageService.setLoginFlag(1);
        
        // Save token to secure storage
        if (loginResponse.token != null) {
          await SecureStorageService.saveToken(loginResponse.token!);
          print('Token saved successfully');
          
          // Update state with login success and user status
          emit(state.copyWith(
            postApiStatus: PostApiStatus.success,
            isNewUser: isNewUser,
            error: loginResponse.msg ?? '',
          ));
          
          // Navigation will be handled in the UI based on isNewUser
        } else {
          emit(state.copyWith(
            postApiStatus: PostApiStatus.error,
            error: 'No authentication token received',
          ));
        }
      } else {
        emit(state.copyWith(
          postApiStatus: PostApiStatus.error,
          error: loginResponse.msg ?? '',
        ));
      }
    } catch (e) {
      print('Login error: $e');
      emit(state.copyWith(
        postApiStatus: PostApiStatus.error,
        error: e is AppExceptions ? e.toString() : 'An error occurred during login. Please try again.',
      ));
    }
  }
}