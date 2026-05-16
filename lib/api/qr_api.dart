import 'dart:convert';
import 'package:application/api/server_address.dart';
import 'package:application/model/QRModel.dart';
import 'package:http/http.dart' as http;

class QRApi {

  static Future<QRModel?> getQR(
      String receiver
      ) async {
    try {
      final response = await http.get(
        Uri.parse(
          '${ServerAddress().address}/getQR/$receiver',
        ),
      );

      if (response.statusCode == 200) {
        final data =
        jsonDecode(response.body);

        return QRModel.fromJson(data);
      }

      return null;
    } catch (e) {
      print('Loi lay QR: $e');
      return null;
    }
  }
}