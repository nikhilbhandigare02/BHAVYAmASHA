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
  }

  void _onEmailChange(UsernameChanged event, Emitter<LoginState> emit) {
    print(event.username);
    emit(
        state.copyWith(
            username: event.username
        )
    );
  }

  void _onPasswordChange(PasswordChange event, Emitter<LoginState> emit) {
    print(event.password);

    emit(
        state.copyWith(
            password: event.password
        )
    );
  }

  Future<void> _login(LoginButton event, Emitter<LoginState> emit) async {
    emit(state.copyWith(postApiStatus: PostApiStatus.loading));

    try {
      const validUsername = 'A10000555';
      const validPassword = 'Temp@123';

      await Future.delayed(const Duration(seconds: 1));

      if (state.username.trim() == validUsername && state.password.trim() == validPassword) {
        emit(state.copyWith(
          postApiStatus: PostApiStatus.success,
          error: '',
        ));
      } else {
        emit(state.copyWith(
          postApiStatus: PostApiStatus.error,
          error: 'Invalid email or password',
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