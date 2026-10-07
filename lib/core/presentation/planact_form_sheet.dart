import 'package:flutter/material.dart';
import 'package:planact/app/theme/planact_spacing.dart';

/// Shared shell for small create/edit forms presented as bottom sheets.
class PlanActFormSheet extends StatelessWidget {
  const PlanActFormSheet({
    super.key,
    required this.title,
    required this.child,
    this.formKey,
    this.onPrimary,
    this.primaryLabel = 'ذخیره',
    this.secondaryLabel = 'انصراف',
    this.onSecondary,
    this.isLoading = false,
    this.error,
    this.showDragHandle = false,
    this.primaryKey,
  });

  final String title;
  final Widget child;
  final GlobalKey<FormState>? formKey;
  final VoidCallback? onPrimary;
  final String primaryLabel;
  final String secondaryLabel;
  final VoidCallback? onSecondary;
  final bool isLoading;
  final String? error;
  final bool showDragHandle;
  final Key? primaryKey;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            PlanActSpacing.lg,
            PlanActSpacing.sm,
            PlanActSpacing.lg,
            bottomInset + PlanActSpacing.lg,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 720),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (showDragHandle)
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        margin: const EdgeInsets.only(
                          bottom: PlanActSpacing.md,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.outlineVariant,
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                    ),
                  Text(title, style: Theme.of(context).textTheme.titleLarge),
                  if (error != null) ...[
                    const SizedBox(height: PlanActSpacing.sm),
                    Semantics(
                      liveRegion: true,
                      child: Text(
                        error!,
                        key: const ValueKey('planact-form-error'),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: PlanActSpacing.md),
                  Flexible(
                    child: ListView(
                      shrinkWrap: true,
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      children: [child],
                    ),
                  ),
                  const SizedBox(height: PlanActSpacing.md),
                  OverflowBar(
                    spacing: PlanActSpacing.sm,
                    overflowSpacing: PlanActSpacing.sm,
                    alignment: MainAxisAlignment.end,
                    children: [
                      SizedBox(
                        child: OutlinedButton(
                          onPressed: isLoading
                              ? null
                              : (onSecondary ??
                                    () => Navigator.of(context).pop()),
                          child: Text(secondaryLabel),
                        ),
                      ),
                      SizedBox(
                        child: FilledButton(
                          key: primaryKey,
                          onPressed: isLoading ? null : onPrimary,
                          child: isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(primaryLabel),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Future<T?> showPlanActFormSheet<T>({
  required BuildContext context,
  required String title,
  required WidgetBuilder builder,
  GlobalKey<FormState>? formKey,
  VoidCallback? onPrimary,
  String primaryLabel = 'ذخیره',
  String secondaryLabel = 'انصراف',
  VoidCallback? onSecondary,
  bool isLoading = false,
  String? error,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: false,
    builder: (sheetContext) => PlanActFormSheet(
      title: title,
      formKey: formKey,
      onPrimary: onPrimary,
      primaryLabel: primaryLabel,
      secondaryLabel: secondaryLabel,
      onSecondary: onSecondary,
      isLoading: isLoading,
      error: error,
      child: builder(sheetContext),
    ),
  );
}
