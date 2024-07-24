import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import '../models/place.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({
    super.key,
    this.location = const PlaceLocation(
      latitude: 37.422,
      longitude: -122.084,
      address: '',
    ),
    this.isSelecting = true,
  });

  final PlaceLocation location;
  final bool isSelecting;

  @override
  State<MapScreen> createState() {
    return _MapScreenState();
  }
}

class _MapScreenState extends State<MapScreen> {
  LatLng? _pickedLocation;
  LocationData? _currentLocation;
  final Location _locationService = Location();

  Future<LocationData?> _getCurrentLocation() async {
    bool serviceEnabled;
    PermissionStatus permissionGranted;

    serviceEnabled = await _locationService.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _locationService.requestService();
      if (!serviceEnabled) {
        return null;
      }
    }

    permissionGranted = await _locationService.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await _locationService.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        return null;
      }
    }

    return await _locationService.getLocation();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isSelecting ? 'Pick your Location' : 'Your Location'),
        actions: [
          if (widget.isSelecting)
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: () {
                Navigator.of(context).pop(_pickedLocation);
              },
            ),
        ],
      ),
      body: FutureBuilder<LocationData?>(
        future: _getCurrentLocation(),
        builder: (ctx, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || !snapshot.hasData) {
            print('Error or no data: ${snapshot.error}');
            return const Center(child: Text('Failed to get current location.'));
          }

          _currentLocation = snapshot.data;

          // Ensure location data is valid
          if (_currentLocation == null || _currentLocation!.latitude == null || _currentLocation!.longitude == null) {
            print('Invalid location data: $_currentLocation');
            return Center(child: Text('Failed to get valid location data.'));
          }

          return GoogleMap(
            onTap: !widget.isSelecting
                ? null
                : (position) {
              setState(() {
                _pickedLocation = position;
              });
            },
            initialCameraPosition: CameraPosition(
              target: _pickedLocation ??
                  LatLng(
                    _currentLocation!.latitude!,
                    _currentLocation!.longitude!,
                  ),
              zoom: 16,
            ),
            markers: (_pickedLocation == null && widget.isSelecting)
                ? {}
                : {
              Marker(
                markerId: const MarkerId('m1'),
                position: _pickedLocation ??
                    LatLng(
                      _currentLocation!.latitude!,
                      _currentLocation!.longitude!,
                    ),
              ),
            },
          );
        },
      ),
    );
  }
}