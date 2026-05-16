// lib/services/distance_service.dart

import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class DistanceService {
  // TODO: thay bằng Google API key của bạn
  static const String _apiKey = 'YOUR_GOOGLE_API_KEY';

  // ── Lấy vị trí hiện tại của user ─────────────────────────────────────────
  static Future<Position?> getCurrentPosition() async {
    try {
      // Kiểm tra services bật chưa
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      // Kiểm tra / xin quyền
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return null;
      }
      if (permission == LocationPermission.deniedForever) return null;

      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
    } catch (_) {
      return null;
    }
  }

  // ── Gọi Distance Matrix API cho 1 địa chỉ ────────────────────────────────
  static Future<String?> getDistance({
    required double originLat,
    required double originLng,
    required String destinationAddress,
  }) async {
    try {
      final origin      = '$originLat,$originLng';
      final destination = Uri.encodeComponent(destinationAddress);

      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/distancematrix/json'
            '?origins=$origin'
            '&destinations=$destination'
            '&mode=driving'
            '&language=vi'
            '&key=$_apiKey',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Kiểm tra status tổng
        if (data['status'] != 'OK') return null;

        final element = data['rows']?[0]?['elements']?[0];
        if (element == null || element['status'] != 'OK') return null;

        // Trả về text dạng "5,2 km" hoặc "350 m"
        return element['distance']['text'] as String?;
      }
    } catch (_) {
      return null;
    }

    return null;
  }

  // ── Gọi batch cho nhiều địa chỉ cùng lúc (tối ưu, 1 request) ─────────────
  // Distance Matrix hỗ trợ tối đa 25 destinations/request
  static Future<List<String?>> getDistanceBatch({
    required double originLat,
    required double originLng,
    required List<String> destinationAddresses,
  }) async {
    if (destinationAddresses.isEmpty) return [];

    try {
      final origin       = '$originLat,$originLng';
      final destinations = destinationAddresses
          .map(Uri.encodeComponent)
          .join('|');

      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/distancematrix/json'
            '?origins=$origin'
            '&destinations=$destinations'
            '&mode=driving'
            '&language=vi'
            '&key=$_apiKey',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] != 'OK') {
          return List.filled(destinationAddresses.length, null);
        }

        final elements = data['rows']?[0]?['elements'] as List<dynamic>?;
        if (elements == null) {
          return List.filled(destinationAddresses.length, null);
        }

        return elements.map<String?>((el) {
          if (el['status'] == 'OK') {
            return el['distance']['text'] as String?;
          }
          return null;
        }).toList();
      }
    } catch (_) {}

    return List.filled(destinationAddresses.length, null);
  }
}