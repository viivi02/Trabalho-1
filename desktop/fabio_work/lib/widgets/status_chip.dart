import 'package:flutter/material.dart';

class StatusChip extends StatelessWidget {
  final String status;

  const StatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withAlpha(30),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _color.withAlpha(120)),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: _color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Color get _color {
    switch (status.toLowerCase()) {
      case 'created':
        return Colors.blue;
      case 'paid':
      case 'confirmed':
        return Colors.green;
      case 'shipped':
      case 'separated':
        return Colors.orange;
      case 'delivered':
        return Colors.teal;
      case 'canceled':
      case 'cancelled':
        return Colors.red;
      case 'pending':
        return Colors.amber.shade800;
      default:
        return Colors.grey;
    }
  }
}
