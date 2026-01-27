import 'package:flutter/material.dart';
import 'injection_container.dart' as di;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Khởi tạo Dependency Injection
  await di.init();
}
