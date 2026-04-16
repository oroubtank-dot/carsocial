import 'package:flutter/material.dart';

void showSnackBar(
  BuildContext context,
  String message, {
  bool isError = false,
}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: isError ? Colors.red : Colors.green,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 2),
    ),
  );
}

String formatDate(DateTime date) {
  final now = DateTime.now();
  final diff = now.difference(date);

  if (diff.inDays > 7) {
    return '${date.day}/${date.month}/${date.year}';
  } else if (diff.inDays > 0) {
    return 'منذ ${diff.inDays} يوم';
  } else if (diff.inHours > 0) {
    return 'منذ ${diff.inHours} ساعة';
  } else if (diff.inMinutes > 0) {
    return 'منذ ${diff.inMinutes} دقيقة';
  } else {
    return 'الآن';
  }
}
