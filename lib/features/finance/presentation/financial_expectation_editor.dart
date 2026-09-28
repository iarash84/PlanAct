import 'package:flutter/material.dart';
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/features/finance/application/financial_expectation_use_cases.dart';
import 'package:planact/features/finance/domain/finance.dart';
import 'package:planact/features/finance/domain/financial_expectation.dart';

class FinancialExpectationEditor extends StatefulWidget {
  const FinancialExpectationEditor({
    super.key,
    required this.occurrenceId,
    required this.useCases,
    required this.accounts,
  });

  final StableId occurrenceId;
  final FinancialExpectationUseCases useCases;
  final List<FinancialAccount> accounts;

  @override
  State<FinancialExpectationEditor> createState() =>
      _FinancialExpectationEditorState();
}

class _FinancialExpectationEditorState
    extends State<FinancialExpectationEditor> {
  final _amount = TextEditingController();
  final _currency = TextEditingController();
  FinancialExpectationDirection _direction =
      FinancialExpectationDirection.outgoing;
  FinancialAccount? _account;
  FinancialExpectation? _existing;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final item = await widget.useCases.getByOccurrence(widget.occurrenceId);
    if (!mounted) return;
    if (item != null) {
      _existing = item;
      _amount.text = item.amount.toString();
      _currency.text = item.currency ?? '';
      _direction = item.direction;
      _account = item.accountId == null
          ? null
          : widget.accounts.cast<FinancialAccount?>().firstWhere(
              (account) => account?.id == item.accountId,
              orElse: () => null,
            );
    }
    setState(() => _loading = false);
  }

  Future<void> _save() async {
    final value = int.tryParse(_amount.text.trim());
    final currency = _currency.text.trim();
    if (value == null || value <= 0) {
      _message('مبلغ مثبت را وارد کنید.');
      return;
    }
    setState(() => _saving = true);
    try {
      if (_existing == null) {
        _existing = await widget.useCases.create(
          occurrenceId: widget.occurrenceId,
          direction: _direction,
          amount: value,
          currency: currency.isEmpty ? null : currency,
          accountId: _account?.id,
        );
      } else {
        _existing = await widget.useCases.update(
          _existing!,
          amount: value,
          currency: currency.isEmpty ? null : currency,
          direction: _direction,
          accountId: _account?.id,
        );
      }
      if (mounted) _message('انتظار مالی ذخیره شد.');
    } catch (_) {
      if (mounted) _message('ذخیرهٔ انتظار مالی انجام نشد.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _message(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  @override
  void dispose() {
    _amount.dispose();
    _currency.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const LinearProgressIndicator();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ExpansionTile(
              initiallyExpanded: _existing != null,
              title: const Text('انتظار مالی این نوبت'),
              subtitle: const Text('اختیاری؛ مستقل از انجام تعهد'),
              children: [
                Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SegmentedButton<FinancialExpectationDirection>(
                        segments: const [
                          ButtonSegment(
                            value: FinancialExpectationDirection.outgoing,
                            label: Text('پرداختی'),
                          ),
                          ButtonSegment(
                            value: FinancialExpectationDirection.incoming,
                            label: Text('دریافتی'),
                          ),
                        ],
                        selected: {_direction},
                        onSelectionChanged: (value) =>
                            setState(() => _direction = value.first),
                      ),
                      TextField(
                        controller: _amount,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'مبلغ (واحد خرد)',
                        ),
                      ),
                      TextField(
                        controller: _currency,
                        decoration: const InputDecoration(
                          labelText: 'ارز، مانند IRR',
                        ),
                      ),
                      DropdownButtonFormField<FinancialAccount?>(
                        initialValue: _account,
                        decoration: const InputDecoration(
                          labelText: 'حساب (اختیاری)',
                        ),
                        items: [
                          const DropdownMenuItem<FinancialAccount?>(
                            value: null,
                            child: Text('بدون حساب'),
                          ),
                          ...widget.accounts.map(
                            (account) => DropdownMenuItem<FinancialAccount?>(
                              value: account,
                              child: Text(account.name),
                            ),
                          ),
                        ],
                        onChanged: (value) => setState(() => _account = value),
                      ),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: _saving ? null : _save,
                        child: Text(
                          _saving ? 'در حال ذخیره…' : 'ذخیرهٔ انتظار',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
