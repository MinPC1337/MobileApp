import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth_state.dart';
import '../../domain/usecases/sign_in_usecase.dart';
import '../../domain/usecases/register_user_usecase.dart';
import '../../domain/usecases/get_current_user_usecase.dart';
import '../../domain/usecases/seed_transactions_usecase.dart';
import '../../domain/usecases/sign_out_usecase.dart';
import '../../domain/repositories/transaction_repository.dart';

class AuthCubit extends Cubit<AuthState> {
  final RegisterUserUseCase registerUserUseCase;
  final SignInUseCase signInUseCase;
  final GetCurrentUserUseCase getCurrentUserUseCase;
  final SeedTransactionsUseCase seedTransactionsUseCase;
  final SignOutUseCase signOutUseCase;
  final TransactionRepository transactionRepository;

  AuthCubit({
    required this.registerUserUseCase,
    required this.signInUseCase,
    required this.getCurrentUserUseCase,
    required this.seedTransactionsUseCase,
    required this.signOutUseCase,
    required this.transactionRepository,
  }) : super(AuthInitial());

  // Hàm kiểm tra trạng thái đăng nhập khi ứng dụng khởi động
  Future<void> checkAuthStatus() async {
    try {
      final user = await getCurrentUserUseCase();
      if (user != null) {
        emit(AuthSuccess(user));
      } else {
        emit(AuthUnauthenticated());
      }
    } catch (e) {
      emit(AuthUnauthenticated());
    }
  }

  // Hàm đăng ký
  Future<void> register(String email, String password, String name) async {
    emit(AuthLoading());
    try {
      final user = await registerUserUseCase(email, password, name);
      if (user != null) {
        // Tự động thêm dữ liệu mẫu cho người dùng mới
        await seedTransactionsUseCase(user.id);
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
    } on FirebaseAuthException catch (e) {
      String message = "Email hoặc mật khẩu không đúng.";
      if (e.code == 'user-not-found') {
        message = 'Tài khoản không tồn tại.';
      } else if (e.code == 'wrong-password') {
        message = 'Mật khẩu không chính xác.';
      } else if (e.code == 'invalid-email') {
        message = 'Định dạng email không hợp lệ.';
      } else if (e.code == 'too-many-requests') {
        message = 'Quá nhiều lần thử đăng nhập. Vui lòng thử lại sau.';
      }
      emit(AuthFailure(message));
    } catch (e) {
      final errorMessage = e.toString().replaceFirst('Exception: ', '');
      emit(AuthFailure(errorMessage));
    }
  }

  // Hàm đăng xuất
  Future<void> signOut() async {
    try {
      await signOutUseCase();
      emit(AuthUnauthenticated());
    } catch (e) {
      emit(AuthFailure("Đăng xuất thất bại"));
    }
  }
}
