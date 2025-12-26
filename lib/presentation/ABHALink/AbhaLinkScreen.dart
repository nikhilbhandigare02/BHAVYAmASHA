import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:medixcel_new/core/widgets/AppHeader/AppHeader.dart';
import 'package:medixcel_new/core/widgets/RoundButton/RoundButton.dart';
import 'package:medixcel_new/l10n/app_localizations.dart';
import '../../core/config/themes/CustomColors.dart';
import '../../core/widgets/Dropdown/Dropdown.dart';
import '../../core/widgets/TextField/TextField.dart';
import '../../data/models/abha/ABHAFetchModes.dart';
import '../../data/models/abha/ABHASelectMode.dart';
import '../../data/models/abha/AbhaProfileResponce.dart';
import '../../data/models/abha/verify_otp_response.dart';
import '../../data/repositories/AbhaCreated/AbhaLogin.dart';

class Abhalinkscreen extends StatefulWidget {
  const Abhalinkscreen({super.key});

  @override
  State<Abhalinkscreen> createState() => _AbhalinkscreenState();
}

class _AbhalinkscreenState extends State<Abhalinkscreen> {
  final AbhaLoginRepository repo = AbhaLoginRepository();
  var abdmEndExt = '@sbx';
  Timer? _timer;
  int _remainingSeconds = 0;
  bool _showTimer = false;
  void startOtpTimer() {
    setState(() {
      _remainingSeconds = 30;
      _showTimer = true;
    });

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds == 0) {
        timer.cancel();
        setState(() {
          _showTimer = false;
        });
      } else {
        setState(() {
          _remainingSeconds--;
        });
      }
    });
  }

  final TextEditingController _addressController = TextEditingController();
  bool _loading = false;
  String? _error;
  Map<String, dynamic>? _apiData;
  String? _selectedAuthMethod;
  bool _showOtpInput = false;
  final _otpController = TextEditingController();
  String? _txnId;
  AbhaFetchModes? abhaFetchModes;
  Future<void> callFetchModesAPI() async {
    final healthInput = _addressController.text.trim();
    if (healthInput.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter ABHA address")),
      );
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final fullAbha = "$healthInput$abdmEndExt";
      final result = await repo.fetchModes(fullAbha);

      print("📥 API Response: $result");
      if (result["status_code"] != null && result["status_code"] != 200) {
        String msg = result["message"] ?? "Failed to fetch modes";

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(msg)));

        setState(() {
          _loading = false;
          _error = msg;
        });

        return; // STOP HERE
      }
      if (result["status_code"] != null && result["status_code"] != 200) {
        String msg = "";

        // First priority: direct message
        if (result["message"] != null) {
          msg = result["message"];
        }
        // Second: nested error in index 0
        else if (result[0] != null && result[0]["message"] != null) {
          msg = result[0]["message"];
        }
        // Fallback
        else {
          msg = "Failed to fetch modes";
        }

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(msg)));

        setState(() {
          _loading = false;
          _error = msg;
        });

        return;
      }
      setState(() {
        _apiData = result;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  AbhaSelectMode? abhaSelectMode;
  Future<void> requestOtp(String healthId, String authMode) async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final result = await repo.selectModes(healthId, authMode);

      print("📥 OTP Request Response: $result");

      // 🔥 CHECK IF API RETURNED ERROR (but still status 200)
      if (result["status_code"] != null && result["status_code"] != 200) {
        String msg = result["message"] ?? "OTP request failed";

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(msg)));

        setState(() {
          _loading = false;
          _error = msg;
        });
        return; // STOP HERE
      }

      // 🔥 If no txnId → also treat as error
      _txnId = result["txnId"];
      if (_txnId == null) {
        String msg = result["message"] ?? "txnId missing";
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(msg)));
        setState(() => _loading = false);
        return;
      }

      setState(() {
        _showOtpInput = true;
        _loading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result["message"] ?? "OTP sent successfully")),
      );
    } catch (e) {
      setState(() => _loading = false);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  VerifyOtpResponse? verifyOtpResponse;
  AbhaProfileResponce? abhaProfileResponce;

  String? _abhaToken;

  // --------------------- VERIFY OTP ---------------------
  Future<void> getOtp(String otp, String authMode) async {
    if (_txnId == null) {
      print("❌ txnId is null! Call requestOtp() first.");
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final result = await repo.verifyOtp(
        txnId: _txnId!,
        otp: otp,
        authMode: authMode,
      );

      print("VERIFY OTP RAW: $result");

      // Show backend message
      if (result["message"] != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(result["message"])));
      }

      final auth = result["authResult"]?.toString().toLowerCase();
      print("AUTH RESULT → $auth");

      // ❌ OTP Failed
      if (auth == "failed") {
        setState(() => _loading = false);
        return;
      }

      // ✅ OTP Success
      if (auth == "success") {
        _abhaToken = result["tokens"]?["token"];

        print("TOKEN → $_abhaToken");

        if (_abhaToken == null) {
          print("❌ Token missing in response!");
          setState(() => _loading = false);
          return;
        }

        setState(() => _loading = false);

        print("➡ CALLING getAbhaProfile()");
        await getAbhaProfile(token: _abhaToken);

        return;
      }

      // Unexpected response
      setState(() => _loading = false);
    } catch (e) {
      setState(() {
        _loading = false;
        _error = e.toString();
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  // --------------------- GET PROFILE ---------------------
  Future<void> getAbhaProfile({required String? token}) async {
    if (token == null) {
      print("❌ Token missing → cannot fetch profile");
      return;
    }

    print("➡ ENTERED getAbhaProfile WITH TOKEN: $token");

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final result = await repo.abhaProfile(token);

      print("📄 PROFILE RESPONSE → $result");

      setState(() => _loading = false);
      Navigator.of(context).pop(result);
    } catch (e) {
      setState(() {
        _loading = false;
        _error = e.toString();
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  String formatTime(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return "$m:$s";
  }

  @override
  void initState() {
    super.initState();

    _otpController.addListener(() {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppHeader(
        screenTitle: AppLocalizations.of(context)!.linkHealthRecordsTitle,
        showBack: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _showOtpInput
              ? _buildOtpInput()
              : _apiData == null
              ? Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _AbhaInput(controller: _addressController),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  SizedBox(
                    height: 44,
                    width: 140,
                    child: RoundButton(
                      title: AppLocalizations.of(context)!.proceedButton,
                      borderRadius: 8,
                      isLoading: _loading,
                      color: Colors.green,
                      icon: Icons.inbox_outlined,
                      onPress: callFetchModesAPI,
                    ),
                  ),
                ],
              ),
            ],
          )
              : _buildAuthMethodButtons(),
        ),
      ),
    );
  }

  Widget _buildOtpInput() {
    final localText = AppLocalizations.of(context)!;
    bool isOtpEntered = _otpController.text.trim().length == 6;

    // 🔥 Disable buttons during timer
    bool disableButtons = _showTimer;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 20),

        CustomTextField(
          controller: _otpController,
          labelText: "Enter OTP",
          hintText: "Please enter OTP",
          keyboardType: TextInputType.number,
          maxLength: 6,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return "OTP is required";
            }
            return null;
          },
        ),

        Divider(color: AppColors.divider, thickness: 1, height: 0),

        const SizedBox(height: 20),

        // 🔥 TIMER VISIBLE ALWAYS WHEN RUNNING
        if (_showTimer)
          Text(
            formatTime(_remainingSeconds),
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),

        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: disableButtons
                  ? null
                  : () async {
                final healthId = "${_addressController.text.trim()}$abdmEndExt";

                await requestOtp(
                  healthId,
                  _selectedAuthMethod ?? "MOBILE_OTP",
                );

                startOtpTimer();
              },
              child: Container(
                width: 100,
                height: 30,
                decoration: BoxDecoration(
                  color: disableButtons
                      ? Colors.yellow.withOpacity(0.4)
                      : Colors.yellow, // filled color
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.refresh,
                      size: 16,
                      color: Colors.white, // icon white
                    ),
                    SizedBox(width: 6),
                    Text(
                      localText.resendOtp,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Spacer(),
            GestureDetector(
              onTap: (!disableButtons && isOtpEntered)
                  ? () {
                getOtp(
                  _otpController.text.trim(),
                  _selectedAuthMethod ?? "MOBILE_OTP",
                );
              }
                  : null,
              child: Container(
                width: 100,
                height: 30,
                decoration: BoxDecoration(
                  color: (!disableButtons && isOtpEntered)
                      ? AppColors.greenHighlight
                      : Colors.green.shade200, // filled color
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.check_box_outlined,
                      size: 16,
                      color: Colors.white, // icon white
                    ),
                    SizedBox(width: 6),
                    Text(
                      localText.verifyOtp,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAuthMethodButtons() {
    final List<String> authMethods =
        (_apiData?['authMethods'] as List<dynamic>?)?.cast<String>() ?? [];
    String? selectedMethod = _selectedAuthMethod;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ApiDropdown<String>(
          labelText: "Authentication Mode",
          items:
          (_apiData?['authMethods'] as List<dynamic>?)?.cast<String>() ??
              [],
          getLabel: (s) {
            switch (s) {
              case 'MOBILE_OTP':
                return 'Mobile OTP';
              case 'AADHAAR_OTP':
                return 'Aadhaar OTP';
              default:
                return s;
            }
          },
          value: _selectedAuthMethod,
          onChanged: (v) {
            if (v == null) return;
            setState(() {
              _selectedAuthMethod = v;
            });
            final healthId = "${_addressController.text.trim()}$abdmEndExt";
            requestOtp(healthId, v);
          },
        ),
        Divider(color: AppColors.divider, thickness: 1, height: 0),
      ],
    );
  }
}

class _AbhaInput extends StatelessWidget {
  final TextEditingController controller;
   _AbhaInput({required this.controller, super.key});
  var abdmEndExt = '@sbx';
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(color: Colors.grey.shade300),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              style: const TextStyle(fontSize: 12),
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.abhaAddressLabel,
                border: InputBorder.none,
              ),
            ),
          ),

           Text(
            '$abdmEndExt',
            style: TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
