import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:launcher/src/blocs/apps_cubit.dart';
import 'package:launcher/src/config/themes/cubit/opacity_cubit.dart';
import 'package:launcher/src/core/modules/home/views/widgets/lomiri_dock.dart';
import 'package:launcher/src/helpers/utilities/image_picker.dart';
import 'package:launcher/src/helpers/utilities/local_storage.dart';
import 'package:launcher/src/helpers/widgets/custom_snackbar.dart';
import 'package:launcher/src/helpers/widgets/success_message.dart';

class Home extends StatefulWidget {
  static const route = '/';
  const Home({Key? key}) : super(key: key);

  @override
  State<Home> createState() => HomeState();
}

class HomeState extends State<Home> {
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
  final String defaultWallpaper = "assets/images/wallpaper.jpg";
  final String starterIcon = "assets/images/drawer.png";

  String? currentWallpaper;
  bool isDockVisible = true;

  @override
  void initState() {
    super.initState();
    loadWallpaper();
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
                      // Reveal dock on swipe from left edge
                      if (details.globalPosition.dx < 50 && details.delta.dx > 10) {
                        setState(() {
                          isDockVisible = true;
                        });
                      }
                      // Hide dock on swipe to left
                      if (isDockVisible && details.delta.dx < -10) {
                        setState(() {
                          isDockVisible = false;
                        });
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
}
