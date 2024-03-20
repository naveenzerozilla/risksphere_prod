import 'package:flutter/material.dart';

class CustomCheckBox extends StatefulWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;
  final Widget label;
  final double size;

  const CustomCheckBox({
    Key? key,
    required this.value,
    required this.onChanged,
    required this.label,
    this.size = 24.0,
  }) : super(key: key);

  @override
  CustomCheckBoxState createState() => CustomCheckBoxState();
}

class CustomCheckBoxState extends State<CustomCheckBox> {
  late bool _value;

  @override
  void initState() {
    super.initState();
    _value = widget.value;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      onTap: () {
        setState(() {
          _value = !_value;
          widget.onChanged?.call(_value);
        });
      },
      child: Row(
        children: [
          Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              color: _value ? colorScheme.primary : Colors.transparent,
              border: Border.all(
                color: _value ? colorScheme.primary : colorScheme.onSurface.withOpacity(0.5),
                width: 2.0,
              ),
              borderRadius: BorderRadius.circular(4.0),
            ),
            child: _value
                ? Icon(
              Icons.check,
              color: colorScheme.onPrimary,
              size: widget.size * 0.6,
            )
                : const SizedBox(),
          ),
          const SizedBox(width: 8.0),
          widget.label,
        ],
      ),
    );
  }
}
