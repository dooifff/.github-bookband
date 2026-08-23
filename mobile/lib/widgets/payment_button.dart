import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

class PaymentButton extends StatelessWidget {
  final String method;
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const PaymentButton({
    super.key,
    required this.method,
    required this.label,
    required this.icon,
    this.isSelected = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor.withOpacity(0.2) : AppTheme.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : AppTheme.borderColor,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? AppTheme.primaryColor : Colors.grey[400],
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[400],
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Payment method selection dialog
class PaymentMethodDialog extends StatelessWidget {
  final String? selectedMethod;
  final Function(String method) onSelect;

  const PaymentMethodDialog({
    super.key,
    this.selectedMethod,
    required this.onSelect,
  });

  static void show(BuildContext context, {
    String? selectedMethod,
    required Function(String method) onSelect,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => PaymentMethodDialog(
        selectedMethod: selectedMethod,
        onSelect: (method) {
          Navigator.pop(context);
          onSelect(method);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[600],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Pilih Metode Pembayaran',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            children: [
              PaymentButton(
                method: 'bank_transfer',
                label: 'Transfer Bank',
                icon: Icons.account_balance,
                isSelected: selectedMethod == 'bank_transfer',
                onTap: () => onSelect('bank_transfer'),
              ),
              PaymentButton(
                method: 'credit_card',
                label: 'Kartu Kredit',
                icon: Icons.credit_card,
                isSelected: selectedMethod == 'credit_card',
                onTap: () => onSelect('credit_card'),
              ),
              PaymentButton(
                method: 'debit_card',
                label: 'Kartu Debit',
                icon: Icons.payment,
                isSelected: selectedMethod == 'debit_card',
                onTap: () => onSelect('debit_card'),
              ),
              PaymentButton(
                method: 'ewallet',
                label: 'E-Wallet',
                icon: Icons.account_balance_wallet,
                isSelected: selectedMethod == 'ewallet',
                onTap: () => onSelect('ewallet'),
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
