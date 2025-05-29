import 'package:flutter/material.dart';

class CustomInfoWindowWidget extends StatelessWidget {
  final String title;
  final String address;
  final bool isAdded;
  final VoidCallback onAddToSOV;
  final VoidCallback onRemoveFromSOV;

  const CustomInfoWindowWidget({
    Key? key,
    required this.title,
    required this.address,
    required this.isAdded,
    required this.onAddToSOV,
    required this.onRemoveFromSOV,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.8),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 4),
          Text(
            address,
            style: TextStyle(color: Colors.white),
          ),
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (isAdded)
                ElevatedButton.icon(
                  onPressed: onRemoveFromSOV,
                  icon: Icon(Icons.delete, color: Colors.red),
                  label: Text('Remove', style: TextStyle(color: Colors.red)),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
                ),
              ElevatedButton.icon(
                onPressed: onAddToSOV,
                icon: Icon(Icons.add, color: Colors.blue),
                label: Text('Add to SOV', style: TextStyle(color: Colors.blue)),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
