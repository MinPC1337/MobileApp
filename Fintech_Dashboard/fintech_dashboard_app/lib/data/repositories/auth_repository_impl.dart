import 'package:firebase_auth/firebase_auth.dart';
import 'package:sqflite/sqflite.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../data_sources/local/database_helper.dart';
import '../data_sources/remote/auth_remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final DatabaseHelper dbHelper;

  AuthRepositoryImpl({required this.remoteDataSource, required this.dbHelper});

  @override
  Future<UserEntity?> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      // 1. Tạo trên Firebase thông qua RemoteDataSource
      final userModel = await remoteDataSource.signUp(email, password, name);

      // 2. Lưu xuống SQLite để dùng offline
      final db = await dbHelper.database;
      await db.insert(
        'users',
        userModel.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      return userModel;
    } on FirebaseAuthException {
      rethrow; // Ném lại lỗi Firebase để Cubit xử lý (vd: mất mạng, email trùng)
    } catch (e) {
      throw Exception("Lỗi đăng ký: ${e.toString()}");
    }
  }

  @override
  Future<UserEntity?> signIn({
    required String email,
    required String password,
  }) async {
    // Gọi RemoteDataSource để đăng nhập
    return await remoteDataSource.signIn(email, password);
  }

  @override
  Future<void> signOut() async {
    await remoteDataSource.signOut();
  }

  @override
  Future<UserEntity?> getCurrentUser() async {
    // Lấy user từ Remote (Firebase)
    final remoteUser = await remoteDataSource.getCurrentUser();
    if (remoteUser == null) return null;

    // Ưu tiên lấy thông tin từ SQLite để có đầy đủ thuộc tính (currency, v.v.)
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [remoteUser.id],
    );

    if (maps.isNotEmpty) {
      // Nếu có trong DB local thì trả về (ưu tiên)
      // Có thể thêm logic cập nhật lại từ remoteUser nếu cần
      return remoteUser; // Hoặc UserModel.fromMap(maps.first)
    }
    return remoteUser;
  }

  @override
  Stream<UserEntity?> get userSession {
    return remoteDataSource.authStateChanges;
  }
}
