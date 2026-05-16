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
import 'package:launcher/src/helpers/widgets/squircle_icon.dart';
import 'package:launcher/src/helpers/utilities/system_services.dart';
import 'package:logger/logger.dart';
import 'package:url_launcher/url_launcher.dart';

class LomiriDock extends StatefulWidget {
  final String starterIcon;
  final ValueNotifier<double>? highlightY;
  final VoidCallback? onHide;

  const LomiriDock({Key? key, required this.starterIcon, this.highlightY, this.onHide}) : super(key: key);

  @override
  State<LomiriDock> createState() => _LomiriDockState();
}

class _LomiriDockState extends State<LomiriDock> {
  List<Application> _runningApps = [];

  @override
  void initState() {
    super.initState();
    _fetchRunningApps();
  }

  Future<void> _fetchRunningApps() async {
    final recentPackages = await SystemServices.getRecentApps();
    final List<Application> running = [];
    for (var pkg in recentPackages) {
      Application? app = await DeviceApps.getApp(pkg, true);
      if (app != null) {
        running.add(app);
      }
    }
    if (mounted) {
      setState(() {
        _runningApps = running;
      });
    }
  }

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

  Widget _buildShortcut(BuildContext context, IconData icon, String? application, ShortcutAppTypes appType, {Application? appWithIcon}) {
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
            widget.onHide?.call();
          } catch (error) {
            Logger().w(error);
            ErrorMessage(context: context, error: "Something went wrong, Please try again.").display();
          }
        }
      },
      onLongPress: () => _showAppSelectDialog(context, appType),
      child: Padding(
        padding: const EdgeInsets.only(top: 15.0, bottom: 15.0),
        child: appWithIcon != null && appWithIcon is ApplicationWithIcon
          ? SquircleIcon(
              icon: MemoryImage(appWithIcon.icon),
              size: 50,
              borderRadius: 8,
            )
          : Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                size: 24,
                color: Colors.white,
              ),
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final opacityCubit = BlocProvider.of<OpacityCubit>(context);
    final appsCubit = BlocProvider.of<AppsCubit>(context);

    return BlocBuilder<OpacityCubit, OpacityState>(
      builder: (context, state) {
        final isDrawerOpen = state is OpacityInitial;
        return Opacity(
          opacity: isDrawerOpen ? 1.0 : 0.4,
          child: Container(
            width: 85.0,
            decoration: const BoxDecoration(
              color: Colors.black, 
            ),
            height: MediaQuery.of(context).size.height,
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  BlocBuilder<AppsCubit, AppsState>(
                    builder: (context, appsState) {
                      if (appsState is AppsLoaded) {
                        final pinnedApps = appsState.apps.where((app) => 
                          appsState.shortcutAppsModel.pinnedApps.contains(app.packageName)
                        ).toList();

                        final shortcutPkgs = [
                          appsState.shortcutAppsModel.phone,
                          appsState.shortcutAppsModel.message,
                          appsState.shortcutAppsModel.camera,
                          appsState.shortcutAppsModel.setting,
                        ];
                        
                        final displayRunningApps = _runningApps.where((app) => 
                          !pinnedApps.map((p) => p.packageName).contains(app.packageName) &&
                          !shortcutPkgs.contains(app.packageName)
                        ).toList();

                        return Expanded(
                          child: SingleChildScrollView(
                            child: Column(
                              children: [
                                _buildShortcut(context, Icons.phone, appsState.shortcutAppsModel.phone, ShortcutAppTypes.PHONE, 
                                  appWithIcon: appsState.apps.cast<Application?>().firstWhere((a) => a?.packageName == appsState.shortcutAppsModel.phone, orElse: () => null)),
                                _buildShortcut(context, Icons.chat_bubble_outline, appsState.shortcutAppsModel.message, ShortcutAppTypes.MESSAGE,
                                  appWithIcon: appsState.apps.cast<Application?>().firstWhere((a) => a?.packageName == appsState.shortcutAppsModel.message, orElse: () => null)),
                                _buildShortcut(context, Icons.camera_alt_outlined, appsState.shortcutAppsModel.camera, ShortcutAppTypes.CAMERA,
                                  appWithIcon: appsState.apps.cast<Application?>().firstWhere((a) => a?.packageName == appsState.shortcutAppsModel.camera, orElse: () => null)),
                                
                                if (pinnedApps.isNotEmpty) ...[
                                  for (final app in pinnedApps)
                                    _buildPinnedApp(context, app, context.read<AppsCubit>()),
                                ],

                                _buildShortcut(context, Icons.settings_outlined, appsState.shortcutAppsModel.setting, ShortcutAppTypes.SETTINGS,
                                  appWithIcon: appsState.apps.cast<Application?>().firstWhere((a) => a?.packageName == appsState.shortcutAppsModel.setting, orElse: () => null)),

                                if (displayRunningApps.isNotEmpty) ...[
                                  const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                                    child: Divider(color: Colors.white24, height: 1),
                                  ),
                                  for (final app in displayRunningApps)
                                    _buildRunningApp(context, app, appsCubit),
                                ]
                              ],
                            ),
                          ),
                        );
                      }
                      return Expanded(child: Container());
                    },
                  ),
                  
                  GestureDetector(
                    onTap: () {
                      opacityCubit.setOpacitySemi();
                      Navigator.pushNamed(context, AppDrawer.route);
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 20, top: 10),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: ubuntuOrange,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Hero(
                        tag: 'drawer',
                        child: Image.asset(
                          widget.starterIcon,
                          width: 32,
                          height: 32,
                          color: Colors.white, 
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRunningApp(BuildContext context, Application app, AppsCubit appsCubit) {
    return GestureDetector(
      onTap: () {
        DeviceApps.openApp(app.packageName);
        widget.onHide?.call();
      },
      onLongPress: () {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: const Color(0xFF1E1E1E),
            title: const Text("Pin App", style: TextStyle(color: Colors.white)),
            content: Text("Do you want to pin ${app.appName} to the dock?", style: const TextStyle(color: Colors.white70)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () {
                  appsCubit.pinApp(app.packageName);
                  Navigator.pop(context);
                },
                child: const Text("Pin", style: TextStyle(color: ubuntuOrange)),
              ),
            ],
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5.0),
        child: Stack(
          alignment: Alignment.centerLeft,
          children: [
            Container(
              width: 3,
              height: 20,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Center(
              child: SquircleIcon(
                icon: app is ApplicationWithIcon ? MemoryImage(app.icon) : null,
                size: 50,
                borderRadius: 8,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPinnedApp(BuildContext context, Application app, AppsCubit appsCubit) {
    return GestureDetector(
      onTap: () {
        DeviceApps.openApp(app.packageName);
        widget.onHide?.call();
      },
      onLongPress: () {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: const Color(0xFF1E1E1E),
            title: const Text("Unpin App", style: TextStyle(color: Colors.white)),
            content: Text("Do you want to unpin ${app.appName} from the dock?", style: const TextStyle(color: Colors.white70)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () {
                  appsCubit.unpinApp(app.packageName);
                  Navigator.pop(context);
                },
                child: const Text("Unpin", style: TextStyle(color: Colors.redAccent)),
              ),
            ],
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5.0),
        child: SquircleIcon(
          icon: app is ApplicationWithIcon ? MemoryImage(app.icon) : null,
          size: 50,
          borderRadius: 8,
        ),
      ),
    );
  }
}
