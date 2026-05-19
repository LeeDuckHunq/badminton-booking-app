import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseStorageService {
  static const String _bucket = 'images';
  static const String _folder = 'uploads';

  static Future<String?> uploadBillImage({
    required File file,
  }) async {
    try {
      final supabase = Supabase.instance.client;

      final bytes = await file.readAsBytes();

      final fileName =
      DateTime.now().millisecondsSinceEpoch.toString();

      final path = '$_folder/$fileName.jpg';

      print("Uploading: $path");

      await supabase.storage
          .from(_bucket)
          .uploadBinary(path, bytes);

      final url = supabase.storage
          .from(_bucket)
          .getPublicUrl(path);

      print("SUCCESS: $url");

      return url;
    } catch (e) {
      print("UPLOAD ERROR: $e");
      return null;
    }
  }
}