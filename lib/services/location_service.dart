import 'package:location/location.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

class LocationService {
  final Location _location = Location();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription<LocationData>? _locationSubscription;

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
  ///
  /// [workerId]: The ID of the worker whose location is being updated.
  Future<void> startUpdatingLocation(String workerId) async {
    final initialized = await _initializeLocationService();
    if (!initialized) return;

    // Listen to location changes
    _locationSubscription = _location.onLocationChanged.listen(
      (LocationData currentLocation) async {
        if (currentLocation.latitude != null && currentLocation.longitude != null) {
          try {
            // Update location in Firestore
            await _firestore.collection('users').doc(workerId).update({
              'location': {
                'latitude': currentLocation.latitude,
                'longitude': currentLocation.longitude,
              },
            });
            print('Location updated for worker: $workerId');
          } catch (e) {
            print('Error updating location in Firestore: $e');
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
}
