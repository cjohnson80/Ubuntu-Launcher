import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:launcher/src/config/constants/size.dart';

class CustomSnackBar {
  final BuildContext context;
  final String message;
  final int days;
  final int seconds;
  final Color color;
  final Function? fn;

  CustomSnackBar({
    required this.context,
    required this.message,
    this.seconds = 2,
    this.fn,
    this.days = 0,
    this.color = Colors.black,
  });

  void display() {
    final snackBar = SnackBar(
      margin: const EdgeInsets.all(10),
      behavior: SnackBarBehavior.floating,
      duration: Duration(days: days, seconds: seconds),
      backgroundColor: Colors.transparent,
      elevation: 0,
      content: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.2),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 10,
                  spreadRadius: 2,
                )
              ],
            ),
            child: GestureDetector(
              onTap: fn as void Function()?,
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      message,
                      style: TextStyle(
                        fontSize: smallTextSize,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}
