import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/auth_cubit.dart';
import '../bloc/auth_state.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Đăng nhập")),
      body: BlocConsumer<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is AuthFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          return Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: "Email"),
                ),
                TextField(
                  controller: _passwordController,
                  decoration: const InputDecoration(labelText: "Mật khẩu"),
                  obscureText: true,
                ),
                const SizedBox(height: 20),
                state is AuthLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: () => context.read<AuthCubit>().signIn(
                          _emailController.text,
                          _passwordController.text,
                        ),
                        child: const Text("ĐĂNG NHẬP"),
                      ),
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/register'),
                  child: const Text("Chưa có tài khoản? Đăng ký ngay"),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
