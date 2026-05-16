class QRModel {
  final String receiver;
  final String qrCode;

  QRModel({
    required this.receiver,
    required this.qrCode,
  });

  factory QRModel.fromJson(
      Map<String, dynamic> json,
      ) {
    return QRModel(
      receiver: json['receiver'] ?? '',
      qrCode: json['qrCode'] ?? '',
    );
  }
}