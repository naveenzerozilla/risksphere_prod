import 'package:flutter/material.dart';

class ReadMoreText extends StatefulWidget {
  final String text;
  final TextStyle? style;

  const ReadMoreText({
    required this.text,
    this.style,
    Key? key,
  }) : super(key: key);

  @override
  State<ReadMoreText> createState() => _ReadMoreTextState();
}

class _ReadMoreTextState extends State<ReadMoreText> {
  @override
  Widget build(BuildContext context) {
    final List<String> points =
        widget.text.split('\n').where((e) => e.trim().isNotEmpty).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: points.map((point) {
        final cleanedPoint = point.replaceAll('•', '').trim();

        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 2),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: Colors.grey[700],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check,
                  color: Colors.green.shade400,
                  size: 18,
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: Text(
                  cleanedPoint,
                  style: widget.style ??
                      const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        height: 1.5,
                      ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}