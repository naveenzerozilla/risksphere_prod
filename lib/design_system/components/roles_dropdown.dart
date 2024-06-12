import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

import '../primitives/custom_typography.dart';

class RolesDropdown extends StatefulWidget {
  @override
  _RolesDropdownState createState() => _RolesDropdownState();
}

class _RolesDropdownState extends State<RolesDropdown> {
  String? _selectedItem;
  List<String> _items = ['Risk Manager', 'Insurers', 'CAT Modeler'];

  @override
  Widget build(BuildContext context) {
    return Container(
     /* padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey), // Outline border color
        borderRadius: BorderRadius.circular(8), // Rounded corners
      ),*/
      child: Row(
        children: [
          DropdownButton<String>(
            underline: SizedBox(),
            value: _selectedItem,
            isDense: false,
            items: _items.map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value, style: CustomTypography.Body2),
              );
            }).toList(),
            onChanged: (String? value) {
              setState(() {
                _selectedItem = value;
              });
            },
            hint: Row(
              children: [
                Icon(Icons.switch_account),
                SizedBox(width: 8),
                Text('Risk Manager', style: CustomTypography.Body2),
              ],
            ),
            icon: Icon(Icons.arrow_drop_down),
          ),
        ],
      ),
    );
  }
}
