import 'package:flutter/material.dart';
import 'package:planact/app/money_unit_scope.dart';
import 'package:planact/app/theme/planact_spacing.dart';
import 'package:planact/core/localization/persian_numbers.dart';
import 'package:planact/core/localization/planact_localizations.dart';
import 'package:planact/core/presentation/persian_money_text.dart';
import 'package:planact/features/finance/domain/finance.dart';
import 'package:planact/features/finance/presentation/account_form_sheet.dart';
import 'package:planact/features/finance/presentation/account_identity_icon.dart';
import 'package:planact/features/search/domain/search.dart';

/// Browsing only. Account commands and fresh reads remain with FinancePage.
class AccountsManagementView extends StatefulWidget {
  const AccountsManagementView({
    super.key,
    required this.accounts,
    required this.entries,
    required this.showArchivedInitially,
    required this.onOpen,
    required this.onCreate,
    required this.onReorder,
    this.loadError,
    required this.onRetry,
  });

  final List<FinancialAccount> accounts;
  final List<AccountEntry> entries;
  final bool showArchivedInitially;
  final ValueChanged<FinancialAccount> onOpen;
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
          padding: const EdgeInsets.all(PlanActSpacing.lg),
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
                title: Text(l10n.financeAccountsShowArchived),
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
              return ListTile(
                key: ValueKey('account-row:${account.id.value}'),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: PlanActSpacing.sm,
                ),
                leading: AccountIdentityIcon(account: account),
                title: Text(account.name),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      [
                        accountTypeLabel(account.type),
                        if (account.bank != null)
                          iranianBankLabel(context, account.bank!),
                        if (account.status == FinancialAccountStatus.archived)
                          l10n.financeAccountsArchived,
                      ].join(' · '),
                    ),
                    Text(
                      PersianMoneyText.money(
                        rebuildBalance(account, widget.entries),
                        unit: MoneyUnitScope.of(context),
                        isolateNumber: true,
                      ),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => widget.onOpen(account),
              );
            },
          ),
        ),
      ],
    );
  }
}
