import 'package:flutter/material.dart';
import 'package:launcher/src/config/constants/colors.dart';
import 'package:launcher/src/helpers/widgets/custom_snackbar.dart';

class SuccessMessage extends CustomSnackBar {
  final BuildContext context;
  final String message;
  final int days;
  final int seconds;

// create constructor for SuccessMessage class
  SuccessMessage({
    required this.context,
    required this.message,
    this.days = 0,
    this.seconds = 2,
  }) : super(
            context: context,
            message: message,
            days: days,
            seconds: seconds,
            color: successColor);
}
