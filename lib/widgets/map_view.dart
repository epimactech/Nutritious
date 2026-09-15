import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../models/producer.dart';

class MapView extends StatefulWidget {
  final List<Producer> producers;
  final Producer? selectedProducer;
  final ValueChanged<Producer> onProducerSelected;

  const MapView({
    super.key,
    required this.producers,
    required this.selectedProducer,
    required this.onProducerSelected,
  });

  @override
  State<MapView> createState() => _MapViewState();
}

class _MapViewState extends State<MapView> {
  GoogleMapController? _controller;

  static const LatLng _darEsSalaam = LatLng(-6.7924, 39.2083);

  @override
  Widget build(BuildContext context) {
    final markers = widget.producers.map((producer) {
      final selected = widget.selectedProducer?.id == producer.id;

      return Marker(
        markerId: MarkerId(producer.id),
        position: LatLng(producer.latitude, producer.longitude),
        infoWindow: InfoWindow(
          title: producer.name,
          snippet:
              '${producer.category} • ★ ${producer.rating.toStringAsFixed(1)}',
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          selected ? BitmapDescriptor.hueOrange : BitmapDescriptor.hueGreen,
        ),
        onTap: () {
          widget.onProducerSelected(producer);
        },
      );
    }).toSet();

    return GoogleMap(
      initialCameraPosition: const CameraPosition(
        target: _darEsSalaam,
        zoom: 12.5,
      ),
      markers: markers,
      myLocationButtonEnabled: true,
      myLocationEnabled: true,
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
      compassEnabled: true,
      mapType: MapType.normal,
      onMapCreated: (controller) {
        _controller = controller;
      },
      onTap: (_) {
        // Keep the selected producer in the list view when tapping on the map
        widget.onProducerSelected(
          widget.selectedProducer ?? widget.producers.first,
        );
      },
    );
  }
}
