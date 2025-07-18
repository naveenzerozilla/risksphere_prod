import 'package:flutter/material.dart';

class ReadMoreText extends StatefulWidget {
  final String text;
  final int trimLines;
  final TextStyle? style;
  final String trimCollapsedText;
  final String trimExpandedText;
  final Color colorClickableText;

  const ReadMoreText({
    required this.text,
    this.trimLines = 5,
    this.style,
    this.trimCollapsedText = 'Read more',
    this.trimExpandedText = 'Show less',
    this.colorClickableText = Colors.blueAccent,
    Key? key,
  }) : super(key: key);

  @override
  _ReadMoreTextState createState() => _ReadMoreTextState();
}

class _ReadMoreTextState extends State<ReadMoreText> {
  bool isExpanded = false;
  bool canExpand = false;
  late String fullText;

  final GlobalKey _textKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    fullText = widget.text;
    // Delay to calculate text layout
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final renderBox =
          _textKey.currentContext?.findRenderObject() as RenderBox?;
      if (renderBox != null && renderBox.size.height > widget.trimLines * 20) {
        setState(() {
          canExpand = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          fullText,
          key: _textKey,
          maxLines: isExpanded ? null : widget.trimLines,
          overflow: isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
          style: widget.style,
        ),
        if (canExpand)
          GestureDetector(
            onTap: () {
              setState(() {
                isExpanded = !isExpanded;
              });
            },
            child: Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                isExpanded ? widget.trimExpandedText : widget.trimCollapsedText,
                style: TextStyle(
                  color: widget.colorClickableText,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          )
      ],
    );
  }
}
