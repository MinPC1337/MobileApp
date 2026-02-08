import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth_state.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/usecases/auth/sign_in_usecase.dart';
import '../../domain/usecases/auth/register_user_usecase.dart';
import '../../domain/usecases/auth/get_current_user_usecase.dart';
import '../../domain/usecases/auth/sign_out_usecase.dart';
import '../../domain/usecases/auth/get_auth_state_stream_usecase.dart';
import '../../domain/usecases/auth/send_password_reset_email_usecase.dart';
import '../../domain/usecases/auth/send_email_verification_usecase.dart';
import '../../domain/repositories/transaction_repository.dart';

class AuthCubit extends Cubit<AuthState> {
  final RegisterUserUseCase registerUserUseCase;
  final SignInUseCase signInUseCase;
  final GetCurrentUserUseCase getCurrentUserUseCase;
  final SignOutUseCase signOutUseCase;
  final GetAuthStateStreamUseCase getAuthStateStreamUseCase;
  final SendPasswordResetEmailUseCase sendPasswordResetEmailUseCase;
  final SendEmailVerificationUseCase sendEmailVerificationUseCase;
  final TransactionRepository transactionRepository;

  StreamSubscription<UserEntity?>? _authSubscription;

  AuthCubit({
    required this.registerUserUseCase,
    required this.signInUseCase,
    required this.getCurrentUserUseCase,
    required this.signOutUseCase,
    required this.getAuthStateStreamUseCase,
    required this.sendPasswordResetEmailUseCase,
    required this.sendEmailVerificationUseCase,
    required this.transactionRepository,
  }) : super(AuthInitial());

  // Hàm kiểm tra trạng thái đăng nhập khi ứng dụng khởi động
  Future<void> checkAuthStatus() async {
    // Hủy đăng ký cũ nếu có để tránh rò rỉ bộ nhớ
    await _authSubscription?.cancel();

    // Lắng nghe luồng sự kiện thay đổi trạng thái đăng nhập (Login/Logout/Khôi phục session)
    _authSubscription = getAuthStateStreamUseCase().listen((user) async {
      if (user != null) {
        // Đồng bộ các giao dịch đang chờ khi khởi động app
        await transactionRepository.syncPendingTransactions(userId: user.id);
        if (!isClosed) emit(AuthSuccess(user));
      } else {
        if (!isClosed) emit(AuthUnauthenticated());
      }
    });
  }

  // Hàm đăng ký
  Future<void> register(String email, String password, String name) async {
    emit(AuthLoading());
    try {
      final user = await registerUserUseCase(email, password, name);
      if (user != null) {
        // Gửi email xác thực
        await sendEmailVerificationUseCase();
        // Đăng xuất ngay để người dùng phải đăng nhập lại sau khi xác thực
        await signOutUseCase();
        emit(AuthNeedsVerification());
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
      } else if (e.code == 'network-request-failed') {
        message = 'Cần có kết nối internet để đăng ký.';
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
        if (user.isEmailVerified) {
          // Đồng bộ các giao dịch đang chờ sau khi đăng nhập thành công
          await transactionRepository.syncPendingTransactions(userId: user.id);
          emit(AuthSuccess(user));
        } else {
          // Nếu chưa xác thực email, đăng xuất và báo lỗi
          await signOutUseCase();
          // Chuyển sang trạng thái cần xác thực để UI điều hướng sang trang thông báo
          emit(AuthNeedsVerification());
        }
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
      } else if (e.code == 'network-request-failed') {
        message = 'Cần có kết nối internet để đăng nhập.';
      }
      emit(AuthFailure(message));
    } catch (e) {
      final errorMessage = e.toString().replaceFirst('Exception: ', '');
      emit(AuthFailure(errorMessage));
    }
  }

  // Hàm quên mật khẩu
  Future<void> resetPassword(String email) async {
    emit(AuthLoading());
    try {
      await sendPasswordResetEmailUseCase(email);
      emit(AuthPasswordResetSent());
    } on FirebaseAuthException catch (e) {
      String message = "Không thể gửi email khôi phục.";
      if (e.code == 'user-not-found') {
        message = 'Email này chưa được đăng ký.';
      } else if (e.code == 'invalid-email') {
        message = 'Định dạng email không hợp lệ.';
      } else if (e.code == 'too-many-requests') {
        message = 'Bạn đã gửi quá nhiều yêu cầu. Vui lòng thử lại sau.';
      } else if (e.code == 'network-request-failed') {
        message = 'Cần có kết nối internet để gửi yêu cầu.';
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

  // Hàm xóa dữ liệu local
  Future<void> clearLocalData() async {
    try {
      await transactionRepository.clearLocalData();
    } catch (e) {
      // Xử lý lỗi nếu cần thiết
    }
  }

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    return super.close();
  }
}
