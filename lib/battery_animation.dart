import 'package:flutter/material.dart';
import 'dart:math' as math;

class BatteryAnimation extends StatefulWidget {
  final int batteryLevel;
  final double width;
  final double height;
  final Duration animationDuration;
  final bool isCharging;
  final bool showPercentage;
  final int warningLevel;

  const BatteryAnimation({
    Key? key,
    required this.batteryLevel,
    this.width = 100,
    this.height = 200,
    this.animationDuration = const Duration(milliseconds: 800),
    this.isCharging = false,
    this.showPercentage = true,
    this.warningLevel = 20,
  }) : super(key: key);

  @override
  State<BatteryAnimation> createState() => _BatteryAnimationState();
}

class _BatteryAnimationState extends State<BatteryAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _batteryLevelAnimation;
  late int _previousBatteryLevel;

  @override
  void initState() {
    super.initState();
    _previousBatteryLevel = widget.batteryLevel;

    _animationController = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    );

    _batteryLevelAnimation = Tween<double>(
      begin: _previousBatteryLevel.toDouble(),
      end: widget.batteryLevel.toDouble(),
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _animationController.forward();
  }

  @override
  void didUpdateWidget(BatteryAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.batteryLevel != widget.batteryLevel) {
      _previousBatteryLevel = oldWidget.batteryLevel;
      _batteryLevelAnimation = Tween<double>(
        begin: _previousBatteryLevel.toDouble(),
        end: widget.batteryLevel.toDouble(),
      ).animate(CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ));

      _animationController.reset();
      _animationController.forward();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Color _getBatteryColor(double level) {
    if (level <= widget.warningLevel) {
      return Colors.red;
    } else if (level <= widget.warningLevel * 1.5) {
      return Colors.orange;
    } else {
      return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        final currentLevel = _batteryLevelAnimation.value;
        final color = _getBatteryColor(currentLevel);

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.showPercentage)
              Text(
                '${currentLevel.toInt()}%',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            if (widget.showPercentage) const SizedBox(height: 16),
            CustomPaint(
              size: Size(widget.width, widget.height),
              painter: BatteryPainter(
                batteryLevel: currentLevel / 100,
                batteryColor: color,
                isCharging: widget.isCharging,
              ),
            ),
          ],
        );
      },
    );
  }
}

class BatteryPainter extends CustomPainter {
  final double batteryLevel;
  final Color batteryColor;
  final bool isCharging;

  BatteryPainter({
    required this.batteryLevel,
    required this.batteryColor,
    this.isCharging = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;

    // 电池外壳
    final outlinePaint = Paint()
      ..color = Colors.grey[600]!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    // 电池顶部的小突起
    final topRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(width * 0.3, 0, width * 0.4, height * 0.05),
      const Radius.circular(3),
    );

    // 电池主体
    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, height * 0.05, width, height * 0.95),
      const Radius.circular(10),
    );

    // 画电池外壳
    canvas.drawRRect(topRect, outlinePaint);
    canvas.drawRRect(bodyRect, outlinePaint);

    // 画电池电量
    final fillPaint = Paint()
      ..color = batteryColor
      ..style = PaintingStyle.fill;

    // 计算填充高度（从底部向上填充）
    final fillHeight = (height * 0.95) * batteryLevel;
    final fillMargin = 6.0; // 留出一些边距

    final fillRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        fillMargin,
        height - fillHeight - fillMargin,
        width - (fillMargin * 2),
        fillHeight,
      ),
      const Radius.circular(6),
    );

    canvas.drawRRect(fillRect, fillPaint);

    // 如果在充电，绘制闪电图标
    if (isCharging) {
      final boltPath = Path();
      final centerX = width / 2;
      final topY = height * 0.3;
      final bottomY = height * 0.7;

      // 绘制闪电形状
      boltPath.moveTo(centerX, topY);
      boltPath.lineTo(centerX - width * 0.2, height * 0.5);
      boltPath.lineTo(centerX, height * 0.5);
      boltPath.lineTo(centerX, bottomY);
      boltPath.lineTo(centerX + width * 0.2, height * 0.5);
      boltPath.lineTo(centerX, height * 0.5);
      boltPath.close();

      final boltPaint = Paint()
        ..color = Colors.yellow
        ..style = PaintingStyle.fill;

      canvas.drawPath(boltPath, boltPaint);
    }
  }

  @override
  bool shouldRepaint(covariant BatteryPainter oldDelegate) {
    return oldDelegate.batteryLevel != batteryLevel ||
        oldDelegate.batteryColor != batteryColor ||
        oldDelegate.isCharging != isCharging;
  }
}

// 低电量警告对话框
class LowBatteryDialog extends StatelessWidget {
  final int batteryLevel;
  final VoidCallback? onDismiss;

  const LowBatteryDialog({
    Key? key,
    required this.batteryLevel,
    this.onDismiss,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('电量不足警告'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 20),
          BatteryAnimation(
            batteryLevel: batteryLevel,
            width: 60,
            height: 120,
          ),
          const SizedBox(height: 20),
          Text(
            '当前电量: $batteryLevel%',
            style: const TextStyle(fontSize: 18),
          ),
          const SizedBox(height: 10),
          const Text(
            '请尽快给设备充电，否则可能会自动关机',
            textAlign: TextAlign.center,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            if (onDismiss != null) {
              onDismiss!();
            }
          },
          child: const Text('稍后提醒'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('知道了'),
        ),
      ],
    );
  }
}
