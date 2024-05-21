import 'package:flutter/material.dart';

enum ButtonType {
  elevated,
  outlined,
  text,
  filled,
  tonal,
}

enum Screens {
  defaultScreen,
  corporateList,
  corporateAdd,
  corporateEdit,
  corporateEmployeeList,
  corporateEmployeeAdd,
  employeeList,
  employeeAdd,
  employeeEdit,
  nonCorporateList,
  connectionList,
  requestList,
  chatList,
  networkList,
  blockedList,
  //////////
  featureList,
  addFeature,
  emailSetup,
  roleList,
  roleAdd,
  verificationList,
  //////////
  corporateConnectionList,
  nonCorporateConnectionList, corporateEmployeeEdit, nonCorporateEdit,
  corporateProfile,
}

enum EmailOptions {
  notifications,
  helpDesk,
  admin,
  contactUs
}


const String ThemeModeKey = 'theme_mode';