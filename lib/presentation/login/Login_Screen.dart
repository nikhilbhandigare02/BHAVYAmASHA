import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:medixcel_new/core/locale/bloc/locale_bloc.dart';
import 'package:medixcel_new/core/locale/bloc/locale_event.dart';
import 'package:medixcel_new/core/config/themes/CustomColors.dart';
import 'package:sizer/sizer.dart';

import '../../core/config/routes/Route_Name.dart';
import '../../core/utils/Validations.dart';
import '../../core/utils/enums.dart';
import '../../core/widgets/Loader/Loader.dart';
import '../../core/widgets/RoundButton/RoundButton.dart';
import '../../core/widgets/TextField/TextField.dart';
import '../../l10n/app_localizations.dart';
import 'bloc/login_bloc.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool isPasswordVisible = false;
  late LoginBloc loginBloc;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    loginBloc = LoginBloc();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final localeCode = context.select((LocaleBloc b) => b.state.languageCode);
    final isEnglishSelected = localeCode == 'en';

    return Scaffold(
      backgroundColor: AppColors.background,
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
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Stack(
                    children: [
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: ClipPath(
                          clipper: TopCurveClipper(),
                          child: Container(
                            height: 50.h,
                            width: double.infinity,
                            color: AppColors.primary,
                          ),
                        ),
                      ),

                      SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              SizedBox(height: 12.h),

                              Text(
                                l10n.trainingTitle,
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
                                  Image.asset('assets/images/bhr1.png', height: 11.h),
                                  SizedBox(width: 1.w),
                                  Image.asset('assets/images/bhabya-logo.png', height: 11.h),
                                  SizedBox(width: 2.w),
                                  Image.asset('assets/images/national_health_mission.png', height: 12.h),
                                ],
                              ),

                              const SizedBox(height: 30),

                              /// Login Form
                              Container(
                                width: double.infinity,
                                padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 2.h),
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
                                                l10n.english,
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
                                                l10n.hindi,
                                                style: TextStyle(fontSize: 13.5.sp),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),

                                      /// Username Field
                                      BlocBuilder<LoginBloc, LoginState>(
                                        buildWhen: (current, previous) => current.username != previous.username,
                                        builder: (context, state) {
                                          return CustomTextField(
                                            labelText: l10n.usernameLabel,
                                            hintText: l10n.usernameHint,
                                            prefixIcon: Icons.person_outline,
                                            keyboardType: TextInputType.text,
                                            validator: (value) => Validations.validateUsername(l10n, value),
                                            onChanged: (value) {
                                              context.read<LoginBloc>().add(UsernameChanged(username: value));
                                            },
                                          );
                                        },
                                      ),
                                      Divider(color: AppColors.divider, thickness: 0.5),

                                      /// Password Field
                                      BlocBuilder<LoginBloc, LoginState>(
                                        buildWhen: (current, previous) => current.password != previous.password,
                                        builder: (context, state) {
                                          return CustomTextField(
                                            labelText: l10n.passwordLabel,
                                            hintText: l10n.passwordHint,
                                            prefixIcon: Icons.lock_outline,
                                            obscureText: true,
                                            keyboardType: TextInputType.visiblePassword,
                                            validator: (value) => Validations.validatePassword(l10n, value),
                                            onChanged: (value) {
                                              context.read<LoginBloc>().add(PasswordChange(password: value));
                                            },
                                          );
                                        },
                                      ),
                                      Divider(color: Theme.of(context).colorScheme.outlineVariant, thickness: 0.5),

                                      SizedBox(height: 1.5.h),

                                      /// Login Button
                                      BlocListener<LoginBloc, LoginState>(
                                        listener: (context, state) {
                                          if (state.postApiStatus == PostApiStatus.success) {
                                            Navigator.pushNamedAndRemoveUntil(
                                              context,
                                              Route_Names.homeScreen,
                                                  (route) => false,
                                            );
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  l10n.loginSuccess,
                                                  style: const TextStyle(color: Colors.white),
                                                ),
                                                backgroundColor: Colors.green,
                                              ),
                                            );
                                          } else if (state.postApiStatus == PostApiStatus.error) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  state.error.isNotEmpty ? state.error : l10n.loginFailed,
                                                  style: const TextStyle(color: Colors.white),
                                                ),
                                                backgroundColor: Colors.red,
                                              ),
                                            );
                                          }
                                        },
                                        child: BlocBuilder<LoginBloc, LoginState>(
                                          buildWhen: (current, previous) => false,
                                          builder: (context, state) {
                                            return SizedBox(
                                              width: double.infinity,
                                              height: 5.h,
                                              child: RoundButton(
                                                title: l10n.loginButton,
                                                color: AppColors.primary,
                                                isLoading: state.postApiStatus == PostApiStatus.loading,
                                                onPress: () {
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

                              /// Footer
                              Text(
                                l10n.poweredBy,
                                style: TextStyle(fontSize: 12.sp, color: AppColors.onPrimary),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "v7.8.10",
                                style: TextStyle(fontSize: 12.sp, color: AppColors.onPrimary),
                              ),
                              const SizedBox(height: 40),
                            ],
                          ),
                        ),
                      ),

                      /// Loader Overlay
                      BlocBuilder<LoginBloc, LoginState>(
                        builder: (context, state) {
                          if (state.postApiStatus == PostApiStatus.loading) {
                            return const CenterBoxLoader();
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

/// 🔹 Curve Clipper for bottom background
class TopCurveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, 0);
    path.quadraticBezierTo(size.width / 2, 100, size.width, 0);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
