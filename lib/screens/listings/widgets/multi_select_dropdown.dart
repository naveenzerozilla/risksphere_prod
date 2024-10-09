import 'package:flutter/material.dart';

import '../../../design_system/primitives/custom_typography.dart';

class MultiSelectDropdown extends StatefulWidget {
  final List<String> items;
  final List<String> selectedItems;
  final ValueChanged<List<String>> onChanged;

  const MultiSelectDropdown({
    Key? key,
    required this.items,
    required this.selectedItems,
    required this.onChanged,
  }) : super(key: key);

  @override
  _MultiSelectDropdownState createState() => _MultiSelectDropdownState();
}

class _MultiSelectDropdownState extends State<MultiSelectDropdown> {
  late List<String> _selectedItems;

  @override
  void initState() {
    super.initState();
    _selectedItems = List.from(widget.selectedItems);
  }

  void _handleItemChange(bool? isSelected, String item) {
    setState(() {
      if (isSelected != null && isSelected) {
        _selectedItems.add(item);
      } else {
        _selectedItems.remove(item);
      }
      widget.onChanged(_selectedItems);
    });
  }

  @override
  Widget build(BuildContext context) {
    var typography = CustomTypography(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8.0),
        // Custom dropdown to select items
        InputDecorator(
          decoration: InputDecoration(
            labelText: 'Campus Ids',
            labelStyle: typography.Body1,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: null,
              hint: Text('Select options', style: typography.Body1),
              onChanged: (_) {},
              items: widget.items.map((item) {
                return DropdownMenuItem<String>(
                  value: item,
                  child:  ListTile(
                    title: Text(item),
                    trailing: _selectedItems.contains(item)
                        ? Icon(Icons.check, color: Theme.of(context).primaryColor)
                        : null,
                    onTap: () {
                      bool isSelected = _selectedItems.contains(item);
                      _handleItemChange(!isSelected, item);
                    },
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
}