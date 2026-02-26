import 'package:flutter/material.dart';

class AppIcons {
  // Private constructor to prevent instantiation of this utility class.
  AppIcons._();

  /// The single source of truth for all category icons.
  static final Map<String, IconData> categoryIcons = {
    'fastfood': Icons.fastfood_rounded,
    'shopping_cart': Icons.shopping_cart_rounded,
    'restaurant': Icons.restaurant_rounded,
    'local_gas_station': Icons.local_gas_station_rounded,
    'flight': Icons.flight_rounded,
    'movie': Icons.movie_rounded,
    'attach_money': Icons.attach_money_rounded,
    'work': Icons.work_rounded,
    'home': Icons.home_rounded,
    'health_and_safety': Icons.health_and_safety_rounded,
    'school': Icons.school_rounded,
    'payments': Icons.payments_rounded,
    'wallet': Icons.wallet_rounded,
    'default': Icons.category_rounded,
  };

  static IconData getIconFromString(String? iconName) {
    return categoryIcons[iconName] ?? categoryIcons['default']!;
  }
}
