import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class LocationPickerScreen extends StatefulWidget {
  final LatLng? initialLocation;

  const LocationPickerScreen({super.key, this.initialLocation});

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  GoogleMapController? _mapController;

  static const LatLng _darEsSalaam = LatLng(-6.7924, 39.2083);

  late LatLng _selectedLocation;

  bool _loadingLocation = false;

  @override
  void initState() {
    super.initState();

    _selectedLocation = widget.initialLocation ?? _darEsSalaam;
  }

  Future<bool> _checkLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      if (!mounted) return false;

      await showDialog(
        context: context,
        builder: (_) {
          return AlertDialog(
            title: const Text('Location is disabled'),
            content: const Text(
              'Please enable location services on your device.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          );
        },
      );

      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      if (!mounted) return false;

      await showDialog(
        context: context,
        builder: (_) {
          return AlertDialog(
            title: const Text('Location permission required'),
            content: const Text(
              'Location permission is required to automatically '
              'get your current location.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          );
        },
      );

      return false;
    }

    return true;
  }

  Future<void> _useCurrentLocation() async {
    setState(() {
      _loadingLocation = true;
    });

    try {
      final allowed = await _checkLocationPermission();

      if (!allowed) return;

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      final location = LatLng(position.latitude, position.longitude);

      setState(() {
        _selectedLocation = location;
      });

      await _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: location, zoom: 17),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to get current location: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _loadingLocation = false;
        });
      }
    }
  }

  void _selectLocation(LatLng location) {
    setState(() {
      _selectedLocation = location;
    });
  }

  void _confirmLocation() {
    Navigator.pop(context, _selectedLocation);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select Location'), elevation: 0),

      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _selectedLocation,
              zoom: 14,
            ),

            myLocationEnabled: false,
            myLocationButtonEnabled: false,

            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            compassEnabled: true,

            mapType: MapType.normal,

            markers: {
              Marker(
                markerId: const MarkerId('selected_location'),

                position: _selectedLocation,

                draggable: true,

                infoWindow: const InfoWindow(
                  title: 'Producer location',
                  snippet: 'Tap or drag to change location',
                ),

                onDragEnd: _selectLocation,
              ),
            },

            onMapCreated: (controller) {
              _mapController = controller;
            },

            onTap: _selectLocation,
          ),

          // Top instruction
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.location_on,
                        color: Colors.green.shade700,
                      ),
                    ),

                    const SizedBox(width: 12),

                    const Expanded(
                      child: Text(
                        'Tap on the map to select the producer location. '
                        'You can also drag the marker.',
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Current location button
          Positioned(
            right: 16,
            bottom: 190,
            child: FloatingActionButton(
              heroTag: 'current_location',

              onPressed: _loadingLocation ? null : _useCurrentLocation,

              child: _loadingLocation
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.my_location),
            ),
          ),

          // Bottom location card
          Positioned(
            left: 12,
            right: 12,
            bottom: 12,
            child: SafeArea(
              child: Card(
                elevation: 8,
                margin: EdgeInsets.zero,

                child: Padding(
                  padding: const EdgeInsets.all(16),

                  child: Column(
                    mainAxisSize: MainAxisSize.min,

                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [
                      const Text(
                        'Selected coordinates',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 8),

                      Row(
                        children: [
                          Expanded(
                            child: _CoordinateItem(
                              label: 'Latitude',
                              value: _selectedLocation.latitude.toStringAsFixed(
                                6,
                              ),
                            ),
                          ),

                          const SizedBox(width: 16),

                          Expanded(
                            child: _CoordinateItem(
                              label: 'Longitude',
                              value: _selectedLocation.longitude
                                  .toStringAsFixed(6),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      SizedBox(
                        width: double.infinity,

                        child: ElevatedButton.icon(
                          onPressed: _confirmLocation,

                          icon: const Icon(Icons.check),

                          label: const Text('Confirm Location'),

                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CoordinateItem extends StatelessWidget {
  final String label;
  final String value;

  const _CoordinateItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ],
    );
  }
}
