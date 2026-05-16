import 'dart:ui';

final double pixelRatio = PlatformDispatcher.instance.views.first.devicePixelRatio;

final double physicalHeight = PlatformDispatcher.instance.views.first.physicalSize.height;

final double physicalWidth = PlatformDispatcher.instance.views.first.physicalSize.width;

final double deviceHeight = physicalHeight / pixelRatio;

final double deviceWidth = physicalWidth / pixelRatio;

final double titleSize = 0.035 * deviceHeight;

final double subTitleSize = 0.032 * deviceHeight;

final double mediumTextSize = 0.030 * deviceHeight;

final double normalTextSize = 0.025 * deviceHeight;

final double smallTextSize = 0.02 * deviceHeight;

final double extraSmallTextSize = 0.018 * deviceHeight;

final double buttonSize = 0.02 * deviceHeight;

final double iconSize = 0.030 * deviceHeight;

final double toggleSize = 0.035 * deviceHeight;

final double textFieldSpace = 0.015 * deviceHeight;
