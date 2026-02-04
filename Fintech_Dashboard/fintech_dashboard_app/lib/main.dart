import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'firebase_options.dart';
import 'injection_container.dart' as di;
import 'presentation/bloc/auth_cubit.dart';
import 'presentation/bloc/dashboard_cubit.dart';
import 'presentation/bloc/auth_state.dart';
import 'presentation/pages/dashboard_page.dart';
import 'domain/usecases/transactions/get_transactions_usecase.dart';
import 'domain/usecases/transactions/delete_transaction_usecase.dart';
import 'presentation/pages/login_page.dart';
import 'presentation/pages/register_page.dart';
import 'presentation/pages/forgot_password_page.dart';
import 'presentation/pages/email_verification_page.dart';
import 'presentation/bloc/budget/budget_cubit.dart';

void main() async {
  // 1. Đảm bảo các plugin hệ thống đã sẵn sàng
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Khởi tạo Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
  );
  // 3. Khởi tạo Dependency Injection (GetIt)
  await di.init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      // Kích hoạt việc kiểm tra trạng thái đăng nhập ngay khi Cubit được tạo
      create: (_) => di.sl<AuthCubit>()..checkAuthStatus(),
      child: MaterialApp(
        title: 'Fintech Dashboard',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
        // AuthGate sẽ quyết định trang nào được hiển thị dựa trên AuthState
        home: const AuthGate(),
        routes: {
          '/register': (context) => const RegisterPage(),
          '/dashboard': (context) => const DashboardPage(),
          '/forgot_password': (context) => const ForgotPasswordPage(),
          '/verify_email': (context) => const EmailVerificationPage(),
        },
      ),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        if (state is AuthSuccess) {
          // Nếu đã xác thực, cung cấp DashboardCubit và hiển thị DashboardPage
          return MultiBlocProvider(
            providers: [
              BlocProvider(
                create: (_) => DashboardCubit(
                  getTransactionsUseCase: di.sl<GetTransactionsUseCase>(),
                  deleteTransactionUseCase: di.sl<DeleteTransactionUseCase>(),
                  userId: state.user.id,
                )..loadDashboardData(),
              ),
              BlocProvider(
                create: (_) =>
                    di.sl<BudgetCubit>(param1: state.user.id)..loadBudgetData(),
              ),
            ],
            child: const DashboardPage(),
          );
        } else if (state is AuthInitial) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        } else {
          return const LoginPage();
        }
      },
    );
  }
}
