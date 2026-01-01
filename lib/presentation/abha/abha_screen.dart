import 'dart:async';
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:medixcel_new/core/config/themes/CustomColors.dart';
import 'package:medixcel_new/core/widgets/AppDrawer/Drawer.dart';
import 'package:medixcel_new/data/SecureStorage/SecureStorage.dart';
import 'package:medixcel_new/core/widgets/AppHeader/AppHeader.dart';
import 'package:medixcel_new/data/models/abha_model/create/get_states.dart';
import 'package:medixcel_new/data/models/abha_model/create/verify_otp_aadhaar.dart';
import 'package:medixcel_new/data/models/abha_model/create/verify_otp_mobile.dart';
import 'package:medixcel_new/data/models/abha_model/error/error400.dart';
import 'package:medixcel_new/data/models/abha_model/existing/send_otp_existing.dart';
import 'package:open_file/open_file.dart';

import '../../core/config/Constant/constant.dart';
import '../../core/utils/utils.dart';
import '../../core/widgets/ConfirmationDialogue/ConfirmationDialogue.dart';
import '../../core/widgets/TextField/TextField.dart';
import '../../data/models/abha/create/Exisiting/profile_existing.dart';
import '../../data/models/abha/create/mobile/abha_suggestion_model.dart';
import '../../data/models/abha/create/mobile/mobile_create_address_response.dart';
import '../../data/models/abha/create/mobile/mobile_link_abha_address.dart';
import '../../data/models/abha/create/search_availability_response.dart'
    hide AvailableAbhaNumbers;
import '../../data/models/abha_model/create/abha_suggestion_mobile.dart';
import '../../data/models/abha_model/create/create_abha_aadhaar.dart';
import '../../data/models/abha_model/create/get_districts.dart';
import '../../data/models/abha_model/create/update_aadhaar_mobile.dart';
import '../../data/models/abha_model/existing/existing_mobile_abha.dart';
import '../../data/models/abha_model/existing/health_card_resposne.dart';
import '../../data/models/abha_model/existing/profile_aadhaar.dart';
import '../../data/models/abha_model/existing/search_abha.dart';
import '../../data/models/abha_model/existing/verify_otp_existing.dart';
import '../../data/repositories/AbhaController.dart';
import '../../l10n/app_localizations.dart';

class ABHAScreen extends StatefulWidget {
  const ABHAScreen({super.key});

  @override
  State<ABHAScreen> createState() => _ABHAScreenState();
}

class _ABHAScreenState extends State<ABHAScreen> {
  TextEditingController abhaIdController = new TextEditingController();
  TextEditingController mobileController = new TextEditingController();
  TextEditingController otpController = new TextEditingController();
  TextEditingController aadhaarController = new TextEditingController();
  bool isAadhaarValid = false;

