import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:launcher/src/config/constants/colors.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:launcher/src/helpers/utilities/system_services.dart';

class IndicatorsPanelView extends StatefulWidget {
  const IndicatorsPanelView({Key? key}) : super(key: key);

  @override
  State<IndicatorsPanelView> createState() => _IndicatorsPanelViewState();
}

class _IndicatorsPanelViewState extends State<IndicatorsPanelView> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    // 4 standard Lomiri tabs: Network, Sound, Battery, Notifications
    _tabController = TabController(length: 4, vsync: this, initialIndex: 3);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // UX Refinement 2: Light/Dark mode support (matching system brightness)
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color panelBgColor = isDark ? Colors.black.withValues(alpha: 0.7) : Colors.white.withValues(alpha: 0.7);
    final Color textColor = isDark ? Colors.white : Colors.black87;
    final Color tabIndicatorColor = ubuntuOrange;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Background Blur
          GestureDetector(
            onTap: () => Navigator.pop(context),
            // UX Refinement 4: Dismissal by swiping up from anywhere in the background
            onVerticalDragUpdate: (details) {
              if (details.delta.dy < -10) {
                Navigator.pop(context);
              }
            },
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Container(
                color: Colors.black.withValues(alpha: 0.2),
              ),
            ),
          ),
          
          // The Dropdown Panel
          Align(
            alignment: Alignment.topCenter,
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
              child: Container(
                height: MediaQuery.of(context).size.height * 0.75, // takes up 75% of screen
                width: double.infinity,
                color: panelBgColor,
                child: SafeArea( // UX Refinement 3: SafeArea for camera cutouts
                  bottom: false,
                  child: Column(
                    children: [
                      // Top Row: Date/Time (acting as panel header)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Today",
                              style: TextStyle(
                                color: textColor,
                                fontSize: 24,
                                fontWeight: FontWeight.w300,
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.settings_outlined, color: textColor),
                              onPressed: () => _showSettingsDialog(context, isDark),
                            ),
                          ],
                        ),
                      ),
                      
                      // Lomiri Tabs
                      TabBar(
                        controller: _tabController,
                        indicatorColor: tabIndicatorColor,
                        labelColor: tabIndicatorColor,
                        unselectedLabelColor: textColor.withValues(alpha: 0.5),
                        tabs: const [
                          Tab(icon: Icon(Icons.wifi)),
                          Tab(icon: Icon(Icons.volume_up)),
                          Tab(icon: Icon(Icons.battery_full)),
                          Tab(icon: Icon(Icons.notifications)),
                        ],
                      ),
                      
                      // Tab Content
                      Expanded(
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            _buildPlaceholderTab("Network Settings", Icons.wifi, textColor),
                            _buildPlaceholderTab("Sound & Media", Icons.volume_up, textColor),
                            _buildPlaceholderTab("Battery & Power", Icons.battery_full, textColor),
                            _buildNotificationsTab(textColor),
                          ],
                        ),
                      ),

                      // Bottom Dismissal Handle (Solves "Finger Gymnastics" reaching to the top)
                      GestureDetector(
                        onVerticalDragUpdate: (details) {
                          if (details.delta.dy < -5) {
                            Navigator.pop(context);
                          }
                        },
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
                          ),
                          child: Center(
                            child: Container(
                              width: 50,
                              height: 5,
                              decoration: BoxDecoration(
                                color: textColor.withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSettingsDialog(BuildContext context, bool isDark) async {
    final prefs = await SharedPreferences.getInstance();
    // Default edge width is 30
    double currentWidth = prefs.getDouble('edge_sensitivity') ?? 30.0;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Edge Sensitivity (Dock)",
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Adjust the width of the invisible left-edge touch zone. Increase this if you use a bulky phone case.",
                    style: TextStyle(
                      color: isDark ? Colors.white70 : Colors.black54,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Icon(Icons.arrow_back_ios, size: 16, color: isDark ? Colors.white54 : Colors.black54),
                      Expanded(
                        child: Slider(
                          value: currentWidth,
                          min: 10,
                          max: 80,
                          divisions: 7,
                          activeColor: ubuntuOrange,
                          label: "${currentWidth.toInt()} px",
                          onChanged: (val) {
                            setModalState(() {
                              currentWidth = val;
                            });
                          },
                          onChangeEnd: (val) async {
                            await prefs.setDouble('edge_sensitivity', val);
                            SystemServices.updateEdgeSensitivity(val);
                          },
                        ),
                      ),
                      Icon(Icons.keyboard_arrow_right, size: 24, color: isDark ? Colors.white54 : Colors.black54),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPlaceholderTab(String title, IconData icon, Color textColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 60, color: textColor.withValues(alpha: 0.2)),
          const SizedBox(height: 15),
          Text(
            title,
            style: TextStyle(color: textColor, fontSize: 18),
          ),
          const SizedBox(height: 10),
          Text(
            "Integration pending Kotlin MethodChannels",
            style: TextStyle(color: textColor.withValues(alpha: 0.5), fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsTab(Color textColor) {
    return ListView.builder(
      padding: const EdgeInsets.all(15),
      itemCount: 1, // Placeholder for actual notifications
      itemBuilder: (context, index) {
        return Card(
          color: textColor == Colors.white ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: ubuntuOrange,
              child: Icon(Icons.system_update, color: Colors.white),
            ),
            title: Text("System Update", style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
            subtitle: Text("Ubuntu Touch OTA-5 Focal is ready.", style: TextStyle(color: textColor.withValues(alpha: 0.7))),
            trailing: Text("Just now", style: TextStyle(color: textColor.withValues(alpha: 0.5), fontSize: 12)),
          ),
        );
      },
    );
  }
}
