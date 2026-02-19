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
        ListTile(
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
                  '${tx.amount.toStringAsFixed(0)}',
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
