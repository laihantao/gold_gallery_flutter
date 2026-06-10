import 'package:flutter/material.dart';

class FilterOption {
  final String value;
  final String label;
  final IconData icon;
  final List<String> choices;

  const FilterOption({
    required this.value,
    required this.label,
    required this.icon,
    this.choices = const [],
  });
}
