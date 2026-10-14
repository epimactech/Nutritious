import 'package:flutter/material.dart';
import 'package:nutrious/screens/producers/producer_dashboard_screen.dart';
import 'package:nutrious/services/dashboard_api_service.dart';
import 'core/theme/app_theme.dart';
import 'screens/home/home_screen.dart';

class NutriFindApp extends StatelessWidget {
  const NutriFindApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NutriFind',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const HomeScreen(),
      // home: ProducerDashboardScreen(
      //   apiService: DashboardApiService(
      //     config: DashboardApiConfig(
      //       baseUrl: 'https://footballfraternity.co.tz',
      //       producersPath: '/api/producers',
      //     ),
      //   ),
      // ),
    );
  }
}
