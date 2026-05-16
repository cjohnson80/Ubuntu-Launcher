import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:launcher/src/config/constants/colors.dart';

class LockScreenView extends StatefulWidget {
  static const route = '/lockscreen';

  @override
  _LockScreenViewState createState() => _LockScreenViewState();
}

class _LockScreenViewState extends State<LockScreenView> with SingleTickerProviderStateMixin {
  static const MethodChannel _channel = MethodChannel('com.ubuntu.launcher/lockscreen');
  
  double _swipeOffset = 0.0;
  int _statIndex = 0;
  late AnimationController _pulseController;
  
  final List<String> _stats = [
    "42\nMessages",
    "2h 15m\nCalls",
    "12\nPhotos",
    "3.4GB\nData"
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    if (details.delta.dx < 0) {
      setState(() {
        _swipeOffset -= details.delta.dx;
      });
    }
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    if (_swipeOffset > MediaQuery.of(context).size.width * 0.4) {
      // Swiped far enough to unlock
      _unlock();
    } else {
      // Snap back
      setState(() {
        _swipeOffset = 0.0;
      });
    }
  }

  Future<void> _unlock() async {
    try {
      await _channel.invokeMethod('unlockAndDismiss');
      SystemNavigator.pop(); // Close Flutter side if it doesn't automatically die
    } on PlatformException catch (e) {
      print("Failed to unlock: '${e.message}'.");
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final double maxSwipe = screenWidth;
    final double opacity = (1 - (_swipeOffset / maxSwipe)).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: Colors.transparent, // Background shows the wallpaper or blur depending on system
      body: GestureDetector(
        onHorizontalDragUpdate: _onHorizontalDragUpdate,
        onHorizontalDragEnd: _onHorizontalDragEnd,
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF2E1A47).withValues(alpha: opacity), // Deep Ubuntu Purple
                Color(0xFFE95420).withValues(alpha: opacity * 0.5), // Ubuntu Orange
              ]
            ),
          ),
          child: Stack(
            children: [
              // Swipe transform layer
              Transform.translate(
                offset: Offset(-_swipeOffset, 0),
                child: Opacity(
                  opacity: opacity,
                  child: Center(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _statIndex = (_statIndex + 1) % _stats.length;
                        });
                      },
                      child: AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, child) {
                          return CustomPaint(
                            painter: InfographicPainter(pulse: _pulseController.value),
                            child: Container(
                              width: 300,
                              height: 300,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.black.withValues(alpha: 0.3),
                                border: Border.all(color: Colors.white24, width: 2),
                              ),
                              child: Center(
                                child: Text(
                                  _stats[_statIndex],
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 32,
                                    fontWeight: FontWeight.w300,
                                    letterSpacing: 1.2,
                                    height: 1.2
                                  ),
                                ),
                              ),
                            ),
                          );
                        }
                      ),
                    ),
                  ),
                ),
              ),
              
              // Edge Hint
              if (_swipeOffset < 20)
                Positioned(
                  right: 10,
                  top: MediaQuery.of(context).size.height / 2 - 20,
                  child: Icon(Icons.arrow_back_ios, color: Colors.white54, size: 40),
                )
            ],
          ),
        ),
      ),
    );
  }
}

class InfographicPainter extends CustomPainter {
  final double pulse;
  InfographicPainter({required this.pulse});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    
    final paint = Paint()
      ..color = ubuntuOrange.withValues(alpha: 0.6)
      ..style = PaintingStyle.fill;
      
    final dotPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.8)
      ..style = PaintingStyle.fill;

    final random = Random(42); // Fixed seed for consistent infographic look
    
    for (int i = 0; i < 60; i++) {
      final angle = (i * 6) * pi / 180;
      final distance = radius + 20 + (random.nextDouble() * 40 * pulse);
      
      final x = center.dx + distance * cos(angle);
      final y = center.dy + distance * sin(angle);
      
      // Draw geometric nodes
      if (i % 3 == 0) {
        canvas.drawCircle(Offset(x, y), 3 + (random.nextDouble() * 3), paint);
      } else {
        canvas.drawCircle(Offset(x, y), 1.5, dotPaint);
      }
      
      // Connect some nodes
      if (i % 5 == 0) {
         final nextAngle = ((i + 5) * 6) * pi / 180;
         final nextDistance = radius + 20 + (random.nextDouble() * 40 * pulse);
         final nextX = center.dx + nextDistance * cos(nextAngle);
         final nextY = center.dy + nextDistance * sin(nextAngle);
         
         final linePaint = Paint()
          ..color = Colors.white24
          ..strokeWidth = 1;
         canvas.drawLine(Offset(x, y), Offset(nextX, nextY), linePaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant InfographicPainter oldDelegate) {
    return oldDelegate.pulse != pulse;
  }
}
