import 'dart:ui';
import 'package:device_apps/device_apps.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:launcher/src/blocs/apps_cubit.dart';
import 'package:launcher/src/config/constants/enums.dart';
import 'package:launcher/src/config/themes/cubit/opacity_cubit.dart';
import 'package:launcher/src/helpers/widgets/squircle_icon.dart';

class AppDrawer extends StatefulWidget {
  static const route = '/app-drawer';
  const AppDrawer({Key? key}) : super(key: key);

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appsCubit = context.read<AppsCubit>();
    final opacityCubit = context.read<OpacityCubit>();

    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) opacityCubit.opacityReset();
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            // Glassy Blur Background
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Container(
                color: Colors.black.withValues(alpha: 0.6),
              ),
            ),
            
            SafeArea(
              child: Column(
                children: [
                  // Header with Search and Sort
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                        Expanded(
                          child: Container(
                            height: 48,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.1),
                                width: 1,
                              ),
                            ),
                            child: TextField(
                              controller: _searchController,
                              style: const TextStyle(color: Colors.white, fontSize: 16),
                              cursorColor: Colors.white,
                              onChanged: (value) {
                                setState(() {
                                  _searchQuery = value.toLowerCase();
                                });
                              },
                              decoration: const InputDecoration(
                                hintText: "Search your applications...",
                                hintStyle: TextStyle(color: Colors.white38, fontSize: 14),
                                prefixIcon: Icon(Icons.search, color: Colors.white38, size: 20),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(vertical: 14),
                              ),
                            ),
                          ),
                        ),
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.sort, color: Colors.white, size: 30),
                          onSelected: (value) {
                            appsCubit.updateSortType(value);
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem(value: SortTypes.Alphabetically.name, child: const Text("Alphabetically")),
                            PopupMenuItem(value: SortTypes.InstallationTime.name, child: const Text("Installation Time")),
                            PopupMenuItem(value: SortTypes.UpdateTime.name, child: const Text("Update Time")),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  // App Grid
                  Expanded(
                    child: BlocBuilder<AppsCubit, AppsState>(
                      builder: (context, state) {
                        if (state is AppsLoading) {
                          return const Center(child: CircularProgressIndicator(color: Colors.white));
                        }
                        
                        if (state is AppsLoaded) {
                          final filteredApps = state.apps.where((app) {
                            return app.appName.toLowerCase().contains(_searchQuery);
                          }).toList();
                          
                          return RefreshIndicator(
                            onRefresh: () => appsCubit.loadApps(),
                            child: GridView.builder(
                              padding: const EdgeInsets.all(20),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 4,
                                mainAxisSpacing: 20,
                                crossAxisSpacing: 20,
                                childAspectRatio: 0.8,
                              ),
                              itemCount: filteredApps.length,
                              itemBuilder: (context, index) {
                                final app = filteredApps[index];
                                  return GestureDetector(
                                    onTap: () {
                                      DeviceApps.openApp(app.packageName);
                                      Navigator.pop(context);
                                    },
                                    onLongPress: () {
                                      _showAppOptions(context, app, appsCubit);
                                    },
                                    child: TweenAnimationBuilder<double>(
                                      duration: Duration(milliseconds: 400 + (index * 50)),
                                      tween: Tween(begin: 0.0, end: 1.0),
                                      curve: Curves.easeOutBack,
                                      builder: (context, value, child) {
                                        return Transform.scale(
                                          scale: value,
                                          child: Opacity(
                                            opacity: value.clamp(0.0, 1.0),
                                            child: Column(
                                              children: [
                                                Expanded(
                                                  child: SquircleIcon(
                                                    icon: app is ApplicationWithIcon ? MemoryImage(app.icon) : null,
                                                    size: 64,
                                                  ),
                                                ),
                                                const SizedBox(height: 10),
                                                Text(
                                                  app.appName,
                                                  textAlign: TextAlign.center,
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w400,
                                                    letterSpacing: 0.5,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  );
                              },
                            ),
                          );
                        }
                        
                        return const Center(child: Text("Error loading apps", style: TextStyle(color: Colors.white)));
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAppOptions(BuildContext context, Application app, AppsCubit appsCubit) {
    final isPinned = appsCubit.getCurrentPayloads(appsStatePayloadTypes: AppsStatePayloadTypes.SHORTCUT_APPS).pinnedApps.contains(app.packageName);
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E).withValues(alpha: 0.95),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.settings, color: Colors.white70),
                title: const Text("App Settings", style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  DeviceApps.openAppSettings(app.packageName);
                },
              ),
              ListTile(
                leading: Icon(isPinned ? Icons.push_pin : Icons.push_pin_outlined, color: Colors.white70),
                title: Text(isPinned ? "Unpin from Dock" : "Pin to Dock", style: const TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  if (isPinned) {
                    appsCubit.unpinApp(app.packageName);
                  } else {
                    appsCubit.pinApp(app.packageName);
                  }
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }
}
