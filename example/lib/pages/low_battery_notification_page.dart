import 'package:flutter/material.dart';
import 'package:flutter_battery/flutter_battery.dart';

/// Demonstrates calling `configureBatteryMonitoring` to hook into the
/// Android PushNotificationManager (or Flutter callbacks) for low-battery alerts.
class LowBatteryNotificationPage extends StatefulWidget {
  const LowBatteryNotificationPage({required this.plugin, super.key});

  final FlutterBattery plugin;

  @override
  State<LowBatteryNotificationPage> createState() => _LowBatteryNotificationPageState();
}

class _LowBatteryNotificationPageState extends State<LowBatteryNotificationPage> {
  final TextEditingController _titleController = TextEditingController(text: '电池电量低');
  final TextEditingController _messageController =
      TextEditingController(text: '当前电池电量已低于预设阈值，请注意充电');

  double _threshold = 20;
  double _intervalMinutes = 15;
  bool _useFlutterRendering = false;
  bool _monitoringEnabled = false;
  bool _busy = false;
  String? _status;

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _toggleMonitoring(bool enable) async {
    setState(() {
      _busy = true;
      _status = enable ? '正在开启低电量监控...' : '正在关闭低电量监控...';
    });
    try {
      // Optional: keep Flutter in the loop for foreground handling.
      if (enable && _useFlutterRendering) {
        widget.plugin.configureBatteryCallbacks(onLowBattery: (level) {
          if (!mounted) return;
          _showSnack('Flutter 收到低电量回调：$level%');
        });
      }

      // Core call bridging to Android PushNotificationManager via MethodChannel.
      final success = await widget.plugin.configureBatteryMonitoring(
        BatteryLevelMonitorConfig(
          enable: enable,
          threshold: _threshold.round(),
          title: _titleController.text.trim().isEmpty ? '电池电量低' : _titleController.text.trim(),
          message: _messageController.text.trim().isEmpty
              ? '当前电池电量已低于预设阈值，请注意充电'
              : _messageController.text.trim(),
          intervalMinutes: _intervalMinutes.round(),
          useFlutterRendering: _useFlutterRendering,
          onLowBattery: _useFlutterRendering ? (int level) => _showSnack('电量低至 $level%') : null,
        ),
      );

      if (!mounted) return;
      setState(() {
        _monitoringEnabled = enable && (success ?? false);
        _status = success == true
            ? (enable
                ? '监控已开启，低于 ${_threshold.round()}% 将通过系统通知提示'
                : '监控已关闭')
            : '操作未生效，请检查日志';
      });
    } catch (err) {
      if (!mounted) return;
      setState(() {
        _status = '监控配置失败: $err';
      });
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  // Quick path to trigger the native PushNotificationManager for manual verification.
  Future<void> _sendTestNotification({int delayMinutes = 0}) async {
    setState(() {
      _busy = true;
      _status = delayMinutes == 0 ? '正在发送即时通知...' : '正在调度延迟通知...';
    });
    try {
      final ok = await widget.plugin.sendNotification(
        title: '系统通知示例',
        message: delayMinutes == 0
            ? '这是一个立即触发的测试通知'
            : '这是一个延迟 $delayMinutes 分钟的测试通知',
        delay: delayMinutes,
      );
      if (!mounted) return;
      setState(() {
        _status = ok == true ? '通知已${delayMinutes == 0 ? '发送' : '调度'}' : '通知触发失败';
      });
    } catch (err) {
      if (!mounted) return;
      setState(() {
        _status = '通知调用失败: $err';
      });
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('低电量通知示例')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            '调用 FlutterBattery.configureBatteryMonitoring，Android 侧将通过 PushNotificationManager 订阅电量并发送系统通知。可以选择 Flutter 回调在前台提示。',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _useFlutterRendering,
                    title: const Text('同时使用 Flutter 回调'),
                    subtitle: const Text('打开后低电量会先回调 Dart，关闭则直接走原生系统通知'),
                    onChanged: _busy ? null : (value) => setState(() => _useFlutterRendering = value),
                  ),
                  const SizedBox(height: 12),
                  _LabeledSlider(
                    label: '低电量阈值',
                    valueLabel: '${_threshold.round()}%',
                    value: _threshold,
                    min: 5,
                    max: 50,
                    divisions: 9,
                    onChanged: _busy ? null : (value) => setState(() => _threshold = value),
                  ),
                  const SizedBox(height: 8),
                  _LabeledSlider(
                    label: '检查间隔',
                    valueLabel: '${_intervalMinutes.round()} 分钟',
                    value: _intervalMinutes,
                    min: 1,
                    max: 60,
                    divisions: 59,
                    onChanged: _busy ? null : (value) => setState(() => _intervalMinutes = value),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: '通知标题',
                      border: OutlineInputBorder(),
                    ),
                    enabled: !_busy,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      labelText: '通知内容',
                      border: OutlineInputBorder(),
                    ),
                    enabled: !_busy,
                    maxLines: 2,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              ElevatedButton.icon(
                onPressed: _busy ? null : () => _toggleMonitoring(true),
                icon: const Icon(Icons.play_arrow),
                label: const Text('开启监控'),
              ),
              OutlinedButton.icon(
                onPressed: (_busy || !_monitoringEnabled) ? null : () => _toggleMonitoring(false),
                icon: const Icon(Icons.stop),
                label: const Text('停止监控'),
              ),
              OutlinedButton.icon(
                onPressed: _busy ? null : () => _sendTestNotification(),
                icon: const Icon(Icons.notifications_active_outlined),
                label: const Text('立即测试通知'),
              ),
              OutlinedButton.icon(
                onPressed: _busy ? null : () => _sendTestNotification(delayMinutes: 1),
                icon: const Icon(Icons.schedule),
                label: const Text('1 分钟后提醒'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_busy) ...[
            const LinearProgressIndicator(minHeight: 2),
            const SizedBox(height: 12),
          ],
          if (_status != null)
            Text(
              _status!,
              style: theme.textTheme.bodySmall,
            ),
        ],
      ),
    );
  }
}

class _LabeledSlider extends StatelessWidget {
  const _LabeledSlider({
    required this.label,
    required this.valueLabel,
    required this.value,
    required this.onChanged,
    this.min = 0,
    this.max = 100,
    this.divisions,
  });

  final String label;
  final String valueLabel;
  final double value;
  final double min;
  final double max;
  final int? divisions;
  final ValueChanged<double>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
            Text(
              valueLabel,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          label: valueLabel,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
