import 'package:flutter/material.dart';

class StaticDropdownExample extends StatefulWidget {
  @override
  _StaticDropdownExampleState createState() => _StaticDropdownExampleState();
}

class _StaticDropdownExampleState extends State<StaticDropdownExample> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  List<String> allOptions = [
    'Bangalore',
    'Chennai',
    'Delhi',
    'Hyderabad',
    'Mumbai',
    'Pune',
    'Kolkata',
  ];
  final GlobalKey _fieldKey = GlobalKey();
  List<String> filteredOptions = [];
  OverlayEntry? _overlayEntry;

  final LayerLink _layerLink = LayerLink();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        _filterOptions(_controller.text);
        _showOverlay();
      } else {
        _removeOverlay();
      }
    });
  }

  void _filterOptions(String input) {
    filteredOptions = allOptions
        .where((item) => item.toLowerCase().contains(input.toLowerCase()))
        .toList();

    _overlayEntry?.markNeedsBuild();
  }

  void _showOverlay() {
    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  OverlayEntry _createOverlayEntry() {
    RenderBox renderBox = _fieldKey.currentContext!.findRenderObject() as RenderBox;
    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);

    return OverlayEntry(
      builder: (context) {
        return Positioned(
          left: offset.dx,
          top: offset.dy + size.height,
          width: size.width,
          child: Material(
            elevation: 4.0,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: 200),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: filteredOptions.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(filteredOptions[index]),
                    onTap: () {
                      _controller.text = filteredOptions[index];
                      _focusNode.unfocus();
                    },
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _removeOverlay();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(title: Text("Static Dropdown Example")),
      body: ListView(
        children: [
          SizedBox(height: 400),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: CompositedTransformTarget(
              link: _layerLink,
              child: TextFormField(
                controller: _controller,
                focusNode: _focusNode,
                decoration: InputDecoration(
                  labelText: 'Enter location',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  _filterOptions(value);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
