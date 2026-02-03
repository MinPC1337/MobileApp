import '../../entities/user_entity.dart';
import '../../repositories/auth_repository.dart';

class RegisterUserUseCase {
  final AuthRepository repository;

  RegisterUserUseCase(this.repository);

  Future<UserEntity?> call(String email, String password, String name) async {
    // 1. Kiểm tra logic nghiệp vụ (vd: tên không được trống)
    if (name.isEmpty) throw Exception("Tên không được để trống");

    // 2. Gọi repository để thực hiện đăng ký
    return await repository.signUp(
      email: email,
      password: password,
      name: name,
    );
  }
}
