import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:flutter/material.dart';

import '../../Models/recommend_response.dart';
import '../../Theme/loftify_design_theme.dart';
import '../../Utils/llm_util.dart';
import '../../Utils/tag_llm_classifier.dart';
import '../../l10n/l10n.dart';
import '../Design/loftify_surfaces.dart';

/// Bottom sheet for the tag LLM classifier: shows the fandom attributes
/// (ship / ending / form) currently assigned to the tag's loaded posts,
/// lets the user trigger (re-)classification and pick a value to filter
/// by. [onSelect] receives the dimension and value to show only matching
/// posts; [onClear] resets the filter.
class LlmClassificationBottomSheet extends StatefulWidget {
  const LlmClassificationBottomSheet({
    super.key,
    required this.tag,
    required this.posts,
    required this.selectedDimension,
    required this.selectedValue,
    this.onSelect,
    this.onClear,
  });

  final String tag;
  final List<PostListItem> posts;
  final TagLlmDimension? selectedDimension;
  final String? selectedValue;
  final void Function(TagLlmDimension dimension, String value)? onSelect;
  final VoidCallback? onClear;

  @override
  State<StatefulWidget> createState() => LlmClassificationBottomSheetState();
}

class LlmClassificationBottomSheetState
    extends State<LlmClassificationBottomSheet> {
  bool _running = false;
  int _done = 0;
  int _total = 0;
  String? _error;

  late Map<int, TagClassification> _classifications;

  @override
  void initState() {
    super.initState();
    _classifications = TagLlmClassifier.load(widget.tag);
  }

  Future<void> _classify() async {
    final config = LlmConfig.load();
    if (!config.isConfigured) {
      IToast.showTop(appLocalizations.llmNotConfigured);
      return;
    }
    if (widget.posts.isEmpty) {
      IToast.showTop(appLocalizations.noSearchResult);
      return;
    }
    setState(() {
      _running = true;
      _error = null;
      _done = 0;
      _total = 0;
    });
    try {
      final result = await TagLlmClassifier.classify(
        widget.tag,
        widget.posts,
        config: config,
        onProgress: (done, total) {
          if (!mounted) return;
          setState(() {
            _done = done;
            _total = total;
          });
        },
      );
      if (!mounted) return;
      setState(() {
        _classifications = result;
        _running = false;
      });
      IToast.showTop(appLocalizations.llmClassifyDone);
    } on LlmException catch (error) {
      if (!mounted) return;
      setState(() {
        _running = false;
        _error = error.message;
      });
    } catch (error, stackTrace) {
      ILogger.error("Tag LLM classification failed", error, stackTrace);
      if (!mounted) return;
      setState(() {
        _running = false;
        _error = appLocalizations.loadFailed;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final design = context.design;
    final hasResults = _classifications.values.any((c) => c.hasAnyValue);
    return LoftifyPanel(
      title: appLocalizations.llmClassify,
      expandBody: true,
      body: SingleChildScrollView(
        primary: false,
        child: Padding(
          padding: EdgeInsets.all(design.spacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                appLocalizations.llmClassifyDescription(widget.posts.length),
                style: design.typography.body.copyWith(
                  color: design.colors.textSecondary,
                ),
              ),
              if (_running) ...[
                SizedBox(height: design.spacing.md),
                Row(
                  children: [
                    SizedBox.square(
                      dimension: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: design.colors.accent,
                      ),
                    ),
                    SizedBox(width: design.spacing.sm),
                    Expanded(
                      child: Text(
                        appLocalizations.llmClassifyProgress(_done, _total),
                        style: design.typography.body.copyWith(
                          color: design.colors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              if (_error != null) ...[
                SizedBox(height: design.spacing.md),
                Text(
                  _error!,
                  style: design.typography.body.copyWith(
                    color: design.colors.danger,
                  ),
                ),
              ],
              SizedBox(height: design.spacing.lg),
              if (!hasResults && !_running)
                Padding(
                  padding: EdgeInsets.symmetric(vertical: design.spacing.lg),
                  child: Center(
                    child: Text(
                      appLocalizations.llmClassifyEmpty,
                      style: design.typography.body.copyWith(
                        color: design.colors.textSecondary,
                      ),
                    ),
                  ),
                )
              else ...[
                _buildDimensionGroup(
                  TagLlmDimension.cp,
                  appLocalizations.llmDimensionCp,
                ),
                _buildDimensionGroup(
                  TagLlmDimension.ending,
                  appLocalizations.llmDimensionEnding,
                ),
                _buildDimensionGroup(
                  TagLlmDimension.kind,
                  appLocalizations.llmDimensionKind,
                ),
              ],
              SizedBox(height: design.spacing.lg),
              Row(
                children: [
                  Expanded(
                    child: RoundIconTextButton(
                      text: _running
                          ? appLocalizations.llmClassifyRunning
                          : hasResults
                              ? appLocalizations.llmClassifyUpdate
                              : appLocalizations.llmClassifyStart,
                      onPressed: _running ? null : _classify,
                    ),
                  ),
                  if (widget.selectedValue != null) ...[
                    SizedBox(width: design.spacing.sm),
                    Expanded(
                      child: RoundIconTextButton(
                        text: appLocalizations.llmClassifyClearFilter,
                        background: design.colors.surfaceRaised,
                        onPressed: () {
                          widget.onClear?.call();
                          Navigator.pop(context);
                        },
                      ),
                    ),
                  ],
                ],
              ),
              SizedBox(height: design.spacing.md),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDimensionGroup(
    TagLlmDimension dimension,
    String title,
  ) {
    final design = context.design;
    final values = TagLlmClassifier.valuesWithCounts(
      dimension,
      _classifications,
      widget.posts,
    );
    if (values.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: EdgeInsets.only(bottom: design.spacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: design.typography.sectionTitle.copyWith(
              color: design.colors.textPrimary,
            ),
          ),
          SizedBox(height: design.spacing.sm),
          Wrap(
            spacing: design.spacing.sm,
            runSpacing: design.spacing.sm,
            children: [
              for (final (value, count) in values)
                _buildValueChip(dimension, value, count),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildValueChip(TagLlmDimension dimension, String value, int count) {
    final design = context.design;
    final selected =
        widget.selectedDimension == dimension && widget.selectedValue == value;
    return ClickableGestureDetector(
      onTap: () {
        widget.onSelect?.call(dimension, value);
        Navigator.pop(context);
      },
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: design.spacing.md,
          vertical: design.spacing.xs + 2,
        ),
        decoration: BoxDecoration(
          color: selected ? design.colors.accent : design.colors.surfaceMuted,
          borderRadius: BorderRadius.circular(design.radii.full),
          border: Border.all(
            color: selected ? design.colors.accent : design.colors.outline,
            width: design.borders.hairline,
          ),
        ),
        child: Text(
          '$value · $count',
          style: design.typography.label.copyWith(
            color:
                selected ? design.colors.onAccent : design.colors.textPrimary,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
