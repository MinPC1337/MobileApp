import '../entities/user_entity.dart';

abstract class AuthRepository {
  // Đăng ký tài khoản mới
  Future<UserEntity?> signUp({
    required String email,
    required String password,
    required String name,
  });

  // Đăng nhập
  Future<UserEntity?> signIn({required String email, required String password});

  // Đăng xuất
  Future<void> signOut();

  // Lấy thông tin người dùng hiện tại đang đăng nhập
  Future<UserEntity?> getCurrentUser();

  // Gửi email khôi phục mật khẩu
  Future<void> sendPasswordResetEmail({required String email});

  // Kiểm tra trạng thái đăng nhập (để quyết định mở màn hình Login hay Dashboard)
  Stream<UserEntity?> get userSession;
}
