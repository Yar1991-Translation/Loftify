import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:flutter/material.dart';
import 'package:loftify/Api/setting_api.dart';

import '../../Widgets/Item/setting_management_item.dart';
import '../../Widgets/loftify_icons.dart';
import '../../l10n/l10n.dart';
import 'base_setting_screen.dart';

class TagShieldSettingScreen extends BaseSettingScreen {
  const TagShieldSettingScreen({
    super.key,
    super.padding,
    super.showTitleBar,
    super.searchConfig,
    super.searchText,
  });

  static const String routeName = "/setting/tagShield";

  @override
  State<TagShieldSettingScreen> createState() => _TagShieldSettingScreenState();
}

class _TagShieldSettingScreenState
    extends BaseDynamicState<TagShieldSettingScreen>
    with TickerProviderStateMixin {
  /// Tags applied by the one-tap otome content filter. Deliberately limited
  /// to explicit otome markers; broader classifications such as「女性向」are
  /// excluded so other content is not caught in the net.
  static const List<String> _otomeShieldTags = [
    '乙女',
    '乙女向',
    '乙女游戏',
    '乙女ゲーム',
    '乙游',
  ];

  bool loading = false;
  bool _applyingOtomeFilter = false;
  final EasyRefreshController _refreshController = EasyRefreshController();
  List<String> tags = [];

  @override
  void dispose() {
    _refreshController.dispose();
    super.dispose();
  }

  void _applyOtomeFilter() {
    if (_applyingOtomeFilter) return;
    final existing = tags.toSet();
    final pending =
        _otomeShieldTags.where((tag) => !existing.contains(tag)).toList();
    if (pending.isEmpty) {
      IToast.showTop(appLocalizations.oneClickOtomeFilterNoChange);
      return;
    }
    DialogBuilder.showConfirmDialog(
      context,
      title: appLocalizations.oneClickOtomeFilter,
      message:
          appLocalizations.oneClickOtomeFilterConfirm(pending.join('、')),
      confirmButtonText: appLocalizations.confirm,
      onTapConfirm: () => _runOtomeFilter(pending),
      onTapCancel: () {},
      customDialogType: CustomDialogType.normal,
    );
  }

  Future<void> _runOtomeFilter(List<String> pending) async {
    setState(() => _applyingOtomeFilter = true);
    var added = 0;
    var failed = 0;
    for (final tag in pending) {
      try {
        final value =
            await SettingApi.shieldOrUnshieldTag(tag: tag, isShield: true);
        if (value != null && value['meta']['status'] == 200) {
          added++;
          if (!tags.contains(tag)) tags.insert(0, tag);
        } else {
          failed++;
        }
      } catch (e, t) {
        ILogger.error('Failed to shield otome tag $tag', e, t);
        failed++;
      }
    }
    if (!mounted) return;
    setState(() => _applyingOtomeFilter = false);
    IToast.showTop(failed == 0
        ? appLocalizations.oneClickOtomeFilterAdded(added)
        : appLocalizations.oneClickOtomeFilterPartial(added, failed));
  }

  Future<IndicatorResult> _fetchTags() async {
    if (loading || !mounted) return IndicatorResult.none;
    loading = true;
    try {
      final value = await SettingApi.getShieldTagList();
      if (!mounted) return IndicatorResult.none;
      if (value == null) return IndicatorResult.fail;
      if (value['meta']['status'] != 200) {
        IToast.showTop(value['meta']['desc'] ?? value['meta']['msg']);
        return IndicatorResult.fail;
      } else {
        tags = (value['response']['list'] as List)
            .map((e) => e.toString())
            .toList();
        return IndicatorResult.success;
      }
    } catch (e, t) {
      if (!mounted) return IndicatorResult.none;
      ILogger.error("Failed to load tag shield list", e, t);
      IToast.showTop(appLocalizations.loadFailed);
      return IndicatorResult.fail;
    } finally {
      loading = false;
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChewieItemBuilder.buildSettingScreen(
      context: context,
      title: appLocalizations.tagShieldSetting,
      showTitleBar: widget.showTitleBar,
      showBack: !ResponsiveUtil.isLandscapeLayout(),
      padding: widget.padding,
      actions: [
        CircleIconButton(
          context: context,
          icon: ChewieIcon(
            LoftifyIcons.add,
            color: Theme.of(context).iconTheme.color,
          ),
          onTap: () {
            BottomSheetBuilder.showBottomSheet(
              context,
              (sheetContext) => InputBottomSheet(
                buttonText: appLocalizations.confirm,
                title: appLocalizations.addShieldTag,
                text: "",
                onConfirm: (text) {
                  SettingApi.shieldOrUnshieldTag(tag: text, isShield: true)
                      .then((value) {
                    IToast.showTop(
                        value['meta']['desc'] ?? value['meta']['msg']);
                    if (value['meta']['status'] == 200) {
                      tags.insert(0, text);
                      setState(() {});
                    }
                  });
                },
              ),
              preferMinWidth: 400,
              responsive: true,
            );
          },
        ),
      ],
      overrideBody: EasyRefresh(
        controller: _refreshController,
        refreshOnStart: true,
        onRefresh: () async {
          return await _fetchTags();
        },
        triggerAxis: Axis.vertical,
        child: ListView(
          padding: widget.padding,
          children: [
            CaptionItem(
              title: appLocalizations.oneClickOtomeFilter,
              children: [
                SettingManagementItem(
                  title: appLocalizations.oneClickOtomeFilter,
                  description: _applyingOtomeFilter
                      ? appLocalizations.shieldingOtome
                      : appLocalizations.oneClickOtomeFilterDescription(
                          _otomeShieldTags.join('、'),
                        ),
                  leadingIcon: LoftifyIcons.block,
                  actionLabel: appLocalizations.apply,
                  onAction: _applyOtomeFilter,
                ),
              ],
            ),
            CaptionItem(
              title: '${appLocalizations.tagShieldSetting} (${tags.length})',
              children: tags.isEmpty
                  ? [
                      SettingManagementEmptyState(
                          text: appLocalizations.noContent),
                    ]
                  : tags.map(_buildTagRow).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTagRow(String tag) {
    return SettingManagementItem(
      title: tag,
      leadingIcon: LoftifyIcons.tag,
      actionLabel: appLocalizations.unblockShieldTag,
      onAction: () {
        DialogBuilder.showConfirmDialog(
          context,
          title: appLocalizations.unblockShieldTag,
          message: appLocalizations.unblockShieldTagMessage(tag),
          confirmButtonText: appLocalizations.unlock,
          onTapConfirm: () {
            SettingApi.shieldOrUnshieldTag(tag: tag, isShield: false)
                .then((value) {
              IToast.showTop(value['meta']['desc'] ?? value['meta']['msg']);
              if (value['meta']['status'] == 200) {
                tags.remove(tag);
                setState(() {});
              }
            });
          },
          onTapCancel: () {},
          customDialogType: CustomDialogType.normal,
        );
      },
    );
  }
}
