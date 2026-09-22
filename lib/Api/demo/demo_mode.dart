import 'package:awesome_chewie/awesome_chewie.dart';

import '../../Utils/app_provider.dart';
import '../../Utils/hive_util.dart';
import 'demo_data.dart';

/// 演示模式（Dev）：`--dart-define=DEMO_MODE=true` 启用。
///
/// 启用后所有 API 请求在 [RequestUtil] 层被 [DemoServer] 拦截并返回测试
/// 数据，不发出任何真实网络请求；同时注入演示账号，让「我的」等需要登录
/// 的界面也能完整演示。演示 token 会在正常启动时自动还原用户真实会话。
class DemoMode {
  static const bool enabled = bool.fromEnvironment('DEMO_MODE');

  static const String demoToken = 'demo-token';
  static const String _savedTokenKey = 'demoMode.savedToken';

  /// 注入演示登录态（仅 demo 启动时调用；真实 token 先存起来）。
  static void seedDemoLogin() {
    final current = appProvider.token;
    if (current != demoToken) {
      ChewieHiveUtil.put(_savedTokenKey, current);
    }
    appProvider.token = demoToken;
    ChewieHiveUtil.put(HiveUtil.userIdKey, DemoData.demoBlogId);
    ChewieHiveUtil.put(HiveUtil.userInfoKey, DemoData.demoFullBlogInfo());
  }

  /// 正常启动时若残留演示 token 则还原用户真实会话。
  static void restoreRealLoginIfStale() {
    if (appProvider.token != demoToken) return;
    appProvider.token = ChewieHiveUtil.getString(_savedTokenKey) ?? '';
    ChewieHiveUtil.delete(_savedTokenKey);
    ChewieHiveUtil.delete(HiveUtil.userInfoKey);
    ChewieHiveUtil.delete(HiveUtil.userIdKey);
  }
}
