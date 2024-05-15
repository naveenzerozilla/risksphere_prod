import 'package:flutter/material.dart';

class ExpandableCardContainer extends StatefulWidget {
  final bool isExpanded;
  final Widget collapsedChild;
  final Widget expandedChild;

  const ExpandableCardContainer(
      {Key? key, required this.isExpanded, required this.collapsedChild, required this.expandedChild})
      : super(key: key);

  @override
  ExpandableCardContainerState createState() =>
      ExpandableCardContainerState();
}

class ExpandableCardContainerState extends State<ExpandableCardContainer> {
  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      child: widget.isExpanded ? widget.expandedChild : widget.collapsedChild,
    );
  }
}