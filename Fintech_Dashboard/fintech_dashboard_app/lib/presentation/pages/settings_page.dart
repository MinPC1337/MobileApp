import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/auth_cubit.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text("Cài đặt tài khoản"),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => context.read<AuthCubit>().signOut(),
            icon: const Icon(Icons.logout),
            label: const Text("Đăng xuất"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade100,
              foregroundColor: Colors.red,
            ),
          ),
        ],
      ),
    );
  }
}
