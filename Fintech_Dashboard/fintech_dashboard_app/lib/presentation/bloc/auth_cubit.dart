import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth_state.dart';
import '../../domain/usecases/sign_in_usecase.dart';
import '../../domain/usecases/register_user_usecase.dart';

class AuthCubit extends Cubit<AuthState> {
  final RegisterUserUseCase registerUserUseCase;
  final SignInUseCase signInUseCase;

  AuthCubit({required this.registerUserUseCase, required this.signInUseCase})
    : super(AuthInitial());

  // Hàm đăng ký
  Future<void> register(String email, String password, String name) async {
    emit(AuthLoading());
    try {
      final user = await registerUserUseCase(email, password, name);
      if (user != null) {
        emit(AuthSuccess(user));
      } else {
        emit(AuthFailure("Đăng ký không thành công"));
      }
    } on FirebaseAuthException catch (e) {
      String message = "Đã có lỗi xảy ra. Vui lòng thử lại.";
      if (e.code == 'weak-password') {
        message = 'Mật khẩu quá yếu.';
      } else if (e.code == 'email-already-in-use') {
        message = 'Email này đã được sử dụng.';
      } else if (e.code == 'invalid-email') {
        message = 'Địa chỉ email không hợp lệ.';
      }
      emit(AuthFailure(message));
    } catch (e) {
      // Bắt các lỗi chung khác từ UseCase hoặc Repository
      // Xóa "Exception: " khỏi thông báo lỗi
      final errorMessage = e.toString().replaceFirst('Exception: ', '');
      emit(AuthFailure(errorMessage));
    }
  }

  // Hàm đăng nhập
  Future<void> signIn(String email, String password) async {
    emit(AuthLoading());
    try {
      final user = await signInUseCase(email, password);
      if (user != null) {
        emit(AuthSuccess(user));
      } else {
        emit(
          AuthFailure("Đăng nhập thất bại. Vui lòng kiểm tra lại thông tin."),
        );
      }
    } on FirebaseAuthException {
      emit(AuthFailure("Email hoặc mật khẩu không đúng."));
    } catch (e) {
      final errorMessage = e.toString().replaceFirst('Exception: ', '');
      emit(AuthFailure(errorMessage));
    }
  }
}
