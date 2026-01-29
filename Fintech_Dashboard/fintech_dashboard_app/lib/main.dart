import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'firebase_options.dart';
import 'injection_container.dart' as di;
import 'presentation/bloc/auth_cubit.dart';
// import 'presentation/bloc/transaction_form_cubit.dart';
import 'presentation/bloc/dashboard_cubit.dart';
import 'presentation/bloc/auth_state.dart';
import 'presentation/pages/dashboard_page.dart';
// import 'presentation/pages/add_edit_transaction_page.dart';
import 'presentation/pages/login_page.dart';
import 'presentation/pages/register_page.dart';

void main() async {
  // 1. Đảm bảo các plugin hệ thống đã sẵn sàng
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Khởi tạo Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true, // Firestore sẽ tự cache thêm 1 lớp nữa
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
          // Route dashboard giờ được AuthGate xử lý,
          // nhưng vẫn giữ lại để phòng trường hợp điều hướng tường minh.
          '/dashboard': (context) => const DashboardPage(),
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
          return BlocProvider(
            create: (_) => di.sl<DashboardCubit>()..loadDashboardData(),
            child: const DashboardPage(),
          );
        } else if (state is AuthUnauthenticated || state is AuthFailure) {
          // Nếu chưa xác thực, hiển thị LoginPage
          return const LoginPage();
        } else {
          // Trong lúc kiểm tra (AuthInitial, AuthLoading), hiển thị màn hình chờ
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
      },
    );
  }
}
