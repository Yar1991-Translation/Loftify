import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:flutter/material.dart';

import '../../Models/recommend_response.dart';
import '../../Theme/loftify_design_theme.dart';
import '../../Utils/llm_util.dart';
import '../../Utils/tag_llm_classifier.dart';
import '../../l10n/l10n.dart';
import '../Design/loftify_surfaces.dart';

/// Bottom sheet for the tag LLM classifier: shows the categories currently
/// assigned to the tag's loaded posts, lets the user trigger (re-)classification
/// and pick a category to filter by. [onSelect] receives `null` to clear the
/// filter and a category label to show only that category.
class LlmClassificationBottomSheet extends StatefulWidget {
  const LlmClassificationBottomSheet({
    super.key,
    required this.tag,
    required this.posts,
    required this.selectedCategory,
    this.onSelect,
  });

  final String tag;
  final List<PostListItem> posts;
  final String? selectedCategory;
  final ValueChanged<String?>? onSelect;

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
      widget.onSelect?.call(widget.selectedCategory);
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
    final categories =
        TagLlmClassifier.categoriesWithCounts(widget.tag, widget.posts);
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
              SizedBox(height: design.spacing.md),
              if (categories.isEmpty)
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
              else
                Wrap(
                  spacing: design.spacing.sm,
                  runSpacing: design.spacing.sm,
                  children: [
                    for (final (category, count) in categories)
                      _buildCategoryChip(category, count),
                  ],
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
              Row(
                children: [
                  Expanded(
                    child: RoundIconTextButton(
                      text: _classifications.isEmpty
                          ? appLocalizations.llmClassifyStart
                          : appLocalizations.llmClassifyUpdate,
                      onPressed: _running ? null : _classify,
                    ),
                  ),
                  if (widget.selectedCategory != null) ...[
                    SizedBox(width: design.spacing.sm),
                    Expanded(
                      child: RoundIconTextButton(
                        text: appLocalizations.llmClassifyClearFilter,
                        background: design.colors.surfaceRaised,
                        onPressed: () {
                          widget.onSelect?.call(null);
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

  Widget _buildCategoryChip(String category, int count) {
    final design = context.design;
    final selected = widget.selectedCategory == category;
    return ClickableGestureDetector(
      onTap: () {
        widget.onSelect?.call(category);
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
            color:
                selected ? design.colors.accent : design.colors.outline,
            width: design.borders.hairline,
          ),
        ),
        child: Text(
          '$category · $count',
          style: design.typography.label.copyWith(
            color: selected ? design.colors.onAccent : design.colors.textPrimary,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
