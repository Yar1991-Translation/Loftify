import 'dart:async';

import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:loftify/Screens/Setting/egg_screen.dart';
import 'package:loftify/Widgets/Design/loftify_surfaces.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../Utils/cloud_control_provider.dart';
import '../../Utils/hive_util.dart';
import '../../Widgets/loftify_icons.dart';
import '../../l10n/l10n.dart';
import 'base_setting_screen.dart';

const countThreholdLevel1 = 3;
const countThreholdLevel2 = 6;
const countThreholdLevel3 = 12;
const countThreholdLevel4 = 18;
const countThreholdLevel5 = 24;

class AboutSettingScreen extends BaseSettingScreen {
  const AboutSettingScreen({
    super.key,
    super.padding,
    super.showTitleBar,
    super.searchConfig,
    super.searchText,
  });

  static const String routeName = "/setting/about";

  @override
  State<AboutSettingScreen> createState() => _AboutSettingScreenState();
}

class _AboutSettingScreenState extends BaseDynamicState<AboutSettingScreen>
    with TickerProviderStateMixin {
  int count = 0;
  late String appName = "";
  bool inAppBrowser = ChewieHiveUtil.getBool(HiveUtil.inappWebviewKey);

  Timer? _timer;
  Timer? _hapticTimer;
  final ShakeAnimationController _shakeAnimationController =
      ShakeAnimationController();

  @override
  void initState() {
    super.initState();
    getAppInfo();
  }

  void getAppInfo() {
    PackageInfo.fromPlatform().then((PackageInfo packageInfo) {
      setState(() {
        appName = packageInfo.appName;
      });
    });
  }

  void diaplayCelebrate() {
    restore();
    RouteUtil.pushFadeRoute(context, const EggScreen());
    setState(() {});
  }

  void restore() {
    count = 0;
    if (_timer != null) _timer!.cancel();
    if (_hapticTimer != null) _hapticTimer!.cancel();
    if (_shakeAnimationController.animationRuning) {
      _shakeAnimationController.stop();
    }
    setState(() {});
  }

  void startShake() {
    _shakeAnimationController.start(shakeCount: 0);
  }

  void setHapticTimer(VoidCallback callback) {
    if (_hapticTimer != null) _hapticTimer!.cancel();
    _hapticTimer =
        Timer.periodic(const Duration(milliseconds: 80), (_) => callback());
  }

  @override
  Widget build(BuildContext context) {
    return ChewieItemBuilder.buildSettingScreen(
      context: context,
      title: appLocalizations.about,
      showTitleBar: widget.showTitleBar,
      showBack: !ResponsiveUtil.isLandscapeLayout(),
      padding: widget.padding,
      overrideBody: EasyRefresh(
        child: ListView(
          padding: widget.padding,
          children: [
            const SizedBox(height: 10),
            Center(
              child: ClickableWrapper(
                child: GestureDetector(
                  onLongPressStart: (details) {
                    if (controlProvider.globalControl.enableEasterEggs) {
                      if (_timer != null) _timer!.cancel();
                      _timer =
                          Timer.periodic(const Duration(seconds: 1), (timer) {
                        count = timer.tick;
                        if (count >= countThreholdLevel4 / 4) {
                          diaplayCelebrate();
                        } else if (count >= countThreholdLevel3 / 4) {
                          setHapticTimer(HapticFeedback.heavyImpact);
                        } else if (count >= countThreholdLevel2 / 4) {
                          setHapticTimer(HapticFeedback.mediumImpact);
                        } else if (count >= countThreholdLevel1 / 4) {
                          startShake();
                          setHapticTimer(HapticFeedback.lightImpact);
                        }
                        setState(() {});
                      });
                    }
                  },
                  onLongPressEnd: (details) {
                    restore();
                  },
                  child: ShakeAnimationWidget(
                    shakeAnimationController: _shakeAnimationController,
                    shakeAnimationType: ShakeAnimationType.RandomShake,
                    isForward: false,
                    shakeRange: 0.1,
                    child: Hero(
                      tag: "logo-egg",
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                              color: Theme.of(context).dividerColor, width: 1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.asset(
                            'assets/logo.png',
                            height: 80,
                            width: 80,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Container(
              margin: const EdgeInsets.only(top: 8),
              alignment: Alignment.center,
              child: Text(
                appName,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: LoftifyCard(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildAboutTile(
                      icon: LoftifyIcons.merge,
                      title: appLocalizations.changelog,
                      onTap: () => RouteUtil.pushPanelCupertinoRoute(
                          context, const UpdateLogScreen()),
                    ),
                    const Divider(height: 1, indent: 68),
                    _buildAboutTile(
                      icon: LoftifyIcons.bug,
                      title: appLocalizations.bugReport,
                      external: true,
                      onTap: () => UriUtil.openExternal(
                          controlProvider.globalControl.issueUrl),
                    ),
                    const Divider(height: 1, indent: 68),
                    _buildAboutTile(
                      icon: LoftifyIcons.commit,
                      title: appLocalizations.githubRepo,
                      external: true,
                      onTap: () => UriUtil.openExternal(
                          controlProvider.globalControl.repoUrl),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool external = false,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: scheme.primary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 18, color: scheme.primary),
      ),
      title: Text(title, style: Theme.of(context).textTheme.titleMedium),
      trailing: Icon(
        external ? LoftifyIcons.openExternal : LoftifyIcons.next,
        size: 20,
        color: scheme.onSurfaceVariant,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    );
  }
}
