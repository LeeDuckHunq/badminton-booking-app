// lib/ui/account/data/account_dummy_data.dart

import 'package:application/model/cum_san_model.dart';
import 'package:application/model/khuyen_mai_model.dart';
import 'package:application/model/phieu_dat_san_model.dart';
import 'package:application/model/san_model.dart';
import 'package:application/model/user_model.dart';

class AccountDummyData {
  static final UserModel user = UserModel(
    username: 'leduehung',
    password: '***',
    role: 'USER',
    fullName: 'Lê Đức Hưng',
    email: 'leduehung@smash.vn',
    phoneNumber: '0901 234 567',
  );

  static final List<SanModel> sanList = [
    SanModel(
      maSan: 'SAN001',
      tenSan: 'Sân 1',
      gia: 120000,
      trangThai: true,
      maCumSan: 'CUM001',
    ),
    SanModel(
      maSan: 'SAN002',
      tenSan: 'Sân 2',
      gia: 150000,
      trangThai: true,
      maCumSan: 'CUM002',
    ),
  ];

  static final List<CumSanModel> cumSanList = [
    CumSanModel(
      maCumSan: 'CUM001',
      tenCumSan: 'Cụm Sân Quận 1',
      diaChi: '12 Nguyễn Huệ, Quận 1, TP.HCM',
      moTa: 'Sân cầu lông cao cấp trung tâm',
      sDT: '0901111222',
      gioMoCua: '06:00',
      gioDongCua: '23:00',
    ),
    CumSanModel(
      maCumSan: 'CUM002',
      tenCumSan: 'Platinum Badminton Trà Mi',
      diaChi: '463 Quốc Lộ 1A, Bình Hưng Hoà, Bình Tân',
      moTa: 'Hệ thống sân cầu lông chuyên nghiệp',
      sDT: '0902222333',
      gioMoCua: '05:00',
      gioDongCua: '23:00',
    ),
  ];

  static final List<PhieuDatSanModel> phieuDatList = [
    PhieuDatSanModel(
      maPhieuDat: 'PD001',
      maNguoiDung: 'leduehung',
      maSan: 'SAN001',
      batDau: DateTime(2026, 5, 20, 7, 0),
      ketThuc: DateTime(2026, 5, 20, 9, 0),
      tongTien: 240000,
      maKhuyenMai: null,
      ngayLap: DateTime(2026, 5, 19),
      trangThai: 'DA_XAC_NHAN',
    ),
    PhieuDatSanModel(
      maPhieuDat: 'PD002',
      maNguoiDung: 'leduehung',
      maSan: 'SAN002',
      batDau: DateTime(2026, 5, 22, 10, 0),
      ketThuc: DateTime(2026, 5, 22, 12, 0),
      tongTien: 300000,
      maKhuyenMai: 'KM001',
      ngayLap: DateTime(2026, 5, 20),
      trangThai: 'CHO_XAC_NHAN',
    ),
    PhieuDatSanModel(
      maPhieuDat: 'PD003',
      maNguoiDung: 'leduehung',
      maSan: 'SAN001',
      batDau: DateTime(2026, 5, 15, 8, 0),
      ketThuc: DateTime(2026, 5, 15, 10, 0),
      tongTien: 240000,
      maKhuyenMai: null,
      ngayLap: DateTime(2026, 5, 14),
      trangThai: 'DA_XAC_NHAN',
    ),
  ];

  static final List<KhuyenMaiModel> khuyenMaiList = [
    KhuyenMaiModel(
      maKhuyenMai: 'KM001',
      tenKhuyenMai: 'Giảm 10% đơn đầu',
      phanTramGiam: 0.10,
      ngayBatDau: DateTime(2026, 5, 1),
      ngayKetThuc: DateTime(2026, 6, 30),
    ),
    KhuyenMaiModel(
      maKhuyenMai: 'KM002',
      tenKhuyenMai: 'Thành viên thân thiết',
      phanTramGiam: 0.15,
      ngayBatDau: DateTime(2026, 5, 1),
      ngayKetThuc: DateTime(2026, 5, 31),
    ),
    KhuyenMaiModel(
      maKhuyenMai: 'KM003',
      tenKhuyenMai: 'Ưu đãi cuối tuần',
      phanTramGiam: 0.20,
      ngayBatDau: DateTime(2026, 5, 15),
      ngayKetThuc: DateTime(2026, 5, 25),
    ),
  ];
}