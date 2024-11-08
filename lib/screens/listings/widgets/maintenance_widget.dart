import 'package:flutter/material.dart';
import 'package:green/design_system/primitives/utilities/custom_spacing.dart';

class MaintenanceUI extends StatefulWidget {
  final bool isMaintenance;

  const MaintenanceUI({super.key, required this.isMaintenance});

  @override
  MaintenanceUIState createState() => MaintenanceUIState();
}

class MaintenanceUIState extends State<MaintenanceUI>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _animation;
  final String text = "Maintenance in Progress ";

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    );

    _animation = Tween<Offset>(
      begin: const Offset(-2, 0), // Start from left of the screen
      end: const Offset(2, 0),    // Move to right of the screen
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.linear,
    ));

    // Repeat the animation indefinitely
    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isMaintenance) {
      return const SizedBox();
    }

    return Column(
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.redAccent, width: 2),
          ),
          clipBehavior: Clip.hardEdge, // Add this to clip overflow
          child: SlideTransition(
            position: _animation,
            child: Row(
              children: [
                ...List.generate(
                  1, // Repeat the text 3 times to ensure continuous flow
                      (_) => Row(
                    children: text.characters.map((char) => Text(
                      char,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Colors.redAccent,
                      ),
                    )).toList(),
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: CustomSpacing.four),
      ],
    );
  }
}