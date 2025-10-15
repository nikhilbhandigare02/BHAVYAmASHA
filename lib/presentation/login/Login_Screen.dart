import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:medixcel_new/core/locale/bloc/locale_bloc.dart';
import 'package:medixcel_new/core/locale/bloc/locale_event.dart';
import 'package:medixcel_new/core/config/themes/CustomColors.dart';

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
  bool isEnglish = true;
  bool isPasswordVisible = false;
  late LoginBloc loginBloc;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
loginBloc = LoginBloc();
  }
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final l10n = AppLocalizations.of(context)!;
    final localeCode = context.select((LocaleBloc b) => b.state.languageCode);
    final isEnglishSelected = localeCode == 'en';

    return Scaffold(
      backgroundColor: AppColors.background,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(30),
          child: AppBar(
            backgroundColor: AppColors.primary,
            elevation: 0,
          ),
        ),
      body: BlocProvider(create: (_)=> loginBloc,
        child: SafeArea(
          child: Stack(
            children: [
              Align(
                alignment: Alignment.bottomCenter,
                child: ClipPath(
                  clipper: TopCurveClipper(),
                  child: Container(
                    height: size.height * 0.45,
                    width: double.infinity,
                    color: AppColors.primary,
                  ),
                ),
              ),

              SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [

                    Column(
                      children: [
                        SizedBox(height: 80,),
                        Text(
                          l10n.trainingTitle,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset('assets/images/bhr1.png', height: 90),
                            SizedBox(width: 8,),
                            Image.asset('assets/images/bhabya-logo.png', height: 90),
                            SizedBox(width: 12,),
                            Image.asset('assets/images/national_health_mission.png', height: 90),

                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 40),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(4),
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
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: AppColors.onSurface,
                              ),
                            ),
                            Text(
                              l10n.loginToContinue,
                              style: TextStyle(
                                fontSize: 16,
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),


                            Row(
                              children: [
                                Expanded(
                                  child: RadioListTile<bool>(
                                    value: true,
                                    groupValue: isEnglishSelected,
                                    title: Text(l10n.english),
                                    activeColor: AppColors.primary,
                                    onChanged: (value) {
                                      context.read<LocaleBloc>().add(const ChangeLocale('en'));
                                    },
                                  ),
                                ),
                                Expanded(
                                  child: RadioListTile<bool>(
                                    value: false,
                                    groupValue: isEnglishSelected,
                                    title: Text(l10n.hindi),
                                    activeColor: AppColors.primary,
                                    onChanged: (value) {
                                      context.read<LocaleBloc>().add(const ChangeLocale('hi'));
                                    },
                                  ),
                                ),
                              ],
                            ),

                            BlocBuilder<LoginBloc, LoginState>(buildWhen: (current, previous)=> current.username != previous.username,
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
                                }),
                            Divider(color: AppColors.divider, thickness: 0.5),


                            BlocBuilder<LoginBloc, LoginState>(buildWhen: (current, previous)=> current.password != previous.password,
                                builder: (context, state){
                                  return CustomTextField(
                                    labelText: l10n.passwordLabel,
                                    hintText: l10n.passwordHint,
                                    prefixIcon: Icons.lock_outline,
                                    obscureText: true,
                                    keyboardType: TextInputType.visiblePassword,
                                    validator: (value) => Validations.validatePassword(l10n, value),
                                    onChanged: (value){
                                      context.read<LoginBloc>().add(PasswordChange(password: value));
                                    },
                                  );
                                }),
                            Divider(color: Theme.of(context).colorScheme.outlineVariant, thickness: 0.5),

                            const SizedBox(height: 12),

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
                                      content: Text(l10n.loginSuccess, style: const TextStyle(color: Colors.white)),
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
                                buildWhen: (current, previous) => false ,
                                builder: (context, state) {
                                  return SizedBox(
                                    width: double.infinity,
                                    height: 50,
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

                    Text(
                      l10n.poweredBy,
                      style: TextStyle(fontSize: 12, color: AppColors.onPrimary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "v7.8.10",
                      style: TextStyle(fontSize: 12, color: AppColors.onPrimary),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),

              BlocBuilder<LoginBloc, LoginState>(
                builder: (context, state) {
                  if (state.postApiStatus == PostApiStatus.loading) {
                    return const CenterBoxLoader(); // your loader widget
                  }
                  return const SizedBox.shrink();
                },
              ),
            ],
          ),
        ),)
    );
  }

}

class TopCurveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, 0);
    path.quadraticBezierTo(
      size.width / 2, 100,
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
