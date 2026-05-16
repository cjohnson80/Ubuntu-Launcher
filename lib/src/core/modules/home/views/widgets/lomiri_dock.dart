import 'dart:ui';
import 'package:device_apps/device_apps.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:launcher/src/blocs/apps_cubit.dart';
import 'package:launcher/src/config/constants/colors.dart';
import 'package:launcher/src/config/constants/enums.dart';
import 'package:launcher/src/config/constants/size.dart';
import 'package:launcher/src/config/themes/cubit/opacity_cubit.dart';
import 'package:launcher/src/core/modules/apps/views/app_drawer.dart';
import 'package:launcher/src/data/models/shortcut_app_model.dart';
import 'package:launcher/src/helpers/widgets/error_message.dart';
import 'package:launcher/src/helpers/widgets/success_message.dart';
import 'package:logger/logger.dart';
import 'package:url_launcher/url_launcher.dart';

class LomiriDock extends StatelessWidget {
  final String starterIcon;

  const LomiriDock({Key? key, required this.starterIcon}) : super(key: key);

  Future<void> _launchCaller() async {
    final Uri url = Uri.parse("tel:");
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  Future<void> _showAppSelectDialog(BuildContext context, ShortcutAppTypes appTypes) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: Color.fromRGBO(30, 30, 30, 0.9),
          title: Text(
            'Select ${appTypes.name} App',
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: normalTextSize, color: ubuntuOrange, fontWeight: FontWeight.bold),
          ),
          content: BlocBuilder<AppsCubit, AppsState>(
            builder: (ctx, state) {
              if (state is AppsLoaded) {
                return Card(
                  color: Colors.transparent,
                  child: Container(
                    height: MediaQuery.of(context).size.height / 2,
                    width: MediaQuery.of(context).size.width,
                    child: ListView(
                      physics: BouncingScrollPhysics(),
                      shrinkWrap: true,
                      children: <Widget>[
                        for (final app in state.apps)
                          GestureDetector(
                            onTap: () async {
                              Navigator.of(dialogContext).pop();
                              final ShortcutAppsModel shortcutApps = state.shortcutAppsModel;

                              switch (appTypes) {
                                case ShortcutAppTypes.CAMERA:
                                  shortcutApps.camera = app.packageName;
                                  break;
                                case ShortcutAppTypes.MESSAGE:
                                  shortcutApps.message = app.packageName;
                                  break;
                                case ShortcutAppTypes.PHONE:
                                  shortcutApps.phone = app.packageName;
                                  break;
                                case ShortcutAppTypes.SETTINGS:
                                  shortcutApps.setting = app.packageName;
                                  break;
                              }

                              BlocProvider.of<AppsCubit>(context).updateShortcutApps(shortcutApps);

                              SuccessMessage(
                                message: '${appTypes.name} application selected successfully.',
                                context: context,
                              ).display();
                            },
                            child: Container(
                              margin: const EdgeInsets.all(5),
                              child: Row(
                                children: [
                                  app is ApplicationWithIcon
                                      ? CircleAvatar(
                                          backgroundImage: MemoryImage(app.icon),
                                          backgroundColor: Colors.white,
                                        )
                                      : Icon(Icons.apps, size: iconSize, color: Colors.white),
                                  SizedBox(width: 10),
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.all(10.0),
                                      child: Text(
                                        app.appName,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(color: Colors.white, fontSize: normalTextSize),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                      ],
                    ),
                  ),
                );
              } else {
                return Container(
                  alignment: Alignment.center,
                  child: CircularProgressIndicator(),
                );
              }
            },
          ),
        );
      },
    );
  }

  Widget _buildShortcut(BuildContext context, IconData icon, String? application, ShortcutAppTypes appType) {
    return GestureDetector(
      onTap: () async {
        if (application == null) {
          _showAppSelectDialog(context, appType);
        } else {
          try {
            if (appType == ShortcutAppTypes.PHONE) {
              _launchCaller();
            } else {
              bool isLaunchAble = await DeviceApps.openApp(application);
              if (!isLaunchAble) {
                ErrorMessage(
                  context: context,
                  fn: () => DeviceApps.openAppSettings(application),
                  seconds: 4,
                  error: "Please tap here to enable the application first or long press to change application."
                ).display();
              }
            }
          } catch (error) {
            Logger().w(error);
            ErrorMessage(context: context, error: "Something went wrong, Please try again.").display();
          }
        }
      },
      onLongPress: () => _showAppSelectDialog(context, appType),
      child: Padding(
        padding: const EdgeInsets.only(top: 25.0, bottom: 25.0),
        child: Icon(
          icon,
          size: 30, // sleek lomiri size
          color: Colors.white,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final opacityCubit = BlocProvider.of<OpacityCubit>(context);

    return BlocBuilder<OpacityCubit, OpacityState>(
      builder: (context, state) {
        final isDrawerOpen = state is OpacityInitial;
        return Opacity(
          opacity: isDrawerOpen ? 1.0 : 0.4,
          child: ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
              child: Container(
                width: 70.0,
                color: Colors.black.withValues(alpha: 0.4), // Dark glassy dock
                height: MediaQuery.of(context).size.height,
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Top launcher icon (Home/App scope button)
                      GestureDetector(
                        onTap: () {
                          opacityCubit.setOpacitySemi();
                          Navigator.pushNamed(context, AppDrawer.route);
                        },
                        child: Container(
                          margin: const EdgeInsets.only(top: 10),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: ClipRRect(
                            child: Hero(
                              tag: 'drawer',
                              child: Image.asset(
                                starterIcon,
                                width: 35,
                                height: 35,
                                color: Colors.white, // sleek monochromatic
                              ),
                            ),
                          ),
                        ),
                      ),
                      
                      // Apps
                      BlocBuilder<AppsCubit, AppsState>(
                        builder: (context, appsState) {
                          if (appsState is AppsLoaded) {
                            return Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _buildShortcut(context, Icons.phone, appsState.shortcutAppsModel.phone, ShortcutAppTypes.PHONE),
                                  _buildShortcut(context, Icons.chat_bubble_outline, appsState.shortcutAppsModel.message, ShortcutAppTypes.MESSAGE),
                                  _buildShortcut(context, Icons.camera_alt_outlined, appsState.shortcutAppsModel.camera, ShortcutAppTypes.CAMERA),
                                  _buildShortcut(context, Icons.settings_outlined, appsState.shortcutAppsModel.setting, ShortcutAppTypes.SETTINGS),
                                ],
                              ),
                            );
                          }
                          return Expanded(child: Container());
                        },
                      ),
                      
                      // Bottom padding or extra tools
                      SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
