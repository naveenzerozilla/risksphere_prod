import 'package:flutter/material.dart';

class RatingSlider extends StatefulWidget {
  final int progress;
  final int total;
  final Color thumbColor;
  final Color progressColor;
  final double progressHeight;
  final Color textColor;
  final double width;
  final bool isDisabled;

  const RatingSlider({
    Key? key,
    required this.progress,
    required this.total,
    this.thumbColor = Colors.blue,
    this.progressColor = Colors.blue,
    this.progressHeight = 8.0,
    this.textColor = Colors.black,
    this.width = 250.0,
    this.isDisabled = false,
  }) : super(key: key);

  @override
  _RatingSliderState createState() => _RatingSliderState();
}

class _RatingSliderState extends State<RatingSlider> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    print("Rating: ${widget.progress} / ${widget.total}");
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _animation = Tween<double>(begin: 0, end: widget.progress / widget.total).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    if (!widget.isDisabled) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(RatingSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.progress != widget.progress || oldWidget.total != widget.total) {
      _animation = Tween<double>(begin: 0, end: widget.progress / widget.total).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
      );
      if (!widget.isDisabled) {
        _controller.forward(from: 0.0);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Container(
            height: widget.progressHeight,
            width: widget.width,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
              borderRadius: BorderRadius.circular(5),
            ),
          ),
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  height: widget.progressHeight,
                  width: widget.isDisabled ? widget.width * (widget.progress / widget.total) : widget.width * _animation.value,
                  decoration: BoxDecoration(
                    color: widget.isDisabled ?
                    Theme.of(context).colorScheme.onSurface.withOpacity(0.1)
                        : widget.progressColor,
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
              );
            },
          ),
          Center(
            child: Container(
              height: 30,
              width: 30,
              decoration: BoxDecoration(
                color: widget.isDisabled ? Colors.grey : widget.thumbColor,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '${widget.progress}/${widget.total}',
                  style: TextStyle(color: widget.textColor, fontSize: 12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
