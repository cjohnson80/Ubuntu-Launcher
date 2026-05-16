import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:launcher/src/blocs/apps_cubit.dart';
import 'package:launcher/src/config/themes/cubit/opacity_cubit.dart';
import 'package:launcher/src/core/modules/home/views/widgets/lomiri_dock.dart';
import 'package:launcher/src/helpers/utilities/image_picker.dart';
import 'package:launcher/src/helpers/utilities/local_storage.dart';
import 'package:launcher/src/helpers/utilities/system_services.dart';
import 'package:launcher/src/helpers/widgets/custom_snackbar.dart';
import 'package:launcher/src/helpers/widgets/success_message.dart';
import 'package:launcher/src/core/modules/home/views/widgets/app_spread.dart';
import 'package:launcher/src/core/modules/home/views/widgets/indicators_panel.dart';
import 'package:launcher/src/config/constants/colors.dart';

class Home extends StatefulWidget {
  static const route = '/';
  const Home({Key? key}) : super(key: key);

  @override
  State<Home> createState() => HomeState();
}

class HomeState extends State<Home> {
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
  final String defaultWallpaper = "assets/images/wallpaper.jpg";
  final String starterIcon = "assets/images/logo.png";

  String? currentWallpaper;
  bool isDockVisible = false;

  @override
  void initState() {
    super.initState();
    loadWallpaper();
    _initGlobalEdgeService();
    SystemServices.setMethodCallHandler((call) async {
      if (call.method == 'openDock') {
        if (mounted && !isDockVisible) {
          setState(() {
            isDockVisible = true;
          });
        }
      }
    });
  }

