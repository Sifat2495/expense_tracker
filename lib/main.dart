import 'package:flutter/material.dart';

import 'src/app.dart';
import 'services/storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final storage = await StorageService.getInstance();
  runApp(ExpenseApp(storage: storage));
}
