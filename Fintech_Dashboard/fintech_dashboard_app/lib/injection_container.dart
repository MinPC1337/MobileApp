import 'package:get_it/get_it.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'data/data_sources/local/database_helper.dart';
import 'data/repositories/transaction_repository_impl.dart';
import 'domain/repositories/transaction_repository.dart';
//import 'domain/usecases/add_transaction_usecase.dart'; // Giả định bạn đã tạo UseCase

final sl = GetIt.instance; // sl: Service Locator

Future<void> init() async {
  //! 1. Features - Transactions (Lớp Domain & Data)

  // Use cases
  //sl.registerLazySingleton(() => AddTransactionUseCase(sl()));

  // Repository
  // Khi ứng dụng yêu cầu TransactionRepository, GetIt sẽ trả về TransactionRepositoryImpl
  sl.registerLazySingleton<TransactionRepository>(
    () => TransactionRepositoryImpl(dbHelper: sl(), firestore: sl()),
  );

  //! 2. Core (Các thành phần hệ thống)
  // Đăng ký DatabaseHelper
  sl.registerLazySingleton(() => DatabaseHelper.instance);

  //! 3. External (Các thư viện bên ngoài)
  final auth = FirebaseAuth.instance;
  final firestore = FirebaseFirestore.instance;

  sl.registerLazySingleton(() => auth);
  sl.registerLazySingleton(() => firestore);
}
