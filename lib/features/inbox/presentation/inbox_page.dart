import 'package:flutter/material.dart';
import 'package:planact/features/finance/application/finance_use_cases.dart';
import 'package:planact/features/finance/domain/finance.dart';
import 'package:planact/features/inbox/application/inbox_use_cases.dart';
import 'package:planact/features/inbox/domain/inbox.dart';

class InboxPage extends StatefulWidget {
  const InboxPage({super.key, required this.inbox, required this.finance});

  final InboxUseCases inbox;
  final FinanceRepository finance;

  @override
  State<InboxPage> createState() => _InboxPageState();
}

class _InboxPageState extends State<InboxPage> {
  List<InboxSuggestion> _items = const [];
  List<FinancialAccount> _accounts = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final suggestions = await widget.inbox.repository.listSuggestions();
    final accounts = await widget.finance.listAccounts();
    if (!mounted) return;
    setState(() {
      _items = suggestions
          .where(
            (item) =>
                item.status == SuggestionStatus.pending ||
                item.status == SuggestionStatus.edited,
          )
          .toList();
      _accounts = accounts;
      _loading = false;
    });
  }

  Future<void> _accept(InboxSuggestion suggestion) async {
    final active = _accounts
        .where(
          (account) =>
              account.status == FinancialAccountStatus.active &&
              account.currency == suggestion.draft.amount.currency,
        )
        .toList();
    if (active.length != 1) {
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('انتخاب حساب لازم است'),
          content: Text(
            active.isEmpty
                ? 'حساب فعال سازگار پیدا نشد.'
                : 'چند حساب سازگار وجود دارد؛ انتساب خودکار انجام نشد.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('بستن'),
            ),
          ],
        ),
      );
      return;
    }
    await widget.inbox.confirm(
      suggestion: suggestion,
      account: active.single,
      finance: widget.finance,
    );
    await _reload();
  }

  Future<void> _reject(InboxSuggestion suggestion) async {
    await widget.inbox.reject(suggestion);
    await _reload();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_items.isEmpty) {
      return const Center(child: Text('ورودی برای بررسی وجود ندارد.'));
    }
    return RefreshIndicator(
      onRefresh: _reload,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _items.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final item = _items[index];
          final draft = item.draft;
          final direction = draft.direction == TransactionDirection.incoming
              ? 'واریز'
              : draft.direction == TransactionDirection.outgoing
              ? 'برداشت'
              : 'جهت نامشخص';
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'پیام بانکی · $direction',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'مبلغ: ${draft.amount.minorUnits} ${draft.amount.currency}',
                  ),
                  if (draft.merchant != null) Text('شرح: ${draft.merchant}'),
                  if (draft.reference != null)
                    Text('شناسه پیگیری: ${draft.reference}'),
                  Text(
                    'اطمینان پردازش: ${draft.confidence}% · ${_quality(draft.quality)}',
                  ),
                  if (draft.accountHint != null)
                    Text('راهنمای حساب/کارت: ${draft.accountHint}'),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => _reject(item),
                        child: const Text('نادیده گرفتن'),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: () => _accept(item),
                        child: const Text('تأیید و ثبت'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _quality(ParseQuality quality) => switch (quality) {
    ParseQuality.high => 'بالا',
    ParseQuality.medium => 'متوسط',
    ParseQuality.low => 'پایین',
    ParseQuality.unsupported => 'پشتیبانی‌نشده',
  };
}
