import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:application/api/server_address.dart';
import 'package:http/http.dart' as http;

class AccountApi {
  static Future<bool> login(String username, String password) async {

    var futureResponse = http.post(
      Uri.parse("${ServerAddress().address}/login"),
      headers: ({
        "Accept": "application/json",
        "Content-Type": "application/json; charset=UTF-8"
      }),
      body: jsonEncode({
        "username": username,
        "password": password
      })
    );

    var response = await futureResponse;

    if (response.statusCode == 200) {
      try {

        final prefs = await SharedPreferences.getInstance();

        await prefs.setString("jwt_token", response.body);
        await prefs.setString("username", username);

        print(prefs.getString("jwt_token"));
        print(prefs.getString("username"));

      } catch (e) {

        print(e);
      }
      return true;
    }
    return false;
  }

  static Future<bool> register(String username, String password, String role,
      String fullName, String email, String phoneNumber) async {

    var futureResponse = http.post(
        Uri.parse("${ServerAddress().address}/register"),
        headers: ({
          "Accept": "application/json",
          "Content-Type": "application/json; charset=UTF-8"
        }),
        body: jsonEncode({
          "username": username,
          "password": password,
          "role": role,
          "fullName": fullName,
          "email": email,
          "phoneNumber": phoneNumber
        })
    );

    var response = await futureResponse;

    if (response.statusCode == 200) {
      print("Successful!");
      return true;
    }
    return false;
  }
}