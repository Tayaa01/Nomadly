import 'package:flutter/material.dart';
<<<<<<< HEAD
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
=======
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/deals_service.dart';

class DealMapView extends StatefulWidget {
  final List<Deal> deals;
  final String country;

  const DealMapView({Key? key, required this.deals, required this.country})
    : super(key: key);

  @override
  State<DealMapView> createState() => _DealMapViewState();
}

class _DealMapViewState extends State<DealMapView> {
  late final MapController _mapController;
  Position? _currentPosition;
  Deal? _selectedDeal;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _getCurrentLocation();
    });
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        final result = await Geolocator.requestPermission();
        if (result == LocationPermission.denied) return;
      }

      if (!mounted) return;

      final position = await Geolocator.getCurrentPosition();
      setState(() => _currentPosition = position);

      // Center map on first deal with valid coordinates or current location
      final validDeals =
          widget.deals
              .where(
                (deal) =>
                    deal.hasValidCoordinates &&
                    deal.location.coordinates!.latitude != null &&
                    deal.location.coordinates!.longitude != null,
              )
              .toList();

      if (validDeals.isNotEmpty) {
        final firstDeal = validDeals.first;
        _mapController.move(
          LatLng(
            firstDeal.location.coordinates!.latitude!,
            firstDeal.location.coordinates!.longitude!,
          ),
          13,
        );
      } else if (_currentPosition != null) {
        _mapController.move(
          LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          13,
        );
      }
    } catch (e) {
      debugPrint('Error getting location: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final validDeals =
        widget.deals
            .where(
              (deal) =>
                  deal.hasValidCoordinates &&
                  deal.location.coordinates!.latitude != null &&
                  deal.location.coordinates!.longitude != null,
            )
            .toList();

    if (validDeals.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_off, size: 64, color: Colors.grey[600]),
            const SizedBox(height: 16),
            Text(
              'No location data available for deals in ${widget.country}',
              style: TextStyle(color: Colors.grey[400], fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Try searching for deals in a different category or location',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    final initialCenter =
        validDeals.isNotEmpty
            ? LatLng(
              validDeals.first.location.coordinates!.latitude!,
              validDeals.first.location.coordinates!.longitude!,
            )
            : const LatLng(48.8566, 2.3522); // Paris coordinates as default

    return Column(
      children: [
        Expanded(
          child: FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: initialCenter,
              initialZoom: 13,
              onTap: (_, __) => setState(() => _selectedDeal = null),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.nomadly.app',
                maxZoom: 19,
              ),
              MarkerLayer(
                markers: [
                  if (_currentPosition != null)
                    Marker(
                      point: LatLng(
                        _currentPosition!.latitude,
                        _currentPosition!.longitude,
                      ),
                      width: 30,
                      height: 30,
                      child: const Icon(Icons.my_location, color: Colors.blue),
                    ),
                  ...validDeals.map((deal) => _buildDealMarker(deal)),
                ],
              ),
            ],
          ),
        ),
        if (_selectedDeal != null) _buildDealCard(_selectedDeal!),
      ],
    );
  }

  Marker _buildDealMarker(Deal deal) {
    final isSelected = deal == _selectedDeal;
    return Marker(
      point: LatLng(
        deal.location.coordinates!.latitude!,
        deal.location.coordinates!.longitude!,
      ),
      width: isSelected ? 40 : 30,
      height: isSelected ? 40 : 30,
      child: GestureDetector(
        onTap: () => setState(() => _selectedDeal = deal),
        child: Container(
          decoration: BoxDecoration(
            color: isSelected ? Colors.green : Colors.red,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Icon(
            Icons.local_offer,
            color: Colors.white,
            size: isSelected ? 24 : 20,
          ),
        ),
      ),
    );
  }

  Widget _buildDealCard(Deal deal) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  deal.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (deal.metadata.verified)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.verified, color: Colors.green, size: 16),
                      SizedBox(width: 4),
                      Text(
                        'Verified',
                        style: TextStyle(color: Colors.green, fontSize: 12),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            deal.description,
            style: TextStyle(color: Colors.grey[400], fontSize: 14),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.location_on, color: Colors.grey[400], size: 16),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  '${deal.location.address ?? ''}, ${deal.location.city ?? ''}, ${deal.location.country}',
                  style: TextStyle(color: Colors.grey[400], fontSize: 14),
                ),
              ),
            ],
          ),
          if (deal.dealDetails.discountPercentage != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.local_offer, color: Colors.grey[400], size: 16),
                const SizedBox(width: 4),
                Text(
                  '${deal.dealDetails.discountPercentage}% OFF',
                  style: const TextStyle(
                    color: Colors.green,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _launchDealUrl(deal.url),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('View Deal'),
            ),
>>>>>>> aziz
          ),
        ],
      ),
    );
  }
<<<<<<< HEAD
=======

  Future<void> _launchDealUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
>>>>>>> aziz
}
