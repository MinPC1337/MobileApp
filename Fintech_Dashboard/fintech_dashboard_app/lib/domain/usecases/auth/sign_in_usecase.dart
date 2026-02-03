import '../../entities/user_entity.dart';
import '../../repositories/auth_repository.dart';

class SignInUseCase {
  final AuthRepository repository;

  SignInUseCase(this.repository);

  Future<UserEntity?> call(String email, String password) async {
    // Ràng buộc nghiệp vụ cơ bản
    if (email.isEmpty || password.isEmpty) {
      throw Exception("Email và mật khẩu không được để trống");
    }
    return await repository.signIn(email: email, password: password);
  }
}
