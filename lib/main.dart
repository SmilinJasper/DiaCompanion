import 'package:flutter/material.dart';

import 'app.dart';
import 'core/services/chatbot_service.dart';
import 'core/services/database_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseService.init();
  ChatbotService.init();
  runApp(const GlucoPredictApp());
}
