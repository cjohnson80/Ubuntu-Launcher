import 'dart:io';
import 'dart:ui';
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
  final String starterIcon = "assets/images/ubuntu_touch_logo.png";

  String? currentWallpaper;
  bool isDockVisible = false;
  bool isSidebarOnly = false;

  // Gesture Tracking
  double _rightSwipeDistance = 0.0;
  DateTime? _rightSwipeStartTime;
  final ValueNotifier<double> _dockHighlightY = ValueNotifier<double>(-1.0);

  @override
  void initState() {
    super.initState();
    loadWallpaper();
    _initGlobalEdgeService();
    SystemServices.setMethodCallHandler((call) async {
      if (call.method == 'openDock') {
        final Map<dynamic, dynamic>? args = call.arguments as Map<dynamic, dynamic>?;
        final bool sidebarOnly = args?['sidebarOnly'] ?? false;
        
        if (mounted) {
          setState(() {
            isDockVisible = true;
            isSidebarOnly = sidebarOnly;
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
          backgroundColor: Colors.transparent,
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
                  if (!isSidebarOnly) ...[
                    // Wallpaper Layer
                    GestureDetector(
                      onHorizontalDragStart: (details) {
                        final screenWidth = MediaQuery.of(context).size.width;
                        if (details.globalPosition.dx > screenWidth - 50) {
                          _rightSwipeDistance = 0.0;
                          _rightSwipeStartTime = DateTime.now();
                        }
                        if (details.globalPosition.dx < 50) {
                          if (!isDockVisible) {
                            setState(() {
                              isDockVisible = true;
                            });
                          }
                        }
                      },
                      onHorizontalDragUpdate: (details) {
                        // Right edge swipe tracking
                        if (_rightSwipeStartTime != null) {
                          if (details.delta.dx < 0) {
                            _rightSwipeDistance -= details.delta.dx;
                          }
                        }

                        // Hide dock on swipe to left
                        if (isDockVisible && details.delta.dx < -10 && details.globalPosition.dx > 100) {
                          HapticFeedback.lightImpact();
                          setState(() {
                            isDockVisible = false;
                            isSidebarOnly = false;
                          });
                          _dockHighlightY.value = -1.0;
                        }
                      },
                      onHorizontalDragEnd: (details) {
                        final screenWidth = MediaQuery.of(context).size.width;
                        
                        // Right edge evaluation (Alt-Tab vs App Spread)
                        if (_rightSwipeStartTime != null) {
                          final swipeDuration = DateTime.now().difference(_rightSwipeStartTime!).inMilliseconds;
                          
                          if (swipeDuration < 200 && _rightSwipeDistance > 60 && _rightSwipeDistance < screenWidth * 0.3) {
                            HapticFeedback.lightImpact();
                            SystemServices.launchLastUsedApp();
                          } 
                          else if (_rightSwipeDistance >= screenWidth * 0.3) {
                            HapticFeedback.mediumImpact();
                            _openAppSpread(context);
                          }
                          
                          _rightSwipeStartTime = null;
                          _rightSwipeDistance = 0.0;
                        }

                        _dockHighlightY.value = -1.0;
                      },
                      onVerticalDragUpdate: (details) {
                        final screenHeight = MediaQuery.of(context).size.height;

                        if (details.delta.dy > 10 && details.globalPosition.dy < screenHeight * 0.5) {
                          SystemServices.closeSystemPanels();
                          HapticFeedback.mediumImpact();
                          _openIndicatorsPanel(context);
                        }

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
                  ],

                  if (!isSidebarOnly) ...[
                    // Lomiri Top Bar (Indicators Header)
                    Align(
                      alignment: Alignment.topCenter,
                      child: ClipRect(
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              border: Border(
                                bottom: BorderSide(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  width: 0.5,
                                )
                              )
                            ),
                            child: SafeArea(
                              bottom: false,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    _buildTopBarIndicator(Icons.wifi, 0),
                                    const SizedBox(width: 15),
                                    _buildTopBarIndicator(Icons.volume_up, 1),
                                    const SizedBox(width: 15),
                                    _buildTopBarIndicator(Icons.battery_full, 2),
                                    const SizedBox(width: 15),
                                    _buildTopBarIndicator(Icons.notifications, 3),
                                    const SizedBox(width: 10),
                                    GestureDetector(
                                      onVerticalDragUpdate: (details) {
                                        if (details.delta.dy > 5) {
                                          _openIndicatorsPanel(context, initialTabIndex: 3);
                                        }
                                      },
                                      child: const Text(
                                        "10:42 AM", 
                                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                                      ),
                                    )
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],

                  // UI Overlay Layer: Lomiri Dock (Animated)
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutCubic,
                    left: isDockVisible ? 0 : -85,
                    top: 0,
                    bottom: 0,
                    width: 85,
                    child: LomiriDock(
                      starterIcon: starterIcon,
                      highlightY: _dockHighlightY,
                      onHide: () {
                        setState(() {
                          isDockVisible = false;
                          isSidebarOnly = false;
                        });
                      },
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

  Widget _buildTopBarIndicator(IconData icon, int tabIndex) {
    return GestureDetector(
      onVerticalDragUpdate: (details) {
        if (details.delta.dy > 5) {
          HapticFeedback.selectionClick();
          _openIndicatorsPanel(context, initialTabIndex: tabIndex);
        }
      },
      child: Icon(icon, color: Colors.white, size: 18),
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

  void _openIndicatorsPanel(BuildContext context, {int initialTabIndex = 3}) async {
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
        return IndicatorsPanelView(initialTabIndex: initialTabIndex);
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