  Future<void> _initGlobalEdgeService() async {
    final hasPermission = await SystemServices.checkOverlayPermission();
    if (hasPermission) {
      SystemServices.startEdgeOverlayService();
    } else {
      // Delay to avoid crashing during initial build
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          _showOverlayPermissionDialog();
        }
      });
    }
  }

  void _showOverlayPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text("Global Edge Gestures", style: TextStyle(color: Colors.white)),
        content: const Text(
          "To pull out the Lomiri Dock even when you are inside another app (like Chrome), Ubuntu Launcher needs the 'Draw over other apps' permission.",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Not Now"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              SystemServices.requestOverlayPermission();
            },
            child: const Text("Settings", style: TextStyle(color: ubuntuOrange)),
          ),
        ],
      ),
    );
  }

  Future<void> loadWallpaper() async {
    currentWallpaper = await LocalStorage.getWallpaper();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final appsCubit = context.read<AppsCubit>();
    final opacityCubit = context.read<OpacityCubit>();

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarIconBrightness: Brightness.light,
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.black,
      ),
    );

    return PopScope(
      canPop: false,
      child: Focus(
        onFocusChange: (isFocusChanged) {
          if (isFocusChanged) {
            opacityCubit.opacityReset();
            appsCubit.loadApps();
          }
        },
        child: Scaffold(
          key: scaffoldKey,
          body: BlocBuilder<AppsCubit, AppsState>(
            builder: (context, state) {
              if (state is AppsLoading) {
                return Container(
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage("assets/images/boot2.gif"),
                      fit: BoxFit.fill,
                    ),
                  ),
                );
              }

              return Stack(
                children: [
                  // Wallpaper Layer
                  GestureDetector(
                    onHorizontalDragUpdate: (details) {
                      final screenWidth = MediaQuery.of(context).size.width;
                      
                      // Right edge swipe (App Spread / Multitasking)
                      if (details.globalPosition.dx > screenWidth - 50 && details.delta.dx < -10) {
                        HapticFeedback.mediumImpact();
                        _openAppSpread(context);
                      }

                      // Reveal dock on swipe from left edge
                      if (details.globalPosition.dx < 50 && details.delta.dx > 10) {
                        if (!isDockVisible) {
                          HapticFeedback.lightImpact();
                          setState(() {
                            isDockVisible = true;
                          });
                        }
                      }
                      // Hide dock on swipe to left
                      if (isDockVisible && details.delta.dx < -10) {
                        HapticFeedback.lightImpact();
                        setState(() {
                          isDockVisible = false;
                        });
                      }
                    },
                    onVerticalDragUpdate: (details) {
                      final screenHeight = MediaQuery.of(context).size.height;
                      
                      // Swipe down from top to open Indicators Panel
                      if (details.globalPosition.dy < 50 && details.delta.dy > 10) {
                        HapticFeedback.mediumImpact();
                        _openIndicatorsPanel(context);
                      }

                      // Swipe up from bottom to open App Drawer (Dash)
                      if (details.globalPosition.dy > screenHeight - 100 && details.delta.dy < -10) {
                        HapticFeedback.mediumImpact();
                        opacityCubit.setOpacitySemi();
                        Navigator.pushNamed(context, '/app-drawer');
                      }
                    },
                    onLongPress: () async {
                      pickImageFile(context, (image) async {
                        if (image == null) {
                          CustomSnackBar(
                            context: context,
                            message: "No image is selected",
                            color: Colors.yellow,
                          ).display();
                        } else {
                          setState(() {
                            currentWallpaper = image.path;
                          });
                          LocalStorage.setWallpaper(image.path);
                          SuccessMessage(
                            context: context,
                            message: "Wallpaper changed successfully",
                          ).display();
                        }
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: currentWallpaper != null
                               ? FileImage(File(currentWallpaper!))
                               : AssetImage(defaultWallpaper) as ImageProvider,
                          fit: BoxFit.cover,
                        ),
                      ),
                      height: double.infinity,
                      width: double.infinity,
                    ),
                  ),

                  // UI Overlay Layer: Lomiri Dock (Animated)
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutCubic,
                    left: isDockVisible ? 0 : -70,
                    top: 0,
                    bottom: 0,
                    child: Row(
                      children: [
                        LomiriDock(starterIcon: starterIcon),
                      ],
                    ),
                  ),

                  // Edge Touch Target for revealing dock when hidden
                  if (!isDockVisible)
                    Positioned(
                      left: 0,
                      top: 0,
                      bottom: 0,
                      width: 20,
                      child: GestureDetector(
                        onHorizontalDragUpdate: (details) {
                          if (details.delta.dx > 5) {
                            setState(() {
                              isDockVisible = true;
                            });
                          }
                        },
                        child: Container(color: Colors.transparent),
                      ),
                    ),

                  // Error State Overlay if any
                  if (state is AppsError)
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        color: Colors.black54,
                        child: const Text(
                          "Something went wrong!",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  void _openAppSpread(BuildContext context) async {
    final hasPermission = await SystemServices.checkUsageStatsPermission();
    if (!hasPermission) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title: const Text("Permission Required", style: TextStyle(color: Colors.white)),
          content: const Text(
            "To display the Lomiri App Spread (recent apps), Ubuntu Launcher needs 'Usage Access'. Would you like to grant it now?",
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Not Now"),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                SystemServices.requestUsageStatsPermission();
              },
              child: Text("Settings", style: TextStyle(color: ubuntuOrange)),
            ),
          ],
        ),
      );
      return;
    }

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "AppSpread",
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return const AppSpreadView();
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: Tween(begin: const Offset(1, 0), end: const Offset(0, 0)).animate(animation),
          child: child,
        );
      },
    );
  }

  void _openIndicatorsPanel(BuildContext context) async {
    final hasPermission = await SystemServices.checkNotificationPermission();
    if (!hasPermission) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title: const Text("Notification Access Required", style: TextStyle(color: Colors.white)),
          content: const Text(
            "To display the Lomiri Indicators panel, Ubuntu Launcher needs permission to read system notifications.",
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Not Now"),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                SystemServices.requestNotificationPermission();
              },
              child: const Text("Settings", style: TextStyle(color: ubuntuOrange)),
            ),
          ],
        ),
      );
      return;
    }

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "IndicatorsPanel",
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return const IndicatorsPanelView();
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: Tween(begin: const Offset(0, -1), end: const Offset(0, 0)).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)
          ),
          child: child,
        );
      },
    );
  }
}
