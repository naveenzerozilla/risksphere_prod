import 'package:flutter/material.dart';

import '../../../design_system/primitives/app_colors.dart';
import '../../../design_system/primitives/custom_typography.dart';

class AnimatedProgressIndicator extends StatefulWidget {
  final String percent;

  AnimatedProgressIndicator({required this.percent});

  @override
  _AnimatedProgressIndicatorState createState() => _AnimatedProgressIndicatorState();
}

class _AnimatedProgressIndicatorState extends State<AnimatedProgressIndicator> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _animation = Tween<double>(begin: 0, end: (double.tryParse(widget.percent) ?? 0.0) / 100).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _controller.forward();
  }

  @override
  void didUpdateWidget(AnimatedProgressIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.percent != widget.percent) {
      _animation = Tween<double>(begin: 0, end: (double.tryParse(widget.percent) ?? 0.0) / 100).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
      );
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var typography = CustomTypography(context);
    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          height: 47,
          width: 47,
          child: AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return CircularProgressIndicator(
                value: _animation.value,
                backgroundColor: Color(0x12FFFFFF),
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryMain),
                strokeWidth: 4,
              );
            },
          ),
        ),
        Text(
          widget.percent + "%",
          style: typography.Subtitle2.copyWith(
            color: AppColors.primaryMain,
            fontSize: 9,
          ),
        ),
      ],
    );
  }
}
