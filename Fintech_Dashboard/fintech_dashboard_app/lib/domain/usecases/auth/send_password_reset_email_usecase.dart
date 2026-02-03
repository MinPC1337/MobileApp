import '../../repositories/auth_repository.dart';

class SendPasswordResetEmailUseCase {
  final AuthRepository repository;

  SendPasswordResetEmailUseCase(this.repository);

  Future<void> call(String email) async {
    if (email.isEmpty) {
      throw Exception("Vui lòng nhập email để khôi phục mật khẩu");
    }
    return await repository.sendPasswordResetEmail(email: email);
  }
}
