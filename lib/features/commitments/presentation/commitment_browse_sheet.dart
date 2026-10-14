import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:planact/app/theme/planact_spacing.dart';
import 'package:planact/core/localization/planact_localizations.dart';
import 'package:planact/core/presentation/planact_state_message.dart';
import 'package:planact/features/commitments/domain/commitment.dart';
import 'package:planact/features/commitments/presentation/commitment_identity_marker.dart';

/// Timeline and history share one expandable route, not a second full-page route.
class CommitmentBrowseSheet extends StatefulWidget {
  const CommitmentBrowseSheet({
    super.key,
    required this.title,
    required this.items,
    required this.subtitle,
    required this.onOpen,
    required this.onRetry,
    this.error,
  });

  final String title;
  final List<Commitment> items;
  final String Function(Commitment) subtitle;
  final Future<void> Function(Commitment) onOpen;
  final VoidCallback onRetry;
  final String? error;

  @override
  State<CommitmentBrowseSheet> createState() => _CommitmentBrowseSheetState();
}

class _CommitmentBrowseSheetState extends State<CommitmentBrowseSheet> {
  final _extent = DraggableScrollableController();
  bool _expanded = false;
  bool _opening = false;
  bool _openFailed = false;

  @override
  void initState() {
    super.initState();
    _extent.addListener(_sizeChanged);
  }

  void _sizeChanged() {
    final expanded = _extent.size >= .99;
    if (expanded != _expanded) setState(() => _expanded = expanded);
  }

  void _toggleSize() {
    final size = _expanded ? .6 : 1.0;
    final duration = PlanActMotion.duration(context);
    if (duration == Duration.zero) {
      _extent.jumpTo(size);
    } else {
      _extent.animateTo(size, duration: duration, curve: PlanActMotion.curve);
    }
  }

  @override
  void dispose() {
    _extent.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = planActL10n(context);
    return Directionality(
      textDirection: TextDirection.rtl,
      child: DraggableScrollableSheet(
        controller: _extent,
        initialChildSize: .6,
        minChildSize: .4,
        maxChildSize: 1,
        expand: false,
        snap: true,
        snapSizes: const [.6],
        shouldCloseOnMinExtent: true,
        builder: (context, scrollController) => Material(
          color: theme.bottomSheetTheme.backgroundColor,
          child: SafeArea(
            top: false,
            child: LayoutBuilder(
              builder: (context, constraints) {
                // The pinned title wraps naturally, including at large text.
                final titlePainter =
                    TextPainter(
                      text: TextSpan(
                        text: widget.title,
                        style: theme.textTheme.titleLarge,
                      ),
                      textDirection: TextDirection.rtl,
                      textScaler: MediaQuery.textScalerOf(context),
                    )..layout(
                      maxWidth: math.max(
                        1,
                        constraints.maxWidth -
                            2 * PlanActSpacing.lg -
                            2 * PlanActSpacing.touchTarget,
                      ),
                    );
                final headerHeight =
                    math.max(PlanActSpacing.touchTarget, titlePainter.height) +
                    PlanActSpacing.xxl +
                    PlanActSpacing.sm;
                titlePainter.dispose();
                return CustomScrollView(
                  key: const ValueKey('commitment-browse-scroll'),
                  controller: scrollController,
                  slivers: [
                    SliverPersistentHeader(
                      pinned: true,
                      delegate: _BrowseHeader(
                        height: headerHeight,
                        child: Material(
                          color:
                              theme.bottomSheetTheme.backgroundColor ??
                              theme.colorScheme.surfaceContainer,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: PlanActSpacing.lg,
                            ),
                            child: Column(
                              children: [
                                const ExcludeSemantics(
                                  child: SizedBox(
                                    height: PlanActSpacing.xxl,
                                    child: Center(
                                      child: Icon(Icons.drag_handle),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Semantics(
                                          header: true,
                                          child: Text(
                                            widget.title,
                                            style: theme.textTheme.titleLarge,
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        key: const ValueKey(
                                          'commitment-browse-expand',
                                        ),
                                        tooltip: _expanded
                                            ? l10n.commitmentBrowseCollapse
                                            : l10n.commitmentBrowseExpand,
                                        onPressed: _toggleSize,
                                        icon: Icon(
                                          _expanded
                                              ? Icons.fullscreen_exit
                                              : Icons.fullscreen,
                                        ),
                                      ),
                                      IconButton(
                                        tooltip: l10n.commonClose,
                                        onPressed: () =>
                                            Navigator.of(context).pop(),
                                        icon: const Icon(Icons.close),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (_openFailed)
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: PlanActSpacing.page,
                        ),
                        sliver: SliverToBoxAdapter(
                          child: PlanActStateMessage(
                            message: l10n.commitmentBrowseOpenError,
                            isError: true,
                          ),
                        ),
                      ),
                    if (widget.error != null)
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: PlanActSpacing.page,
                        ),
                        sliver: SliverToBoxAdapter(
                          child: PlanActStateMessage(
                            message: widget.error!,
                            isError: true,
                            action: TextButton(
                              onPressed: widget.onRetry,
                              child: Text(l10n.commonRetry),
                            ),
                          ),
                        ),
                      )
                    else if (widget.items.isEmpty)
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: PlanActSpacing.page,
                        ),
                        sliver: SliverToBoxAdapter(
                          child: PlanActStateMessage(
                            message: l10n.planactAppShowTimelineContent,
                          ),
                        ),
                      )
                    else
                      SliverList.builder(
                        itemCount: widget.items.length,
                        itemBuilder: (context, index) {
                          final item = widget.items[index];
                          return ListTile(
                            key: ValueKey('commitment-browse-${item.id.value}'),
                            leading: CommitmentIdentityMarker(commitment: item),
                            title: Text(item.title),
                            subtitle: Text(widget.subtitle(item)),
                            enabled: !_opening,
                            onTap: () async {
                              setState(() {
                                _opening = true;
                                _openFailed = false;
                              });
                              try {
                                await widget.onOpen(item);
                              } catch (_) {
                                if (mounted) {
                                  setState(() => _openFailed = true);
                                  // Keep the inline failure visible even after browsing
                                  // deep into a long history. The next row tap retries.
                                  scrollController.jumpTo(0);
                                }
                              } finally {
                                if (mounted) setState(() => _opening = false);
                              }
                            },
                          );
                        },
                      ),
                    const SliverToBoxAdapter(
                      child: SizedBox(height: PlanActSpacing.lg),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _BrowseHeader extends SliverPersistentHeaderDelegate {
  _BrowseHeader({required this.height, required this.child});
  final double height;
  final Widget child;

  @override
  double get minExtent => height;
  @override
  double get maxExtent => height;
  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) => child;
  @override
  bool shouldRebuild(covariant _BrowseHeader oldDelegate) => true;
}
