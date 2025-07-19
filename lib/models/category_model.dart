import 'package:flutter/material.dart';
import '../utils/constants.dart';

class CategoryModel {
  final String id;
  final String name;
  final Color color;
  final IconData icon;

  CategoryModel({
    required this.id,
    required this.name,
    required this.color,
    required this.icon,
  });

  static List<CategoryModel> getAllCategories() {
    return EventCategory.allCategories.map((categoryId) {
      return CategoryModel(
        id: categoryId,
        name: EventCategory.categoryNames[categoryId] ?? '',
        color: EventCategory.categoryColors[categoryId] ?? AppColors.primary,
        icon: EventCategory.categoryIcons[categoryId] ?? Icons.help_outline,
      );
    }).toList();
  }

  static CategoryModel? getCategoryById(String id) {
    try {
      return getAllCategories().firstWhere((category) => category.id == id);
    } catch (e) {
      return null;
    }
  }

  @override
  String toString() {
    return 'CategoryModel(id: $id, name: $name)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CategoryModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
