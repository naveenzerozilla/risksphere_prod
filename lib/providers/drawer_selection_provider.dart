import 'package:flutter/material.dart';

class DrawerSelectionProvider extends ChangeNotifier {
  String _selectedItem = "dashboard";
  bool _isLoading = false;

  String get selectedItem => _selectedItem;
  bool get isLoading => _isLoading;

  void setSelectedItem(String item) {
    _selectedItem = item;
    notifyListeners();
  }

  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}

