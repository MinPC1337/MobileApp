import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/auth_cubit.dart';
import '../bloc/auth_state.dart';
import '../bloc/setting/settings_cubit.dart';
import '../bloc/setting/settings_state.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    // Lấy trạng thái cài đặt hiện tại
    final settingsState = context.watch<SettingsCubit>().state;
    final isVi = settingsState.locale.languageCode == 'vi';

    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        return ListView(
          children: [
            _buildAccountSection(context, state, isVi),
            const Divider(thickness: 1, height: 32),
            _buildDataSection(context, isVi),
            const Divider(thickness: 1, height: 32),
            _buildConfigSection(context, settingsState, isVi),
          ],
        );
      },
    );
  }

  // 1. Nhóm chức năng Tài khoản
  Widget _buildAccountSection(
    BuildContext context,
    AuthState state,
    bool isVi,
  ) {
    if (state is! AuthSuccess) {
      return const SizedBox.shrink();
    }
    final user = state.user;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            isVi ? "Tài khoản" : "Account",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
          ),
        ),
        ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.blue.shade100,
            child: Text(
              user.displayName.isNotEmpty
                  ? user.displayName[0].toUpperCase()
                  : "U",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
          ),
          title: Text(
            user.displayName,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(user.email),
          trailing: user.isEmailVerified
              ? const Tooltip(
                  message: "Verified",
                  child: Icon(Icons.verified, color: Colors.green),
                )
              : const Tooltip(
                  message: "Unverified",
                  child: Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.orange,
                  ),
                ),
        ),
        ListTile(
          leading: const Icon(Icons.logout, color: Colors.red),
          title: Text(
            isVi ? "Đăng xuất" : "Logout",
            style: TextStyle(color: Colors.red, fontWeight: FontWeight.w500),
          ),
          onTap: () => _showLogoutDialog(context, isVi),
        ),
      ],
    );
  }

  // 2. Nhóm chức năng Dữ liệu
  Widget _buildDataSection(BuildContext context, bool isVi) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Text(
            isVi ? "Dữ liệu" : "Data",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.delete_outline),
          title: Text(isVi ? "Xóa dữ liệu local" : "Clear local data"),
          subtitle: Text(
            isVi
                ? "Xóa bộ nhớ đệm trên thiết bị này"
                : "Clear cache on this device",
          ),
          onTap: () => _showClearDataDialog(context, isVi),
        ),
      ],
    );
  }

  // 3. Nhóm chức năng Cấu hình ứng dụng
  Widget _buildConfigSection(
    BuildContext context,
    SettingsState settingsState,
    bool isVi,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Text(
            isVi ? "Cấu hình ứng dụng" : "App Configuration",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
          ),
        ),
        SwitchListTile(
          secondary: const Icon(Icons.dark_mode_outlined),
          title: Text(isVi ? "Chế độ tối (Dark Mode)" : "Dark Mode"),
          value: settingsState.themeMode == ThemeMode.dark,
          onChanged: (val) {
            context.read<SettingsCubit>().toggleTheme(val);
          },
        ),
        ListTile(
          leading: const Icon(Icons.language),
          title: Text(isVi ? "Ngôn ngữ" : "Language"),
          trailing: DropdownButton<String>(
            value: settingsState.locale.languageCode,
            underline: Container(),
            items: const [
              DropdownMenuItem(value: 'vi', child: Text("Tiếng Việt")),
              DropdownMenuItem(value: 'en', child: Text("English")),
            ],
            onChanged: (val) {
              if (val != null) {
                context.read<SettingsCubit>().changeLanguage(val);
              }
            },
          ),
        ),
      ],
    );
  }

  void _showLogoutDialog(BuildContext context, bool isVi) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isVi ? "Đăng xuất" : "Logout"),
        content: Text(
          isVi
              ? "Bạn có chắc chắn muốn đăng xuất không?"
              : "Are you sure you want to logout?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(isVi ? "Hủy" : "Cancel"),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              context.read<AuthCubit>().signOut();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(isVi ? "Đăng xuất" : "Logout"),
          ),
        ],
      ),
    );
  }

  void _showClearDataDialog(BuildContext context, bool isVi) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isVi ? "Xóa dữ liệu local" : "Clear local data"),
        content: Text(
          isVi
              ? "Hành động này sẽ xóa dữ liệu được lưu trên máy. Dữ liệu đã đồng bộ lên mây sẽ không bị mất. Bạn có muốn tiếp tục?"
              : "This action will clear data stored on this device. Synced data on cloud will not be lost. Continue?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(isVi ? "Hủy" : "Cancel"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await context.read<AuthCubit>().clearLocalData();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      isVi ? "Đã xóa dữ liệu local" : "Local data cleared",
                    ),
                  ),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(isVi ? "Xóa" : "Clear"),
          ),
        ],
      ),
    );
  }
}
