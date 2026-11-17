/// Địa chỉ backend. Mặc định là production; build khác môi trường bằng
/// `flutter build ... --dart-define=API_BASE_URL=http://localhost:8080`.
interface class ServerAddress {
  static const String baseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: 'https://be-badminton-booking-app-production.up.railway.app');

  String address = baseUrl;
}
