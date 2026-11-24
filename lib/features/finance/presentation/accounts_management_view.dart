import 'package:flutter/material.dart';
import 'package:planact/app/theme/planact_spacing.dart';
import 'package:planact/core/localization/persian_numbers.dart';
import 'package:planact/core/localization/planact_localizations.dart';
import 'package:planact/features/finance/domain/finance.dart';
import 'package:planact/features/finance/presentation/account_form_sheet.dart';
import 'package:planact/features/finance/presentation/account_identity_icon.dart';
import 'package:planact/features/search/domain/search.dart';

/// Browsing only. Account commands and fresh reads remain with FinancePage.
class AccountsManagementView extends StatefulWidget {
  const AccountsManagementView({
    super.key,
    required this.accounts,
    required this.showArchivedInitially,
    required this.accountBuilder,
    required this.onCreate,
    required this.onReorder,
    this.loadError,
    required this.onRetry,
  });

  final List<FinancialAccount> accounts;
  final bool showArchivedInitially;
  final Widget Function(BuildContext, FinancialAccount) accountBuilder;
  final VoidCallback onCreate;
  final VoidCallback? onReorder;
  final String? loadError;
  final VoidCallback onRetry;

  @override
  State<AccountsManagementView> createState() => _AccountsManagementViewState();
}

class _AccountsManagementViewState extends State<AccountsManagementView> {
  String _query = '';
  late bool _showArchived = widget.showArchivedInitially;

  @override
  Widget build(BuildContext context) {
    final l10n = planActL10n(context);
    final words = normalizeSearchText(_query)
        .split(' ')
        .where((w) => w.isNotEmpty);
    final accounts = widget.accounts.where((account) {
      if (!_showArchived && account.status != FinancialAccountStatus.active) {
        return false;
      }
      // Identifiers are deliberately excluded, including from search semantics.
      final text = normalizeSearchText(
        [
          account.name,
          if (account.bank != null) iranianBankLabel(context, account.bank!),
          accountTypeLabel(account.type),
          account.currency,
        ].join(' '),
      );
      return words.every(text.contains);
    }).toList();
    return CustomScrollView(
      key: const PageStorageKey('finance-accounts'),
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(PlanActSpacing.page),
          sliver: SliverList.list(
            children: [
              if (widget.loadError != null)
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.warning_amber_outlined),
                    title: Text(l10n.financePageBuildTitle2),
                    subtitle: Text(widget.loadError!),
                    trailing: TextButton(
                      onPressed: widget.onRetry,
                      child: Text(l10n.commonRetry),
                    ),
                  ),
                ),
              Wrap(
                spacing: PlanActSpacing.sm,
                runSpacing: PlanActSpacing.sm,
                children: [
                  FilledButton.icon(
                    onPressed: widget.onCreate,
                    icon: const Icon(Icons.add_card),
                    label: Text(l10n.accountFormSheetBuildTitle),
                  ),
                  OutlinedButton.icon(
                    onPressed: widget.onReorder,
                    icon: const Icon(Icons.swap_vert),
                    label: Text(l10n.financePageReorderAccounts),
                  ),
                ],
              ),
              const SizedBox(height: PlanActSpacing.lg),
              TextField(
                key: const ValueKey('accounts-search'),
                decoration: InputDecoration(
                  labelText: l10n.financeAccountsSearch,
                  prefixIcon: const Icon(Icons.search),
                ),
                onChanged: (value) => setState(() => _query = value),
              ),
              const SizedBox(height: PlanActSpacing.lg),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.financeShowArchivedAccounts),
                value: _showArchived,
                onChanged: (value) => setState(() => _showArchived = value),
              ),
              Text(
                l10n.financeAccountsCount(
                  PersianNumbers.format('${accounts.length}'),
                ),
              ),
              const SizedBox(height: PlanActSpacing.lg),
              if (accounts.isEmpty) Text(l10n.financeAccountsNoResults),
            ],
          ),
        ),
        SliverPadding(
          padding: const EdgeInsetsDirectional.only(
            start: PlanActSpacing.lg,
            end: PlanActSpacing.lg,
            bottom: PlanActSpacing.lg,
          ),
          sliver: SliverList.builder(
            itemCount: accounts.length,
            itemBuilder: (context, index) {
              final account = accounts[index];
              return Padding(
                key: ValueKey('account-row:${account.id.value}'),
                padding: const EdgeInsets.only(bottom: PlanActSpacing.lg),
                child: widget.accountBuilder(context, account),
              );
            },
          ),
        ),
      ],
    );
  }
}
