# DailyFit — Trợ lý Phối đồ Cá nhân Thông minh (Android Mobile App)

Ứng dụng di động **DailyFit** thiết kế theo ngôn ngữ **Blue & White Premium Glassmorphism**, hỗ trợ quản lý tủ đồ cá nhân, phân tích thời tiết theo khu vực, gợi ý phối đồ thông minh cho nhiều hoàn cảnh (*Đi học, Đi làm, Đi chơi, Hẹn hò, Thể thao, Dự tiệc*), lưu bộ đồ yêu thích và lập lịch mặc đồ hàng ngày.

---

## 1. Kiến trúc & Công nghệ

- **Mobile Framework:** Flutter `3.47+` & Dart `3.13+` (tương thích hoàn toàn Android vật lý & máy ảo).
- **Thiết kế UI/UX:** Hệ thống thiết kế **DailyFit Blue Glassmorphism** (bảng màu Royal Blue `#2563EB` & Arctic White `#F4F8FF`, hiệu ứng kính mờ `BackdropFilter`, phông chữ `Inter` chuẩn độ tương phản WCAG AA), đồng bộ với bản thiết kế trên **Google Stitch**.
- **5 Màn hình cốt lõi (`lib/screens/`):**
  1. **Trang chủ (`HomeScreen`):** Vị trí, thời tiết trực tiếp, lời khuyên phối đồ, bộ đồ nổi bật và CTA *"Phối đồ theo ý muốn"*.
  2. **Gợi ý (`OutfitScreen`):** Đề xuất phối đồ theo *Đi học, Đi làm, Đi chơi...*, làm mới biến thể và lưu yêu thích / lên lịch.
  3. **Tủ đồ (`WardrobeScreen` & `AddClothingScreen`):** Thêm ảnh trang phục từ điện thoại, phân loại danh mục, màu sắc, phong cách.
  4. **Lịch đồ (`CalendarScreen`):** Lên kế hoạch trang phục theo ngày và duyệt danh sách *Bộ đồ yêu thích*.
  5. **Hồ sơ (`ProfileScreen`):** Tuỳ chỉnh phong cách cá nhân, màu sắc yêu thích, thành phố thời tiết và kiểm tra trạng thái dịch vụ.
- **Tầng dữ liệu bền bỉ (`lib/services/`):**
  - Đồng bộ trực tiếp với **Backend API (.NET / SQL Server)** qua `BASE_URL` trong `.env`.
  - Tự động kích hoạt **Offline Fallback + Lưu trữ cục bộ (`SharedPreferences`) + Dữ liệu mẫu** khi máy chủ Backend chưa bật, đảm bảo ứng dụng luôn mượt mà trên điện thoại thật.
  - **Dịch vụ Thời tiết (`WeatherService`):** Hỗ trợ OpenWeatherMap (`WEATHER_API_KEY`) hoặc Open-Meteo trực tiếp không lộ khoá bí mật, kèm Mock Fallback khi mất mạng.
  - **Supabase Cloud (`ConfigUrl`):** Tầng cấu hình sẵn sàng trong `.env` để mở rộng xác thực/lưu trữ đám mây khi cần.

---

## 2. Cấu hình Biến Môi trường (`.env`)

File `.env` đã được cấu hình sẵn và đồng bộ chung trên Git cho cả nhóm (khai báo trong `pubspec.yaml` assets), nên các thành viên khi `git clone` / `git pull` về có thể chạy ngay mà không cần tạo lại thủ công:

```env
BASE_URL=https://differentaquakayak62.conveyor.cloud/api/
WEATHER_API_KEY=
SUPABASE_URL=
SUPABASE_ANON_KEY=
```
*(Khi đổi đường dẫn Conveyor hoặc chạy thử Backend qua IP LAN nội bộ, chỉ cần sửa giá trị `BASE_URL` trong file `.env`)*.

---

## 3. Hướng dẫn Mở Dự án, Cấu hình Android SDK & Chạy trên Điện thoại Android Thật

### Bước 1: Kiểm tra môi trường trên máy hiện tại
Trên máy của bạn đã có sẵn:
- **Flutter SDK:** `D:\flutter`
- **Android SDK:** `C:\Users\zudinh\AppData\Local\Android\sdk` (đã khai báo trong `android/local.properties`)

Cài đặt thư viện và kiểm tra mã nguồn từ Terminal trong **Antigravity IDE**:
```powershell
& "D:\flutter\bin\flutter.bat" pub get
& "D:\flutter\bin\flutter.bat" analyze
& "D:\flutter\bin\flutter.bat" test
```

### Bước 2: Bật Gỡ lỗi USB (USB Debugging) trên điện thoại Android thật
1. Trên điện thoại Android, mở **Cài đặt (Settings)** → **Giới thiệu về điện thoại (About phone)**.
2. Nhấn liên tục **7 lần** vào mục **Số bản dựng (Build number)** để bật *Tùy chọn nhà phát triển (Developer options)*.
3. Quay lại **Cài đặt** → **Hệ thống / Cài đặt bổ sung** → **Tùy chọn nhà phát triển**, bật **Gỡ lỗi USB (USB debugging)**.
4. Cắm cáp USB nối điện thoại với máy tính và nhấn **Cho phép (Allow)** trên hộp thoại xác nhận RSA của điện thoại.

### Bước 3: Kiểm tra kết nối thiết bị & Chạy trực tiếp lên điện thoại
Kiểm tra danh sách thiết bị đã nhận diện qua ADB / Flutter:
```powershell
& "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe" devices
& "D:\flutter\bin\flutter.bat" devices
```
Chạy ứng dụng trực tiếp lên điện thoại Android đang cắm cáp:
```powershell
& "D:\flutter\bin\flutter.bat" run
```

---

## 4. Hướng dẫn Mở bằng Android Studio & Xuất file cài đặt Debug APK

### Cách 1: Xuất nhanh file `app-debug.apk` bằng dòng lệnh (Khuyên dùng)
Tại thư mục gốc dự án, chạy lệnh:
```powershell
& "D:\flutter\bin\flutter.bat" build apk --debug
```
Hoặc chạy trực tiếp bằng **Gradle Wrapper** trong thư mục `android`:
```powershell
cd android
.\gradlew.bat assembleDebug
```
Sau khi hoàn tất, file cài đặt APK nằm tại:
`build\app\outputs\flutter-apk\app-debug.apk`

Bạn có thể chép file `app-debug.apk` này sang điện thoại hoặc cài thẳng qua ADB:
```powershell
& "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe" install -r build\app\outputs\flutter-apk\app-debug.apk
```

### Cách 2: Mở & Build bằng Android Studio
1. Mở **Android Studio** → chọn **Open** → trỏ tới thư mục `android` bên trong dự án (`...\DACN-Vinh-Frontend\DACN-Vinh-Frontend\android`) để sử dụng đầy đủ công cụ Gradle/SDK, hoặc mở thư mục gốc nếu đã cài plugin Flutter.
2. Kiểm tra **Tools → SDK Manager**: đảm bảo đã tích chọn **Android SDK Platform**, **Android SDK Build-Tools** và **Android SDK Platform-Tools**.
3. Để chạy lên điện thoại: chọn tên điện thoại của bạn trên thanh thiết bị phía trên rồi nhấn nút **Run (▶)**.
4. Để xuất file APK từ menu: chọn **Build → Build Bundle(s) / APK(s) → Build APK(s)**.
