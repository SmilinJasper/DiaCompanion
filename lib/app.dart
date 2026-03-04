import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'features/home/providers/home_provider.dart';
import 'features/data_center/providers/data_center_provider.dart';
import 'features/diabot/providers/diabot_provider.dart';
import 'features/risk_predictor/providers/risk_predictor_provider.dart';
import 'features/home/presentation/pages/home_page.dart';

/// Root widget for the GlucoPredict application.
class GlucoPredictApp extends StatelessWidget {
  const GlucoPredictApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => HomeProvider()),
        ChangeNotifierProvider(create: (_) => DataCenterProvider()),
        ChangeNotifierProvider(create: (_) => DiaBotProvider()),
        ChangeNotifierProvider(create: (_) => RiskPredictorProvider()),
      ],
      child: MaterialApp(
        title: 'DiaCompanion',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        home: const HomePage(),
      ),
    );
  }
}
