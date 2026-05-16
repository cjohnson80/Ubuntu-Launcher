import 'dart:ui';
import 'package:device_apps/device_apps.dart';
import 'package:flutter/material.dart';
import 'package:launcher/src/helpers/utilities/system_services.dart';
import 'package:launcher/src/helpers/widgets/squircle_icon.dart';

class AppSpreadView extends StatefulWidget {
  const AppSpreadView({Key? key}) : super(key: key);

  @override
  State<AppSpreadView> createState() => _AppSpreadViewState();
}

class _AppSpreadViewState extends State<AppSpreadView> {
  List<Application> _recentApps = [];
  bool _isLoading = true;
  late PageController _pageController;
  double _currentPage = 0.0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.7);
    _pageController.addListener(() {
      setState(() {
        _currentPage = _pageController.page!;
      });
    });
    _loadRecentApps();
  }

  Future<void> _loadRecentApps() async {
    final recentPackages = await SystemServices.getRecentApps();
    final List<Application> apps = [];

    for (var pkg in recentPackages) {
      Application? app = await DeviceApps.getApp(pkg, true);
      if (app != null) {
        apps.add(app);
      }
    }

    if (mounted) {
      setState(() {
        _recentApps = apps;
        _isLoading = false;
      });
    }
  }

  void _closeApp(int index) {
    final app = _recentApps[index];
    SystemServices.closeApp(app.packageName);
    setState(() {
      _recentApps.removeAt(index);
    });
    if (_recentApps.isEmpty) {
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Background Blur
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Container(
                color: Colors.black.withValues(alpha: 0.4),
              ),
            ),
          ),
          
          // Content
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 20.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "App Spread",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w200,
                          letterSpacing: 2.0,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.layers_clear_outlined, color: Colors.white70),
                        tooltip: "System Switcher",
                        onPressed: () async {
                          final success = await SystemServices.showRecentApps();
                          if (success && mounted) Navigator.pop(context);
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_sweep_outlined, color: Colors.white70),
                        tooltip: "Close All",
                        onPressed: () {
                          for (var app in _recentApps) {
                            SystemServices.closeApp(app.packageName);
                          }
                          setState(() {
                            _recentApps.clear();
                          });
                          Navigator.pop(context);
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white70),
                        onPressed: () => Navigator.pop(context),
                      )
                    ],
                  ),
                ),
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator(color: Colors.white))
                      : _recentApps.isEmpty
                          ? const Center(
                              child: Text(
                                "No running apps",
                                style: TextStyle(color: Colors.white54, fontSize: 18),
                              ),
                            )
                          : Stack(
                              children: [
                                PageView.builder(
                                  controller: _pageController,
                                  itemCount: _recentApps.length,
                                  itemBuilder: (context, index) {
                                    final app = _recentApps[index];
                                    
                                    // 3D Card Transform Logic
                                    double relativePosition = index - _currentPage;
                                    double scale = (1 - (relativePosition.abs() * 0.2)).clamp(0.0, 1.0);
                                    double opacity = (1 - (relativePosition.abs() * 0.5)).clamp(0.0, 1.0);
                                    double rotation = (relativePosition * 0.3).clamp(-0.5, 0.5);
                                    double translation = relativePosition * 10.0;

                                    return Transform(
                                      transform: Matrix4.identity()
                                        ..setEntry(3, 2, 0.001) // perspective
                                        ..scale(scale)
                                        ..rotateY(rotation)
                                        ..translate(translation),
                                      alignment: Alignment.center,
                                      child: Opacity(
                                        opacity: opacity,
                                        child: _buildAppCard(app, index),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                ),
                const Padding(
                  padding: EdgeInsets.only(bottom: 40),
                  child: Center(
                    child: Text(
                      "Swipe up to close",
                      style: TextStyle(color: Colors.white30, fontSize: 12),
                    ),
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppCard(Application app, int index) {
    return Dismissible(
      key: Key(app.packageName + index.toString()),
      direction: DismissDirection.vertical,
      onDismissed: (direction) => _closeApp(index),
      child: GestureDetector(
        onTap: () {
          DeviceApps.openApp(app.packageName);
          Navigator.pop(context);
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 30),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white24, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 25,
                offset: const Offset(0, 15),
              )
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Hero(
                    tag: 'app_${app.packageName}',
                    child: SquircleIcon(
                      icon: app is ApplicationWithIcon ? MemoryImage(app.icon) : null,
                      size: 110,
                      borderRadius: 24,
                    ),
                  ),
                  const SizedBox(height: 30),
                  Text(
                    app.appName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w400,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    app.packageName,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.4),
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

