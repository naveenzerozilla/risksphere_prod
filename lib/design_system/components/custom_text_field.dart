import 'package:flutter/material.dart';

class CustomTextField extends StatefulWidget {
  final String labelText;
  final String hintText;
  final TextStyle labelStyle;
  final TextStyle hintStyle;
  final TextEditingController controller;
  final EdgeInsets padding;
  final bool obscureText; // New parameter for obscuring text

  const CustomTextField({
    Key? key,
    required this.labelText,
    required this.hintText,
    required this.labelStyle,
    required this.hintStyle,
    required this.controller,
    this.padding = const EdgeInsets.all(8.0),
    this.obscureText = false, // Default value is false
  }) : super(key: key);

  @override
  CustomTextFieldState createState() => CustomTextFieldState();
}

class CustomTextFieldState extends State<CustomTextField> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: widget.padding,
      child: TextField(
        controller: widget.controller,
        obscureText: widget.obscureText, // Pass the obscureText parameter to TextField
        decoration: InputDecoration(
          labelText: widget.labelText,
          labelStyle: widget.labelStyle,
          hintText: widget.hintText,
          hintStyle: widget.hintStyle,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}
