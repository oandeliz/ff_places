import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import '../models/place.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({
    Key? key,
    this.location = const PlaceLocation(
      latitude: 37.422,
      longitude: -122.084,
      address: '',
    ),
    this.isSelecting = true,
  }) : super(key: key);

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
    bool _serviceEnabled;
    PermissionStatus _permissionGranted;

    _serviceEnabled = await _locationService.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await _locationService.requestService();
      if (!_serviceEnabled) {
        return null;
      }
    }

    _permissionGranted = await _locationService.hasPermission();
    if (_permissionGranted == PermissionStatus.denied) {
      _permissionGranted = await _locationService.requestPermission();
      if (_permissionGranted != PermissionStatus.granted) {
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
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
            return Center(child: Text('Failed to get current location.'));
          }

          _currentLocation = snapshot.data;

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