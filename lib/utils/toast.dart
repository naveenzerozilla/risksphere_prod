import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

const String somethingWentWrong = 'Please try after some time';
const String pleaseCheckYourInternetConnectivityAndTryAgain =
    'Please check your internet connectivity and try again';
const String reLogin = 'Re Login';

errorToast(String errorText, {isShortDurationText = false}) {
  Fluttertoast.showToast(
    msg: errorText,
    toastLength: isShortDurationText ? Toast.LENGTH_SHORT : Toast.LENGTH_LONG,
    gravity: ToastGravity.BOTTOM,
    backgroundColor: Colors.red.shade300,
    textColor: Colors.white,
    fontSize: 14,
  );
}

Future<bool> checkIsConnectedToInternet() async {
  var connectivityResult = await Connectivity().checkConnectivity();
  print(connectivityResult);
  if (connectivityResult == ConnectivityResult.mobile) {
    return true;
  } else if (connectivityResult == ConnectivityResult.wifi) {
    return true;
  } else {
    return true;
  }
}

successToast(String successText, BuildContext context,
    {isShortDurationText = false}) {
  Fluttertoast.showToast(
    msg: successText,
    toastLength: isShortDurationText ? Toast.LENGTH_SHORT : Toast.LENGTH_LONG,
    gravity: ToastGravity.BOTTOM,
    backgroundColor: Colors.white,
    textColor: Colors.black,
    fontSize: 14,
  );
}

notificationToast(String successText,
    {isShortDurationText = false}) {
  Fluttertoast.showToast(
    msg: successText,
    toastLength: isShortDurationText ? Toast.LENGTH_SHORT : Toast.LENGTH_LONG,
    gravity: ToastGravity.TOP,
    backgroundColor: Colors.white,
    textColor: Colors.black,
    fontSize: 14,
  );
}
