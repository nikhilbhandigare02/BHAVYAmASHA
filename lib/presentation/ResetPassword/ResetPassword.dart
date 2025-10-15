import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:medixcel_new/core/widgets/AppHeader/AppHeader.dart';
import 'package:medixcel_new/presentation/ResetPassword/bloc/reset_password_bloc.dart';
import 'package:medixcel_new/core/config/themes/CustomColors.dart';

import '../../core/config/routes/Route_Name.dart';
import '../../core/utils/Validations.dart';
import '../../core/utils/enums.dart';
import '../../core/widgets/RoundButton/RoundButton.dart';
import '../../core/widgets/TextField/TextField.dart';
import '../../l10n/app_localizations.dart';

class Resetpassword extends StatefulWidget {
  const Resetpassword({super.key});

  @override
  State<Resetpassword> createState() => _ResetpasswordState();
}

class _ResetpasswordState extends State<Resetpassword> {
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocProvider(
      create: (_) => ResetPasswordBloc(),
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppHeader(screenTitle: l10n.resetCreateNewPasswordTitle, showBack: true),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          BlocBuilder<ResetPasswordBloc, ResetPasswordState>(
                            buildWhen: (prev, curr) => prev.username != curr.username,
                            builder: (context, state) {
                              return CustomTextField(
                                labelText: l10n.usernameLabel,
                                hintText: l10n.usernameHint,
                                keyboardType: TextInputType.text,
                                validator: (value) => Validations.validateUsername(l10n, value),
                                onChanged: (value) {
                                  context
                                      .read<ResetPasswordBloc>()
                                      .add(UsernameChanged(username: value));
                                },
                              );
                            },
                          ),
                          Divider(color: AppColors.divider, thickness: 0.5),

                          // Current Password
                          BlocBuilder<ResetPasswordBloc, ResetPasswordState>(
                            buildWhen: (prev, curr) =>
                            prev.currentPassword != curr.currentPassword,
                            builder: (context, state) {
                              return CustomTextField(
                                labelText: l10n.currentPasswordLabel,
                                hintText: l10n.currentPasswordHint,
                                keyboardType: TextInputType.text,
                                validator: (value) => Validations.validateCurrentPassword(l10n, value),
                                obscureText: true,
                                onChanged: (value) {
                                  context
                                      .read<ResetPasswordBloc>()
                                      .add(CurrentPasswordChange(
                                      currentPassword: value));
                                },
                              );
                            },
                          ),
                          Divider(color: Theme.of(context).colorScheme.outlineVariant, thickness: 0.5),

                          // New Password
                          BlocBuilder<ResetPasswordBloc, ResetPasswordState>(
                            buildWhen: (prev, curr) =>
                            prev.newPasswordPassword != curr.newPasswordPassword,
                            builder: (context, state) {
                              return CustomTextField(
                                labelText: l10n.newPasswordLabel,
                                hintText: l10n.newPasswordHint,
                                keyboardType: TextInputType.text,
                                validator: (value) => Validations.validateNewPassword(l10n, value),
                                obscureText: true,
                                onChanged: (value) {
                                  context
                                      .read<ResetPasswordBloc>()
                                      .add(NewPasswordChange(newPassword: value));
                                },
                              );
                            },
                          ),
                          Divider(color: Theme.of(context).colorScheme.outlineVariant, thickness: 0.5),

                          // Re-Enter Password
                          BlocBuilder<ResetPasswordBloc, ResetPasswordState>(
                            buildWhen: (prev, curr) =>
                            prev.reEnterPassword != curr.reEnterPassword,
                            builder: (context, state) {
                              return CustomTextField(
                                labelText: l10n.reenterPasswordLabel,
                                hintText: l10n.reenterPasswordHint,
                                keyboardType: TextInputType.text,
                                validator: (value) =>
                                    Validations.validateReEnterPassword(
                                        l10n, value, state.newPasswordPassword),
                                obscureText: true,
                                onChanged: (value) {
                                  context
                                      .read<ResetPasswordBloc>()
                                      .add(ReEnterPasswordChange(
                                      reEnterPassword: value));
                                },
                              );
                            },
                          ),
                          Divider(color: Theme.of(context).colorScheme.outlineVariant, thickness: 0.5),

                        ],
                      ),
                    ),
                  ),
                ),

                // Submit Button at Bottom
                BlocListener<ResetPasswordBloc, ResetPasswordState>(
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
                            state.error.isNotEmpty
                                ? state.error
                                : l10n.loginFailed,
                            style: const TextStyle(color: Colors.white),
                          ),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  child: BlocBuilder<ResetPasswordBloc, ResetPasswordState>(
                    buildWhen: (prev, curr) =>
                    prev.postApiStatus != curr.postApiStatus,
                    builder: (context, state) {
                      return SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: RoundButton(
                          title: l10n.updateButton,
                          color: AppColors.primary,
                          isLoading:
                          state.postApiStatus == PostApiStatus.loading,
                          onPress: () {
                            if (_formKey.currentState!.validate()) {
                              context
                                  .read<ResetPasswordBloc>()
                                  .add(ResetPasswordButton());
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
      ),
    );
  }
}
