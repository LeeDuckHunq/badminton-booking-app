import 'dart:convert';
import 'package:application/api/server_address.dart';
import 'package:http/http.dart' as http;
import '../model/san_model.dart';

class SanApi {

  static Future<List<SanModel>>
  getSanTheoCumSan(String maCumSan) async {

    final response = await http.get(
      Uri.parse(
        '${ServerAddress().address}/san/get-san/$maCumSan',
      ),
    );

    if (response.statusCode == 200) {

      final List<dynamic> data =
      jsonDecode(response.body);

      return data
          .map((e) => SanModel.fromJson(e))
          .toList();
    }

    throw Exception(
      'Không lấy được danh sách sân',
    );
  }
}