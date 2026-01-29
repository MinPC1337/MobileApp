import 'package:get_it/get_it.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'data/data_sources/local/database_helper.dart';
import 'data/repositories/auth_repository_impl.dart';
import 'data/repositories/transaction_repository_impl.dart';
import 'domain/repositories/auth_repository.dart';
import 'domain/repositories/transaction_repository.dart';
import 'domain/usecases/register_user_usecase.dart';
import 'domain/usecases/sign_in_usecase.dart';
import 'domain/usecases/get_current_user_usecase.dart';
import 'domain/usecases/update_transaction_usecase.dart';
import 'domain/usecases/add_transaction_usecase.dart';
import 'domain/usecases/delete_transaction_usecase.dart';
import 'domain/usecases/sign_out_usecase.dart';
import 'presentation/bloc/auth_cubit.dart';
import 'domain/usecases/get_transactions_usecase.dart';
import 'presentation/bloc/dashboard_cubit.dart';
import 'presentation/bloc/transaction_form_cubit.dart';

final sl = GetIt.instance; // sl: Service Locator

Future<void> init() async {
  // =================================================================
  //! Features
  // =================================================================

  // -- Auth Feature --
  // Bloc - Sử dụng registerFactory cho Cubit/Bloc để tạo mới mỗi khi cần (tránh giữ state cũ)
  sl.registerFactory(
    () => AuthCubit(
      registerUserUseCase: sl(),
      signInUseCase: sl(),
      getCurrentUserUseCase: sl(),
      signOutUseCase: sl(),
      transactionRepository: sl(),
    ),
  );
  // Đăng ký DashboardCubit
  sl.registerFactory(
    () => DashboardCubit(
      getTransactionsUseCase: sl(),
      deleteTransactionUseCase: sl(),
    ),
  );
  // Đăng ký TransactionFormCubit
  sl.registerFactory(
    () => TransactionFormCubit(
      addTransactionUseCase: sl(),
      updateTransactionUseCase: sl(),
    ),
  );

  // Use cases
  sl.registerLazySingleton(() => RegisterUserUseCase(sl()));
  sl.registerLazySingleton(() => SignInUseCase(sl()));
  sl.registerLazySingleton(() => GetCurrentUserUseCase(sl()));
  sl.registerLazySingleton(() => SignOutUseCase(sl()));
  sl.registerLazySingleton(() => UpdateTransactionUseCase(sl()));
  sl.registerLazySingleton(() => AddTransactionUseCase(sl()));
  sl.registerLazySingleton(() => DeleteTransactionUseCase(sl()));
  sl.registerLazySingleton(() => GetTransactionsUseCase(sl()));
  // Repository
  sl.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(sl()));

  // -- Transaction Feature --
  // Khi ứng dụng yêu cầu TransactionRepository, GetIt sẽ trả về TransactionRepositoryImpl
  sl.registerLazySingleton<TransactionRepository>(
    () => TransactionRepositoryImpl(dbHelper: sl(), firestore: sl()),
  );

  // =================================================================
  //! Core & External
  // =================================================================
  sl.registerLazySingleton(() => DatabaseHelper.instance);
  sl.registerLazySingleton(() => FirebaseAuth.instance);
  sl.registerLazySingleton(() => FirebaseFirestore.instance);
}
