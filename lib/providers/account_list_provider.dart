import 'package:flutter/material.dart';
import 'package:green/models/account_list_model.dart';

class AccountListProvider extends ChangeNotifier {

  bool _isLoading = false;
  bool get isLoading => _isLoading;
  set isLoading(bool value) {
    _isLoading = value;
    WidgetsBinding.instance!.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  List<Accounts> _accountList = [];
  List<Accounts> get accountList => _accountList;
  set accountList(List<Accounts> value) {
    _accountList = value;
    WidgetsBinding.instance!.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  void addDummyData() {
    accountList = [
      Accounts(
        name: 'JP Morgan & Chase',
        displayName: 'JP Morgan & Chase',
        id: '1',
        locationCount: 110,
        overAllScore: '60',
      ),
      Accounts(
        name: 'Pizza Hut',
        displayName: 'Pizza Hut',
        id: '2',
        locationCount: 210,
        overAllScore: '100',
      ),
      Accounts(
        name: 'McDonalds',
        displayName: 'McDonalds',
        id: '3',
        locationCount: 310,
        overAllScore: '20',
      ),
    ];
  }
}
