import 'package:flutter/material.dart';
import '../../../core/services/notification_service.dart';

class NotificationBannerWidget extends StatefulWidget {
  final NotificationModel notification;
  final bool isDark;
  final VoidCallback onDismiss;

  const NotificationBannerWidget({
    super.key,
    required this.notification,
    required this.isDark,
    required this.onDismiss,
  });

  @override
  State<NotificationBannerWidget> createState() => _NotificationBannerWidgetState();
}

class _NotificationBannerWidgetState extends State<NotificationBannerWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0.0, -1.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    ));
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant NotificationBannerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.notification.id != widget.notification.id) {
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _dismiss() async {
    await _controller.reverse();
    widget.onDismiss();
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.isDark ? Colors.white : Colors.black;
    final textColor = widget.isDark ? Colors.black : Colors.white;
    final borderColor = widget.isDark ? Colors.black : Colors.white;
    final subtextColor = widget.isDark ? Colors.black54 : Colors.white70;

    return SlideTransition(
      position: _offsetAnimation,
      child: GestureDetector(
        onVerticalDragEnd: (details) {
          if (details.primaryVelocity != null && details.primaryVelocity! < -100) {
            _dismiss();
          }
        },
        onTap: _dismiss,
        child: Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor, width: 2),
            boxShadow: [
              BoxShadow(
                color: widget.isDark ? Colors.white24 : Colors.black38,
                offset: const Offset(0, 6),
                blurRadius: 12,
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: textColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getIcon(widget.notification.type),
                  color: _getIconColor(widget.notification.type, textColor),
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.notification.title,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.notification.body,
                      style: TextStyle(
                        color: subtextColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(Icons.close_rounded, color: subtextColor, size: 18),
                onPressed: _dismiss,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIcon(NotificationType type) {
    switch (type) {
      case NotificationType.route:
        return Icons.navigation_rounded;
      case NotificationType.alert:
        return Icons.warning_amber_rounded;
      case NotificationType.success:
        return Icons.check_circle_rounded;
      case NotificationType.info:
      default:
        return Icons.info_outline;
    }
  }

  Color _getIconColor(NotificationType type, Color defaultColor) {
    switch (type) {
      case NotificationType.alert:
        return Colors.orangeAccent;
      case NotificationType.success:
        return Colors.greenAccent;
      case NotificationType.route:
      case NotificationType.info:
      default:
        return defaultColor;
    }
  }
}
