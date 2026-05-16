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

  @override
  void initState() {
    super.initState();
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
                  padding: const EdgeInsets.all(20.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Recent Apps",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w300,
                          letterSpacing: 1.2,
                        ),
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
                                "No recent apps found.",
                                style: TextStyle(color: Colors.white54),
                              ),
                            )
                          : Center(
                              child: SizedBox(
                                height: 350,
                                child: PageView.builder(
                                  controller: PageController(viewportFraction: 0.6),
                                  itemCount: _recentApps.length,
                                  itemBuilder: (context, index) {
                                    final app = _recentApps[index];
                                    return AnimatedBuilder(
                                      animation: PageController(viewportFraction: 0.6), // Note: We actually need a custom transition here, but this is a placeholder for the PageView scrolling.
                                      builder: (context, child) {
                                        return child!;
                                      },
                                      child: GestureDetector(
                                        onTap: () {
                                          DeviceApps.openApp(app.packageName);
                                          Navigator.pop(context);
                                        },
                                        child: Container(
                                          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(24),
                                            border: Border.all(color: Colors.white24, width: 1),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withValues(alpha: 0.3),
                                                blurRadius: 15,
                                                offset: const Offset(0, 10),
                                              )
                                            ],
                                          ),
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              SquircleIcon(
                                                icon: app is ApplicationWithIcon ? MemoryImage(app.icon) : null,
                                                size: 100,
                                                borderRadius: 24,
                                              ),
                                              const SizedBox(height: 20),
                                              Text(
                                                app.appName,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                                textAlign: TextAlign.center,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
