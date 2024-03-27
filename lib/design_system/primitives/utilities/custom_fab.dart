import 'package:flutter/material.dart';

class CustomFAB extends StatelessWidget {
  final VoidCallback onPressed;
  final IconData icon;

  const CustomFAB({
    Key? key,
    required this.onPressed,
    required this.icon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: onPressed,
      backgroundColor: Theme.of(context).primaryColor, // Use primary color from theme
      elevation: 4,
      child: Icon(
        icon,
        color: Colors.white,
      ),
    );
  }
}
