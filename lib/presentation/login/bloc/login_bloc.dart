 import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:medixcel_new/core/error/Exception/app_exception.dart';
import 'package:medixcel_new/data/SecureStorage/SecureStorage.dart';
import '../../../core/utils/enums.dart';
import '../../../data/repositories/auth_repository.dart';

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

      print('Login response received. Success: ${response.success}');
      print('Token: ${response.token}');
      print('User Data: ${response.data}');

      if (response.success) {
        await SecureStorageService.setLoginFlag(1);
        
        // Save token to secure storage
        if (response.token != null) {
          await SecureStorageService.saveToken(response.token!);
          print('Token saved successfully');
          
          // Save user data with unique key if available
          if (response.data != null) {
            try {
              print('Saving user data: ${response.data}');
              final userData = response.data!;
              final uniqueKey = userData['unique_key'] ?? 
                              userData['id']?.toString() ?? 
                              userData['username'] ?? 
                              'default_key';
              
              print('Using unique key: $uniqueKey');
              await SecureStorageService.saveUserDataWithKey(uniqueKey, userData);
              
              // Verify data was saved
              final savedData = await SecureStorageService.getCurrentUserData();
              print('Verification - Retrieved saved data: $savedData');
            } catch (e) {
              print('Error saving user data: $e');
              // Don't fail the login if we can't save user data
            }
          } else {
            print('No user data in response');
          }
        } else {
          print('No token in response');
        }
        
        emit(state.copyWith(
          postApiStatus: PostApiStatus.success,
          error: '',
          showValidationErrors: false,
        ));
      } else {
        emit(state.copyWith(
          postApiStatus: PostApiStatus.error,
          error: response.msg ?? 'Login failed',
          showValidationErrors: true,
        ));
      }
    } on AppExceptions catch (e) {
      emit(state.copyWith(
        postApiStatus: PostApiStatus.error,
        error: e.toString(),
        showValidationErrors: true,
      ));
    } catch (e) {
      emit(state.copyWith(
        postApiStatus: PostApiStatus.error,
        error: 'An unexpected error occurred. Please try again.',
        showValidationErrors: true,
      ));
    }
  }}