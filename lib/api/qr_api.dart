import 'dart:convert';
import 'package:application/api/api_client.dart';
import 'package:application/model/QRModel.dart';
import 'package:flutter/foundation.dart';

class QRApi {
  static Future<QRModel?> getQR(String receiver) async {
    try {
      final response = await ApiClient.get('/getQR/${Uri.encodeComponent(receiver)}');
      if (response.statusCode == 200) {
        return QRModel.fromJson(jsonDecode(response.body));
      }
      return null;
    } catch (e) {
      debugPrint('Loi lay QR: $e');
      return null;
    }
  }
}
