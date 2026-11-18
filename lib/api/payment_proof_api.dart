import 'dart:convert';

import 'package:application/api/api_client.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class PaymentProofApi {
  /// Tải ảnh bill lên server (chạy được cả mobile và web). Trả về URL ảnh hoặc null.
  static Future<String?> upload({required Uint8List bytes, required String filename}) async {
    try {
      final token = await ApiClient.token();
      if (token == null) {
        debugPrint('Payment proof upload failed: missing access token');
        return null;
      }

      final request = http.MultipartRequest('POST', ApiClient.uri('/files/payment-proof'))
        ..headers['Accept'] = 'application/json'
        ..headers['Authorization'] = 'Bearer $token'
        ..files.add(http.MultipartFile.fromBytes('file', bytes, filename: filename));

      final streamedResponse = await request.send().timeout(const Duration(seconds: 45));
      final response = await http.Response.fromStream(streamedResponse);
      await ApiClient.checkUnauthorized(response);

      if (response.statusCode != 200) {
        debugPrint('Payment proof upload failed: HTTP ${response.statusCode}');
        return null;
      }

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return body['url'] as String?;
    } catch (error) {
      debugPrint('Payment proof upload failed: $error');
      return null;
    }
  }
}
