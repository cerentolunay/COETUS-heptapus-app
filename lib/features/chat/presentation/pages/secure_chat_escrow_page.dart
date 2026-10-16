import 'package:flutter/material.dart';
import 'package:coetus/features/exchange/presentation/pages/exchange_page.dart';

/// Token movements are shown from real sessions, never preview balances.
class SecureChatEscrowPage extends StatelessWidget {
  const SecureChatEscrowPage({super.key});
  @override
  Widget build(BuildContext context) => const ExchangePage();
}
