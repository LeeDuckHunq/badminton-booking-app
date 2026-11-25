# SmashZone – App khách hàng

App đặt sân cầu lông viết bằng Flutter (Android, Web, Windows).

Dự án gồm 3 repo:

| Repo | Vai trò |
|---|---|
| [BE-badminton-booking-app](https://github.com/LeeDuckHunq/BE-badminton-booking-app) | API (Spring Boot + MongoDB) |
| **badminton-booking-app** (repo này) | App khách hàng |
| [smashzone-dashboard](https://github.com/LeeDuckHunq/smashzone-dashboard) | Trang quản trị cho chủ sân / admin |

## 1. Cần cài

- **Flutter 3.38** (Dart 3.10) trở lên. Kiểm tra: `flutter doctor`.
- Để chạy Android: Android Studio + một máy ảo (emulator) hoặc điện thoại bật USB debugging.
- Để chạy Web: Chrome hoặc Edge.

## 2. Cài thư viện

```bash
flutter pub get
```

## 3. Chọn máy chủ (BE)

App gọi BE theo biến `API_BASE_URL` lúc chạy/build. Không truyền gì thì app dùng **bản thật**:
`https://be-badminton-booking-app-production.up.railway.app`.

| Muốn | Lệnh |
|---|---|
| Dùng bản thật | `flutter run` |
| Dùng BE chạy trên máy mình, app chạy Web/Windows | `flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8089` |
| Dùng BE chạy trên máy mình, app chạy **máy ảo Android** | `flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8089` |
| Dùng BE trên máy mình, app chạy **điện thoại thật** (cùng Wi-Fi) | `flutter run --dart-define=API_BASE_URL=http://<IP-máy-tính>:8089` |

`10.0.2.2` là địa chỉ máy tính khi nhìn từ máy ảo Android. Với điện thoại thật, xem IP máy tính bằng `ipconfig` (Windows) hoặc `ifconfig` (macOS/Linux), và mở cổng 8089 trên tường lửa nếu cần.

Cách chạy BE và tạo dữ liệu demo: xem README của repo **BE-badminton-booking-app**.

> **Nên test trên BE local.** Bản thật đang có dữ liệu thật: đặt sân, huỷ đơn… trên bản thật sẽ ảnh hưởng chủ sân. Chỉ dùng bản thật để kiểm tra lần cuối.

## 4. Tài khoản test

Với BE local đã chạy `scripts/seed-demo.mjs`:

| Tài khoản | Mật khẩu | Có sẵn |
|---|---|---|
| `tuananh` | `secret12` | Đơn chờ duyệt, đã xác nhận, hoàn thành (chưa đánh giá), đã huỷ; voucher; sân yêu thích; tin nhắn với chủ sân |
| `minhkhang` | `secret12` | Vài đơn, đã đánh giá |
| `mailinh` | `secret12` | Vài đơn, đã đánh giá |

Hoặc tự đăng ký tài khoản mới ngay trong app.

## 5. Kịch bản test gợi ý

1. **Đăng ký / đăng nhập**: sai mật khẩu, bỏ trống, "Ghi nhớ đăng nhập", đăng xuất.
2. **Trang chủ & tìm kiếm**: lọc theo giờ mở cửa, tìm theo tên/địa chỉ, thêm/bỏ yêu thích, chỉ đường.
3. **Đặt sân**: chọn ngày, chọn nhiều ô 30 phút liền nhau, đặt sân. Thử chọn ô đã đặt, ô đã qua giờ.
4. **Thanh toán**: màn hoá đơn, áp voucher, mã QR chuyển khoản, upload ảnh bill.
5. **Sân đã đặt**: lọc theo trạng thái, xem hoá đơn, đặt lại sân. Đơn do chủ sân đặt hộ hiện nhãn "Đặt tại sân".
6. **Đánh giá**: với đơn đã hoàn thành, bấm "Đánh giá", chọn sao, viết nhận xét, gửi rồi sửa lại. Bấm điểm sao trên card cụm sân để xem danh sách đánh giá và phản hồi của chủ sân.
7. **Voucher**: nhận voucher mới, xem voucher của tôi.
8. **Tin nhắn**: nhắn với chủ sân / người chơi khác.
9. **Nổi bật**: bảng xếp hạng cụm sân được đặt nhiều.

Kiểm tra song song trên dashboard (repo `smashzone-dashboard`) bằng tài khoản chủ sân `hoanganh` / `owner1234`: duyệt đơn, đặt hộ, trả lời đánh giá… rồi xem app có cập nhật đúng không.

Khi báo lỗi, ghi rõ: tài khoản dùng, thiết bị (Android/Web/Windows), BE local hay bản thật, các bước làm, ảnh chụp màn hình.

## 6. Build

```bash
# APK Android (dùng bản thật)
flutter build apk --release

# Web, trỏ tới BE khác
flutter build web --release --dart-define=API_BASE_URL=https://<địa-chỉ-BE>
```

File APK nằm ở `build/app/outputs/flutter-apk/app-release.apk`. Nếu build Web để đưa lên mạng, domain của web phải được thêm vào biến `CORS_ALLOWED_ORIGINS` của BE.

Không có `android/key.properties` thì APK được ký bằng khoá debug của máy đang build: dùng để test được, nhưng **không cài đè lên bản phát hành** được.

### Phát hành bản mới & tự cập nhật (trưởng nhóm)

App (từ v1.1.0, gói `vn.smashzone.app`) tự hỏi BE `GET /app/phien-ban` khi mở. Có bản mới thì hiện màn hình cập nhật, tải APK hợp với CPU của máy và mở trình cài của Android. Bản cũ hơn "build tối thiểu" sẽ bị bắt buộc cập nhật.

1. Tăng `version:` trong `pubspec.yaml` (ví dụ `1.2.0+3`: tên 1.2.0, build 3). Build phải luôn tăng.
2. Chạy `bash scripts/release-android.sh`: build APK cho ARM 64-bit và 32-bit (đã ký), chép vào `smashzone-web/public/download/`.
3. Deploy web khách (file APK lên Cloudflare cùng web).
4. Dashboard → **Phiên bản app** → "Điền link trên web khách", nhập dung lượng, ghi "Có gì mới", bấm **Phát hành**.

> **Khoá ký** (`smashzone-release.jks` + `key.properties`) không có trên git. Bản gốc lưu ở `D:\SmashZone\keys`, hãy sao lưu thêm (Google Drive cá nhân, USB…). **Mất khoá thì không phát hành bản cập nhật được nữa**: người dùng sẽ phải gỡ app và cài lại.

## 7. Cấu trúc thư mục

```
lib/
├── main.dart
├── api/          Gọi API (ApiClient tự gắn token, tự đăng xuất khi hết phiên)
├── model/        Model dữ liệu
├── security/     Lưu phiên đăng nhập
├── ui/
│   ├── screen/   Các màn hình chính
│   ├── account/  Tài khoản, lịch sử đặt, hoá đơn
│   ├── review/   Đánh giá
│   ├── theme/    Màu, chữ, bo góc (design system)
│   └── widget/   Component dùng chung (sz.dart)
└── dev/          Chế độ xem trước màn hình, chỉ bật khi build với SZ_PREVIEW=true
```

## 8. Lỗi thường gặp

| Hiện tượng | Cách xử lý |
|---|---|
| Không kết nối được máy chủ (máy ảo Android + BE local) | Dùng `http://10.0.2.2:8089`, không phải `localhost` |
| Điện thoại thật không gọi được BE local | Cùng mạng Wi-Fi, dùng IP máy tính, mở cổng 8089 trên tường lửa |
| Web báo lỗi CORS | BE local mặc định cho phép mọi nguồn; với bản thật cần thêm domain vào `CORS_ALLOWED_ORIGINS` |
| Upload bill báo lỗi | BE chưa cấu hình Supabase (bình thường khi chạy BE local) |
| Đăng nhập xong bị đá ra | Phiên hết hạn (12 giờ) hoặc BE đổi `JWT_SECRET`; đăng nhập lại |
