import 'package:flutter/material.dart';

class CustomDialogs {
  static Future<void> showSimpleDialog({
    required BuildContext context,
    required String title,
    required String content,
    required String confirmText,
    String cancelText = 'Cancel',
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
  }) {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                if (onCancel != null) onCancel();
                Navigator.of(context).pop();
              },
              child: Text(cancelText),
            ),
            TextButton(
              onPressed: () {
                if (onConfirm != null) onConfirm();
                Navigator.of(context).pop();
              },
              child: Text(confirmText),
            ),
          ],
        );
      },
    );
  }

  static Future<void> showIconDialog({
    required BuildContext context,
    required String title,
    required String content,
    required String confirmText,
    IconData? icon,
    String cancelText = 'Cancel',
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
  }) {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: <Widget>[
              if (icon != null) Icon(icon),
              SizedBox(width: icon != null ? 8.0 : 0),
              Text(title),
            ],
          ),
          content: Text(content),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                if (onCancel != null) onCancel();
                Navigator.of(context).pop();
              },
              child: Text(cancelText),
            ),
            TextButton(
              onPressed: () {
                if (onConfirm != null) onConfirm();
                Navigator.of(context).pop();
              },
              child: Text(confirmText),
            ),
          ],
        );
      },
    );
  }

  static Future<void> showListDialog({
    required BuildContext context,
    required String title,
    required List<String> items,
    required String confirmText,
    String cancelText = 'Cancel',
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
  }) {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: items
                .map(
                  (item) => ListTile(
                title: Text(item),
                onTap: () {
                  if (onConfirm != null) onConfirm();
                  Navigator.of(context).pop();
                },
              ),
            )
                .toList(),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                if (onCancel != null) onCancel();
                Navigator.of(context).pop();
              },
              child: Text(cancelText),
            ),
          ],
        );
      },
    );
  }

  static Future<void> showCheckboxListDialog({
    required BuildContext context,
    required String title,
    required List<String> items,
    required List<bool> checkedItems,
    required String confirmText,
    String cancelText = 'Cancel',
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
    ValueChanged<List<bool>>? onChanged,
  }) {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(items.length, (index) {
              return CheckboxListTile(
                title: Text(items[index]),
                value: checkedItems[index]??false,
                onChanged: onChanged != null
                    ? (value) {
                  onChanged([...checkedItems..[index] = value??false]);
                }
                    : null,
              );
            }),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                if (onCancel != null) onCancel();
                Navigator.of(context).pop();
              },
              child: Text(cancelText),
            ),
            TextButton(
              onPressed: () {
                if (onConfirm != null) onConfirm();
                Navigator.of(context).pop();
              },
              child: Text(confirmText),
            ),
          ],
        );
      },
    );
  }

}
