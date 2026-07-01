import 'package:geolocator/geolocator.dart';
import '../network/api_client.dart';

class LocationService {
  static Future<Map<String, dynamic>?> updateWeather() async {
    try {
      // Check permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever) {
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return null;
      }

      // Check if service is enabled
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      // Get position
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: Duration(seconds: 10),
        ),
      );

      // Send to backend
      final response = await ApiClient().dio.post('/weather/update', data: {
        'latitude': position.latitude,
        'longitude': position.longitude,
      });

      return response.data as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }
}
