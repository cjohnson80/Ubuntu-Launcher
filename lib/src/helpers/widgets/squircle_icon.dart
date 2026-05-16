import 'package:flutter/material.dart';

class SquircleIcon extends StatelessWidget {
  final ImageProvider? icon;
  final IconData? fallbackIcon;
  final double size;
  final double borderRadius;
  final Color backgroundColor;

  const SquircleIcon({
    Key? key,
    this.icon,
    this.fallbackIcon,
    this.size = 64.0,
    this.borderRadius = 18.0,
    this.backgroundColor = Colors.white,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: icon != null
            ? Padding(
                padding: EdgeInsets.all(size * 0.15), // 15% padding inside the squircle
                child: Image(
                  image: icon!,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => _buildFallback(),
                ),
              )
            : _buildFallback(),
      ),
    );
  }

  Widget _buildFallback() {
    return Center(
      child: Icon(
        fallbackIcon ?? Icons.apps,
        size: size * 0.6,
        color: Colors.black54,
      ),
    );
  }
}
