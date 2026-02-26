// ignore_for_file: deprecated_member_use

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import '../../../domain/entities/transaction_entity.dart';
import '../../bloc/auth/auth_cubit.dart';
import '../../bloc/auth/auth_state.dart';
import '../../bloc/dashboard/dashboard_cubit.dart';
import '../../bloc/setting/settings_cubit.dart';
import '../../bloc/setting/settings_state.dart';

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
      builder: (context, authState) {
        if (authState is! AuthSuccess) {
          // Hiển thị một widget trống hoặc loading nếu chưa đăng nhập thành công
          return const Center(child: CircularProgressIndicator());
        }
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: [
            _buildSectionCard(
              context: context,
              title: isVi ? "Tài khoản" : "Account",
              children: _buildAccountItems(context, authState, isVi),
            ),
            const SizedBox(height: 24),
            _buildSectionCard(
              context: context,
              title: isVi ? "Dữ liệu" : "Data",
              children: _buildDataItems(context, isVi),
            ),
            const SizedBox(height: 24),
            _buildSectionCard(
              context: context,
              title: isVi ? "Cấu hình ứng dụng" : "App Configuration",
              children: _buildConfigItems(context, settingsState, isVi),
            ),
            const SizedBox(height: 24),
            _buildSectionCard(
              context: context,
              title: isVi ? "Thông tin" : "Information",
              children: [
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  leading: const Icon(Icons.info_outline),
                  title: Text(isVi ? "Giới thiệu ứng dụng" : "About App"),
                  onTap: () => _showAppAboutDialog(context),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  // Helper widget để tạo một card cho mỗi section
  Widget _buildSectionCard({
    required BuildContext context,
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 16, 8, 12),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: children.length,
              itemBuilder: (context, index) => children[index],
              separatorBuilder: (context, index) => Divider(
                height: 1,
                indent: 72, // Căn lề cho divider
                color: Theme.of(context).dividerColor.withOpacity(0.3),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // 1. Các mục trong nhóm Tài khoản
  List<Widget> _buildAccountItems(
    BuildContext context,
    AuthSuccess state,
    bool isVi,
  ) {
    final user = state.user;

    return [
      ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 10,
        ),
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: Text(
            user.displayName.isNotEmpty
                ? user.displayName[0].toUpperCase()
                : "U",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
        ),
        title: Text(
          user.displayName,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Text(user.email),
        trailing: user.isEmailVerified
            ? Tooltip(
                message: isVi ? "Đã xác thực" : "Verified",
                child: const Icon(Icons.verified, color: Colors.green),
              )
            : Tooltip(
                message: isVi ? "Chưa xác thực" : "Unverified",
                child: const Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.orange,
                ),
              ),
      ),
      ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: const Icon(Icons.logout, color: Colors.red),
        title: Text(
          isVi ? "Đăng xuất" : "Logout",
          style: const TextStyle(
            color: Colors.red,
            fontWeight: FontWeight.w500,
          ),
        ),
        onTap: () => _showLogoutDialog(context, isVi),
      ),
    ];
  }

  // 2. Các mục trong nhóm Dữ liệu
  List<Widget> _buildDataItems(BuildContext context, bool isVi) {
    return [
      ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: const Icon(Icons.upload_file, color: Colors.green),
        title: Text(isVi ? "Xuất dữ liệu ra Excel" : "Export data to Excel"),
        subtitle: Text(
          isVi
              ? "Lưu toàn bộ giao dịch vào file .xlsx"
              : "Save all transactions to an .xlsx file",
        ),
        onTap: () {
          final transactions = context
              .read<DashboardCubit>()
              .state
              .transactions;
          if (transactions.isNotEmpty) {
            _exportToExcel(transactions, isVi);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  isVi ? "Không có dữ liệu để xuất" : "No data to export",
                ),
              ),
            );
          }
        },
      ),
      ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
        title: Text(isVi ? "Xuất dữ liệu ra PDF" : "Export data to PDF"),
        subtitle: Text(
          isVi
              ? "Tạo báo cáo giao dịch dưới dạng file .pdf"
              : "Create a transaction report as a .pdf file",
        ),
        onTap: () {
          final transactions = context
              .read<DashboardCubit>()
              .state
              .transactions;
          if (transactions.isNotEmpty) {
            _exportToPdf(transactions, isVi);
          }
        },
      ),
    ];
  }

  // 3. Các mục trong nhóm Cấu hình
  List<Widget> _buildConfigItems(
    BuildContext context,
    SettingsState settingsState,
    bool isVi,
  ) {
    return [
      SwitchListTile(
        contentPadding: const EdgeInsets.only(
          left: 20,
          right: 16,
          top: 8,
          bottom: 8,
        ),
        secondary: const Icon(Icons.dark_mode_outlined),
        title: Text(isVi ? "Chế độ tối" : "Dark Mode"),
        value: settingsState.themeMode == ThemeMode.dark,
        onChanged: (val) {
          context.read<SettingsCubit>().toggleTheme(val);
        },
      ),
      ListTile(
        contentPadding: const EdgeInsets.only(
          left: 20,
          right: 20,
          top: 8,
          bottom: 8,
        ),
        leading: const Icon(Icons.language_outlined),
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
    ];
  }

  void _showLogoutDialog(BuildContext context, bool isVi) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28.0),
        ),
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

  void _showAppAboutDialog(BuildContext context) {
    final isVi =
        context.read<SettingsCubit>().state.locale.languageCode == 'vi';
    showAboutDialog(
      context: context,
      applicationName: 'Fintech Dashboard',
      // Để lấy version động, bạn có thể dùng package `package_info_plus`
      applicationVersion: '1.0.0',
      applicationIcon: const Padding(
        padding: EdgeInsets.all(8.0),
        child: Icon(Icons.wallet_rounded, size: 48),
      ),
      applicationLegalese: '© 2026 Fintech App',
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(top: 24, bottom: 8),
          child: Text(
            isVi
                ? 'Một ứng dụng giúp bạn quản lý tài chính cá nhân một cách thông minh và hiệu quả.'
                : 'An application to help you manage your personal finances smartly and effectively.',
            textAlign: TextAlign.justify,
          ),
        ),
      ],
    );
  }

  // --- HÀM XUẤT EXCEL ---
  Future<void> _exportToExcel(
    List<TransactionEntity> transactions,
    bool isVi,
  ) async {
    var excel = Excel.createExcel();
    Sheet sheetObject = excel['Transactions'];
    excel.delete('Sheet1'); // Xóa sheet mặc định

    // Tiêu đề cột
    List<String> headers = isVi
        ? ['Ngày', 'Danh mục', 'Ghi chú', 'Loại', 'Số tiền']
        : ['Date', 'Category', 'Note', 'Type', 'Amount'];

    sheetObject.appendRow(headers.map((e) => TextCellValue(e)).toList());

    // Dữ liệu
    for (var tx in transactions) {
      String type = tx.categoryType == 'income'
          ? (isVi ? 'Thu nhập' : 'Income')
          : (isVi ? 'Chi tiêu' : 'Expense');

      sheetObject.appendRow([
        TextCellValue(DateFormat('yyyy-MM-dd').format(tx.date)),
        TextCellValue(tx.categoryName ?? ''),
        TextCellValue(tx.note),
        TextCellValue(type),
        DoubleCellValue(tx.amount),
      ]);
    }

    // Lưu và chia sẻ file
    final directory = await getTemporaryDirectory();
    final path = "${directory.path}/transactions_export.xlsx";
    final file = File(path);
    var fileBytes = excel.save();

    if (fileBytes != null) {
      await file.writeAsBytes(fileBytes);
      await Share.shareXFiles([XFile(path)], text: 'Transaction Report');
    }
  }

  // --- HÀM XUẤT PDF ---
  Future<void> _exportToPdf(
    List<TransactionEntity> transactions,
    bool isVi,
  ) async {
    final doc = pw.Document();
    final font = await PdfGoogleFonts.robotoRegular();
    final boldFont = await PdfGoogleFonts.robotoBold();

    // Tính tổng
    double totalIncome = 0;
    double totalExpense = 0;
    for (var tx in transactions) {
      if (tx.categoryType == 'income') {
        totalIncome += tx.amount;
      } else {
        totalExpense += tx.amount;
      }
    }

    doc.addPage(
      pw.MultiPage(
        theme: pw.ThemeData.withFont(base: font, bold: boldFont),
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Text(
                isVi ? 'Báo cáo Giao dịch' : 'Transaction Report',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Table.fromTextArray(
              headers: isVi
                  ? ['Ngày', 'Danh mục', 'Ghi chú', 'Loại', 'Số tiền']
                  : ['Date', 'Category', 'Note', 'Type', 'Amount'],
              data: transactions.map((tx) {
                String type = tx.categoryType == 'income'
                    ? (isVi ? 'Thu' : 'Inc')
                    : (isVi ? 'Chi' : 'Exp');
                return [
                  DateFormat('yyyy-MM-dd').format(tx.date),
                  tx.categoryName ?? '',
                  tx.note,
                  type,
                  tx.amount.toStringAsFixed(0),
                ];
              }).toList(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.grey300,
              ),
              cellAlignment: pw.Alignment.centerLeft,
              cellAlignments: {
                4: pw.Alignment.centerRight, // Căn phải cột số tiền
              },
            ),
            pw.SizedBox(height: 20),
            pw.Divider(),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      "${isVi ? 'Tổng thu' : 'Total Income'}: ${totalIncome.toStringAsFixed(0)}",
                      style: const pw.TextStyle(color: PdfColors.green),
                    ),
                    pw.Text(
                      "${isVi ? 'Tổng chi' : 'Total Expense'}: ${totalExpense.toStringAsFixed(0)}",
                      style: const pw.TextStyle(color: PdfColors.red),
                    ),
                    pw.SizedBox(height: 5),
                    pw.Text(
                      "${isVi ? 'Số dư' : 'Balance'}: ${(totalIncome - totalExpense).toStringAsFixed(0)}",
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            pw.Footer(
              leading: pw.Text(
                DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now()),
              ),
              trailing: pw.Text(
                isVi ? 'Được tạo bởi Fintech App' : 'Generated by Fintech App',
              ),
            ),
          ];
        },
      ),
    );

    await Printing.sharePdf(
      bytes: await doc.save(),
      filename: 'transaction_report.pdf',
    );
  }
}
