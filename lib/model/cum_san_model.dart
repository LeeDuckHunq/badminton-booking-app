// lib/model/cum_san_model.dart

import 'package:flutter/material.dart';

class CumSanModel {
  String maCumSan;
  String tenCumSan;
  String diaChi;
  String moTa;
  String sDT;
  String gioMoCua;
  String gioDongCua;

  CumSanModel({
    required this.maCumSan,
    required this.tenCumSan,
    required this.diaChi,
    required this.moTa,
    required this.sDT,
    required this.gioMoCua,
    required this.gioDongCua,
  });

  factory CumSanModel.fromJson(Map<String, dynamic> json) {
    return CumSanModel(
      maCumSan:    json['maCumSan']    as String? ?? '',
      tenCumSan:   json['tenCumSan']   as String? ?? '',
      diaChi:      json['diaChi']      as String? ?? '',
      moTa:        json['moTa']        as String? ?? '',
      sDT:         json['sDT']         as String? ?? '',
      gioMoCua:    json['gioMoCua']    as String? ?? '00:00',
      gioDongCua:  json['gioDongCua']  as String? ?? '00:00',
    );
  }

  TimeOfDay parseTime(String time) {
    final parts = time.split(':');
    return TimeOfDay(
      hour:   int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );
  }
}