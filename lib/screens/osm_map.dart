import 'package:flutter/material.dart';
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart';
import 'package:location/location.dart';

import '../models/place.dart';

final mapController = MapController.withUserPosition(
  trackUserLocation: const UserTrackingOption(
    enableTracking: true,
    unFollowUser: false,
  ),
);

class OsmMap extends StatefulWidget {
  const OsmMap({
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
  State<OsmMap> createState() {
    return _MapScreenState();
  }
}

class _MapScreenState extends State<OsmMap> with OSMMixinObserver {
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
  void onSingleTap(GeoPoint position) {
    super.onSingleTap(position);
    mapController.changeLocation(position);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            Text(widget.isSelecting ? 'Pick your Location' : 'Your Location'),
        actions: [
          if (widget.isSelecting)
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: () {
                //TODO:: get the locations
                Navigator.of(context).pop("todo");
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
          if (_currentLocation == null ||
              _currentLocation!.latitude == null ||
              _currentLocation!.longitude == null) {
            print('Invalid location data: $_currentLocation');
            return const Center(
                child: Text('Failed to get valid location data.'));
          }

          return OSMFlutter(
              controller: mapController,
              osmOption: OSMOption(
                userTrackingOption: const UserTrackingOption(
                  enableTracking: true,
                  unFollowUser: false,
                ),
                zoomOption: const ZoomOption(
                  initZoom: 8,
                  minZoomLevel: 3,
                  maxZoomLevel: 19,
                  stepZoom: 1.0,
                ),
                userLocationMarker: UserLocationMaker(
                  personMarker: const MarkerIcon(
                    icon: Icon(
                      Icons.location_history_rounded,
                      color: Colors.red,
                      size: 48,
                    ),
                  ),
                  directionArrowMarker: const MarkerIcon(
                    icon: Icon(
                      Icons.double_arrow,
                      size: 48,
                    ),
                  ),
                ),
                roadConfiguration: const RoadOption(
                  roadColor: Colors.yellowAccent,
                ),
                markerOption: MarkerOption(
                    defaultMarker: const MarkerIcon(
                  icon: Icon(
                    Icons.person_pin_circle,
                    color: Colors.blue,
                    size: 56,
                  ),
                )),
              ));
        },
      ),
    );
  }

  @override
  Future<void> mapIsReady(bool isReady) {
    // TODO: implement mapIsReady
    throw UnimplementedError();
  }
}
