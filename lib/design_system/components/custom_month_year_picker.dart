import 'package:flutter/cupertino.dart';

Future<DateTime?> showMonthYearPicker(
    BuildContext context,
    DateTime initialDate,
    DateTime firstDate,
    DateTime lastDate,
    ) {
  return showCupertinoModalPopup<DateTime>(
    context: context,
    builder: (context) {
      return Container(
        height: 250,
        color: CupertinoColors.systemBackground,
        child: Column(
          children: [
            SizedBox(height: 20),
            CupertinoButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            SizedBox(height: 20),
            CupertinoDatePicker(
              mode: CupertinoDatePickerMode.date,
              initialDateTime: initialDate,
              onDateTimeChanged: (DateTime newDate) {
                initialDate = DateTime(newDate.year, newDate.month, 1);
              },
              minimumYear: firstDate.year,
              maximumYear: lastDate.year,
            ),
            SizedBox(height: 20),
            CupertinoButton(
              onPressed: () => Navigator.pop(context, initialDate),
              child: Text('OK'),
            ),
          ],
        ),
      );
    },
  );
}