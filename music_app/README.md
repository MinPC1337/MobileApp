# 🎵 Music App - Flutter Project

Ứng dụng nghe nhạc hiện đại được xây dựng bằng **Flutter**, tập trung vào giao diện người dùng mượt mà và khả năng quản lý thư viện âm nhạc hiệu quả.

---

## ✨ Tính năng nổi bật

* **Phát nhạc (Audio Playback):** Hỗ trợ đầy đủ các tính năng: Phát, Tạm dừng, Chuyển bài, Shuffle (ngẫu nhiên) và Repeat (lặp lại).
* **Quản lý thư viện:** Lấy dữ liệu từ internet.
* **Giao diện thân thiện:** Giao diện đơn giản thân thiện với người dùng.

## 🛠 Công nghệ & Thư viện sử dụng

* **Core:** Flutter SDK & Dart.
* **Audio Engine:** `just_audio` hoặc `audioplayers` (Xử lý phát nhạc chất lượng cao).
* **State Management:** `Provider` / `BLoC` (Giúp đồng bộ hóa trạng thái ứng dụng).
* **Permissions:** `permission_handler` (Yêu cầu quyền truy cập bộ nhớ trên Android/iOS).
* **Metadata:** `on_audio_query` (Lấy thông tin bài hát, nghệ sĩ và ảnh bìa).

## 🏗 Cấu trúc dự án

Dự án được tổ chức theo mô hình phân lớp rõ ràng:
- `lib/ui/`: Chứa các màn hình (UI) và các Widget tùy chỉnh.
- `lib/data/`: Xử lý việc quét file và lấy dữ liệu.

## 🚀 Hướng dẫn cài đặt

### 1. Yêu cầu hệ thống
* Đã cài đặt **Flutter SDK** (phiên bản 3.0.0 trở lên).
* Đã cài đặt **Android Studio** hoặc **VS Code**.

### 2. Cài đặt và Chạy
Mở terminal tại thư mục dự án và chạy các lệnh sau:

```bash
# Lấy các thư viện cần thiết
flutter pub get

# Kiểm tra kết nối thiết bị (Emulator hoặc Máy thật)
flutter devices

# Chạy ứng dụng ở chế độ Debug
flutter run
