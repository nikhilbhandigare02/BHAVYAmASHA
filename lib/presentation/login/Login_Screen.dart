import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:medixcel_new/core/locale/bloc/locale_bloc.dart';
import 'package:medixcel_new/core/locale/bloc/locale_event.dart';
import 'package:medixcel_new/core/config/themes/CustomColors.dart';
import 'package:sizer/sizer.dart';

import '../../core/config/routes/Route_Name.dart';
import 'package:medixcel_new/core/utils/Validations.dart';
import 'package:medixcel_new/core/utils/app_version.dart';
import '../../core/utils/enums.dart';
import '../../core/widgets/Loader/Loader.dart';
import '../../core/widgets/Loader/Loader_login.dart';
import '../../core/widgets/RoundButton/RoundButton.dart';
import '../../core/widgets/TextField/TextField.dart';
import '../../l10n/app_localizations.dart';
import 'bloc/login_bloc.dart';
import 'package:medixcel_new/data/sync/sync_service.dart';
import 'package:medixcel_new/core/widgets/SnackBar/app_snackbar.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  bool isPasswordVisible = false;
  late LoginBloc loginBloc;
  final _formKey = GlobalKey<FormState>();
  late AnimationController _animationController;
  bool _isKeyboardVisible = false;
  final FocusNode _usernameFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();
  String _appVersion = '';
  void _showSnackBar(BuildContext context, String message) {
    showAppSnackBar(context, message);
  }

  @override
  void initState() {
    super.initState();
    loginBloc = LoginBloc();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _loadAppVersion();
  }

  Future<void> _loadAppVersion() async {
    final version = await AppVersion.getAppVersion();
    if (mounted) {
      setState(() {
        // _appVersion = version;
        _appVersion = '1.2.1';
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final newKeyboardVisible = bottomInset > 0;

    if (newKeyboardVisible != _isKeyboardVisible) {
      _isKeyboardVisible = newKeyboardVisible;
      if (_isKeyboardVisible) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    }
  }


  @override
  void dispose() {
    _animationController.dispose();
    _usernameFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final localeCode = context.select((LocaleBloc b) => b.state.languageCode);
    final isEnglishSelected = localeCode == 'en';

    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(30),
        child: AppBar(
          backgroundColor: AppColors.primary,
          elevation: 0,
        ),
      ),
      body: BlocProvider(
        create: (_) => loginBloc,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                  minWidth: constraints.maxWidth,
                ),
                child: IntrinsicHeight(
                  child: Stack(
                    children: [
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          transform: Matrix4.identity()
                            ..translate(0.0, _isKeyboardVisible ? -15.h : 0.0),
                          child: ClipPath(
                            clipper: TopCurveClipper(
                              curveHeight: _isKeyboardVisible ? 30 : 100,
                            ),
                            child: Container(
                              height: 42.h,
                              width: double.infinity,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                              transform: Matrix4.identity()
                                ..translate(0.0, _isKeyboardVisible ? -4.h : 0.0),
                              child: Column(
                                children: [
                                  SizedBox(height: 10.h),
                                  Text(
                                    'BHAVYA mASHA Training',
                                    style: TextStyle(
                                      fontSize: 20.sp,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  SizedBox(height: 2.h),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Image.asset('assets/images/bhr1.png', height: 10.h),
                                      SizedBox(width: 1.w),
                                      Image.asset('assets/images/bhabya-logo.png', height: 10.h),
                                      SizedBox(width: 2.w),
                                      Image.asset('assets/images/national_health_mission.png', height: 10.h),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            SizedBox(height: 8.h),

                            AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                              width: double.infinity,
                              padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 1.h),
                              transform: Matrix4.identity()..translate(0.0, _isKeyboardVisible ? -10.h : 0.0),
                              transformAlignment: Alignment.center,
                              margin: EdgeInsets.only(bottom: _isKeyboardVisible ? 2.h : 5.h),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(1.w),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.shadow.withOpacity(0.1),
                                    blurRadius: 10,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      l10n.welcome,
                                      style: TextStyle(
                                        fontSize: 18.sp,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.onSurface,
                                      ),
                                    ),
                                    Text(
                                      l10n.loginToContinue,
                                      style: TextStyle(
                                        fontSize: 14.sp,
                                        color: AppColors.onSurfaceVariant,
                                      ),
                                    ),

                                    /// Language Selection
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Row(
                                          children: [
                                            Radio<bool>(
                                              value: true,
                                              groupValue: isEnglishSelected,
                                              activeColor: AppColors.primary,
                                              onChanged: (value) {
                                                context.read<LocaleBloc>().add(const ChangeLocale('en'));
                                              },
                                            ),
                                            Text(
                                              'English',
                                              style: TextStyle(fontSize: 13.5.sp),
                                            ),
                                          ],
                                        ),
                                        SizedBox(width: 8.w),
                                        Row(
                                          children: [
                                            Radio<bool>(
                                              value: false,
                                              groupValue: isEnglishSelected,
                                              activeColor: AppColors.primary,
                                              onChanged: (value) {
                                                context.read<LocaleBloc>().add(const ChangeLocale('hi'));
                                              },
                                            ),
                                            Text(
                                              'हिंदी',
                                              style: TextStyle(fontSize: 13.5.sp),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),

                                    /// Username Field
                                    BlocBuilder<LoginBloc, LoginState>(
                                      buildWhen: (current, previous) => 
                                          current.username != previous.username || 
                                          current.showValidationErrors != previous.showValidationErrors,
                                      builder: (context, state) {
                                        return CustomTextField(
                                          focusNode: _usernameFocusNode,
                                          textInputAction: TextInputAction.next,
                                          // labelText: l10n.usernameLabel,
                                          hintText: l10n.usernameHint,
                                          textStyle:  TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black,
                                            fontSize: 14.sp,
                                          ),
                                          prefixIcon: Icons.person,
                                          keyboardType: TextInputType.text,

                                          onChanged: (value) {
                                            context.read<LoginBloc>().add(UsernameChanged(username: value));
                                          },
                                        );
                                      },
                                    ),
                                    Divider(color: AppColors.divider, thickness: 0.5),

                                    /// Password Field
                                    BlocBuilder<LoginBloc, LoginState>(
                                      buildWhen: (current, previous) => 
                                          current.password != previous.password || 
                                          current.showValidationErrors != previous.showValidationErrors,
                                      builder: (context, state) {
                                        return CustomTextField(
                                          focusNode: _passwordFocusNode,
                                          // labelText: l10n.passwordHint,
                                          hintText: l10n.passwordHint,
                                          prefixIcon: Icons.key,
                                          obscureText: true,
                                          keyboardType: TextInputType.visiblePassword,
                                          textInputAction: TextInputAction.done,
                                          onChanged: (value) {
                                            context.read<LoginBloc>().add(PasswordChange(password: value));
                                          },
                                        );
                                      },
                                    ),
                                    Divider(color: Theme.of(context).colorScheme.outlineVariant, thickness: 0.5),

                                    SizedBox(height: 1.5.h),

                                BlocListener<LoginBloc, LoginState>(
                                  listenWhen: (previous, current) =>
                                  previous.postApiStatus != current.postApiStatus,
                                  listener: (context, state) {
                                    // ✅ ONLY SUCCESS (200)
                                    if (state.postApiStatus == PostApiStatus.success) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            state.error.toLowerCase().contains('user found')
                                                ? l10n.userLoginSuccses
                                                : state.error,

                                              style: const TextStyle(color: Colors.white),
                                          ),
                                          backgroundColor: Colors.black,
                                        ),
                                      );

                                      Future.delayed(const Duration(milliseconds: 500), () {
                                        if (!context.mounted) return;

                                        Navigator.pushNamedAndRemoveUntil(
                                          context,
                                          state.isNewUser
                                              ? Route_Names.profileScreen
                                              : Route_Names.homeScreen,
                                              (_) => false,
                                          arguments: {
                                            'fromLogin': true,
                                          },
                                        );
                                      });
                                    }

                                    else if (state.postApiStatus == PostApiStatus.error) {
                                      var message = state.error;
                                      if(message =='User does not exists. Please enter valid credentials.'){
                                        message =
                                        state.error == 'User does not exists. Please enter valid credentials.'
                                            ? l10n.userNotFound
                                            : state.error.isNotEmpty
                                            ? state.error
                                            : '';
                                      }
                                      else if(message =='Please enter both username and password'){
                                         message =
                                        state.error == 'Please enter both username and password'
                                            ? l10n.userNotFound
                                            : state.error.isNotEmpty
                                            ? state.error
                                            : '';
                                      }
                                      else if(message =='Please enter valid user credentials.'){
                                        message =
                                        state.error == 'Please enter valid user credentials.'
                                            ? l10n.invalidLoginCredentials
                                            : state.error.isNotEmpty
                                            ? state.error
                                            : '';
                                      }

                                      if (message.trim().isEmpty) return;

                                      // 🚫 Ignore message if it contains "error" in any case
                                      if (message.toLowerCase().contains('error')) {
                                        return;
                                      }


                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            message,
                                            style: const TextStyle(color: Colors.white),
                                          ),
                                          backgroundColor: Colors.black,
                                        ),
                                      );
                                    }

                                  },
                                  child: BlocBuilder<LoginBloc, LoginState>(
                                    buildWhen: (previous, current) => false,
                                    builder: (context, state) {
                                      return SizedBox(
                                        width: double.infinity,
                                        height: 5.h,
                                        child: RoundButton(
                                          title: l10n.loginButton,
                                          color: AppColors.primary,
                                          isLoading: state.postApiStatus == PostApiStatus.loading,
                                          onPress: () {
                                            context.read<LoginBloc>().add(ShowValidationErrors());
                                            final username = context.read<LoginBloc>().state.username;
                                            final password = context.read<LoginBloc>().state.password;

                                            if (username.isEmpty && password.isEmpty) {
                                              _showSnackBar(context, l10n.pleaseEnterValidUsername);
                                              return;
                                            }
                                            if (username.isNotEmpty && password.isEmpty) {
                                              _showSnackBar(context, l10n.pleaseEnterValidPassword);
                                              return;
                                            }

                                            if (_formKey.currentState!.validate()) {
                                              context.read<LoginBloc>().add(LoginButton());
                                            }
                                          },
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 40),
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                              transform: Matrix4.identity()
                                ..translate(0.0, _isKeyboardVisible ? -15.h : 0.0),
                              child: Column(
                                children: [
                                  Text(
                                    '${l10n.poweredBy} ${DateTime.now().year}',
                                    style: TextStyle(
                                      fontSize: 14.sp,
                                      color: AppColors.onPrimary,
                                    ),
                                  ),

                                  const SizedBox(height: 4),
                                  Text(
                                    _appVersion,
                                    style: TextStyle(fontSize: 14.sp, color: AppColors.onPrimary),
                                  ),
                                  SizedBox(height: _isKeyboardVisible ? 20.h : 40),
                                ],
                              ),
                            )
                          ],
                        ),
                      ),
                      BlocBuilder<LoginBloc, LoginState>(
                        builder: (context, state) {
                          if (state.postApiStatus == PostApiStatus.loading) {
                            return const CenterBoxLoaderLogin();
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class TopCurveClipper extends CustomClipper<Path> {
  final double curveHeight;
  
  const TopCurveClipper({this.curveHeight = 100});
  
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, 0);
    final controlPoint1 = Offset(size.width * 0.3, curveHeight);
    final controlPoint2 = Offset(size.width * 0.7, curveHeight);
    path.cubicTo(
      controlPoint1.dx, controlPoint1.dy,
      controlPoint2.dx, controlPoint2.dy,
      size.width, 0,
    );
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
