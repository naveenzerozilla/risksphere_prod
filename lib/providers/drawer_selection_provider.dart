import 'package:flutter/material.dart';

class DrawerSelectionProvider extends ChangeNotifier {
  String _selectedItem = "dashboard"; // Default selection

  String get selectedItem => _selectedItem;

  void setSelectedItem(String item) {
    _selectedItem = item;
    notifyListeners();
  }
}
