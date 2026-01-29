import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'firebase_options.dart';
import 'injection_container.dart' as di;
import 'presentation/bloc/auth_cubit.dart';
import 'presentation/pages/login_page.dart';
import 'presentation/pages/register_page.dart';

void main() async {
  // 1. Đảm bảo các plugin hệ thống đã sẵn sàng
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Khởi tạo Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // 3. Khởi tạo Dependency Injection (GetIt)
  await di.init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => di.sl<AuthCubit>(),
      child: MaterialApp(
        title: 'Fintech Dashboard',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
        // Cung cấp AuthCubit toàn cục để các màn hình có thể sử dụng
        home: const LoginPage(),
        routes: {
          '/register': (context) => const RegisterPage(),
          '/dashboard': (context) =>
              const Scaffold(body: Center(child: Text("Dashboard"))),
        },
      ),
    );
  }
}
