## Unreleased

* 重构平台架构：集中通道常量、新增平台能力查询 API
* 新增 `BatteryFeature`、`BatteryPlatformCapabilities`、`UnsupportedBatteryFeatureException`
* macOS 支持事件规范化、回调桥接、显式声明不支持的通知/BLE/IoT 功能
* 示例页面通过能力对象控制功能入口
* 移除 iOS 声明（待未来实现）
* 更新通道契约文档，覆盖所有方法/事件通道与平台支持矩阵
* 更新 README、AGENTS.md、example/AGENTS.md

## 0.0.3

* 新增高级整合API `configureBattery`，一次性配置所有电池监控功能
* 添加 `BatteryConfiguration` 高级配置类，优化参数管理
* 添加更多配置类支持，使API更清晰和易用
* 优化测试覆盖，提高代码稳定性
* 标记旧API为弃用，引导用户使用新的整合API
* 优化示例应用，展示全面电池监控功能
* 增强错误处理和文档

## 0.0.2

* 添加电池电量变化实时监听功能
* 优化电池电量 UI 动画组件，增加自定义参数
* 完善错误处理和权限管理
* 更新示例应用，展示电池电量历史记录

## 0.0.1

* 初始版本发布
* 支持电池电量获取和低电量监控
* 支持系统通知和 Flutter UI 渲染
