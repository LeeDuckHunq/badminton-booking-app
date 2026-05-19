import 'dart:convert';
import 'package:application/api/server_address.dart';
import 'package:application/model/create_phieu_dat_model.dart';
import 'package:http/http.dart' as http;
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

  static Future<bool>
  createPhieuDat(
      CreatePhieuDatModel request
      ) async {

    try {

      final response =
      await http.post(

        Uri.parse(
          '${ServerAddress().address}/phieu-dat-san/create',
        ),

        headers: {
          'Content-Type':
          'application/json',
        },

        body: jsonEncode(
          request.toJson(),
        ),
      );

      print(
        'Status: '
            '${response.statusCode}',
      );

      print(
        'Response: '
            '${response.body}',
      );

      return response
          .statusCode == 200;

    } catch (e) {

      print(
        'Loi create phieu: '
            '$e',
      );

      return false;
    }
  }
}