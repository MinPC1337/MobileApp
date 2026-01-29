import 'package:firebase_auth/firebase_auth.dart';
import 'package:sqflite/sqflite.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../data_sources/local/database_helper.dart';
import '../models/user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final FirebaseAuth _firebaseAuth;
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  AuthRepositoryImpl(this._firebaseAuth);

  @override
  Future<UserEntity?> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      // 1. Tạo trên Firebase
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        await credential.user!.updateDisplayName(name);

        final userModel = UserModel(
          id: credential.user!.uid,
          email: email,
          displayName: name,
          currency: 'VND',
          createdAt: DateTime.now(),
        );

        // 2. Lưu xuống SQLite để dùng offline
        final db = await _dbHelper.database;
        await db.insert(
          'users',
          userModel.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );

        return userModel;
      }
    } catch (e) {
      throw Exception("Lỗi đăng ký: ${e.toString()}");
    }
    return null;
  }

  @override
  Future<UserEntity?> signIn({
    required String email,
    required String password,
  }) async {
    final credential = await _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    if (credential.user != null) {
      // Lấy từ SQLite hoặc tạo model mới từ Firebase User
      return UserModel(
        id: credential.user!.uid,
        email: credential.user!.email!,
        displayName: credential.user!.displayName ?? '',
        currency: 'VND',
        createdAt: DateTime.now(),
      );
    }
    return null;
  }

  @override
  Future<void> signOut() async => await _firebaseAuth.signOut();

  @override
  Future<UserEntity?> getCurrentUser() async {
    final firebaseUser = _firebaseAuth.currentUser;
    if (firebaseUser == null) return null;

    // Ưu tiên lấy thông tin từ SQLite để có đầy đủ thuộc tính (currency, v.v.)
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [firebaseUser.uid],
    );

    if (maps.isNotEmpty) {
      return UserModel.fromMap(maps.first);
    }
    return null;
  }

  @override
  Stream<UserEntity?> get userSession {
    return _firebaseAuth.authStateChanges().map((firebaseUser) {
      if (firebaseUser == null) return null;
      return UserEntity(
        id: firebaseUser.uid,
        email: firebaseUser.email!,
        displayName: firebaseUser.displayName ?? '',
        currency: 'VND',
        createdAt: DateTime.now(),
      );
    });
  }
}
