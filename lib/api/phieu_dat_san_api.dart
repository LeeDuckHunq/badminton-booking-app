import 'dart:convert';
import 'package:application/api/server_address.dart';
import 'package:application/model/create_phieu_dat_model.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../model/phieu_dat_san_model.dart';

class PhieuDatSanApi {

  static Future<List<PhieuDatSanModel>>
  getPhieuDatTheoNgay(
      DateTime ngay) async {

    String formattedDate =
        "${ngay.year}"
        "-${ngay.month.toString().padLeft(2, '0')}"
        "-${ngay.day.toString().padLeft(2, '0')}";

    final response = await http.get(
      Uri.parse(
        '${ServerAddress().address}/phieu-dat-san/theo-ngay?ngay=$formattedDate',
      ),
    );

    if (response.statusCode == 200) {

      final List<dynamic> data =
      jsonDecode(response.body);

      return data
          .map(
            (e) =>
            PhieuDatSanModel
                .fromJson(e),
      )
          .toList();
    }

    throw Exception(
      'Không lấy được lịch đặt sân',
    );
  }

  static Future<String?> createPhieuDat(CreatePhieuDatModel request) async {
    try {
      final response = await http.post(
        Uri.parse('${ServerAddress().address}/phieu-dat-san/create'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(request.toJson()),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data['maPhieuDat'] as String?; // BE trả về maPhieuDat
      }
      return null;
    } catch (e) {
      print('createPhieuDat error: $e');
      return null;
    }
  }

  static Future<List<PhieuDatSanModel>> getPhieuDatSanTheoUser(String username) async {

    var response = await http.get(
      Uri.parse('${ServerAddress().address}/phieu-dat-san/get-theo-user/$username'),
      headers: ({
        "Accept": "application/json"
      })
    );

    if (response.statusCode == 200) {

      final List<dynamic> data = jsonDecode(response.body);

      return data.map((e) => PhieuDatSanModel.fromJson(e)).toList();
    }

    throw Exception('Không lấy được lịch đặt sân');
  }

  static Future<bool> deletePhieuDat(String maPhieuDat) async {
    final uri = Uri.parse('${ServerAddress().address}/phieu-dat-san/delete-phieu-dat/$maPhieuDat');

    final response = await http.delete(
      uri,
      headers: {
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200 || response.statusCode == 204) {
      return true;
    } else {
      final body = response.body.isNotEmpty ? jsonDecode(response.body) : {};
      throw Exception(body['message'] ?? 'Xóa phiếu đặt thất bại (${response.statusCode})');
    }
  }
}