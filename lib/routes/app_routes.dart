import 'package:flutter/material.dart';
import '../screens/splash_screen.dart';
import '../screens/map_screen.dart';
import '../screens/report_screen.dart';
import '../screens/list_screen.dart';

class AppRoutes {
  static const String splash = '/';
  static const String map = '/map';
  static const String report = '/report';
  static const String list = '/list';
  static const String detail = '/detail';

  static Map<String, WidgetBuilder> get routes {
    return {
      splash: (context) => const SplashScreen(),
      map: (context) => const MapScreen(),
      report: (context) => const ReportScreen(),
      list: (context) => const ListScreen(),
      // detail route is removed since DetailScreen requires eventData
    };
  }

  /// Navigate to a route with optional arguments
  static Future<T?> push<T>(
    BuildContext context,
    String routeName, {
    Object? arguments,
  }) {
    return Navigator.pushNamed(context, routeName, arguments: arguments);
  }

  /// Replace current route with new route
  static Future<T?> pushReplacement<T>(
    BuildContext context,
    String routeName, {
    Object? arguments,
  }) {
    return Navigator.pushReplacementNamed(
      context,
      routeName,
      arguments: arguments,
    );
  }

  /// Navigate and clear all previous routes
  static Future<T?> pushAndRemoveUntil<T>(
    BuildContext context,
    String routeName, {
    Object? arguments,
  }) {
    return Navigator.pushNamedAndRemoveUntil(
      context,
      routeName,
      (route) => false,
      arguments: arguments,
    );
  }

  /// Go back to previous route
  static void pop(BuildContext context, [dynamic result]) {
    Navigator.pop(context, result);
  }
}
