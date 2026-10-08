/*
 * Copyright (c) 2025 Robert-Stackflow.
 *
 * This program is free software: you can redistribute it and/or modify it under the terms of the
 * GNU General Public License as published by the Free Software Foundation, either version 3 of the
 * License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without
 * even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along with this program.
 * If not, see <https://www.gnu.org/licenses/>.
 */

import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:awesome_chewie/src/Utils/System/route_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:package_info_plus/package_info_plus.dart';

class UpdateLogScreen extends StatefulWidget {
  const UpdateLogScreen({
    super.key,
    this.showTitleBar = true,
    this.padding = const EdgeInsets.symmetric(horizontal: 10),
    this.feedbackCard,
  });

  final bool showTitleBar;
  final EdgeInsets padding;

  /// Mounted above the timeline by the host app: its feedback entry point
  /// (a QQ group card, a mail row...). Optional.
  final Widget? feedbackCard;

  @override
  State<UpdateLogScreen> createState() => _UpdateLogScreenState();
}

class _UpdateLogScreenState extends BaseDynamicState<UpdateLogScreen>
    with TickerProviderStateMixin {
  List<ReleaseItem> releaseItems = [];
  final EasyRefreshController _refreshController = EasyRefreshController();
  String currentVersion = "";
  String latestVersion = "";

  @override
  void initState() {
    super.initState();
    getAppInfo();
  }

  void getAppInfo() {
    PackageInfo.fromPlatform().then((PackageInfo packageInfo) {
      setState(() {
        currentVersion = packageInfo.version;
      });
    });
  }

  /// 本地更新日志：从 v2.6.0（本 fork 的首个版本）开始维护，不依赖
  /// GitHub Releases。发布新版本时在列表头部追加一条即可。
  static final List<ReleaseItem> _localReleases = [
    ReleaseItem(
      assets: const [],
      assetsUrl: '',
      author: null,
      createdAt: DateTime(2026, 10, 9),
      draft: false,
      htmlUrl: 'https://github.com/Yar1991-Translation/Loftify/releases',
      id: 20261009,
      name: 'Loftify 2.7.0-dev.2',
      nodeId: '',
      prerelease: true,
      publishedAt: DateTime(2026, 10, 9),
      tagName: 'v2.7.0-dev.2',
      tarballUrl: '',
      targetCommitish: 'dev/ao3',
      uploadUrl: '',
      url: 'https://github.com/Yar1991-Translation/Loftify/releases',
      zipballUrl: null,
      body: '''
开发版 · AO3 主页

- 新增 AO3 主页：搜索框、继续阅读、关注标签与最新动态，首屏全部走本地缓存
- 新增 AO3 搜索页：作品搜索（由 AO3 处理，较慢）与标签浏览（快）双模式
- 标签管理：关注与取消关注集中在「管理标签」面板，建议标签来自你缓存过的作品
- 修复带斜杠的标签打不开（Hurt/Comfort 之类的关系标签此前一律 404）
- 修复删除作品后主页仍显示、点开又被重新缓存的问题
- 书库卡片支持左滑删除
- 修复点击作品标签导致的崩溃（标签改为纯展示）
- AO3 界面与底部导航按钮改用 AO3 主题色 #990000 生成的莫奈配色
- 「在 AO3 打开」改为系统浏览器，并新增独立按钮
- 更新日志改为逐条列表展示，设置与更新日志新增 QQ 反馈群入口（257167340）
''',
    ),
    ReleaseItem(
      assets: const [],
      assetsUrl: '',
      author: null,
      createdAt: DateTime(2026, 10, 5),
      draft: false,
      htmlUrl: 'https://github.com/Yar1991-Translation/Loftify/releases',
      id: 20261005,
      name: 'Loftify 2.7.0-dev.1',
      nodeId: '',
      prerelease: true,
      publishedAt: DateTime(2026, 10, 5),
      tagName: 'v2.7.0-dev.1',
      tarballUrl: '',
      targetCommitish: 'dev/ao3',
      uploadUrl: '',
      url: 'https://github.com/Yar1991-Translation/Loftify/releases',
      zipballUrl: null,
      body: '''
开发版 · AO3 阅读

- 新增 AO3 阅读：识别作品链接后用应用自己的界面显示标题、作者、标签、摘要与章节正文，支持章节切换、阅读进度记忆与离线重读
- AO3 抓取走官方导出接口，需要时可单独配置代理；抓取失败可一键用内置浏览器打开原页
- 新增 AO3 书库与阅读设置（代理、剪贴板提示、缓存上限、正文字号）
- 复制 AO3 链接后可选提示打开（默认关闭，设置里开启）
- 本开发版仅用于测试，正式功能以之后的稳定版为准
''',
    ),
    ReleaseItem(
      assets: const [],
      assetsUrl: '',
      author: null,
      createdAt: DateTime(2026, 10, 1),
      draft: false,
      htmlUrl: 'https://github.com/Yar1991-Translation/Loftify/releases',
      id: 20261001,
      name: 'Loftify 2.6.3',
      nodeId: '',
      prerelease: false,
      publishedAt: DateTime(2026, 10, 1),
      tagName: 'v2.6.3',
      tarballUrl: '',
      targetCommitish: 'main',
      uploadUrl: '',
      url: 'https://github.com/Yar1991-Translation/Loftify/releases',
      zipballUrl: null,
      body: '''
- 本版本部分功能与代码参考自上游仓库 Robert-Stackflow/Loftify（v3.0.0 / v3.1.0）：加载与分页健壮性修复、剪贴板链接识别、合集与粮单排序记忆、Windows SQLite 打包、搜索框样式
- 收藏夹、乐投、推荐、粮单、帖子归档的加载与分页全面加固：切换账号后不再串入上一账号的数据，批量下载遇到数据不完整会明确报错，而不是给出半份列表
- Windows 发布包补上 sqlite3.dll，修复能启动但没有画面的问题
- 新增：复制 LOFTER 链接后切回应用，可直接打开该链接
- 新增：合集与粮单的排序方式会被记住
- 搜索框改为圆角样式、搜索按钮移到右侧；桌面端窗口按钮独立成一行，搜索框加宽
''',
    ),
    ReleaseItem(
      assets: const [],
      assetsUrl: '',
      author: null,
      createdAt: DateTime(2026, 9, 23),
      draft: false,
      htmlUrl: 'https://github.com/Yar1991-Translation/Loftify/releases',
      id: 20260923,
      name: 'Loftify 2.6.1',
      nodeId: '',
      prerelease: false,
      publishedAt: DateTime(2026, 9, 23),
      tagName: 'v2.6.1',
      tarballUrl: '',
      targetCommitish: 'main',
      uploadUrl: '',
      url: 'https://github.com/Yar1991-Translation/Loftify/releases',
      zipballUrl: null,
      body: '''
- 平板竖屏改用与手机一致的样式和底部悬浮导航栏，横屏保留侧边导航栏
- 悬浮栏位置三种可选（居中浮动 / 右下停靠 / 底部全宽），折叠展开动画全面重制，滚动更顺滑
- 阅读页在平板上不再使用电脑双栏，正文优先、相关推荐在下
- 搜索框换用 Material 3 SearchBar，修复输入卡顿
- 按钮、对话框、底部面板、提示等组件全面替换为 Material 3，显著降低卡顿
- 新增启动时自动检查更新（设置中可关闭）
''',
    ),
    ReleaseItem(
      assets: const [],
      assetsUrl: '',
      author: null,
      createdAt: DateTime(2026, 9, 22),
      draft: false,
      htmlUrl: 'https://github.com/Yar1991-Translation/Loftify/releases',
      id: 20260922,
      name: 'Loftify 2.6.0',
      nodeId: '',
      prerelease: false,
      publishedAt: DateTime(2026, 9, 22),
      tagName: 'v2.6.0',
      tarballUrl: '',
      targetCommitish: 'main',
      uploadUrl: '',
      url: 'https://github.com/Yar1991-Translation/Loftify/releases',
      zipballUrl: null,
      body: '''
- 全新 Material 3 Expressive 视觉：右下角停靠的悬浮导航栏，滚动时收起为圆形按钮
- 标签长按（或右键）即可屏蔽，乙女向内容一键过滤
- 标签 LLM 智能分类，支持按分类持久过滤
- 新增演示模式（DEMO_MODE）与桌面端手机布局开关（FORCE_MOBILE_LAYOUT）
- 应用包名统一为 com.loftify.yatmt
- 修复部分设备因日期区域数据未初始化而卡在启动页的问题
''',
    ),
  ];

  Future<void> fetchReleases() async {
    if (!mounted) return;
    setState(() {
      releaseItems = _localReleases;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.showTitleBar
          ? ResponsiveAppBar(
              title: chewieLocalizations.changelog,
              showBack: true,
              onTapBack: () {
                RouteUtil.popSubPage(context);
              },
              backgroundColor: ResponsiveUtil.isLandscapeLayout()
                  ? ChewieTheme.canvasColor
                  : ChewieTheme.scaffoldBackgroundColor,
            )
          : null,
      body: EasyRefresh(
        controller: _refreshController,
        refreshOnStart: true,
        onRefresh: () async {
          await fetchReleases();
        },
        child: ListView.builder(
          padding: widget.padding
              .add(const EdgeInsets.symmetric(horizontal: 8, vertical: 20)),
          itemCount: releaseItems.length + (widget.feedbackCard != null ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == 0 && widget.feedbackCard != null) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: widget.feedbackCard!,
              );
            }
            final itemIndex =
                index - (widget.feedbackCard != null ? 1 : 0);
            return _buildItem(
              releaseItems[itemIndex],
              itemIndex,
              itemIndex == releaseItems.length - 1,
            );
          },
        ),
      ),
    );
  }

  Widget _buildItem(ReleaseItem item, int index, bool isLast) {
    final isCurrent = ChewieUtils.compareVersion(
            item.tagName.replaceAll(RegExp(r'[a-zA-Z]'), ''), currentVersion) ==
        0;

    final releaseDate =
        item.publishedAt != null ? TimeUtil.formatDate(item.publishedAt!) : "";

    final color = HSLColor.fromAHSL(
      1.0,
      140 + (index * 220 / (releaseItems.length + 1)),
      0.6,
      isCurrent ? 0.5 : 0.4,
    ).toColor();

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isCurrent ? ChewieTheme.primaryColor : color,
                  border: Border.all(color: Colors.grey.shade300, width: 2),
                ),
              ).animate().fadeIn(duration: 400.ms).scale(delay: 50.ms),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.only(top: 2),
                    color: Colors.grey.shade300,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        "${item.tagName}  $releaseDate",
                        style: ChewieTheme.bodyMedium,
                      ),
                      const SizedBox(width: 6),
                      if (isCurrent)
                        RoundIconTextButton(
                          height: 20,
                          text: chewieLocalizations.currentVersion,
                          background: ChewieTheme.primaryColor,
                          textStyle: ChewieTheme.labelMedium.apply(
                            color: ChewieTheme.primaryButtonColor,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          radius: 4,
                        ),
                      const Spacer(),
                      ClickableGestureDetector(
                        // padding: const EdgeInsets.symmetric(
                        //   horizontal: 6,
                        //   vertical: 2,
                        // ),
                        child: Icon(
                          ChewieIcons.next,
                          size: 16,
                          color: ChewieTheme.labelMedium.color,
                        ),
                        onTap: () {
                          UriUtil.openExternal(item.htmlUrl);
                        },
                      ),
                    ],
                  ),
                  if ((item.body ?? "").isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: ChewieTheme.cardColor,
                        borderRadius: ChewieDimens.borderRadius8,
                      ),
                      child: SelectableAreaWrapper(
                        focusNode: FocusNode(),
                        child: _buildBodyLines(context, item.body ?? ""),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Update notes read best as a calm list, not a markdown dump: strip
  /// list markers and link syntax, then render one quiet bullet per line.
  List<String> _bodyLines(String body) {
    final rows = <String>[];
    for (final raw in body.replaceAll('\r\n', '\n').split('\n')) {
      var text = raw.trim();
      if (text.isEmpty) continue;
      text = text.replaceFirst(RegExp(r'^#{1,6}\s*'), '');
      text = text.replaceFirst(RegExp(r'^[-*•]\s*'), '');
      text = text.replaceAll(RegExp(r'\[([^\]]+)\]\(([^)]+)\)'), r'$1');
      text = text.replaceAll(RegExp(r'\*{1,2}([^*]+)\*{1,2}'), r'$1');
      text = text.trim();
      if (text.isEmpty) continue;
      rows.add(text);
    }
    return rows;
  }

  Widget _buildBodyLines(BuildContext context, String body) {
    final rows = _bodyLines(body);
    final dotColor =
        ChewieTheme.labelMedium.color?.withValues(alpha: 0.55) ??
        ChewieTheme.primaryColor;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < rows.length; i++)
          Padding(
            padding: EdgeInsets.only(
              bottom: i == rows.length - 1 ? 0 : 6,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: dotColor,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    rows[i],
                    style: ChewieTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
