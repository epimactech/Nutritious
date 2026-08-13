import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../models/company.dart';

class MapView extends StatefulWidget {
  final List<Company> companies;
  final Company? selectedCompany;
  final ValueChanged<Company> onCompanySelected;

  const MapView({
    super.key,
    required this.companies,
    required this.selectedCompany,
    required this.onCompanySelected,
  });

  @override
  State<MapView> createState() => _MapViewState();
}

class _MapViewState extends State<MapView> {
  GoogleMapController? _controller;

  static const LatLng _darEsSalaam = LatLng(-6.7924, 39.2083);

  @override
  Widget build(BuildContext context) {
    final markers = widget.companies.map((company) {
      final selected = widget.selectedCompany?.id == company.id;

      return Marker(
        markerId: MarkerId(company.id),
        position: LatLng(company.latitude, company.longitude),
        infoWindow: InfoWindow(
          title: company.name,
          snippet: '${company.category} • ★ ${company.rating.toStringAsFixed(1)}',
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          selected
              ? BitmapDescriptor.hueOrange
              : BitmapDescriptor.hueGreen,
        ),
        onTap: () {
          widget.onCompanySelected(company);
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
        // Keep the selected company on web; mobile can close its modal.
      },
    );
  }
}
