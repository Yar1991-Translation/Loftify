import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../Screens/AO3/ao3_library_screen.dart';
import '../../Theme/loftify_design_theme.dart';
import '../../Utils/ao3_config.dart';
import '../../Utils/app_provider.dart';
import '../../Utils/ao3_store.dart';
import '../../l10n/l10n.dart';

/// AO3 reader settings: proxy, clipboard prompt, cache budget and text size.
class Ao3SettingScreen extends StatefulWidget {
  const Ao3SettingScreen({
    super.key,
    this.showTitleBar = true,
    this.padding = const EdgeInsets.symmetric(horizontal: 10),
  });

  static const String routeName = "/setting/ao3";

  final bool showTitleBar;
  final EdgeInsets padding;

  @override
  State<Ao3SettingScreen> createState() => _Ao3SettingScreenState();
}

class _Ao3SettingScreenState extends BaseDynamicState<Ao3SettingScreen> {
  static const List<int> _cacheLimits = [20, 50, 100, 200];
  static const List<double> _fontScales = [0.9, 1.0, 1.15, 1.3];

  final Ao3Store _store = Ao3Store();
  late final TextEditingController _proxyController;
  late bool _enabled;
  late bool _clipboardPrompt;
  late int _cacheLimit;
  late double _fontScale;

  @override
  void initState() {
    super.initState();
    final config = Ao3Config.load();
    _proxyController = TextEditingController(text: config.proxy);
    _enabled = config.enabled;
    _clipboardPrompt = config.clipboardPrompt;
    _cacheLimit = config.cacheLimit;
    _fontScale = config.fontScale;
  }

  @override
  void dispose() {
    _proxyController.dispose();
    super.dispose();
  }

  void _saveProxy() {
    Ao3Config.saveProxy(_proxyController.text);
    IToast.showTop(appLocalizations.saveSuccess);
  }

  String _cacheUsage() {
    final count = _store.entries().where((e) => e.cached).length;
    final megabytes = _store.cachedBytes() / (1024 * 1024);
    return appLocalizations.ao3CacheUsage(
      count.toString(),
      megabytes.toStringAsFixed(1) + ' MB',
    );
  }

  void _clearCache() {
    DialogBuilder.showConfirmDialog(
      context,
      title: appLocalizations.ao3ClearCache,
      message: appLocalizations.ao3ClearCacheMessage,
      confirmButtonText: appLocalizations.confirm,
      cancelButtonText: appLocalizations.cancel,
      onTapConfirm: () async {
        await _store.clear();
        if (!mounted) return;
        setState(() {});
        IToast.showTop(appLocalizations.ao3CacheCleared);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final design = context.design;
    return ChewieItemBuilder.buildSettingScreen(
      context: context,
      title: appLocalizations.ao3Setting,
      showTitleBar: widget.showTitleBar,
      showBack: true,
      padding: widget.padding,
      children: [
        CaptionItem(
          context: context,
          title: appLocalizations.ao3Reading,
          children: [
            CheckboxItem(
              context: context,
              value: _enabled,
              title: appLocalizations.ao3Enabled,
              description: appLocalizations.ao3EnabledDescription,
              onTap: () {
                setState(() => _enabled = !_enabled);
                // Through the provider so the shell rebuilds its navigation
                // (the AO3 tab appears or disappears immediately).
                context.read<AppProvider>().ao3Enabled = _enabled;
              },
            ),
            CheckboxItem(
              context: context,
              value: _clipboardPrompt,
              title: appLocalizations.ao3ClipboardPrompt,
              description: appLocalizations.ao3ClipboardPromptDescription,
              onTap: () {
                setState(() => _clipboardPrompt = !_clipboardPrompt);
                Ao3Config.saveClipboardPrompt(_clipboardPrompt);
              },
            ),
            EntryItem(
              context: context,
              title: appLocalizations.ao3Library,
              description: appLocalizations.ao3LibraryDescription,
              onTap: () {
                RouteUtil.pushCupertinoRoute(context, const Ao3LibraryScreen());
              },
            ),
          ],
        ),
        CaptionItem(
          context: context,
          title: appLocalizations.ao3Network,
          children: [
            InputItem(
              title: appLocalizations.ao3Proxy,
              description: appLocalizations.ao3ProxyHint,
              hint: '127.0.0.1:7890',
              controller: _proxyController,
              keyboardType: TextInputType.url,
              onSubmit: (_) => _saveProxy(),
            ),
          ],
        ),
        CaptionItem(
          context: context,
          title: appLocalizations.ao3Cache,
          children: [
            InlineSelectionItem<SelectionItemModel<int>>(
              title: appLocalizations.ao3CacheLimit,
              description: appLocalizations.ao3CacheLimitDescription,
              items: _cacheLimits
                  .map((limit) => SelectionItemModel(limit.toString(), limit))
                  .toList(),
              initItem: SelectionItemModel(_cacheLimit.toString(), _cacheLimit),
              hint: appLocalizations.ao3CacheLimit,
              onChanged: (item) {
                if (item == null) return;
                setState(() => _cacheLimit = item.value);
                Ao3Config.saveCacheLimit(item.value);
                _store.prune();
              },
            ),
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: design.spacing.md,
                vertical: design.spacing.sm,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _cacheUsage(),
                      style: ChewieTheme.bodySmall,
                    ),
                  ),
                  RoundIconTextButton(
                    text: appLocalizations.ao3ClearCache,
                    onPressed: _clearCache,
                  ),
                ],
              ),
            ),
          ],
        ),
        CaptionItem(
          context: context,
          title: appLocalizations.ao3FontScale,
          children: [
            InlineSelectionItem<SelectionItemModel<double>>(
              title: appLocalizations.ao3FontScale,
              description: appLocalizations.ao3FontScaleDescription,
              items: _fontScales
                  .map((scale) => SelectionItemModel(
                      (scale * 100).round().toString() + '%', scale))
                  .toList(),
              initItem: SelectionItemModel(
                  (_fontScale * 100).round().toString() + '%', _fontScale),
              hint: appLocalizations.ao3FontScale,
              onChanged: (item) {
                if (item == null) return;
                setState(() => _fontScale = item.value);
                Ao3Config.saveFontScale(item.value);
              },
            ),
          ],
        ),
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: design.spacing.md,
            vertical: design.spacing.sm,
          ),
          child: Row(
            children: [
              Expanded(
                child: RoundIconTextButton(
                  text: appLocalizations.save,
                  onPressed: _saveProxy,
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: design.spacing.md,
            vertical: design.spacing.xs,
          ),
          child: Text(
            appLocalizations.ao3SettingDescription,
            style: ChewieTheme.bodySmall,
          ),
        ),
      ],
    );
  }
}
