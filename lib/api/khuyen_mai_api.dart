import 'dart:convert';

import 'package:application/api/server_address.dart';
import 'package:application/model/khuyen_mai_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class KhuyenMaiApi {

  static Future<List<KhuyenMaiModel>>
  getKhuyenMaiTheoUser(String username) async {

    try {
      final response = await http.get(
        Uri.parse(
          "${ServerAddress().address}"
              "/khuyen-mai/get-khuyen-mai/$username",
        ),
      );

      if (response.statusCode == 200) {

        List<dynamic> data =
        jsonDecode(response.body);

        print("STATUS: ${response.statusCode}");
        print("BODY: ${response.body}");

        print(data.length);

        return data
            .map(
              (e) => KhuyenMaiModel
              .fromJson(e),
        )
            .toList();
      }

      throw Exception(
        "Lỗi API: ${response.statusCode}",
      );

    } catch (e) {
      print(
        "Lỗi getKhuyenMaiTheoUser: $e",
      );

      return [];
    }
  }
}