  bool verifyAbhaFlag = false;
  bool searchFlag = false;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool isABDMEnabled = true;
  double? latitude;
  double? longitude;
  bool isEnableSearch = true;

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return PopScope(
        canPop: true,
        // whether the route can be popped
        onPopInvoked: (didPop) {
          /*   if (!didPop) {
            Utils.willPopCallback(context);
            // system already popped
          }*/
          // your custom logic before pop
          // Example: show a dialog instead of closing
        },
        child: Container(
            child: Container(
          child: createVerifyAbha(context),
        )));
  }

  var abhaIdEnd = '@sbx';

  //var abhaIdEnd = '@abdm';

  var _base64HealthcardID = '';
  Uint8List? _healthCardImageBytes;

  String clinicToken = '';
  var box = GetStorage();
  String _userName = '';

  Future<void> _loadUserName() async {
    try {
      final userData = await SecureStorageService.getCurrentUserData();
      if (userData != null) {
        String fullName = '';
        if (userData['name'] is Map) {
          final name = userData['name'] as Map;
          fullName = [
            name['first_name'],
            name['middle_name'],
            name['last_name']
          ].where((part) => part != null).join(' ').trim();
        } else {
          fullName = [
            userData['first_name'],
            userData['middle_name'],
            userData['last_name'],
            userData['name']
          ].where((part) => part != null && part is String).join(' ').trim();
        }

        if (mounted) {
          setState(() {
            _userName = fullName.isNotEmpty ? fullName : '-';
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading user name: $e');
    }
  }

  @override
  void initState() {
    _loadUserName();
    abhaIdController.addListener(_filterAbhaId);

    listABHAID.add(ABHAID('rohit@inde', true));
    listABHAID.add(ABHAID('aagg@www', true));
    listABHAID.add(ABHAID('qqq@ooo', false));
    listABHAID.add(ABHAID('vvv@popo', false));

    Constant.abhaToken = Utils.generateAbhaTokenUAT();

    _getStates();
  }

  void allcheckbosRefresh() {
    var value = otpVisible();
    setState(() {
      checkedValue = value;
      if (checkedValue) {
        sendOtpAbha = true;
        checkedValue = true;
      } else {
        sendOtpAbha = false;
        checkedValue = false;
      }
    });
  }


  void _filterAbhaId() {
    if (abhaIdController.text.isNotEmpty) {
      verifyAbhaFlag = true;
    } else {
      verifyAbhaFlag = false;
    }
    setState(() {
      verifyAbhaFlag;
    });
  }

  void _showStateSelectionPopup(StateSetter setStatea) {
    final TextEditingController _searchController = TextEditingController();

    showMenu(
      color: Colors.white,
      context: context,
      position:
          RelativeRect.fromLTRB(100, 140, 0, 0), // Adjust position as needed
      items: [
        PopupMenuItem(
          child: StatefulBuilder(
            builder: (context, setState) {
              return Container(
                width: 300, // Set width for the popup
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      style: TextStyle(fontSize: 11.sp),
                      controller: _searchController,
                      decoration: InputDecoration(
                        labelStyle: TextStyle(fontSize: 11.sp),
                        labelText: 'Search State',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        setState(() {});
                      },
                    ),
                    SizedBox(height: 10),
                    Container(
                        height: 200, // Set a height for the list
                        child: getStates?.states != null
                            ? ListView(
                                children: getStates.states!
                                    .where((val) => val.stateName!
                                        .toLowerCase()
                                        .contains(_searchController.text
                                            .toLowerCase()))
                                    .map((val) {
                                  return ListTile(
                                    title: Text(
                                      '${val.stateName}',
                                      style: TextStyle(fontSize: 11.sp),
                                    ),
                                    onTap: () {
                                      setStatea(() {
                                        selectedState = val;
                                        patientStateController.text =
                                            selectedState.stateName ?? '';
                                        _getDistricts(); // Update selected doctor
                                      });
                                      Navigator.pop(context); // Close the popup
                                      // Call setState in the parent widget to update UI
                                      this.setState(() {});
                                    },
                                  );
                                }).toList(),
                              )
                            : Center(child: Text('No record found'))),
                    SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          Navigator.pop(context); // Close the popup
                        },
                        child: Text(
                          'Close',
                          style: TextStyle(
                              color: AppColors.blueApp, fontSize: 11.sp),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showDistrictSelectionPopup(StateSetter setStatea) {
    final TextEditingController _searchController = TextEditingController();

    showMenu(
      color: Colors.white,
      context: context,
      position: RelativeRect.fromLTRB(100, 140, 0, 0),
      items: [
        PopupMenuItem(
          child: StatefulBuilder(
            builder: (context, setState) {
              return Container(
                width: 300, // Set width for the popup
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      style: TextStyle(fontSize: 11.sp),
                      controller: _searchController,
                      decoration: InputDecoration(
                        labelStyle: TextStyle(fontSize: 11.sp),
                        labelText: 'Search State',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        setState(() {}); // Trigger rebuild on search
                      },
                    ),
                    SizedBox(height: 10),
                    Container(
                        height: 200, // Set a height for the list
                        child: getDistricts?.districts != null
                            ? ListView(
                                children: getDistricts.districts!
                                    .where((val) => val.name!
                                        .toLowerCase()
                                        .contains(_searchController.text
                                            .toLowerCase()))
                                    .map((val) {
                                  return ListTile(
                                    title: Text(
                                      '${val.name}',
                                      style: TextStyle(fontSize: 11.sp),
                                    ),
                                    onTap: () {
                                      setStatea(() {
                                        selectedDistrict = val;
                                        patientDistrictController.text =
                                            selectedDistrict.name ?? '';
                                      });
                                      Navigator.pop(context); // Close the popup
                                      // Call setState in the parent widget to update UI
                                      this.setState(() {});
                                    },
                                  );
                                }).toList(),
                              )
                            : Center(child: Text('No record found'))),
                    SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: Text(
                          'Close',
                          style: TextStyle(
                              color: AppColors.blueApp, fontSize: 11.sp),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  bool isResendEnabled = false;
  int countdown = 60; // 1 minute
  Timer? timer;

  void startTimer() {
    setState(() {
      isResendEnabled = false;
      countdown = 60;
    });

    timer?.cancel();
    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (countdown == 0) {
        t.cancel();
        setState(() {
          isResendEnabled = true;
        });
      } else {
        setState(() {
          countdown--;
        });
      }
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  String formatTime(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return "$minutes:$secs";
  }

  final _formKey = GlobalKey<FormState>();

  @override
  Widget createVerifyAbha(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ScreenUtilInit(
        designSize: const Size(360, 690),
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (_, __) => Scaffold(
              appBar: AppHeader(
                screenTitle: l10n.gridAbhaGeneration ,
                showBack: false,
              ),
              drawer: CustomDrawer(),
              body: SafeArea(
                bottom: true,
                child: Stack(
                  children: [
                    /*Container(
                        decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/img/background_abdm.png'),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  Color.fromRGBO(255, 255, 255, 0.5), // white overlay with 10% opacity
                  BlendMode.lighten, // blend mode
                ),
              ),
                        ),
                      ),*/

                    Padding(
                      padding: EdgeInsets.all(10),
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            SizedBox(
                              height: 15,
                            ),
                            Padding(
                              padding: EdgeInsets.all(0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  createAbhaAddress(context),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ));
  }

  String dropdownvalue = '';

  // List of items in our dropdown menu
  /*var items = [
    'Mobile',
    'Aadhaar',
  ];*/
  var items = [
    'Aadhaar',
  ];
  List<ABHAID> listABHAID = [];
  List<AvailableAbhaNumbers> availableAbhaNumbers = [];
  int availableAbhaNumbersSelectedIndex = -1;

  var checkedValue = false;
  var checkedIAgreeValue_1 = false;
  var checkedIAgreeValue_7 = false;
  var checkedIAgreeValue_2 = false;
  var checkedIAgreeValue_3 = false;
  var checkedIAgreeValue_4 = false;
  var checkedIAgreeValue_5 = false;
  var checkedIAgreeValue_6 = false;

  bool checkavailableAbha = true;
  bool availableAbha = false;
  bool createnewFlag = false;
  bool linkExistAbha = false;
  bool healthCardShow = false;
  bool sendOtpAbha = false;
  bool createViaAbha = false;
  bool termCondFlag = false;
  bool showLinkAbhaIdList = false;
  bool enableAbhaClick = false;

  var _selectedAbhaIDValue;
  String defaultDropdownValue = "";


  void refresh() {
    isResendEnabled = false;
    countdown = 60;
    dropdownvalue = '';
    callAbhaSuggestion = false;
    //mobileController.text ='';
    checkavailableAbha = true;
    availableAbha = false;
    createnewFlag = false;
    enableAbhaClick = false;

    updateMobile = false;
    linkExistAbha = false;
    sendOtpAbha = false;
    createViaAbha = false;
    termCondFlag = false;
    showLinkAbhaIdList = false;
    healthCardShow = false;
    _selectedAbhaIDValue = '';
    checkedValue = false;
    checkedIAgreeValue_2 = false;
    checkedIAgreeValue_3 = false;
    checkedIAgreeValue_1 = false;
    checkedIAgreeValue_7 = false;
    checkedIAgreeValue_4 = false;
    checkedIAgreeValue_5 = false;
    checkedIAgreeValue_6 = false;
    otpController.text = '';

    firstNameController.text = '';
    firstMiddleController.text = '';
    lastNameController.text = '';
    mobileCreateController.text = '';
    patientEmailController.text = '';
    dobController.text = '';
    patientStateController.text = '';
    patientDistrictController.text = '';
    patientPinCodeController.text = '';
    patientAddressController.text = '';
    txtABHAIDMobileController.text = '';
    createMobileAadhharView = true;

    availableAbhaNumbers = [];
    availableAbhaNumbersSelectedIndex = -1;
    listMobileAbhaSuggestion = [];
    _valueSelectedSuggestId = '';
    aadhaarController.text = "";
    availableAbhaNumbersSelectedIndex = -1;
    listABHAID = [];
  }

  @override
  Widget createAbhaAddress(BuildContext context) {
    final localText = AppLocalizations.of(context)!;
    String? selectedOption = box.read('selectedABHASettings');
    print("sselected option $selectedOption");
    defaultDropdownValue = "Aadhaar";
    /*if (selectedOption == null) {
      items = ['Mobile', 'Aadhaar'];
      defaultDropdownValue='Mobile';
    } else {
      if (selectedOption == "Mobile") {
        items = ['Mobile'];
        defaultDropdownValue='Mobile';
      } else if (selectedOption == "Aadhaar") {
        items = ['Aadhaar'];
        defaultDropdownValue="Aadhaar";
      } else {
        items = ['Mobile', 'Aadhaar'];
        defaultDropdownValue='Mobile';
      }
    }*/
    return Padding(
      padding: EdgeInsets.all(15),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
             localText.mobileLabel,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          SizedBox(
            height: 5,
          ),
          Row(
            children: [
              // Mobile number text field
              Expanded(
                child: Container(
                  alignment: Alignment.center,
                  //width: 200.w,
                  height: 35.h,
                  child: TextFormField(
                    controller: mobileController,
                    style: TextStyle(fontSize: 11),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly, // only digits
                      LengthLimitingTextInputFormatter(10), // max 10 digits
                    ],
                    enabled: isEnableSearch,
                    decoration: InputDecoration(
                      fillColor:
                          isEnableSearch ? Colors.white : Colors.grey.shade200,

                      hintText: localText.enterMobileToSearchAbha ,
                      // border: OutlineInputBorder(
                      //   borderRadius: BorderRadius.only(
                      //     topLeft: Radius.circular(5),
                      //     bottomLeft: Radius.circular(5),
                      //   ),
                      //   borderSide: BorderSide(color: Colors.grey),
                      // ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(5),
                          bottomLeft: Radius.circular(5),
                        ),
                        borderSide: BorderSide(color: Colors.grey),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(5),
                          bottomLeft: Radius.circular(5),
                        ),
                        borderSide: BorderSide(color: Colors.grey),
                      ),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16.sp),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return localText.pleaseEnterMobileNumber;
                      }

                      // Must be exactly 10 digits
                      if (value.length != 10) {
                        return localText.validMobileNumber;
                      }

                      // Must start with 6, 7, 8 or 9
                      if (!RegExp(r'^[6-9]').hasMatch(value)) {
                        return localText.enterValidIndianMobile;
                      }

                      // Reject if all digits are the same (1111111111, 9999999999)
                      if (RegExp(r'^(\d)\1{9}$').hasMatch(value)) {
                        return localText.invalidMobileNumber;
                      }

                      return null;
                    },
                  ),
                ),
              ),

              // Search icon
              // if(checkavailableAbha)
              InkWell(
                onTap: () {
                  if (isEnableSearch) {
                    if (mobileController.text.isEmpty) {
                      Utils.showToastMessage(localText.pleaseEnterMobileNumber);
                      Utils.showToastMessage(
                          'Enter valid 10-digit mobile number');
                    } else {
                      setState(() {
                        refresh();
                        refreshLinkABha();
                      });
                      _searchAvailability(mobileController.text);
                    }
                  }
                },
                child: Container(
                  width: 60.w,
                  height: 35.h,
                  decoration: BoxDecoration(
                    color: isEnableSearch
                        ? AppColors.primary
                        : Colors.grey.shade300,
                    border: Border.all(
                      color: isEnableSearch
                          ? AppColors.primary
                          : Colors.grey.shade300,
                    ),
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(5),
                      bottomRight: Radius.circular(5),
                    ),
                  ),
                  child: Icon(
                    Icons.search,
                    size: 18,
                    color: AppColors.background,
                  ),
                ),
              ),
              /* if(!checkavailableAbha)
            InkWell(
              onTap: (){
                setState(() {
                  refresh();
                  refreshLinkABha();
                });
              },
              child: Container(
                width: 60.w,
                height: 35.h,
                decoration: BoxDecoration(
                  color: AppColors.orangeApp,
                  border: Border.all(color: AppColors.orangeApp),
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(5),
                    bottomRight: Radius.circular(5),
                  ),
                ),
                child: Center(
                  child: Text(localText.cancel, style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 11.sp,
                    //fontWeight: FontWeight.bold,
                  ),),
                )*/ /*Icon(Icons.refresh, size: 18, color: AppColors.white,)*/ /*,
              ),
            ),*/
            ],
          ),

/*

        Row(children: [
          Expanded(flex: 3,
            child: SizedBox(
              height: 40.h,
              child: TextFormField(
              //readOnly: verifyAbhaFlag==true?true:false,
              controller: mobileController,
              style: TextStyle(
                fontSize: 11,
              ),
              keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly, // only digits
                  LengthLimitingTextInputFormatter(10),   // max 10 digits
                ],
              decoration: InputDecoration(
                hintText: "Enter mobile number",
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(5),
                      bottomLeft: Radius.circular(5),
                      topRight: Radius.circular(0),
                      bottomRight: Radius.circular(0),
                    ),
                    borderSide: BorderSide(color: Colors.grey)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(5),
                      bottomLeft: Radius.circular(5),
                      topRight: Radius.circular(0),
                      bottomRight: Radius.circular(0),
                    ),
                    borderSide: BorderSide(color: Colors.grey)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(5),
                    bottomLeft: Radius.circular(5),
                    topRight: Radius.circular(0),
                    bottomRight: Radius.circular(0),
                  ),
                  borderSide: BorderSide(color: Colors.grey),
                ),
                contentPadding: EdgeInsets.symmetric(
                  //vertical: 14.sp,
                  horizontal: 16.sp,
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter mobile number';
                }
                return null;
              },
                        ),
            ),),


          SizedBox(width: 0,),
          //SizedBox(height: 20,),
          if(checkavailableAbha)
            Container(
             // flex: 1,
              child: Padding(
                padding: EdgeInsets.only(top: 0),
                child: Align(
                  alignment: Alignment.center,
                  child: SizedBox(
                    height: 40.h,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.only(
                            topRight: Radius.circular(5.0),
                            bottomRight: Radius.circular(5.0),
                            topLeft: Radius.circular(0),   // 👈 no rounding
                            bottomLeft: Radius.circular(0), // 👈 no rounding
                          ),
                          side: BorderSide(
                            color: AppColors.primary,
                            width: 1.w,
                          ),
                        ),
                      ),
                      onPressed: () {

                        if (mobileController.text.isEmpty) {
                          Utils.showToastMessage('Please enter mobile number');
                        }
                        else if (mobileController.text.length!=10){
                          Utils.showToastMessage('Enter valid 10-digit mobile number');
                        }
                        else {
                        _searchAvailability(mobileController.text);
                        }
                      },
                      child: Icon(
                        Icons.search,
                        color: Colors.white,
                        size: 16.sp,
                      ),
                    ),
                  ),
                ),
              ),
            )
          else
            Container(
              //flex: 1,
              child: Padding(
                padding: EdgeInsets.only(top: 0),
                child: Align(
                  alignment: Alignment.center,
                  child: SizedBox(
                    height: 40.h,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.only(
                            topRight: Radius.circular(5.0),
                            bottomRight: Radius.circular(5.0),
                            topLeft: Radius.circular(0),   // 👈 no rounding
                            bottomLeft: Radius.circular(0), // 👈 no rounding
                          ),
                          side: BorderSide(
                            color: AppColors.primary,
                            width: 1.w,
                          ),
                        ),
                      ),
                      onPressed: () {

                        setState(() {
                          refresh();
                          refreshLinkABha();
                        });
                       refresh();
                       refreshLinkABha();
                      },
                      child: Icon(
                        Icons.refresh,
                        color: Colors.white,
                        size: 16.sp,
                      ),
                    ),
                  ),
                ),
              ),
            )

        ],),

*/

          Container(
            child: Column(
              children: [
                // if(availableAbha)
                SizedBox(
                  height: 20,
                ),
                if (availableAbhaNumbers != null &&
                    availableAbhaNumbers.length != 0 &&
                    enableAbhaClick)
                  Text(
                    "Select to Proceed",
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                Container(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: 200, // your max height
                      ), // set your max height here
                      child: Scrollbar(
                        thumbVisibility: true, // always show scrollbar
                        thickness: 6,
                        radius: Radius.circular(10),

                        child: ListView(
                          shrinkWrap: true,
                          children: List.generate(
                            availableAbhaNumbers.length,
                            (index) => Padding(
                              padding: EdgeInsets.only(bottom: 10),
                              child: InkWell(
                                onTap: () {
                                  if (enableAbhaClick) {
                                    setState(() {
                                      availableAbhaNumbersSelectedIndex = index;
                                    });
                                  }
                                },
                                child: Container(
                                  padding: EdgeInsets.all(15),
                                  //width: 240.w,
                                  //height: 50.h,
                                  //padding: EdgeInsets.all(6.w),
                                  decoration: BoxDecoration(
                                    color: (availableAbhaNumbersSelectedIndex ==
                                            index)
                                        ? AppColors.bgColorScreen
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(10.0),
                                    border: Border.all(
                                        color:
                                            (availableAbhaNumbersSelectedIndex ==
                                                    index)
                                                ? AppColors.blueApp
                                                : Colors.grey,
                                        width:
                                            (availableAbhaNumbersSelectedIndex ==
                                                    index)
                                                ? 1.5.w
                                                : 1.w),
                                  ),
                                  child:Container(
                                   /* margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(14),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.08),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),*/
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // 🔵 Avatar
                                        CircleAvatar(
                                          radius: 22,
                                          backgroundColor: AppColors.primary,
                                          child: Text(
                                            availableAbhaNumbers[index].name
                                                ?.substring(0, 1)
                                                .toUpperCase() ??
                                                '',
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),

                                        const SizedBox(width: 12),

                                        // 📄 Details
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              // 👤 Name + Gender
                                              Text(
                                                '${availableAbhaNumbers[index].name ?? ''}'
                                                    '${availableAbhaNumbers[index].gender != null ? ' (${availableAbhaNumbers[index].gender})' : ''}',
                                                style: TextStyle(
                                                  fontSize: 13.sp,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.black,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),

                                              const SizedBox(height: 6),

                                              // 🆔 ABHA Number
                                              Text(
                                                '${localText.abhaNumber}: '
                                                    '${availableAbhaNumbers[index].abhaNumber ?? ''}',
                                                style: TextStyle(
                                                  fontSize: 11.sp,
                                                  color: Colors.grey.shade700,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  /*Column(
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            flex: 1,
                                            child: Align(
                                              alignment: Alignment.centerLeft,
                                              child: Text(
                                                localText.abhaNumber,
                                                style: TextStyle(
                                                  color: Colors.black,
                                                  fontSize: 11.sp,
                                                  //fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                          Text(
                                            ':  ',
                                            style: TextStyle(
                                              color: Colors.black,
                                              fontSize: 11.sp,
                                              //fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Expanded(
                                            flex: 2,
                                            child: Align(
                                              alignment: Alignment.centerLeft,
                                              child: Text(
                                                availableAbhaNumbers[index]
                                                        .abhaNumber ??
                                                    '',
                                                style: TextStyle(
                                                  color: Colors.black,
                                                  fontSize: 11.sp,
                                                  //fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          )
                                        ],
                                      ),

                                      Row(
                                        children: [
                                          Expanded(
                                            flex: 1,
                                            child: Text(
                                              localText.name,
                                              style: TextStyle(fontSize: 11.sp),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          Text(':  '),
                                          Expanded(
                                            flex: 2,
                                            child: Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    availableAbhaNumbers[index]
                                                            .name ??
                                                        '',
                                                    style: TextStyle(
                                                        fontSize: 11.sp),
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    softWrap: true,
                                                  ),
                                                ),
                                                Text(
                                                  availableAbhaNumbers[index]
                                                              .gender !=
                                                          null
                                                      ? ' (${availableAbhaNumbers[index].gender})'
                                                      : '',
                                                  style: TextStyle(
                                                      fontSize: 11.sp),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      )

                                    ],
                                  )*/
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    )

                    /*ListView.builder(
                  // primary: false,
                    shrinkWrap: true,
                    itemCount: availableAbhaNumbers.length ?? 0,
                    itemBuilder: (BuildContext context, int index) {
                      return

                        Padding(
                        padding: EdgeInsets.only(bottom: 10),
                        child: InkWell(
                          onTap: (){
                            if(enableAbhaClick){
                              setState(() {
                                availableAbhaNumbersSelectedIndex = index;
                              });
                            }
                          },
                          child: Container(
                            padding: EdgeInsets.all(15),
                            //width: 240.w,
                            //height: 50.h,
                            //padding: EdgeInsets.all(6.w),
                            decoration: BoxDecoration(
                              color:  (availableAbhaNumbersSelectedIndex == index)?AppColors.bgColorScreen:Colors.white,
                              borderRadius: BorderRadius.circular(10.0),
                              border: Border.all(color: (availableAbhaNumbersSelectedIndex == index)?AppColors.blueApp:Colors.grey, width: (availableAbhaNumbersSelectedIndex == index)?1.5.w:1.w),
                            ),
                            child: Column(children: [
                              Row(children: [
                                Expanded(flex:1,
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      localText.abhaNumber,
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontSize: 11.sp,
                                        //fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),),
                                Text(
                                  ':  ',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 11.sp,
                                    //fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Expanded(flex:2,
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      availableAbhaNumbers[index].abhaNumber??'',
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontSize: 11.sp,
                                        //fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),)
                              ],),
                              */ /*Row(children: [
                                Expanded(flex:1,
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      localText.name,
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontSize: 11.sp,
                                        //fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),),
                                Text(
                                  ':  ',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 11.sp,
                                    //fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Expanded(flex:2,
                                  child:
                                  Row(
                                    children: [
                                      Expanded(
                                        flex: 1,
                                        child: Text(
                                          localText.abhaNumber,
                                          style: TextStyle(fontSize: 11.sp),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),

                                      Text(':  '),

                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          availableAbhaNumbers[index].abhaNumber ?? '',
                                          style: TextStyle(fontSize: 11.sp),
                                          overflow: TextOverflow.ellipsis,
                                          softWrap: true,
                                        ),
                                      ),
                                    ],
                                  ),
                                 */ /**/ /* Row(children: [
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        availableAbhaNumbers[index].name??'',
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontSize: 11.sp,
                                          //fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        availableAbhaNumbers[index].gender!=null?
                                        ' (${availableAbhaNumbers[index].gender??''})':'',
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontSize: 11.sp,
                                          //fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],)*/ /**/ /*

                                  )
                              ],),*/ /*
                              Row(
                                children: [
                                  Expanded(
                                    flex: 1,
                                    child: Text(
                                      localText.name,
                                      style: TextStyle(fontSize: 11.sp),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),

                                  Text(':  '),

                                  Expanded(
                                    flex: 2,
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            availableAbhaNumbers[index].name ?? '',
                                            style: TextStyle(fontSize: 11.sp),
                                            overflow: TextOverflow.ellipsis,
                                            softWrap: true,
                                          ),
                                        ),
                                        Text(
                                          availableAbhaNumbers[index].gender != null
                                              ? ' (${availableAbhaNumbers[index].gender})'
                                              : '',
                                          style: TextStyle(fontSize: 11.sp),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              )

                              */ /* Row(children: [
                                Expanded(flex:1,
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      '',
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontSize: 11.sp,
                                        //fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),),
                                Text(
                                  '   ',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 11.sp,
                                    //fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Expanded(flex:2,
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      availableAbhaNumbers[index].gender!=null?
                                      '(${availableAbhaNumbers[index].gender??''})':'',
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontSize: 11.sp,
                                        //fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),)
                              ],),*/ /*
                            ],),
                          ),
                        ),
                      );
                    }),*/
                    ),
                Padding(
                  padding: EdgeInsets.only(top: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      if (availableAbha)
                        Align(
                          alignment: Alignment.center,
                          child: InkWell(
                            onTap: () {
                              dropdownvalue = '';
                              if (availableAbhaNumbersSelectedIndex != -1 &&
                                  availableAbhaNumbers != null) {
                                _sendOTPLinkExisting();
                              } else {
                                Utils.showToastMessage('Select ABHA number');
                              }
                            },
                            child: Container(
                              width: 150.w,
                              height: 30.h,
                              decoration: BoxDecoration(
                                color: Colors.amberAccent,
                                borderRadius: BorderRadius.circular(5.0),
                                border: Border.all(
                                    color: Colors.amberAccent, width: 1.w),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    // Prefix icon for "Create New"
                                    color: Colors.white,
                                    size: 16.sp,
                                  ),
                                  SizedBox(width: 6.w),
                                  // Small space between icon and text
                                  Text(
                                    localText.proceedwithkyc,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 11.sp,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      if (availableAbha) Spacer(),
                      // SizedBox(width: 10,),
                      //if(availableAbha)
                      if (availableAbha)
                        Align(
                          alignment: Alignment.center,
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                dropdownvalue = defaultDropdownValue;
                                isEnableSearch = false;
                                linkExistAbha = false;
                                availableAbha = false;
                                createViaAbha = true;
                                termCondFlag = true;
                                createnewFlag = false;
                                enableAbhaClick = false;
                              });
                            },
                            child: Container(
                              width: 130.w,
                              height: 30.h,
                              decoration: BoxDecoration(
                                color: AppColors.greenHighlight,
                                borderRadius: BorderRadius.circular(5.0),
                                border: Border.all(
                                    color: AppColors.greenHighlight,
                                    width: 1.w),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.add, // Prefix icon for "Create New"
                                    color: Colors.white,
                                    size: 16.sp,
                                  ),
                                  SizedBox(width: 6.w),
                                  // Small space between icon and text
                                  Text(
                                    localText.createNew,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 11.sp,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          //if(createViaAbha)
          if (false)
            Column(
              children: [
                SizedBox(
                  height: 0,
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    localText.createVia,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                SizedBox(
                  height: 10,
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: DropdownButtonFormField<String>(
                    value: dropdownvalue,
                    isExpanded: true,
                    decoration: InputDecoration(
                      contentPadding: EdgeInsets.zero,
                      border: UnderlineInputBorder(
                        borderSide:
                            BorderSide(color: AppColors.blueApp, width: 1),
                      ),
                      enabledBorder: UnderlineInputBorder(
                        borderSide:
                            BorderSide(color: AppColors.blueApp, width: 1),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide:
                            BorderSide(color: AppColors.blueApp, width: 2),
                      ),
                    ),
                    icon: Icon(Icons.keyboard_arrow_down,
                        color: AppColors.blueApp),
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 11.sp,
                    ),
                    items: items.map((String item) {
                      return DropdownMenuItem(
                        value: item,
                        child: Text(item),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        dropdownvalue = newValue!;
                      });
                    },
                  ),
                ),
                SizedBox(
                  height: 25,
                )
              ],
            ),

          if (createViaAbha && dropdownvalue == 'Aadhaar')
            Column(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    localText.aadhaarNumber,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                SizedBox(
                  height: 10,
                ),
                Form(
                  key: _formKey,
                  child: TextFormField(
                    controller: aadhaarController,
                    style: const TextStyle(fontSize: 11),
                    keyboardType: TextInputType.number,
                    maxLength: 12,
                    onChanged: (value) {
                      if (RegExp(r'^[2-9][0-9]{11}$').hasMatch(value)) {
                        setState(() {
                          isAadhaarValid = true;
                        });
                      } else {
                        setState(() {
                          isAadhaarValid = false;
                        });
                      }
                    },
                    decoration: InputDecoration(
                      hintText: localText.aadhaarNumber,

                      border: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey),
                      ),

                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(
                            color: isAadhaarValid ? Colors.green : Colors.red,
                            width: 2),
                      ),
                      errorBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.red),
                      ),
                      focusedErrorBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.red, width: 2),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16.sp,
                        vertical: 12,
                      ),
                      counterText: "", // hides character counter
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter Aadhaar number';
                      }

                      if (!RegExp(r'^[2-9][0-9]{11}$').hasMatch(value)) {
                        return 'Enter a valid 12-digit Aadhaar number';
                      }

                      return null;
                    },
                  ),
                ),

                  /*TextFormField(
                //readOnly: verifyAbhaFlag==true?true:false,
                controller: aadhaarController,
                style: TextStyle(
                  fontSize: 11,
                ),
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: localText.aadhaarNumber,

                  // Completely remove the box — use underline only
                  border: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey),
                  ),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.green, width: 2), // Green when focused
                  ),
                  errorBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.red),
                  ),
                  focusedErrorBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.red, width: 2),
                  ),

                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16.sp,
                    vertical: 12, // keeps good height & alignment
                  ),
                ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter Aadhaar number';
                    }

                    if (!RegExp(r'^[2-9][0-9]{11}$').hasMatch(value)) {
                      return 'Enter a valid 12-digit Aadhaar number';
                    }

                    return null;
                  },
              ),*/

                SizedBox(
                  height: 15,
                ),
              ],
            ),

          Visibility(
            visible: termCondFlag,
            child: Column(
              children: [

                Container(
                  //width: 240.w,
                  height: 50.h,
                  //padding: EdgeInsets.all(6.w),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10.0),
                    border: Border.all(color: AppColors.blueApp, width: 1.w),
                  ),

                  child: Align(

                    alignment: Alignment.centerLeft,

                    child: Text(
                      '    ${localText.iHerebyDeclareThat}',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 11.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  height: 20,
                ),
                Padding(
                  padding: EdgeInsets.only(left: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      //const SizedBox(width: 10),
                      Checkbox(
                        // tristate: true, // Example with tristate
                        value: checkedValue,
                        onChanged: (bool? newValue) {
                          setState(() {
                            checkedValue = newValue!;
                            checkedIAgreeValue_1 = newValue;
                            checkedIAgreeValue_7 = newValue;
                            checkedIAgreeValue_2 = newValue;
                            checkedIAgreeValue_3 = newValue;
                            checkedIAgreeValue_4 = newValue;
                            checkedIAgreeValue_5 = newValue;
                            checkedIAgreeValue_6 = newValue;
                            sendOtpAbha = true;
                          });
                        },
                      ),
                      // const SizedBox(width: 10),
                      InkWell(
                        onTap: () {
                          setState(() {
                            checkedValue = !checkedValue;

                            checkedIAgreeValue_1 = checkedValue;
                            checkedIAgreeValue_7 = checkedValue;
                            checkedIAgreeValue_2 = checkedValue;
                            checkedIAgreeValue_3 = checkedValue;
                            checkedIAgreeValue_4 = checkedValue;
                            checkedIAgreeValue_5 = checkedValue;
                            checkedIAgreeValue_6 = checkedValue;
                            sendOtpAbha = true;
                          });
                        },
                        child: Text(
                          localText.agreeAll,
                          style: TextStyle(
                              fontSize: 11.0, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 10,
                ),
                Container(
                  //width: 240.w,
                  //height: 50.h,
                  //padding: EdgeInsets.all(6.w),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10.0),
                    border: Border.all(color: AppColors.blueApp, width: 1.w),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(10),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        Text(
                          localText.iHerebyDeclareThat,
                          style: TextStyle(fontSize: 11.0),
                        ),
                        SizedBox(
                          height: 20,
                        ),

                        InkWell(
                          onTap: () {
                            setState(() {
                              checkedIAgreeValue_7 = !checkedIAgreeValue_7;
                            });

                            allcheckbosRefresh();
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              //  const SizedBox(width: 10),
                              Checkbox(
                                // tristate: true, // Example with tristate
                                value: checkedIAgreeValue_7,
                                onChanged: (bool? newValue) {
                                  setState(() {
                                    checkedIAgreeValue_7 = newValue!;
                                  });
                                  allcheckbosRefresh();
                                },
                              ),
                              // const SizedBox(width: 10),
                              Flexible(
                                child: Text(
                                  localText.igree_7,
                                  style: TextStyle(fontSize: 11.0),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          height: 20,
                        ),
                        InkWell(
                          onTap: () {
                            setState(() {
                              checkedIAgreeValue_1 = !checkedIAgreeValue_1;
                            });

                            allcheckbosRefresh();
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              //  const SizedBox(width: 10),
                              Checkbox(
                                // tristate: true, // Example with tristate
                                value: checkedIAgreeValue_1,
                                onChanged: (bool? newValue) {
                                  setState(() {
                                    checkedIAgreeValue_1 = newValue!;
                                  });
                                  allcheckbosRefresh();
                                },
                              ),
                              // const SizedBox(width: 10),
                              Flexible(
                                child: Text(
                                  localText.igree1,
                                  style: TextStyle(fontSize: 11.0),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          height: 20,
                        ),
                        InkWell(
                          onTap: () {
                            setState(() {
                              checkedIAgreeValue_2 = !checkedIAgreeValue_2;
                            });
                            allcheckbosRefresh();
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              //  const SizedBox(width: 10),
                              Checkbox(
                                // tristate: true, // Example with tristate
                                value: checkedIAgreeValue_2,
                                onChanged: (bool? newValue) {
                                  setState(() {
                                    checkedIAgreeValue_2 = newValue!;
                                  });
                                  allcheckbosRefresh();
                                },
                              ),
                              // const SizedBox(width: 10),
                              Flexible(
                                child: Text(
                                  localText.igree2,
                                  style: TextStyle(fontSize: 11.0),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          height: 20,
                        ),
                        InkWell(
                          onTap: () {
                            setState(() {
                              checkedIAgreeValue_3 = !checkedIAgreeValue_3;
                            });
                            allcheckbosRefresh();
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              //  const SizedBox(width: 10),
                              Checkbox(
                                // tristate: true, // Example with tristate
                                value: checkedIAgreeValue_3,
                                onChanged: (bool? newValue) {
                                  setState(() {
                                    checkedIAgreeValue_3 = newValue!;
                                  });

                                  allcheckbosRefresh();
                                },
                              ),
                              // const SizedBox(width: 10),
                              Flexible(
                                child: Text(
                                  localText.igree3,
                                  style: TextStyle(fontSize: 11.0),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          height: 20,
                        ),
                        InkWell(
                          onTap: () {
                            setState(() {
                              checkedIAgreeValue_4 = !checkedIAgreeValue_4;
                            });
                            allcheckbosRefresh();
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              //  const SizedBox(width: 10),
                              Checkbox(
                                // tristate: true, // Example with tristate
                                value: checkedIAgreeValue_4,
                                onChanged: (bool? newValue) {
                                  setState(() {
                                    checkedIAgreeValue_4 = newValue!;
                                  });
                                  allcheckbosRefresh();
                                },
                              ),
                              // const SizedBox(width: 10),
                              Flexible(
                                child: Text(
                                  localText.igree4,
                                  style: TextStyle(fontSize: 11.0),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          height: 20,
                        ),
                        InkWell(
                          onTap: () {
                            setState(() {
                              checkedIAgreeValue_5 = !checkedIAgreeValue_5;
                            });
                            allcheckbosRefresh();
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              //  const SizedBox(width: 10),
                              Checkbox(
                                // tristate: true, // Example with tristate
                                value: checkedIAgreeValue_5,
                                onChanged: (bool? newValue) {
                                  setState(() {
                                    checkedIAgreeValue_5 = newValue!;
                                  });
                                  allcheckbosRefresh();
                                },
                              ),
                              // const SizedBox(width: 10),
                              Flexible(
                                child: Text(
                                  '${localText.igree_I}'
                                      '$_userName, '
                                      '${localText.igree5}'
                                  ,
                                  style: TextStyle(fontSize: 11.0),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          height: 20,
                        ),
                        InkWell(
                          onTap: () {
                            setState(() {
                              checkedIAgreeValue_6 = !checkedIAgreeValue_6;
                            });
                            allcheckbosRefresh();
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              //  const SizedBox(width: 10),
                              Checkbox(
                                // tristate: true, // Example with tristate
                                value: checkedIAgreeValue_6,
                                onChanged: (bool? newValue) {
                                  setState(() {
                                    checkedIAgreeValue_6 = newValue!;
                                  });
                                  allcheckbosRefresh();
                                },
                              ),
                              // const SizedBox(width: 10),
                              Flexible(
                                child: Text(
                                  localText.igree6,
                                  style: TextStyle(fontSize: 11.0),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          height: 20,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (sendOtpAbha)
            Visibility(
              visible: otpVisible(),
              child: Align(
                alignment: Alignment.centerLeft,
                child: InkWell(
                  onTap: () {
                    if (dropdownvalue == 'Aadhaar') {
                      if (_formKey.currentState!.validate()) {
                        // ✅ Aadhaar is valid (non-empty + 12 digits)
                        _aadhaarOTPABHA(sendOTP);
                      } else {

                        var msg ="";
                        if (aadhaarController.text == null || aadhaarController.text.isEmpty) {
                          msg = 'Please enter Aadhaar number';
                        }
                        else if (!RegExp(r'^[2-9][0-9]{11}$').hasMatch(aadhaarController.text)) {
                          msg = 'Enter a valid 12-digit Aadhaar number';
                        }
                        Utils.showToastMessage(msg);
                      }
                    } /*else {
                      _aadhaarOTPABHA(sendOTP);
                    }*/
                  },
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: Container(
                      width: 150.w,
                      height: 30.h,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(5.0),
                        border:
                            Border.all(color:  AppColors.primary, width: 1.w),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.send_rounded,
                            // Perfect prefix icon for "Send OTP"
                            color: Colors.white,
                            size: 15.sp,
                          ),
                          SizedBox(width: 6.w),
                          // Small space between icon and text
                          Text(
                           localText.generateOtp,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          if (linkExistAbha)
            Column(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    getOtpLabel(localText.enterOtp),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                SizedBox(
                  height: 5,
                ),
                CustomTextField(
                  controller: otpController,
                  hintText: localText.pleaseEnterOtp,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return localText.otpIsRequired;
                    }
                    return null;
                  },
                ),
                Divider(color: AppColors.divider, thickness: 1, height: 0),
                Padding(
                  padding: EdgeInsets.only(top: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      InkWell(
                        onTap: isResendEnabled
                            ? () {
                                if (dropdownvalue == 'Aadhaar') {
                                  if (aadhaarController.text.isNotEmpty) {
                                    _aadhaarOTPABHA(sendOTP);
                                  } else {
                                    Utils.showToastMessage(
                                        'Please enter Aadhaar number');
                                  }
                                } else {
                                  _aadhaarOTPABHA(sendOTP);
                                }
                              }
                            : null,
                        borderRadius: BorderRadius.circular(5.0),
                        child: Container(
                          width: 100.w,
                          height: 30.h,
                          decoration: BoxDecoration(
                            color: isResendEnabled
                                ? Colors.yellow
                                : Colors.yellow.withOpacity(0.4),
                            borderRadius: BorderRadius.circular(5.0),
                            border:
                                Border.all(color: Colors.yellow, width: 1.w),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.refresh,
                                  color: Colors.white, size: 16.sp),
                              // Prefix icon
                              SizedBox(width: 6.w),
                              Text(
                                localText.resendOtp,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Spacer(),
                      InkWell(
                        onTap: () {
                          if (dropdownvalue == 'Aadhaar') {
                            if (otpController.text.isNotEmpty) {
                              _aadhaarOTPABHA(verifyOTP);
                            } else {
                              Utils.showToastMessage(localText.pleaseEnterOtp);
                            }
                          } else if (dropdownvalue == 'Mobile') {
                            if (otpController.text.isNotEmpty) {
                              _aadhaarOTPABHA(verifyOTP);
                            } else {
                              Utils.showToastMessage(localText.pleaseEnterOtp);
                            }
                          } else {
                            if (otpController.text.isNotEmpty) {
                              _verifyOTPLinkExisting(otpController.text);
                            } else {
                              Utils.showToastMessage(localText.pleaseEnterOtp);
                            }
                          }
                        },
                        child: Container(
                          width: 100.w,
                          height: 30.h,
                          decoration: BoxDecoration(
                            color: AppColors.greenHighlight,
                            borderRadius: BorderRadius.circular(5.0),
                            border: Border.all(
                                color: AppColors.greenHighlight, width: 1.w),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check_box_outlined,
                                  color: Colors.white,
                                  size: 16.sp), // Prefix icon
                              SizedBox(width: 6.w),
                              Text(
                                localText.verifyOtp,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                AnimatedOpacity(
                  opacity: isResendEnabled ? 0.0 : 1.0,
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeInOut,
                  child: isResendEnabled
                      ? const SizedBox.shrink()
                      : Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: Colors.blueAccent.withOpacity(0.2)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.timer_outlined,
                                  size: 18, color: Colors.blueAccent),
                              const SizedBox(width: 6),
                              Text(
                                formatTime(countdown),
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: Colors.blueAccent.shade700,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.5,
                                    ),
                              ),
                            ],
                          ),
                        ),
                )
              ],
            ),

          Visibility(
              visible: (showLinkAbhaIdList),
              child: Column(
                children: [
                  //For aadhar
                  /*if (listMobileAbhaSuggestion != null &&
                      listMobileAbhaSuggestion.length != 0)*/
                  if(showTextFieldABHAID)
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            width: 100.w,
                            height: 50.h,
                            child: TextFormField(
                              onTap: () {
                                //suggestion(setState);
                                //createAbhaMobileSuggestion();
                              },
                              controller: txtABHAIDMobileController,
                              style: TextStyle(fontSize: 11),
                              // keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                hintText: localText.abhaId,
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10.0),
                                    borderSide: BorderSide(color: Colors.blue)),
                                focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: Colors.blue)),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.blue),
                                ),
                                contentPadding: EdgeInsets.symmetric(
                                  vertical: 14.sp,
                                  horizontal: 16.sp,
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter ABHA ID';
                                }
                                return null;
                              },
                            ),
                          ),
                        ),
                        Container(
                          width: 80.w,
                          height: 50.h,
                          child: TextFormField(
                            readOnly: true,
                            // controller: usernameController,
                            style: TextStyle(fontSize: 11),
                            keyboardType: TextInputType.number,
                            initialValue: abhaIdEnd,
                            decoration: InputDecoration(
                              hintText: abhaIdEnd,
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10.0),
                                  borderSide: BorderSide(color: Colors.blue)),
                              focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.blue)),
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.blue),
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                vertical: 14.sp,
                                horizontal: 16.sp,
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return localText.pleaseEnterOtp;
                              }
                              return null;
                            },
                          ),
                        ),
                        /*ElevatedButton(
                  onPressed: () {
                    */ /*if (dropdownvalue == 'Aadhaar') {
                      createAbhaAadhaarSuggestion(setState);
                    } else {*/ /*
                      suggestion(setState);
                   // }
                  },
                  child: Text('suggestion'))*/
                      ],
                    ),
                  if (listMobileAbhaSuggestion != null &&
                      listMobileAbhaSuggestion.length != 0)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: EdgeInsets.only(bottom: 5, top: 10),
                        child: Text(
                          '${localText.suggestedAbhaAddress} :',
                          style: TextStyle(
                            color: Colors.blueGrey,
                            fontSize: 10.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  if (listMobileAbhaSuggestion != null &&
                      listMobileAbhaSuggestion.length != 0)
                    Wrap(
                      children: List<Widget>.generate(
                        listMobileAbhaSuggestion.length,
                        (int idx) {
                          return Padding(
                            padding: EdgeInsets.only(right: 3, left: 2),
                            child: ChoiceChip(
                                disabledColor: Colors.grey,
                                selectedColor: Colors.blue[100],
                                backgroundColor: Colors.white,
                                shadowColor: Colors.grey,
                                pressElevation: 5.0,
                                elevation: 1.0,
                                label: Text(
                                  listMobileAbhaSuggestion[idx],
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 9.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                selected: _valueSelectedSuggestId == idx,
                                onSelected: (bool selected) {
                                  setState(() {
                                    _valueSelectedSuggestId =
                                        (selected ? idx : null)!;
                                    txtABHAIDMobileController.text =
                                        listMobileAbhaSuggestion[idx];
                                  });
                                }),
                          );
                        },
                      ).toList(),
                    ),

                  if (listABHAID.length > 0)
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: 200, // your max height
                      ), // set your max height here

                      child: Scrollbar(
                        //controller: _scrollController,
                        thumbVisibility: true, // always show scrollbar
                        thickness: 6,
                        radius: Radius.circular(10),

                        child: ListView.builder(
                            primary: false,
                            shrinkWrap: true,
                            itemCount: listABHAID.length ?? 0,
                            itemBuilder: (BuildContext context, int index) {
                              return Card(
                                color: Colors.white,
                                child: Padding(
                                  padding: EdgeInsets.all(10),
                                  child: Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'ABHA Address Linked!',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 8),

                                      _rowText('Name', '${verifyOtpAadhaar?.aBHAProfile?.firstName??''} ${verifyOtpAadhaar?.aBHAProfile?.middleName??''} ${verifyOtpAadhaar?.aBHAProfile?.lastName??''}'),
                                      _rowText('Gender', verifyOtpAadhaar?.aBHAProfile?.gender??''),
                                      _rowText('Health ID', listABHAID[index].abhaId ?? ''),
                                      _rowText('Abha No', verifyOtpAadhaar?.aBHAProfile?.aBHANumber??''),
                                    ],
                                  ),
                                                                ),
                                ),)


                                /*RadioListTile(
                                dense: true,
                                title:  Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'ABHA Address Linked!',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 8),

                                      _rowText('Name', '${verifyOtpAadhaar?.aBHAProfile?.firstName??''} ${verifyOtpAadhaar?.aBHAProfile?.middleName??''} ${verifyOtpAadhaar?.aBHAProfile?.lastName??''}'),
                                      _rowText('Gender', verifyOtpAadhaar?.aBHAProfile?.gender??''),
                                      _rowText('Health ID', listABHAID[index].abhaId ?? ''),
                                      _rowText('Abha No', verifyOtpAadhaar?.aBHAProfile?.aBHANumber??''),
                                    ],
                                  ),
                                ),


                                    *//* Text(listABHAID[index].abhaId ?? '',
                                    style: TextStyle(
                                        color: Colors.black,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13)),*//*
                                // Display the title for option 1
                                // subtitle: Text('Subtitle for Option 1'), // Display a subtitle for option 1
                                value: listABHAID[index].abhaId ?? '',
                                // Assign a value of 1 to this option
                                groupValue: _selectedAbhaIDValue,
                                // Use _selectedValue to track the selected option
                                onChanged: (value) {
                                  setState(() {
                                    _selectedAbhaIDValue =
                                        value!; // Update _selectedValue when option 1 is selected
                                  });
                                },
                              )*/;
                            }),
                      ),
                    ),
                  if (listABHAID.length > 0)
                    SizedBox(
                      height: 10,
                    ),
                  Container(
                    child: Row(
                      children: [
                        if (listABHAID.length > 0)
                          Align(
                            alignment: Alignment.center,
                            child: InkWell(
                              onTap: () {
                                if (dropdownvalue == 'Aadhaar') {
                                  _healthCardLinkExisting(
                                      verifyOtpAadhaar?.tokens?.token ?? '');
                                  // _profileLinkExisting(verifyOtpAadhaar?.tokens?.token??'');
                                } else {
                                  if (_selectedAbhaIDValue != null &&
                                      _selectedAbhaIDValue != "") {
                                    _continueExisitingABHAMobileUser(
                                        _selectedAbhaIDValue);
                                  } else {
                                    Utils.showToastMessage("Select Abha Id");
                                  }
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.only(
                                    left: 10.0, right: 10),
                                height: 30.h,
                                decoration: BoxDecoration(
                                  color: Colors.yellow,
                                  borderRadius: BorderRadius.circular(5.0),
                                  border: Border.all(
                                      color: Colors.yellow, width: 1.w),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.person, // prefix icon
                                      size: 14.sp,
                                      color: Colors.white,
                                    ),
                                    SizedBox(width: 6),
                                    Text(
                                      localText.useExisting,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 11.sp,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        if (listABHAID.length > 0)
                          SizedBox(
                            width: 10,
                          ),
                        Align(
                          alignment: Alignment.center,
                          child: InkWell(
                            onTap: () {
                              mobileCreateController.text =
                                  mobileController.text;
                              //crateNewABHADialog();
                              if (dropdownvalue == 'Aadhaar') {
                                if (callAbhaSuggestion) {
                                  _aadhaarabhasuggestions();
                                } else if (txtABHAIDMobileController
                                    .text.isNotEmpty) {
                                  _aadhaarCreateABHA();
                                } else {
                                  Utils.showToastMessage(
                                      'Please enter ABHA ID');
                                }
                              } else {
                                crateNewABHADialog();
                              }
                            },
                            child: Container(
                              padding:
                                  const EdgeInsets.only(left: 10.0, right: 10),
                              height: 30.h,
                              decoration: BoxDecoration(
                                color: Colors.yellow,
                                borderRadius: BorderRadius.circular(5.0),
                                border: Border.all(
                                    color: Colors.yellow, width: 1.w),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.add_circle, // prefix icon
                                    size: 14.sp,
                                    color: Colors.white,
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    localText.createNew,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 11.sp,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              )),

          if (healthCardShow) _showHealthCard(),

          /*SizedBox(
          height: 20,
        ),
        Text(
          '$dropdownvalue${' No.'}',
          style: TextStyle(
              color: Colors.blue,
              fontWeight: FontWeight.bold,
              fontSize: 11.sp),
          textAlign: TextAlign.center,
        ),*/
        ],
      ),
    );
  }

  Widget _rowText(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: RichText(
        text: TextSpan(
          style: TextStyle(color: Colors.black, fontSize: 12),
          children: [
            TextSpan(
              text: '$label: ',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }

  void showUserDialog() {
    showGeneralDialog(
      context: context,
      barrierColor: Colors.white /*.withOpacity(0.6)*/,
      // Background color
      barrierDismissible: false,
      barrierLabel: 'Dialog',
      transitionDuration: Duration(milliseconds: 400),
      pageBuilder: (context, se, ___) {
        return WillPopScope(
          onWillPop: () async {
            Navigator.pop(context);
            Navigator.pop(context);
            return true;
          },
          child: StatefulBuilder(// You need this, notice the parameters below:
              builder: (BuildContext context, StateSetter setStateDialog) {
            final localText = AppLocalizations.of(context)!;
            return Scaffold(
              backgroundColor: Colors.white,
              body: Container(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(
                        height: 50,
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            Text(localText.createAbhaAddress,
                                style: TextStyle(
                                    color: Colors.black, fontSize: 18)),
                            Spacer(),
                            InkWell(
                                onTap: () {
                                  Navigator.pop(context);
                                  Navigator.pop(context);
                                  refresh();
                                },
                                child: Icon(Icons.close))
                          ],
                        ),
                      ),
                      createAbhaAddress(context),
                    ],
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }

  Future<bool> _confirmExit(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('Exit'),
            content: const Text('Are you sure you want to close this screen?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('No'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Yes'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<bool> _showConfirmDialog(BuildContext context) async {
    final l10n = AppLocalizations.of(context);

    final result = await showConfirmationDialog(
      context: context,
      message: l10n?.doYouWantToContinue ?? 'Do you want to close this screen?',
      yesText: l10n?.yes ?? 'Yes',
      noText: l10n?.no ?? 'No',
    );
    return result ?? false;
  }

  void crateNewABHADialog() {
    showGeneralDialog(
      context: context,
      barrierColor: Colors.white /*.withOpacity(0.6)*/,
      // Background color
      barrierDismissible: false,
      barrierLabel: 'Dialog',
      transitionDuration: Duration(milliseconds: 400),
      pageBuilder: (context, se, ___) {
        return StatefulBuilder(// You need this, notice the parameters below:
            builder: (BuildContext context, StateSetter setDialogState) {
          final localText = AppLocalizations.of(context)!;
          return PopScope(
            canPop: false, // prevent default back close
            onPopInvoked: (didPop) async {
              if (didPop) return;

              final confirm = await _showConfirmDialog(context);
              if (confirm) {
                refresh();
                Navigator.pop(context);
              }

              /* final shouldExit = await _confirmExit(context);
                  if (shouldExit) {
                    refresh();
                    Navigator.pop(context);
                  }*/
            },
            child: Scaffold(
              backgroundColor: Colors.white,
              body: Container(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: 30,
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            Text(localText.createAbha,
                                style: TextStyle(
                                    color: Colors.black, fontSize: 18)),
                            Spacer(),
                            InkWell(
                                onTap: () async {
                                  final confirm =
                                      await _showConfirmDialog(context);
                                  if (confirm) {
                                    setState(() {
                                      refresh();
                                    });

                                    Navigator.pop(context);
                                  }
                                },
                                child: Icon(Icons.close))
                          ],
                        ),
                      ),
                      _buildTableOne(setDialogState),
                      Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: SizedBox(
                          width: 150.w,
                          height: 40.h,
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: InkWell(
                              onTap: () {
                                /* if (dropdownvalue == 'Aadhaar') {
                                      if(txtABHAIDMobileController.text.isNotEmpty){
                                        _aadhaarCreateABHA();
                                      }
                                      else {
                                        Utils.showToastMessage('Please enter ABHA ID');
                                      }
                                    }
                                    else {

                                      if(createMobileAadhharView){
                                        _submitDetailsMobile(setDialogState);

                                      }
                                      else {*/
                                // if(txtABHAIDMobileController.text.isNotEmpty){
                                _mobileCreateABHA();
                                /* }
                                    else {
                                      Utils.showToastMessage('Please enter ABHA ID');
                                    }*/

                                // }
                                // }
                              },
                              child: Container(
                                width: 150.w,
                                height: 30.h,
                                //padding: EdgeInsets.all(6.w),
                                decoration: BoxDecoration(
                                  color: Colors.amberAccent,
                                  borderRadius: BorderRadius.circular(5.0),
                                  border: Border.all(
                                      color: Colors.amberAccent, width: 1.w),
                                ),
                                child: Align(
                                  alignment: Alignment.center,
                                  child: Text(
                                    (createMobileAadhharView)
                                        ? localText.submit
                                        : localText.createAbhaAddress,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 11.sp,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        });
      },
    );
  }

  TextEditingController firstNameController = TextEditingController();
  TextEditingController firstMiddleController = TextEditingController();
  TextEditingController lastNameController = TextEditingController();
  TextEditingController mobileCreateController = TextEditingController();
  TextEditingController patientEmailController = TextEditingController();
  TextEditingController dobController = TextEditingController();
  TextEditingController patientStateController = TextEditingController();
  TextEditingController patientDistrictController = TextEditingController();
  TextEditingController patientPinCodeController = TextEditingController();
  TextEditingController patientAddressController = TextEditingController();
  TextEditingController txtABHAIDMobileController = TextEditingController();

  String? gender_dropdownvalue;

  var genderItems = [
    'Male',
    'Female',
    'Other',
  ];

  void suggestion(StateSetter setStateDialog) {
    if (firstNameController.text.isNotEmpty &&
        lastNameController.text.isNotEmpty &&
        dobController.text.isNotEmpty) {
      _mobileabhasuggestions(setStateDialog);
    }
  }

  bool createMobileAadhharView = true;

  //Create new abha address view
  Widget _buildTableOne(StateSetter setDialogState) {
    final localText = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          //For mobile
          if (dropdownvalue == 'Mobile' && createMobileAadhharView)
            Table(
              border: TableBorder.all(color: Colors.grey, width: 1),
              children: [
                TableRow(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text('${localText.firstName}*',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 11.sp)),
                    ),
                    TextFormField(
                      controller: firstNameController,
                      style: TextStyle(fontSize: 11),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: localText.enterFirstName,
                        filled: true,
                        fillColor: Colors.transparent,
                      ),
                      onChanged: (value) {
                        // Call your method here
                        suggestion(setDialogState);
                      },
                    ),
                  ],
                ),
                TableRow(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(localText.middleName,
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 11.sp)),
                    ),
                    TextFormField(
                      controller: firstMiddleController,
                      style: TextStyle(fontSize: 11),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: localText.enterMiddleName,
                        filled: true,
                        fillColor: Colors.transparent,
                      ),
                    ),
                  ],
                ),
                TableRow(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text('${localText.lastName}*',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 11.sp)),
                    ),
                    TextFormField(
                      controller: lastNameController,
                      style: TextStyle(fontSize: 11),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: localText.enterLastName,
                        filled: true,
                        fillColor: Colors.transparent,
                      ),
                      onChanged: (value) {
                        // Call your method here
                        suggestion(setDialogState);
                      },
                    ),
                  ],
                ),
                TableRow(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        localText.gender,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 11.sp,
                        ),
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.only(left: 8),
                      height: 40.h,
                      alignment: Alignment.centerLeft,
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 15.0),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(5.0),
                        ),
                        child: DropdownButton(
                          isDense: true,
                          hint: Text(
                            "Select an option",
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.normal,
                              fontSize: 10.sp,
                            ),
                          ),
                          value: gender_dropdownvalue,
                          icon: const Icon(Icons.keyboard_arrow_down),
                          underline: Container(),
                          // Removes the default underline
                          items: genderItems.map((String items) {
                            return DropdownMenuItem(
                              value: items,
                              child: Text(
                                items,
                                style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11.sp,
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setDialogState(() {
                              gender_dropdownvalue = newValue!;
                            });
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                TableRow(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Text(
                            '${localText.dateOfBirth}*',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 11.sp),
                          ),
                          SizedBox(width: 10.sp),
                          GestureDetector(
                            onTap: () {
                              _selectDate(setDialogState);
                            },
                            child: Icon(Icons.calendar_today, size: 20.sp),
                          ),
                        ],
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        _selectDate(setDialogState);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          dobController.text.isEmpty
                              ? 'dd/mm/yyyy'
                              : dobController.text,
                          style: TextStyle(fontSize: 11.sp),
                        ),
                      ),
                    ),
                  ],
                ),
                TableRow(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text('${localText.state}*',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 11.sp)),
                    ),
                    TextFormField(
                      readOnly: true,
                      onTap: () {
                        _showStateSelectionPopup(setDialogState);
                      },
                      controller: patientStateController,
                      style: TextStyle(fontSize: 11),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Select State',
                        filled: true,
                        fillColor: Colors.transparent,
                      ),
                    ),
                  ],
                ),
                TableRow(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text('${localText.district}*',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 11.sp)),
                    ),
                    TextFormField(
                      readOnly: true,
                      onTap: () {
                        if (selectedState != null) {
                          _showDistrictSelectionPopup(setDialogState);
                        } else {
                          Utils.showToastMessage('Select State');
                        }
                      },
                      controller: patientDistrictController,
                      style: TextStyle(fontSize: 11),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Select District',
                        filled: true,
                        fillColor: Colors.transparent,
                      ),
                    ),
                  ],
                ),
                TableRow(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text('${localText.emailId}*',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 11.sp)),
                    ),
                    TextFormField(
                      controller: patientEmailController,
                      style: TextStyle(fontSize: 11),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: localText.enterEmailId,
                        filled: true,
                        fillColor: Colors.transparent,
                      ),
                    ),
                  ],
                ),
                TableRow(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text('${localText.mobileNumber}*',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 11.sp)),
                    ),
                    TextFormField(
                      controller: mobileCreateController,
                      keyboardType: TextInputType.number,
                      style: TextStyle(fontSize: 11),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: localText.enterMobileNo,
                        filled: true,
                        fillColor: Colors.transparent,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(10),
                      ],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter mobile number';
                        }

                        // Must be exactly 10 digits
                        if (value.length != 10) {
                          return 'Mobile number must be 10 digits';
                        }

                        // Must start with 6, 7, 8 or 9
                        if (!RegExp(r'^[6-9]').hasMatch(value)) {
                          return 'Enter valid Indian mobile number';
                        }

                        // Reject if all digits are the same (1111111111, 9999999999)
                        if (RegExp(r'^(\d)\1{9}$').hasMatch(value)) {
                          return 'Invalid mobile number';
                        }

                        return null;
                      },
                    ),
                  ],
                ),
                TableRow(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text('${localText.pinCode}*',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 11.sp)),
                    ),
                    TextFormField(
                      controller: patientPinCodeController,
                      keyboardType: TextInputType.number,
                      style: TextStyle(fontSize: 11),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: localText.enterPincode,
                        filled: true,
                        fillColor: Colors.transparent,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(6),
                      ],
                    ),
                  ],
                ),
                TableRow(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text('${localText.address}*',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 11.sp)),
                    ),
                    TextFormField(
                      controller: patientAddressController,
                      style: TextStyle(fontSize: 11),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: localText.address,
                        filled: true,
                        fillColor: Colors.transparent,
                      ),
                    ),
                  ],
                ),
              ],
            ),

          //For aadhar
          //   if(!createMobileAadhharView)

          Padding(
            padding: EdgeInsets.only(top: 10),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    width: 100.w,
                    height: 50.h,
                    child: TextFormField(
                      onTap: () {
                        //suggestion(setState);
                        //createAbhaMobileSuggestion();
                      },
                      controller: txtABHAIDMobileController,
                      style: TextStyle(fontSize: 11),
                      // keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: localText.abhaId,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.0),
                            borderSide: BorderSide(color: Colors.blue)),
                        focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.blue)),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.blue),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          vertical: 14.sp,
                          horizontal: 16.sp,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter ABHA ID';
                        }
                        return null;
                      },
                    ),
                  ),
                ),
                Container(
                  width: 80.w,
                  height: 50.h,
                  child: TextFormField(
                    readOnly: true,
                    // controller: usernameController,
                    style: TextStyle(fontSize: 11),
                    keyboardType: TextInputType.number,
                    initialValue: abhaIdEnd,
                    decoration: InputDecoration(
                      hintText: abhaIdEnd,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0),
                          borderSide: BorderSide(color: Colors.blue)),
                      focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.blue)),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.blue),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        vertical: 14.sp,
                        horizontal: 16.sp,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter OTP';
                      }
                      return null;
                    },
                  ),
                ),
                /*ElevatedButton(
                    onPressed: () {
                      */ /*if (dropdownvalue == 'Aadhaar') {
                        createAbhaAadhaarSuggestion(setState);
                      } else {*/ /*
                        suggestion(setState);
                     // }
                    },
                    child: Text('suggestion'))*/
              ],
            ),
          ),
          if (listMobileAbhaSuggestion != null &&
              listMobileAbhaSuggestion.length != 0)
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: EdgeInsets.only(bottom: 5, top: 10),
                child: Text(
                  '${localText.suggestedAbhaAddress} :',
                  style: TextStyle(
                    color: Colors.blueGrey,
                    fontSize: 10.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          if (listMobileAbhaSuggestion != null &&
              listMobileAbhaSuggestion.length != 0)
            Wrap(
              children: List<Widget>.generate(
                listMobileAbhaSuggestion.length,
                (int idx) {
                  return Padding(
                    padding: EdgeInsets.only(right: 3, left: 2),
                    child: ChoiceChip(
                        disabledColor: Colors.grey,
                        selectedColor: Colors.blue[100],
                        backgroundColor: Colors.white,
                        shadowColor: Colors.grey,
                        pressElevation: 5.0,
                        elevation: 1.0,
                        label: Text(
                          listMobileAbhaSuggestion[idx],
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 9.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        selected: _valueSelectedSuggestId == idx,
                        onSelected: (bool selected) {
                          setDialogState(() {
                            _valueSelectedSuggestId = (selected ? idx : null)!;
                            txtABHAIDMobileController.text =
                                listMobileAbhaSuggestion[idx];
                          });
                        }),
                  );
                },
              ).toList(),
            ),
        ],
      ),
    );
  }

  SearchAbhaResponse? searchAvailabilityResponse;

  //Availale
  Future<void> _searchAvailability(var mobileNo) async {
    if (await Utils.isConnected()) {
      bool _isLoading = true;
      Utils.onLoading(context);

      String response_sync = "";
      Map<String, dynamic> data = {"mobile": mobileNo ?? ''};

      String dataString = jsonEncode(data);

      AbhaController controller = AbhaController();
      try {
        final response = await controller.searchExistingAbha(data, clinicToken);

        if (response != null && response.statusCode == 200) {
          searchAvailabilityResponse =
              SearchAbhaResponse.fromJson(response.data);

          _isLoading = false;
          Navigator.pop(context);
          availableAbhaNumbers = searchAvailabilityResponse?.abha ?? [];

          if (availableAbhaNumbers.length > 0) {
            enableAbhaClick = true;
          }

          setState(() {
            availableAbhaNumbers;
            //available_abha_numbers
            availableAbha = true;
            checkavailableAbha = false;
            enableAbhaClick;
          });
          // Utils.showToastMessage('${searchAvailabilityResponse?.sMessage}');
        } else {
          if (response != null && response.statusCode == 404) {
            Error400 error400 = Error400.fromJson(response?.data);
            Utils.showToastMessage(
                (error400.error?.message?.contains("User not found.") ?? false)
                    ? "ABHA account not found."
                    : error400.error?.message ??
                        'Something went wrong! ${response?.statusCode}');
            setState(() {
              checkavailableAbha = false;
              dropdownvalue = defaultDropdownValue;
              linkExistAbha = false;
              availableAbha = false;

              createViaAbha = true;
              termCondFlag = true;
              /*createViaAbha =false;
              termCondFlag =false;*/
            });
            print(response);
          } else {
            Error400 error400 = Error400.fromJson(response?.data);
            Utils.showToastMessage(error400.errorDetails?.message ??
                'Something went wrong! ${response?.statusCode}');
            setState(() {
              checkavailableAbha = false;
              dropdownvalue = defaultDropdownValue;
              linkExistAbha = false;
              availableAbha = false;
              createViaAbha = true;

              termCondFlag = true;
            });
            print(response);
          }
        }

        response_sync = jsonEncode(response?.data ?? {});
      } catch (e) {
        response_sync = e.toString() ?? '';
        Utils.showToastMessage('Something went wrong!');
        print(e);
      } finally {
        if (_isLoading) {
          Navigator.pop(context);
        }
        /* setState(() {
          createnewFlag = true;
        });*/
      }
    } else {
      Utils.showToastMessage(Constant.internetConMsg);
    }
  }

  SendOtpExisting? sendOtpExisting;

  Future<void> _sendOTPLinkExisting() async {
    if (await Utils.isConnected()) {
      bool _isLoading = true;
      Utils.onLoading(context);

      String dataRequestSync = "";
      String dataResponseSync = "";

      num? loginId = 1;

      if (availableAbhaNumbersSelectedIndex != -1 &&
          availableAbhaNumbers != null) {
        loginId =
            availableAbhaNumbers[availableAbhaNumbersSelectedIndex]!.index;
      }

      Map<String, dynamic> data = {
        "loginId": loginId,
        "txnId": searchAvailabilityResponse?.txnId ?? '',
        "loginHint": "index"
      };

      dataRequestSync = jsonEncode(data);

      AbhaController controller = AbhaController();
      try {
        final response =
            await controller.sendOTPLinkExisting(data, clinicToken);

        if (response != null && response.statusCode == 200) {
          sendOtpExisting = SendOtpExisting.fromJson(response.data);

          if (sendOtpExisting?.statusCode == 200) {
            _isLoading = false;
            Navigator.pop(context);
            setState(() {
              enableAbhaClick = false;
              linkExistAbha = true;
              availableAbha = false;
              createnewFlag = false;
              startTimer();
            });
          }

          Utils.showToastMessage('${sendOtpExisting?.message}');
        } else {
          Utils.showToastMessage('Something went wrong!');
          print(response);
        }
        dataResponseSync = jsonEncode(response?.data ?? {});
      } catch (e) {
        Utils.showToastMessage('Something went wrong!');
        print(e);
      } finally {
        if (_isLoading) {
          Navigator.pop(context);
        }
      }
    } else {
      Utils.showToastMessage(Constant.internetConMsg);
    }
  }

  VerifyOtpExisting? verifyOtpExisting;

  Future<void> _verifyOTPLinkExisting(var otpCode) async {
    if (await Utils.isConnected()) {
      bool _isLoading = true;
      Utils.onLoading(context);

      var methodNameLog = Constant.log_type_existing_kyc;

      String dataRequestSync = "";
      String dataResponseSync = "";

      Map<String, dynamic> data = {
        "otp": otpCode,
        "txnId": sendOtpExisting?.txnId ?? ""
      };
      dataRequestSync = jsonEncode(data);

      AbhaController controller = AbhaController();
      try {
        final response =
            await controller.verifyOTPLinkExisting(data, clinicToken);

        if (response != null && response.statusCode == 200) {
          verifyOtpExisting = VerifyOtpExisting.fromJson(response.data);

          if (verifyOtpExisting?.statusCode == 200 &&
              verifyOtpExisting?.authResult == "success") {
            _isLoading = false;
            Navigator.pop(context);
            setState(() {
              linkExistAbha = false;
            });
            methodNameLog = Constant.log_type_existing;
            _healthCardLinkExisting(verifyOtpExisting?.token ?? '');
            // _profileLinkExisting(setStateDialog, verifyOtpExisting?.token??'');
          }

          Utils.showToastMessage('${verifyOtpExisting?.message}');
        } else {
          Utils.showToastMessage('Something went wrong!');
          print(response);
        }
        dataResponseSync = jsonEncode(response?.data ?? {});
      } catch (e) {
        dataResponseSync = e.toString() ?? '';
        Utils.showToastMessage('Something went wrong!');
        print(e);
      } finally {
        if (_isLoading) {
          Navigator.pop(context);
        }
      }
    } else {
      Utils.showToastMessage(Constant.internetConMsg);
    }
  }

  HealthCardResposne? healthCardResposne;

  Future<void> _healthCardLinkExisting(var token) async {
    if (await Utils.isConnected()) {
      bool _isLoading = true;
      Utils.onLoading(context);

      String dataRequestSync = "";
      String dataResponseSync = "";

      Map<String, dynamic> data = {"X-Token": "Bearer ${token}"};

      dataRequestSync = jsonEncode(data);

      AbhaController controller = AbhaController();
      try {
        final response =
            await controller.healthCardLinkExisting(data, clinicToken);

        if (response != null && response.statusCode == 200) {
          HealthCardResposne healthCardResposne =
              HealthCardResposne.fromJson(response.data);

          if (healthCardResposne.statusCode == 200) {
            _isLoading = false;
            Navigator.pop(context);
            setState(() {
              healthCardShow = true;
              showLinkAbhaIdList = false;
              _base64HealthcardID = healthCardResposne?.content ?? '';
              // Decode once here
              if (_base64HealthcardID!.isNotEmpty) {
                _healthCardImageBytes = base64Decode(_base64HealthcardID!);
              }
              createViaAbha = false;
            });
            // _viewImage(healthCardResposne.sData?.content??'', verifyOtpExisting?.sData?.token??'');
          } else {
            Utils.showToastMessage(Constant.tryagain);
          }
        } else {
          Utils.showToastMessage('Something went wrong!');
          print(response);
        }
        dataResponseSync = jsonEncode(response?.data ?? {});
      } catch (e) {
        dataResponseSync = e.toString() ?? '';
        Utils.showToastMessage('Something went wrong!');
        print(e);
      } finally {
        if (_isLoading) {
          Navigator.pop(context);
        }
      }
    } else {
      Utils.showToastMessage(Constant.internetConMsg);
    }
  }

  Future<void> _healthCardLinkExistingMobile(var token) async {
    if (await Utils.isConnected()) {
      bool _isLoading = true;
      Utils.onLoading(context);

      Map<String, dynamic> data = {"X-Token": "Bearer ${token}"};

      AbhaController controller = AbhaController();
      try {
        final response =
            await controller.healthCardLinkExistingMobile(data, clinicToken);

        if (response != null && response.statusCode == 200) {
          HealthCardResposne healthCardResposne =
              HealthCardResposne.fromJson(response.data);

          if (healthCardResposne.statusCode == 200) {
            _isLoading = false;
            Navigator.pop(context);
            setState(() {
              healthCardShow = true;
              showLinkAbhaIdList = false;
              _base64HealthcardID = healthCardResposne?.content ?? '';
              // Decode once here
              if (_base64HealthcardID!.isNotEmpty) {
                _healthCardImageBytes = base64Decode(_base64HealthcardID!);
              }
              createViaAbha = false;
            });
            // _viewImage(healthCardResposne.sData?.content??'', verifyOtpExisting?.sData?.token??'');
          } else {
            Utils.showToastMessage(Constant.tryagain);
          }
        } else {
          Utils.showToastMessage('Something went wrong!');
          print(response);
        }
      } catch (e) {
        Utils.showToastMessage('Something went wrong!');
        print(e);
      } finally {
        if (_isLoading) {
          Navigator.pop(context);
        }
      }
    } else {
      Utils.showToastMessage(Constant.internetConMsg);
    }
  }

  Future<void> _profileLinkExisting(var token) async {
    if (await Utils.isConnected()) {
      bool _isLoading = true;
      Utils.onLoading(context);

      Map<String, dynamic> data = {"x-token": token};

      AbhaController controller = AbhaController();
      try {
        final response =
            await controller.profileLinkExisting(data, clinicToken);

        if (response != null) {
          ProfileExisting profileExisting =
              ProfileExisting.fromJson(response.data);

          if (profileExisting.sCode == 200) {
            _isLoading = false;
            Navigator.pop(context);
          }

          Utils.showToastMessage('${profileExisting.sMessage}');
        } else {
          Utils.showToastMessage('Something went wrong!');
          print(response);
        }
      } catch (e) {
        Utils.showToastMessage('Something went wrong!');
        print(e);
      } finally {
        if (_isLoading) {
          Navigator.pop(context);
        }
      }
    } else {
      Utils.showToastMessage(Constant.internetConMsg);
    }
  }

  Widget _showHealthCard() {
    final localText = AppLocalizations.of(context)!;

    return Padding(
      padding: EdgeInsets.all(15),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          /* Align(
            alignment: Alignment.centerRight,
            child: InkWell(
                onTap: () {
                  Navigator.pop(context);
                  refresh();
                },
                child: Padding(
                    padding: EdgeInsets.all(10), child: Icon(Icons.close))),
          ),*/
          Container(
            height: 250,
            width: 250 /*MediaQuery.of(context).size.width * 0.8*/,
            // Set dialog width
            child: ClipRect(
              child: Image.memory(
                _healthCardImageBytes ?? Uint8List(0),
                fit: BoxFit.cover,
              ),
            ),
          ),
          SizedBox(
            height: 20,
          ),
          Center(
            child: Align(
              alignment: Alignment.center,
              child: InkWell(
                onTap: () async {
                  try {
                    await Utils.requestMediaPermissions();
                    String timestamp =
                        DateTime.now().millisecondsSinceEpoch.toString();
                    String filePath = await Utils.saveImageToDownloads(
                      _base64HealthcardID,
                      'ABHACard_$timestamp.png',
                    );
                    final result = await OpenFile.open(filePath);
                    print("Open file result: $result");
                  } catch (e) {
                    print('Error opening file: $e');
                    Utils.showToastMessage("Error opening file: $e");
                  }
                },
                child: Container(
                  width: 130.w,
                  height: 30.h,
                  decoration: BoxDecoration(
                    color: AppColors.greenHighlight,
                    borderRadius: BorderRadius.circular(5.0),
                    border:
                        Border.all(color: AppColors.greenHighlight, width: 1.w),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.download, // Prefix icon for "Create New"
                        color: Colors.white,
                        size: 16.sp,
                      ),
                      SizedBox(width: 6.w), // Small space between icon and text
                      Text(
                        localText.download,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          /*Row(
            children: [
              SizedBox(
                width: 125.w,
                height: 40.h,
                child: TextButton.icon(
                  onPressed: () async {
                    try {
                      await Utils.requestMediaPermissions();
                      String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
                      String filePath = await Utils.saveImageToDownloads(
                        _base64HealthcardID,
                        'ABHACard_$timestamp.png',
                      );
                      final result = await OpenFile.open(filePath);
                      print("Open file result: $result");
                    } catch (e) {
                      print('Error opening file: $e');
                      Utils.showToastMessage("Error opening file: $e");
                    }
                  },

                  icon: const Icon(Icons.download, color: Colors.white, size: 20),
                  label: Text(
                    localText.download,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12.0),
                    backgroundColor: AppColors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                ),

              ),
              */ /*SizedBox(
                width: 10,
              ),*/ /*
              */ /*Expanded(
                      flex: 1,
                      child: SizedBox(
                        // width: 125.w,
                        height: 40.h,
                        child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: () async {
                             // _abhaProfile(_token);
                            },
                            child: Text(
                              'Add New Patient',
                              style: TextStyle(
                                fontSize: 10.sp,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            )),
                      ))*/ /*
            ],
          )*/
        ],
      ),
    );
  }

  void _viewImage(String _base64, String _token) {
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (context) => Dialog(
        child: Padding(
          padding: EdgeInsets.all(15),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: InkWell(
                    onTap: () {
                      Navigator.pop(context);
                      refresh();
                    },
                    child: Padding(
                        padding: EdgeInsets.all(10), child: Icon(Icons.close))),
              ),
              Container(
                height: 250,
                width: 250 /*MediaQuery.of(context).size.width * 0.8*/,
                // Set dialog width
                child: ClipRect(
                  child: Image.memory(
                    base64Decode(_base64),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              SizedBox(
                height: 20,
              ),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      // width: 125.w,
                      height: 40.h,
                      child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.orangeApp,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () async {
                            /* try {
                              await _requestMediaPermissions(); // Ensure permission is granted.

                              String timestamp = DateTime.now()
                                  .millisecondsSinceEpoch
                                  .toString();
                              await Utils.saveImageToDownloads(
                                  _base64, 'ABHACard_$timestamp.png');
                            } catch (e) {
                              print('Error: $e');
                            }*/
                          },
                          child: Text(
                            'Download',
                            style: TextStyle(
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          )),
                    ),
                  ),
                  SizedBox(
                    width: 10,
                  ),
                  /*Expanded(
                      flex: 1,
                      child: SizedBox(
                        // width: 125.w,
                        height: 40.h,
                        child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: () async {
                             // _abhaProfile(_token);
                            },
                            child: Text(
                              'Add New Patient',
                              style: TextStyle(
                                fontSize: 10.sp,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            )),
                      ))*/
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectDate(StateSetter setStatea) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (pickedDate != null) {
      setStatea(() {
        dobController.text = DateFormat('dd/MM/yyyy').format(pickedDate);
      });
      suggestion(setStatea);
    }
  }

  //Verify ABHA
  TextEditingController otpLinkController = new TextEditingController();

  String? authMethodSelectedvalue;
  var txnIdLinkAbha = '';

  // List of items in our dropdown menu
  var itemsAuthMethod = [''];

  void refreshLinkABha() {
    otpLinkController.text = '';
    authMethodSelectedvalue = '';
    itemsAuthMethod = [];
    txnIdLinkAbha = '';
    abhaIdController.text = '';
  }

  GetStates getStates = new GetStates();
  SDataState selectedState = new SDataState();

  //GetState and districts
  Future<void> _getStates() async {
    if (await Utils.isConnected()) {
      bool _isLoading = true;
      //Utils.onLoading(context);

      AbhaController controller = AbhaController();
      try {
        final response = await controller.getStates(clinicToken);

        if (response != null) {
          getStates = GetStates.fromJson(response.data);

          if (getStates?.sCode == 200) {
            _isLoading = false;
            // Navigator.pop(context);
          }

          //Utils.showToastMessage('${getStates.sMessage}');
        } else {
          // Utils.showToastMessage('Something went wrong!');
          print(response);
        }
      } catch (e) {
        //  Utils.showToastMessage('Something went wrong!');
        print(e);
      } finally {
        /* if (_isLoading) {
          Navigator.pop(context);
        }*/
      }
    } else {
      // Utils.showToastMessage(Constant.internetConMsg);
    }
  }

  GetDistricts getDistricts = new GetDistricts();
  SDataDistricts selectedDistrict = new SDataDistricts();

  Future<void> _getDistricts() async {
    if (await Utils.isConnected()) {
      bool _isLoading = true;
      Utils.onLoading(context);

      Map<String, dynamic> data = {"stateId": selectedState.stateCode};

      AbhaController controller = AbhaController();
      try {
        final response = await controller.getDistricts(data, clinicToken);

        if (response != null) {
          getDistricts = GetDistricts.fromJson(response.data);

          if (getDistricts.sCode == 200) {
            _isLoading = false;
            Navigator.pop(context);
          }

          //Utils.showToastMessage('${getDistricts.sMessage}');
        } else {
          Utils.showToastMessage('Something went wrong!');
          print(response);
        }
      } catch (e) {
        Utils.showToastMessage('Something went wrong!');
        print(e);
      } finally {
        if (_isLoading) {
          Navigator.pop(context);
        }
      }
    } else {
      Utils.showToastMessage(Constant.internetConMsg);
    }
  }

  String getOtpLabel(String defaultText) {
    if (dropdownvalue == 'Aadhaar' && updateMobile == false) {
      return 'Enter Aadhaar OTP';
    } else if (dropdownvalue == 'Aadhaar' && updateMobile == true) {
      return 'Enter Mobile Verify OTP';
    } else {
      return defaultText;
    }
  }

// Create abha Addhaar

  var callAbhaSuggestion = false;
  var updateMobile = false;
  var sendOTP = 'SendOtp';
  var verifyOTP = 'VierfyOtp';
  SendOtpExisting? aadhaarSendOtp;
  VerifyOtpAadhaar? verifyOtpAadhaar;
  VerifyOtpMobile? verifyOtpMobile;

  Future<void> _aadhaarOTPABHA(var clickVal) async {
    listABHAID = [];
    if (await Utils.isConnected()) {
      bool _isLoading = true;
      Utils.onLoading(context);
      String dataRequestSync = "";
      String dataResponseSync = "";

      Map<String, dynamic>? jsonData;
      var methodName = '';

      //Aadhaar
      if (dropdownvalue == 'Aadhaar') {
        if (clickVal == sendOTP) {
          jsonData = {
            "aadhaar": aadhaarController.text,
            "entity_type": "patient",
            "entity_id": "0" //patient id for existing patient
          };
          methodName = AbhaController.aadharSendOTP;
        } else if (clickVal == verifyOTP) {
          if (updateMobile) {
            jsonData = {
              "txnId": verifyOtpAadhaar?.txnId ?? '',
              "otp": otpController.text ?? ''
            };
            methodName = AbhaController.aadhaarMobileVerify;
          } else {
            jsonData = {
              "txnId": aadhaarSendOtp?.txnId ?? '',
              "otp": otpController.text ?? '',
              "mobile": mobileController.text
            };
            methodName = AbhaController.aadharVerifyOTP;
          }
        }
      } else {
        //Mobile
        if (clickVal == sendOTP) {
          jsonData = {
            "mobile": mobileController.text,
            "entity_type": "patient",
            "entity_id": "0" //patient id for existing patient
          };

          methodName = AbhaController.mobileSendotp;
        } else if (clickVal == verifyOTP) {
          jsonData = {
            "otp": otpController.text ?? '',
            "txnId": aadhaarSendOtp?.txnId ?? ''
          };
          methodName = AbhaController.mobileVerifyotp;
        }
      }

      dataRequestSync = jsonEncode(jsonData);

      AbhaController controller = AbhaController();
      try {
        final response = await controller.aadhaarCreateABHA(
            methodName, jsonData, clinicToken);

        if (response != null && response.statusCode == 200) {
          var sMessage;
          if (clickVal == sendOTP) {
            aadhaarSendOtp = SendOtpExisting.fromJson(response.data);
            if (aadhaarSendOtp?.statusCode == 200) {
              _isLoading = false;
              Navigator.pop(context);
              setState(() {
                linkExistAbha = true;
                sendOtpAbha = false;
                termCondFlag = false;
              });
              startTimer();
            }
            sMessage = aadhaarSendOtp?.message;
          } else if (clickVal == verifyOTP) {
            if (dropdownvalue == 'Aadhaar') {
              if (response != null && response.statusCode == 200) {
                //VerifyOtpAadhaar verifyres = VerifyOtpAadhaar.fromJson(response.data);
                if (updateMobile) {
                  final txnId = response.data["txnId"];
                  if (verifyOtpAadhaar != null) {
                    verifyOtpAadhaar!.txnId = txnId;
                  }
                } else {
                  verifyOtpAadhaar = VerifyOtpAadhaar.fromJson(response.data);
                }
                if (verifyOtpAadhaar?.statusCode == 200) {
                  createMobileAadhharView = false;
                  _isLoading = false;
                  Navigator.pop(context);
                  /* setState(() {
                    linkExistAbha = false;
                    showLinkAbhaIdList = true;
                  //  listABHAID.add(ABHAID(verifyOtpAadhaar?.aBHAProfile?.phrAddress?.first??'', true));
                  });*/

                  var abhaMobileNo =
                      verifyOtpAadhaar?.aBHAProfile?.mobile ?? '';

                  if (abhaMobileNo != mobileController.text &&
                      updateMobile == false) {
                    final result = await showAadharAlert(context);
                    if (result == true) {
                      // User selected Yes → update the number
                      _updateCommunication();
                    } else {
                      // User selected No
                      updateMobile = false;
                      setState(() {
                        linkExistAbha = false;
                        showLinkAbhaIdList = true;
                        listABHAID.add(ABHAID(
                            verifyOtpAadhaar?.aBHAProfile?.phrAddress?.first ??
                                '',
                            true));
                      });

                      if (listABHAID.length == 0) {
                        setState(() {
                          callAbhaSuggestion = false;
                        });
                        _aadhaarabhasuggestions();
                      } else {
                        callAbhaSuggestion = true;
                      }
                    }
                  } else {
                    updateMobile = false;
                    setState(() {
                      linkExistAbha = false;
                      showLinkAbhaIdList = true;
                      listABHAID.add(ABHAID(
                          verifyOtpAadhaar?.aBHAProfile?.phrAddress?.first ??
                              '',
                          true));
                    });

                    if (listABHAID.length == 0) {
                      setState(() {
                        callAbhaSuggestion = false;
                      });
                      _aadhaarabhasuggestions();
                    } else {
                      callAbhaSuggestion = true;
                    }
                  }
                }

                // _profileMobile(verifyOtpAadhaar?.tokens?.token??'');
                sMessage = verifyOtpAadhaar?.message;
              } else {
                Error400 error400 = Error400.fromJson(response?.data);
                Utils.showToastMessage(error400.errorDetails?.message ??
                    'Something went wrong! ${response?.statusCode}');
                setState(() {
                  checkavailableAbha = false;
                  dropdownvalue = defaultDropdownValue;
                  linkExistAbha = false;
                  availableAbha = false;
                  createViaAbha = true;

                  termCondFlag = true;
                });
                print(response);
              }
            } else {
              verifyOtpMobile = VerifyOtpMobile.fromJson(response.data);
              if (verifyOtpMobile?.statusCode == 200) {
                _isLoading = false;
                Navigator.pop(context);
                setState(() {
                  linkExistAbha = false;
                  showLinkAbhaIdList = true;
                  if (verifyOtpMobile?.users != null) {
                    for (var imageAsset in verifyOtpMobile!.users!) {
                      if (imageAsset.kycStatus == "VERIFIED") {
                        listABHAID
                            .add(ABHAID(imageAsset.abhaAddress ?? '', true));
                      }
                    }
                  }
                });
                //_mobileabhasuggestions();
                // _profileMobile(verifyOtpMobile?.tokens?.token??'');
              }
              sMessage = verifyOtpMobile?.message;
            }
          }
          Utils.showToastMessage(sMessage);
        } else if (response != null && response.statusCode == 400) {
          Error400 error400 = Error400.fromJson(response.data);
          Utils.showToastMessage(error400.errorDetails?.message ??
              'Something went wrong! ${response?.statusCode}');
          print(response);
        } else {
          if (response != null) {
            Error400 error400 = Error400.fromJson(response.data);
            // Get the message safely
            String fullMessage = error400.error?.message ??
                'Something went wrong! ${response?.statusCode}';

            // Check if it contains "OTP validation failed"
            String displayMessage;
            if (fullMessage.contains("OTP validation failed")) {
              displayMessage = "OTP validation failed";
            } else {
              displayMessage = fullMessage;
            }

// Show toast
            Utils.showToastMessage(displayMessage);
          } else {
            Utils.showToastMessage(
                'Something went wrong! ${response?.statusCode}');
          }

          print(response);
        }
        dataResponseSync = jsonEncode(response?.data ?? {});
      } catch (e) {
        dataResponseSync = e.toString() ?? '';
        Utils.showToastMessage('Something went wrong!');
        print(e);
      } finally {
        if (_isLoading) {
          Navigator.pop(context);
        }
        var logName = Constant.log_type_create_new_via_mobile;
        if (dropdownvalue == 'Aadhaar') {
          logName = Constant.log_type_create_new_via_aadhaar;
        }
      }
    } else {
      Utils.showToastMessage(Constant.internetConMsg);
    }
  }

  static Future<bool?> showAadharAlert(BuildContext context) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false, // forces user to choose Yes or No
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Mobile Number Mismatch',
            style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 12.sp),
          ),
          content: Text(
            'The Aadhaar-linked mobile number is different from the number you searched for.\n\nDo you want to update the mobile number?',
            style: TextStyle(color: Colors.black, fontSize: 12.sp),
          ),
          actionsAlignment: MainAxisAlignment.end,
          actions: [
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey[700],
              ),
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('No',
                  style: TextStyle(color: Colors.black, fontSize: 12.sp)),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('Yes',
                  style: TextStyle(color: Colors.white, fontSize: 12.sp)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _updateCommunication() async {
    //listABHAID = [];
    if (await Utils.isConnected()) {
      bool _isLoading = true;
      Utils.onLoading(context);
      String dataRequestSync = "";
      String dataResponseSync = "";

      Map<String, dynamic>? jsonData = {
        "txnId": verifyOtpAadhaar?.txnId,
        "mobile": mobileController.text
      };
      dataRequestSync = jsonEncode(jsonData);

      AbhaController controller = AbhaController();
      try {
        final response = await controller.aadhaarCreateABHA(
            AbhaController.aadhaarMobileUpdate, jsonData, clinicToken);

        if (response != null && response.statusCode == 200) {
          var sMessage;
          UpdateAadhaarMobile verifyOtpAadhaar =
              UpdateAadhaarMobile.fromJson(response.data);
          if (verifyOtpAadhaar?.statusCode == 200) {
            _isLoading = false;
            Navigator.pop(context);
            sMessage = verifyOtpAadhaar?.message ?? '';
            setState(() {
              otpController.text = "";
              updateMobile = true;
              linkExistAbha = true;
              sendOtpAbha = false;
              termCondFlag = false;
            });
          }
          // sMessage = abhaSuggestionMobile?.statusCode;
          Utils.showToastMessage(sMessage);
        } else {
          Error400 error400 = Error400.fromJson(response?.data);
          Utils.showToastMessage(error400.errorDetails?.message ??
              'Something went wrong! ${response?.statusCode}');
          setState(() {
            checkavailableAbha = false;
            dropdownvalue = defaultDropdownValue;
            linkExistAbha = false;
            availableAbha = false;
            createViaAbha = true;

            termCondFlag = true;
          });
          print(response);
        }
        dataResponseSync = jsonEncode(response?.data ?? {});
      } catch (e) {
        dataResponseSync = e.toString() ?? '';
        Utils.showToastMessage('Something went wrong!');
        print(e);
      } finally {
        if (_isLoading) {
          Navigator.pop(context);
        }
      }
    } else {
      Utils.showToastMessage(Constant.internetConMsg);
    }
  }

  Future<void> _continueExisitingABHAMobileUser(var selectedAbha) async {
    if (await Utils.isConnected()) {
      bool _isLoading = true;
      Utils.onLoading(context);
      String dataRequestSync = "";
      String dataResponseSync = "";
      Map<String, dynamic> data = {
        "X-Token": "Bearer ${verifyOtpMobile?.tokens?.token}",
        //token that came in the above API.
        "abhaAddress": selectedAbha,
        "txnId": verifyOtpMobile?.txnId ?? ''
      };
      dataRequestSync = jsonEncode(data);

      var methodName = AbhaController.continueExisitingABHAMobile;

      AbhaController controller = AbhaController();
      try {
        final response =
            await controller.aadhaarCreateABHA(methodName, data, clinicToken);

        if (response != null && response.statusCode == 200) {
          ExistingMobileAbha existingMobileAbha =
              ExistingMobileAbha.fromJson(response.data);

          if (existingMobileAbha.statusCode == 200) {
            _isLoading = false;
            Navigator.pop(context);
            _healthCardLinkExistingMobile(existingMobileAbha.token ?? '');
            //_mobileabhasuggestions(profileAadhaar);
          }

          //Utils.showToastMessage('${profileMobile}');
        } else {
          Error400 error400 = Error400.fromJson(response?.data);
          Utils.showToastMessage(error400.errorDetails?.message ??
              'Something went wrong! ${response?.statusCode}');
          setState(() {
            checkavailableAbha = false;
            dropdownvalue = defaultDropdownValue;
            linkExistAbha = false;
            availableAbha = false;
            createViaAbha = true;

            termCondFlag = true;
          });
          print(response);
        }
        dataResponseSync = jsonEncode(response?.data ?? {});
      } catch (e) {
        dataResponseSync = e.toString() ?? '';
        Utils.showToastMessage('Something went wrong!');
        print(e);
      } finally {
        if (_isLoading) {
          Navigator.pop(context);
        }
      }
    } else {
      Utils.showToastMessage(Constant.internetConMsg);
    }
  }

//Mobile create
  Future<void> _mobileCreateLinkExisitingABHA() async {
    if (await Utils.isConnected()) {
      bool _isLoading = true;
      Utils.onLoading(context);

      Map<String, dynamic>? jsonData = {
        "txnId": verifyOtpMobile?.txnId ?? '',
        "abha_address": _selectedAbhaIDValue,
        "x_token": 'Bearer ${verifyOtpMobile?.tokens?.token}'
      };
      var methodName = AbhaController.mobileLinkExisting;

      AbhaController controller = AbhaController();
      try {
        final response = await controller.aadhaarCreateABHA(
            methodName, jsonData, clinicToken);

        if (response != null) {
          var sMessage;
          MobileLinkAbhaAddress createAadhaarResponse =
              MobileLinkAbhaAddress.fromJson(response.data);
          if (createAadhaarResponse?.sCode == 200) {
            _isLoading = false;
            Navigator.pop(context);
            _healthCardMobile(createAadhaarResponse?.sData?.token ?? '');
            //_profileLinkMobile(setStateDialog, createAadhaarResponse?.sData?.token??'');
          }
          sMessage = createAadhaarResponse?.sMessage;
          Utils.showToastMessage(sMessage);
        } else {
          Utils.showToastMessage('Something went wrong!');
          print(response);
        }
      } catch (e) {
        Utils.showToastMessage('Something went wrong!');
        print(e);
      } finally {
        if (_isLoading) {
          Navigator.pop(context);
        }
      }
    } else {
      Utils.showToastMessage(Constant.internetConMsg);
    }
  }

  Future<void> _healthCardMobile(var token) async {
    if (await Utils.isConnected()) {
      bool _isLoading = true;
      Utils.onLoading(context);

      Map<String, dynamic> data = {"token": 'Bearer ${token}'};

      AbhaController controller = AbhaController();
      try {
        final response = await controller.aadhaarCreateABHA(
            AbhaController.mobileHealthCard, data, clinicToken);

        if (response != null) {
          HealthCardResposne healthCardResposne =
              HealthCardResposne.fromJson(response.data);

          if (healthCardResposne.statusCode == 200) {
            _isLoading = false;
            Navigator.pop(context);
            setState(() {
              healthCardShow = true;
              showLinkAbhaIdList = false;
              _base64HealthcardID = healthCardResposne?.content ?? '';
              // Decode once here
              if (_base64HealthcardID!.isNotEmpty) {
                _healthCardImageBytes = base64Decode(_base64HealthcardID!);
              }
            });
            // _viewImage(healthCardResposne.sData?.content??'', verifyOtpExisting?.sData?.token??'');
          }

          // Utils.showToastMessage('${healthCardResposne.sMessage}');
        } else {
          Utils.showToastMessage('Something went wrong!');
          print(response);
        }
      } catch (e) {
        Utils.showToastMessage('Something went wrong!');
        print(e);
      } finally {
        if (_isLoading) {
          Navigator.pop(context);
        }
      }
    } else {
      Utils.showToastMessage(Constant.internetConMsg);
    }
  }

  Future<void> _healthCardAfterCreateMobile(var token) async {
    if (await Utils.isConnected()) {
      bool _isLoading = true;
      Utils.onLoading(context);
      String dataRequestSync = "";
      String dataResponseSync = "";

      Map<String, dynamic> data = {"X-Token": 'Bearer ${token}'};
      dataRequestSync = jsonEncode(data);

      AbhaController controller = AbhaController();
      try {
        final response = await controller.aadhaarCreateABHA(
            AbhaController.mobileCreateABHACard, data, clinicToken);

        if (response != null) {
          HealthCardResposne healthCardResposne =
              HealthCardResposne.fromJson(response.data);
          if (healthCardResposne.statusCode == 200) {
            _isLoading = false;
            Navigator.pop(context);
            setState(() {
              healthCardShow = true;
              showLinkAbhaIdList = false;
              _base64HealthcardID = healthCardResposne?.content ?? '';
              // Decode once here
              if (_base64HealthcardID!.isNotEmpty) {
                _healthCardImageBytes = base64Decode(_base64HealthcardID!);
              }
            });
            // _viewImage(healthCardResposne.sData?.content??'', verifyOtpExisting?.sData?.token??'');
          } else {
            Error400 error400 = Error400.fromJson(response?.data);
            Utils.showToastMessage(error400.errorDetails?.message ??
                'Something went wrong! ${response?.statusCode}');

            setState(() {
              refresh();
              refreshLinkABha();
            });
            print(response);
          }

          // Utils.showToastMessage('${healthCardResposne.sMessage}');
        } else {
          Utils.showToastMessage('Something went wrong!');
          print(response);
        }
        dataResponseSync = jsonEncode(response?.data ?? {});
      } catch (e) {
        dataResponseSync = e.toString() ?? '';
        Utils.showToastMessage('Something went wrong!');
        print(e);
      } finally {
        if (_isLoading) {
          Navigator.pop(context);
        }
        //syncConcierge(Constant.create_new, dataRequestSync, dataResponseSync, Constant.log_type_downloadCard);
      }
    } else {
      Utils.showToastMessage(Constant.internetConMsg);
    }
  }

  Future<void> _profileMobile(var token) async {
    if (await Utils.isConnected()) {
      bool _isLoading = true;
      Utils.onLoading(context);

      Map<String, dynamic> data = {"X-Token": "Bearer ${token}"};

      var methodName = "";
      if (dropdownvalue == 'Aadhaar') {
        methodName = AbhaController.aadhaarProfile;
      } else {
        methodName = AbhaController.mobileProfile;
      }
      AbhaController controller = AbhaController();
      try {
        final response =
            await controller.aadhaarCreateABHA(methodName, data, clinicToken);

        if (response != null && response.statusCode == 200) {
          ProfileAadhaar profileAadhaar =
              ProfileAadhaar.fromJson(response.data);

          if (profileAadhaar.statusCode == 200) {
            _isLoading = false;
            Navigator.pop(context);
            //_mobileabhasuggestions(profileAadhaar);
          }

          //Utils.showToastMessage('${profileMobile}');
        } else {
          Error400 error400 = Error400.fromJson(response?.data);
          Utils.showToastMessage(error400.errorDetails?.message ??
              'Something went wrong! ${response?.statusCode}');
          setState(() {
            checkavailableAbha = false;
            dropdownvalue = defaultDropdownValue;
            linkExistAbha = false;
            availableAbha = false;
            createViaAbha = true;

            termCondFlag = true;
          });
          print(response);
        }
      } catch (e) {
        Utils.showToastMessage('Something went wrong!');
        print(e);
      } finally {
        if (_isLoading) {
          Navigator.pop(context);
        }
      }
    } else {
      Utils.showToastMessage(Constant.internetConMsg);
    }
  }

   bool showTextFieldABHAID= false;
  Future<void> _aadhaarabhasuggestions() async {
    //listABHAID = [];
    if (await Utils.isConnected()) {
      bool _isLoading = true;
      Utils.onLoading(context);

      Map<String, dynamic>? jsonData = {
        "txnId": verifyOtpAadhaar?.txnId ?? '',
      };

      AbhaController controller = AbhaController();
      try {
        final response = await controller.getABHASuggesstion(jsonData, "");

        if (response != null && response.statusCode == 200) {
          var sMessage;
          AbhaSuggestionMobile abhaSuggestionMobile =
              AbhaSuggestionMobile.fromJson(response.data);
          if (abhaSuggestionMobile?.statusCode == 200) {
            _isLoading = false;
            Navigator.pop(context);
            if (abhaSuggestionMobile?.abhaAddressList != null) {
              listMobileAbhaSuggestion = abhaSuggestionMobile!.abhaAddressList!;
              if (listMobileAbhaSuggestion.isNotEmpty) {
                setState(() {
                  txtABHAIDMobileController.text =
                      listMobileAbhaSuggestion[0] ?? '';
                  _valueSelectedSuggestId = 0;
                });
              }
            }

            setState(() {
              listABHAID = [];
              createMobileAadhharView = true;
              listMobileAbhaSuggestion;
              callAbhaSuggestion = false;
            });
          }
          // sMessage = abhaSuggestionMobile?.statusCode;
          // Utils.showToastMessage(sMessage);
        } else {
          listABHAID = [];
          Error400 error400 = Error400.fromJson(response?.data);
          Utils.showToastMessage(error400.errorDetails?.message ??
              'Something went wrong! ${response?.statusCode}');
          setState(() {
            showLinkAbhaIdList = true;
            callAbhaSuggestion = false;
            listABHAID;
          });
          /* setState(() {
            checkavailableAbha= false;
            dropdownvalue = defaultDropdownValue;
            linkExistAbha =false;
            availableAbha =false;
            createViaAbha =true;

            termCondFlag =true;
          });*/
          print(response);
        }
      } catch (e) {
        Utils.showToastMessage('Something went wrong!');
        print(e);
      } finally {
        if (_isLoading) {
          Navigator.pop(context);
        }
        setState(() {
          showTextFieldABHAID = true;
        });
      }
    } else {
      Utils.showToastMessage(Constant.internetConMsg);
    }
  }

  Future<void> _mobileabhasuggestions(StateSetter setStateDialog) async {
    //listABHAID = [];
    if (await Utils.isConnected()) {
      bool _isLoading = true;
      Utils.onLoading(context);

      var dayOfBirth = '', monthOfBirth = '', yearOfBirth = '';

      if (dobController.text.isNotEmpty) {
        String date = dobController.text;
        List<String> dateParts = date.split("/");
        dayOfBirth = dateParts[0];
        monthOfBirth = dateParts[1];
        yearOfBirth = dateParts[2];
      }

      Map<String, dynamic>? jsonData = {
        "txnId": verifyOtpMobile?.txnId ?? '',
        "firstName": firstNameController.text.trim() ?? '',
        "lastName": lastNameController.text.trim() ?? '',
        "dayOfBirth": dayOfBirth,
        "monthOfBirth": monthOfBirth,
        "yearOfBirth": yearOfBirth,
        "email": ""
      };

      AbhaController controller = AbhaController();
      try {
        final response =
            await controller.getMobileABHASuggesstion(jsonData, "");

        if (response != null && response.statusCode == 200) {
          var sMessage;
          AbhaSuggestionMobile abhaSuggestionMobile =
              AbhaSuggestionMobile.fromJson(response.data);
          if (abhaSuggestionMobile?.statusCode == 200) {
            _isLoading = false;
            Navigator.pop(context);
            if (abhaSuggestionMobile?.abhaAddressList != null) {
              listMobileAbhaSuggestion = abhaSuggestionMobile!.abhaAddressList!;
              if (listMobileAbhaSuggestion.isNotEmpty) {
                setState(() {
                  _valueSelectedSuggestId = 0;
                  txtABHAIDMobileController.text = listMobileAbhaSuggestion[0];
                });
              }
            }

            setStateDialog(() {
              createMobileAadhharView = true;
              listMobileAbhaSuggestion;
            });
          }
          // sMessage = abhaSuggestionMobile?.statusCode;
          // Utils.showToastMessage(sMessage);
        } else {
          Error400 error400 = Error400.fromJson(response?.data);
          Utils.showToastMessage(error400.errorDetails?.message ??
              'Something went wrong! ${response?.statusCode}');
          setState(() {
            checkavailableAbha = false;
            dropdownvalue = defaultDropdownValue;
            linkExistAbha = false;
            availableAbha = false;
            createViaAbha = true;

            termCondFlag = true;
          });
          print(response);
        }
      } catch (e) {
        Utils.showToastMessage('Something went wrong!');
        print(e);
      } finally {
        if (_isLoading) {
          Navigator.pop(context);
        }
      }
    } else {
      Utils.showToastMessage(Constant.internetConMsg);
    }
  }

  Future<void> _aadhaarCreateABHA() async {
    //listABHAID = [];
    if (await Utils.isConnected()) {
      bool _isLoading = true;
      Utils.onLoading(context);
      var methodNameLog = Constant.create_new;
      String dataRequestSync = "";
      String dataResponseSync = "";

      Map<String, dynamic>? jsonData = {
        "abhaAddress": txtABHAIDMobileController.text,
        "preferred": 1,
        "txnId": verifyOtpAadhaar?.txnId ?? ''
      };

      dataRequestSync = jsonEncode(jsonData);

      var methodName = AbhaController.aadhaarCreate;

      AbhaController controller = AbhaController();
      try {
        final response = await controller.aadhaarCreateABHA(
            methodName, jsonData, clinicToken);

        if (response != null) {
          var sMessage;
          CreateAbhaAadhaar createAadhaarResponse =
              CreateAbhaAadhaar.fromJson(response.data);
          if (createAadhaarResponse?.statusCode == 200) {
            _isLoading = false;
            Navigator.pop(context);
            Utils.showToastMessage("Abha Created Successfully!");
            methodNameLog = Constant.log_type_create_new_via_aadhaar_final;
            _healthCardLinkExisting(verifyOtpAadhaar?.tokens?.token ?? '');
          }
          // sMessage = createAadhaarResponse?.;
          // Utils.showToastMessage(sMessage);
        } else {
          Utils.showToastMessage('Something went wrong!');
          print(response);
        }
        dataResponseSync = jsonEncode(response?.data ?? {});
      } catch (e) {
        dataResponseSync = e.toString() ?? '';
        Utils.showToastMessage('Something went wrong!');
        print(e);
      } finally {
        if (_isLoading) {
          Navigator.pop(context);
        }
      }
    } else {
      Utils.showToastMessage(Constant.internetConMsg);
    }
  }

  List<String> listMobileAbhaSuggestion = [];
  var _valueSelectedSuggestId;

  Future<void> _submitDetailsMobile(StateSetter setStateDialog) async {
    if (firstNameController.text.isEmpty) {
      Utils.showToastMessage('Enter First Name');
    } else if (lastNameController.text.isEmpty) {
      Utils.showToastMessage('Enter Last Name');
    } else if (gender_dropdownvalue == null || gender_dropdownvalue == '') {
      Utils.showToastMessage('Select Gender');
    } else if (dobController.text.isEmpty) {
      Utils.showToastMessage('Select Date of Birth');
    } else if (patientEmailController.text.isEmpty) {
      Utils.showToastMessage('Enter Email ID');
    } else if (mobileCreateController.text.isEmpty) {
      Utils.showToastMessage('Enter Mobile Number');
    } else if (patientAddressController.text.isEmpty) {
      Utils.showToastMessage('Enter Address');
    } else if (patientPinCodeController.text.isEmpty) {
      Utils.showToastMessage('Enter Pincode');
    } else {
      if (await Utils.isConnected()) {
        bool _isLoading = true;
        Utils.onLoading(context);

        var name =
            '${firstNameController.text} ${firstMiddleController.text} ${lastNameController.text}';

        var gender = '';
        if (gender_dropdownvalue == 'Male') {
          gender = 'M';
        } else if (gender_dropdownvalue == 'Female') {
          gender = 'F';
        } else if (gender_dropdownvalue == 'Other') {
          gender = 'O';
        }

        DateFormat dateFormat = DateFormat('dd/mm/yyyy');

        // Parse the dateString to DateTime
        DateTime birthDate = dateFormat.parse(dobController.text);
        var selectedDate = DateFormat('yyyy-mm-dd').format(birthDate);

        /* Map<String, dynamic> data = {
          "sessionId" : aadhaarSendOtp?.sData?.sessionId??'',
          "name" : name,
          "dateOfBirth" : selectedDate, // Format yyyy-mm-dd
          "gender" : gender, // M for male, F for femal, O for others
          "stateCode" : selectedState.stateCode,
          "districtCode" : selectedDistrict.code,
          "email" : patientEmailController.text,
          "mobile" : mobileCreateController.text,
          "pinCode" : patientPinCodeController.text,
          "address" : patientAddressController.text
        };*/
        Map<String, dynamic> data = {
          "txnId": verifyOtpMobile?.txnId ?? '',
          "firstName": firstNameController.text,
          "lastName": lastNameController.text,
          "dateOfBirth": selectedDate
        };

        listMobileAbhaSuggestion = [];
        _valueSelectedSuggestId = '';
        AbhaController controller = AbhaController();
        var methodName = AbhaController.mobileSubmitDetails;
        try {
          final response =
              await controller.aadhaarCreateABHA(methodName, data, clinicToken);

          if (response != null) {
            AbhaSuggestionModel abhaSuggestionModel =
                AbhaSuggestionModel.fromJson(response.data);

            if (abhaSuggestionModel.sCode == 200) {
              _isLoading = false;
              Navigator.pop(context);

              if (abhaSuggestionModel?.sData?.abhaAddressList != null) {
                listMobileAbhaSuggestion =
                    abhaSuggestionModel!.sData!.abhaAddressList!;
              }

              setStateDialog(() {
                createMobileAadhharView = false;
              });
            }

            Utils.showToastMessage('${abhaSuggestionModel.sMessage}');
          } else {
            Utils.showToastMessage('Something went wrong!');
            print(response);
          }
        } catch (e) {
          Utils.showToastMessage('Something went wrong!');
          print(e);
        } finally {
          if (_isLoading) {
            Navigator.pop(context);
          }
        }
      } else {
        Utils.showToastMessage(Constant.internetConMsg);
      }
    }
  }

  Future<void> _mobileCreateABHA() async {
    if (firstNameController.text.isEmpty) {
      Utils.showToastMessage('Enter First Name');
    } else if (lastNameController.text.isEmpty) {
      Utils.showToastMessage('Enter Last Name');
    } else if (gender_dropdownvalue == null || gender_dropdownvalue == '') {
      Utils.showToastMessage('Select Gender');
    } else if (dobController.text.isEmpty) {
      Utils.showToastMessage('Select Date of Birth');
    } else if (selectedState.stateCode == null ||
        selectedState.stateCode.toString().isEmpty) {
      Utils.showToastMessage('Select State');
    } else if (selectedDistrict.code == null ||
        selectedDistrict.code.toString().isEmpty) {
      Utils.showToastMessage('Select District');
    } else if (patientEmailController.text.isEmpty) {
      Utils.showToastMessage('Enter Email ID');
    } else if (mobileCreateController.text.isEmpty) {
      Utils.showToastMessage('Enter Mobile Number');
    } else if (patientAddressController.text.isEmpty) {
      Utils.showToastMessage('Enter Address');
    } else if (patientPinCodeController.text.isEmpty) {
      Utils.showToastMessage('Enter Pincode');
    } else if (txtABHAIDMobileController.text.isEmpty) {
      Utils.showToastMessage('Please enter ABHA ID');
    } else {
      if (await Utils.isConnected()) {
        bool _isLoading = true;
        Utils.onLoading(context);
        var gender = '';
        var dayOfBirth = '', monthOfBirth = '', yearOfBirth = '';
        try {
          if (dobController.text.isNotEmpty) {
            String date = dobController.text;
            List<String> dateParts = date.split("/");
            dayOfBirth = dateParts[0];
            monthOfBirth = dateParts[1];
            yearOfBirth = dateParts[2];
          }

          if (gender_dropdownvalue == 'Male') {
            gender = 'M';
          } else if (gender_dropdownvalue == 'Female') {
            gender = 'F';
          } else if (gender_dropdownvalue == 'Other') {
            gender = 'O';
          }
        } catch (e) {}

        var methodNameLog = Constant.create_new;

        String dataRequestSync = "";
        String dataResponseSync = "";

        Map<String, dynamic>? jsonData = {
          "txnId": verifyOtpMobile?.txnId ?? '',
          "phrDetails": {
            "firstName": firstNameController.text,
            "middleName": firstMiddleController.text,
            "lastName": lastNameController.text,
            "dayOfBirth": dayOfBirth,
            "monthOfBirth": monthOfBirth,
            "yearOfBirth": yearOfBirth,
            "gender": gender,
            "email": patientEmailController.text,
            "mobile": mobileCreateController.text,
            "address": patientAddressController.text,
            "stateName": selectedState.stateName,
            "stateCode": selectedState.stateCode.toString(),
            "districtName": selectedDistrict.name,
            "districtCode": selectedDistrict.code.toString(),
            "pinCode": patientPinCodeController.text,
            "abhaAddress": '${txtABHAIDMobileController.text}$abhaIdEnd',
            "password": ""
          }
        };

        dataRequestSync = jsonEncode(jsonData);

        var methodName = AbhaController.mobileCreateAbhaAddress;

        AbhaController controller = AbhaController();
        try {
          final response = await controller.aadhaarCreateABHA(
              methodName, jsonData, clinicToken);

          if (response != null && response.statusCode == 200) {
            var sMessage;
            MobileCreateAddressResponse mobileCreateAddressResponse =
                MobileCreateAddressResponse.fromJson(response.data);
            if (mobileCreateAddressResponse?.statusCode == 200) {
              _isLoading = false;
              Navigator.pop(context);
              Navigator.pop(context);
              methodNameLog = Constant.log_type_create_new_via_mobile_final;

              _healthCardAfterCreateMobile(
                  mobileCreateAddressResponse?.tokens?.token ?? '');

              //_healthCardAfterCreateMobile(mobileCreateAddressResponse?.tokens?.token??'');
              // _profileLinkExisting(setStateDialog, mobileCreateAddressResponse?.sData?.token??'');
            } else {
              Error400 error400 = Error400.fromJson(response?.data);
              Utils.showToastMessage(error400.errorDetails?.message ??
                  'Something went wrong! ${response?.statusCode}');
              setState(() {
                checkavailableAbha = false;
                dropdownvalue = defaultDropdownValue;
                linkExistAbha = false;
                availableAbha = false;
                createViaAbha = true;

                termCondFlag = true;
              });
              print(response);
            }
            sMessage = mobileCreateAddressResponse?.message;
            Utils.showToastMessage(sMessage ?? '');
          } else {
            Utils.showToastMessage('Something went wrong!');
            print(response);
          }
          dataResponseSync = jsonEncode(response?.data ?? {});
        } catch (e) {
          dataResponseSync = e.toString() ?? '';
          Utils.showToastMessage('Something went wrong!');
          print(e);
        } finally {
          if (_isLoading) {
            Navigator.pop(context);
          }
        }
      } else {
        Utils.showToastMessage(Constant.internetConMsg);
      }
    }
  }

  bool otpVisible() {
    bool visible = false;
    if (checkedIAgreeValue_1 == true &&
        checkedIAgreeValue_2 == true &&
        checkedIAgreeValue_3 == true &&
        checkedIAgreeValue_4 == true &&
        checkedIAgreeValue_5 == true &&
        checkedIAgreeValue_7 == true &&
        checkedIAgreeValue_6 == true) {
      visible = true;
    }

    return visible;
  }
}

class ABHAID {
  String? abhaId;
  bool selectedAbha = false;

  ABHAID(this.abhaId, this.selectedAbha);
}
