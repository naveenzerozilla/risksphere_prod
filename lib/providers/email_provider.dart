import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:RiskSphere/models/email_model.dart';
// Import for JSON encoding/decoding
// Import for logging

import '../design_system/components/custom_toast.dart';
import '../models/all_email_model.dart';
import '../service/api_service.dart';
import '../utils/api_constants.dart';

class EmailProvider with ChangeNotifier {


  bool _isLoading = false;
  bool get isLoading => _isLoading;
  set isLoading(bool value) {
    _isLoading = value;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  bool _isUpdateLoading = false;
  bool get isUpdateLoading => _isUpdateLoading;
  set isUpdateLoading(bool value) {
    _isUpdateLoading = value;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  Email _email = Email();
  Email get email => _email;
  set email(Email value) {
    _email = value;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  List<Emails> _allEmails = [];
  List<Emails> get allEmails => _allEmails;
  set allEmail(List<Emails> value) {
    _allEmails = value;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }


  /// Fetches all email info from the API.
  Future<List<Emails>> getAllEmails(BuildContext context) async {
    try {
      // Set loading state to true
      isLoading = true;
      // Use API Service to fetch email
      ApiService apiService = ApiService(AppConstant.GET_EMAILS);

      // Send a GET request to the API
      Map<String, dynamic> response = await apiService.get();

// Parse the response into an AllEmailModel
      AllEmailModel allEmailModel = AllEmailModel.fromJson(response);
      _allEmails = allEmailModel.emails??[];
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });


      isLoading = false;
      return allEmailModel.emails??[];
    } catch (e, stackTrace) {
      // Catch any errors that occur during the process
      print('Stack Trace: $stackTrace'); // Print the stack trace for debugging
      log('Error: $e'); // Log the error
      // Show a generic error message to the user
      // TODO: Display a generic error message to the user

      isLoading = false;
      if (!context.mounted) return []; // Return an empty Email object in case of error
      CustomToast.error(context, 'Error fetching email. Please try again later.');
      return []; // Return an empty Email object in case of error
    }
  }

  /// Fetches all email info from the API.
  Future<Email> getEmailByType(BuildContext context, String type) async {
    try {
      // Set loading state to true
      isLoading = true;
      // Use API Service to fetch email
      ApiService apiService = ApiService(AppConstant.GET_EMAILS);

      // Send a GET request to the API
      Map<String, dynamic> response = await apiService.get("&email_type=$type");

      // Parse the response into an EmailModel
      EmailModel emailModel = EmailModel.fromJson(response);

      // Extract email from the EmailModel
      Email email = emailModel.email!;

      // Update the email and notify listeners
      this.email = email;
      isLoading = false;
      return email;
    } catch (e, stackTrace) {
      // Catch any errors that occur during the process
      print('Stack Trace: $stackTrace'); // Print the stack trace for debugging
      log('Error: $e'); // Log the error
      // Show a generic error message to the user
      // TODO: Display a generic error message to the user

      isLoading = false;
      if (!context.mounted) return Email(); // Return an empty Email object in case of error
      CustomToast.error(context, 'Error fetching email. Please try again later.');
      return Email(); // Return an empty Email object in case of error
    }
  }

  /// Updates the email info in the API.
  /*
  {
    "data":{
        "email_type":"notification",
        "email":"dummymymm@f.com",
        "password":"1234567",
        "port":2343,
        "host":"h.stmp.com"
    }
}
  * */
  Future<bool> updateEmail(BuildContext context, Map<String, dynamic> body) async {
    try {
      // Set loading state to true
      isUpdateLoading = true;
      // Use API Service to update email
      ApiService apiService = ApiService(AppConstant.ADD_EMAILS);

      // Send a POST request to the API
      Map<String, dynamic> response = await apiService.patch(body);
      String message = response['message'];
      // Show a success message to the user
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(message),
      ));

      getAllEmails(context);

      isUpdateLoading = false;
      return true;
    } catch (e, stackTrace) {
      // Catch any errors that occur during the process
      print('Stack Trace: $stackTrace'); // Print the stack trace for debugging
      log('Error: $e'); // Log the error
      // Show a generic error message to the user
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error updating email. Please try again later.'),
      ));
      isUpdateLoading = false;
      return false; // Return false in case of error
    }
  }

  /// Creates a new email info in the API.
  Future<bool> createEmail(BuildContext context, Map<String, dynamic> body) async {
    try {
      // Set loading state to true
      isUpdateLoading = true;
      // Use API Service to update email
      ApiService apiService = ApiService(AppConstant.ADD_EMAILS);

      // Send a POST request to the API
      Map<String, dynamic> response = await apiService.post(body);
      String message = response['message'];
      // Show a success message to the user
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(message),
      ));

      getAllEmails(context);

      isUpdateLoading = false;
      return true;
    } catch (e, stackTrace) {
      // Catch any errors that occur during the process
      print('Stack Trace: $stackTrace'); // Print the stack trace for debugging
      log('Error: $e'); // Log the error
      // Show a generic error message to the user
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error updating email. Please try again later.'),
      ));
      isUpdateLoading = false;
      return false; // Return false in case of error
    }
  }


}