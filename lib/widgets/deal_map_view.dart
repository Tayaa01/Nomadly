import 'package:flutter/material.dart';
import '../services/deals_service.dart';

class DealMapView extends StatelessWidget {
  final List<Deal> deals;
  final String country;

  const DealMapView({super.key, required this.deals, required this.country});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.map_outlined, size: 64, color: Colors.grey[600]),
          const SizedBox(height: 16),
          Text(
            'Map view is not available in this version',
            style: TextStyle(color: Colors.grey[400], fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Please use the list view to see deals',
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
