import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class GeoLocation {
  final double? latitude;
  final double? longitude;
  final double? accuracy;
  final DateTime timestamp;
  final String? error;

  GeoLocation({
    this.latitude,
    this.longitude,
    this.accuracy,
    DateTime? timestamp,
    this.error,
  }) : timestamp = timestamp ?? DateTime.now();

  bool get hasCoordinates => latitude != null && longitude != null;

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{
      'timestamp': timestamp.toIso8601String(),
    };

    if (hasCoordinates) {
      data['latitude'] = latitude?.toString();
      data['longitude'] = longitude?.toString();
      data['accuracy'] = accuracy?.toString();
    }

    if (error != null) {
      data['error'] = error!;
    }

    return data;
  }

  static Future<GeoLocation> getCurrentLocation() async {
    try {
      print('🔍 Requesting location permission...');
      final permission = await Permission.location.request();
      
      if (!permission.isGranted) {
        if (permission.isPermanentlyDenied) {
          print('❌ Location permission permanently denied');
          return GeoLocation(error: 'Location permission permanently denied');
        } else {
          print('⚠️ Location permission denied');
          return GeoLocation(error: 'Location permission denied');
        }
      }

      print('✅ Location permission granted, checking if location services are enabled...');
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('⚠️ Location services are disabled');
        return GeoLocation(error: 'Location services are disabled');
      }

      print('📍 Getting current position...');
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      if (position.latitude == 0.0 && position.longitude == 0.0) {
        print('⚠️ Invalid location coordinates received (0,0)');
        return GeoLocation(error: 'Invalid location coordinates');
      }

      print('📍 Location obtained - Lat: ${position.latitude}, Long: ${position.longitude}, Accuracy: ${position.accuracy?.toStringAsFixed(2)}m');
      
      return GeoLocation(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
      );
    } catch (e, stackTrace) {
      print('❌ Error getting location:');
      print('Error: $e');
      print('Stack trace: $stackTrace');
      
      // Try to get last known position if available
      try {
        final lastPosition = await Geolocator.getLastKnownPosition();
        if (lastPosition != null) {
          print('ℹ️ Using last known position');
          return GeoLocation(
            latitude: lastPosition.latitude,
            longitude: lastPosition.longitude,
            accuracy: lastPosition.accuracy,
          );
        }
      } catch (e) {
        print('⚠️ Could not get last known position: $e');
      }
      
      return GeoLocation(error: e.toString());
    }
  }
}
