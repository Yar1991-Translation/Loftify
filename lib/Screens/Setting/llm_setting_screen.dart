import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:flutter/material.dart';

import '../../Theme/loftify_design_theme.dart';
import '../../Utils/llm_util.dart';
import '../../l10n/l10n.dart';

/// Configuration for the OpenAI-compatible endpoint used by the tag LLM
/// classifier (DeepSeek, GLM, Moonshot, OpenAI, Ollama, relays…).
class LlmSettingScreen extends StatefulWidget {
  const LlmSettingScreen({
    super.key,
    this.showTitleBar = true,
    this.padding = const EdgeInsets.symmetric(horizontal: 10),
  });

  static const String routeName = "/setting/llm";

  final bool showTitleBar;
  final EdgeInsets padding;

  @override
  State<StatefulWidget> createState() => LlmSettingScreenState();
}

class LlmSettingScreenState extends BaseDynamicState<LlmSettingScreen> {
  late final TextEditingController _baseUrlController;
  late final TextEditingController _apiKeyController;
  late final TextEditingController _modelController;
  bool _obscureKey = true;

  @override
  void initState() {
    super.initState();
    final config = LlmConfig.load();
    _baseUrlController = TextEditingController(text: config.baseUrl);
    _apiKeyController = TextEditingController(text: config.apiKey);
    _modelController = TextEditingController(text: config.model);
  }

  @override
  void dispose() {
    _baseUrlController.dispose();
    _apiKeyController.dispose();
    _modelController.dispose();
    super.dispose();
  }

  void _save() {
    LlmConfig.save(
      baseUrl: _baseUrlController.text,
      apiKey: _apiKeyController.text,
      model: _modelController.text,
    );
    IToast.showTop(appLocalizations.saveSuccess);
  }

  @override
  Widget build(BuildContext context) {
    final design = context.design;
    return ChewieItemBuilder.buildSettingScreen(
      context: context,
      title: appLocalizations.llmSetting,
      showTitleBar: widget.showTitleBar,
      showBack: true,
      padding: widget.padding,
      children: [
        CaptionItem(
          context: context,
          title: appLocalizations.llmService,
          children: [
            InputItem(
              title: appLocalizations.llmBaseUrl,
              description: appLocalizations.llmBaseUrlHint,
              hint: 'https://api.deepseek.com/v1',
              controller: _baseUrlController,
              keyboardType: TextInputType.url,
              onSubmit: (_) => _save(),
            ),
            InputItem(
              title: appLocalizations.llmApiKey,
              hint: 'sk-…',
              controller: _apiKeyController,
              tailingConfig: InputItemLeadingTailingConfig(
                type: InputItemLeadingTailingType.widget,
                widget: ChewieIcon(
                  _obscureKey ? ChewieIcons.eyeOff : ChewieIcons.eye,
                  size: 16,
                ),
                onTap: () => setState(() => _obscureKey = !_obscureKey),
              ),
              style: InputItemStyle(obscure: _obscureKey),
              onSubmit: (_) => _save(),
            ),
            InputItem(
              title: appLocalizations.llmModel,
              description: appLocalizations.llmModelHint,
              hint: 'deepseek-chat',
              controller: _modelController,
              onSubmit: (_) => _save(),
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
                  onPressed: _save,
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
            appLocalizations.llmSettingDescription,
            style: ChewieTheme.bodySmall,
          ),
        ),
      ],
    );
  }
}
