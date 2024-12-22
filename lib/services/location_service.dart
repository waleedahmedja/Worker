import 'package:location/location.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'dart:math';

class LocationService {
  final Location _location = Location();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription<LocationData>? _locationSubscription;
  LatLng? _lastLocation; // Cache to store the last updated location

  /// Requests necessary permissions and ensures location services are enabled.
  Future<bool> _initializeLocationService() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await _location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await _location.requestService();
        if (!serviceEnabled) {
          print('Location services are disabled.');
          return false;
        }
      }

      // Check and request location permissions
      PermissionStatus permissionGranted = await _location.hasPermission();
      if (permissionGranted == PermissionStatus.denied) {
        permissionGranted = await _location.requestPermission();
        if (permissionGranted != PermissionStatus.granted) {
          print('Location permission denied.');
          return false;
        }
      }

      return true;
    } catch (e) {
      print('Error initializing location service: $e');
      return false;
    }
  }

  /// Starts real-time location updates for a worker and updates Firestore.
  Future<void> startUpdatingLocation(String workerId) async {
    if (workerId.isEmpty) {
      print('Worker ID is invalid.');
      return;
    }

    final initialized = await _initializeLocationService();
    if (!initialized) return;

    // Listen to location changes
    _locationSubscription = _location.onLocationChanged.listen(
      (LocationData currentLocation) async {
        if (currentLocation.latitude != null && currentLocation.longitude != null) {
          final newLocation = LatLng(currentLocation.latitude!, currentLocation.longitude!);
          if (_lastLocation == null || _distanceBetween(_lastLocation!, newLocation) > 10) {
            // Update location in Firestore only if it has changed significantly (e.g., > 10 meters)
            _lastLocation = newLocation;
            try {
              await _firestore.collection('users').doc(workerId).update({
                'location': {
                  'latitude': newLocation.latitude,
                  'longitude': newLocation.longitude,
                },
              });
              print('Location updated for worker: $workerId');
            } catch (e) {
              print('Error updating location in Firestore: $e');
            }
          }
        }
      },
    );
  }

  /// Stops location updates.
  void stopUpdatingLocation() {
    if (_locationSubscription != null) {
      _locationSubscription!.cancel();
      _locationSubscription = null;
      print('Location updates stopped.');
    }
  }

  /// Calculates the distance between two points using the Haversine formula.
  double _distanceBetween(LatLng loc1, LatLng loc2) {
    const double earthRadius = 6371000; // in meters
    final dLat = (loc2.latitude - loc1.latitude) * (pi / 180);
    final dLon = (loc2.longitude - loc1.longitude) * (pi / 180);
    final a = (sin(dLat / 2) * sin(dLat / 2)) +
        (cos(loc1.latitude * (pi / 180)) *
            cos(loc2.latitude * (pi / 180)) *
            sin(dLon / 2) *
            sin(dLon / 2));
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }
}

/// Helper class for latitude and longitude.
class LatLng {
  final double latitude;
  final double longitude;

  LatLng(this.latitude, this.longitude);
}
