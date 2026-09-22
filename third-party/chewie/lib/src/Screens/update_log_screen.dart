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
  });

  final bool showTitleBar;
  final EdgeInsets padding;

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
          itemBuilder: (context, index) => _buildItem(
            releaseItems[index],
            index,
            index == releaseItems.length - 1,
          ),
          itemCount: releaseItems.length,
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
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: ChewieTheme.cardColor,
                        borderRadius: ChewieDimens.borderRadius8,
                      ),
                      child: SelectableAreaWrapper(
                        focusNode: FocusNode(),
                        child: CustomMarkdownWidget(
                          item.body ?? "",
                          baseStyle: ChewieTheme.bodyMedium,
                        ),
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
}
