import 'package:firebase_auth/firebase_auth.dart';
import '../../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<UserModel> signUp(String email, String password, String name);
  Future<UserModel> signIn(String email, String password);
  Future<void> signOut();
  Future<UserModel?> getCurrentUser();
  Future<void> sendPasswordResetEmail(String email);
  Future<void> sendEmailVerification();
  Stream<UserModel?> get authStateChanges;
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final FirebaseAuth firebaseAuth;

  AuthRemoteDataSourceImpl(this.firebaseAuth);

  // Hàm tiện ích để chuyển đổi Firebase User sang UserModel
  UserModel _mapFirebaseUserToModel(User user) {
    return UserModel(
      id: user.uid,
      email: user.email ?? '',
      displayName: user.displayName ?? '',
      currency: 'VND',
      createdAt: DateTime.now(),
      isEmailVerified: user.emailVerified,
    );
  }

  @override
  Future<UserModel> signUp(String email, String password, String name) async {
    final credential = await firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = credential.user!;

    // Cập nhật tên hiển thị ngay sau khi tạo
    await user.updateDisplayName(name);

    // Trả về model với tên đã cập nhật
    return _mapFirebaseUserToModel(user).copyWith(displayName: name);
  }

  @override
  Future<UserModel> signIn(String email, String password) async {
    final credential = await firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return _mapFirebaseUserToModel(credential.user!);
  }

  @override
  Future<void> signOut() async {
    await firebaseAuth.signOut();
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    final user = firebaseAuth.currentUser;
    if (user != null) {
      return _mapFirebaseUserToModel(user);
    }
    return null;
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    await firebaseAuth.setLanguageCode(
      'vi',
    ); // Thiết lập ngôn ngữ tiếng Việt cho email
    await firebaseAuth.sendPasswordResetEmail(email: email);
  }

  @override
  Future<void> sendEmailVerification() async {
    final user = firebaseAuth.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
    }
  }

  @override
  Stream<UserModel?> get authStateChanges {
    return firebaseAuth.authStateChanges().map((user) {
      if (user == null) return null;
      return _mapFirebaseUserToModel(user);
    });
  }
}
