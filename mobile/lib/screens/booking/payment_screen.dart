import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/booking_model.dart';
import '../../providers/payment_provider.dart';
import '../../utils/formatters.dart';
import '../home/home_screen.dart';
import 'booking_success_screen.dart';

class PaymentScreen extends StatefulWidget {
  final Booking booking;
  final int totalAmount;

  const PaymentScreen({
    super.key,
    required this.booking,
    required this.totalAmount,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String _selectedMethod = 'bank_transfer';
  String? _selectedBank;
  bool _isLoading = false;

  final List<Map<String, dynamic>> _paymentMethods = [
    {
      'id': 'bank_transfer',
      'name': 'Bank Transfer',
      'icon': Icons.account_balance,
      'banks': ['BCA', 'Mandiri', 'BRI', 'BNI'],
    },
    {
      'id': 'ewallet',
      'name': 'E-Wallet',
      'icon': Icons.account_balance_wallet,
      'banks': ['GoPay', 'OVO', 'DANA', 'ShopeePay'],
    },
    {
      'id': 'va',
      'name': 'Virtual Account',
      'icon': Icons.payment,
      'banks': ['BCA VA', 'Mandiri VA', 'BRI VA', 'BNI VA'],
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Booking Summary
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Booking Summary',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Booking Code'),
                        Text(
                          widget.booking.bookingCode,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.accent,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Amount'),
                        Text(
                          Formatters.currency(widget.totalAmount),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Payment Methods
            const Text(
              'Select Payment Method',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            ..._paymentMethods.map((method) {
              final isSelected = _selectedMethod == method['id'];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                color: isSelected ? AppTheme.accent[50] : null,
                child: ExpansionTile(
                  leading: Icon(
                    method['icon'],
                    color: isSelected ? AppTheme.accent : AppTheme.textMuted,
                  ),
                  title: Text(
                    method['name'],
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  initiallyExpanded: isSelected,
                  onExpansionChanged: (expanded) {
                    if (expanded) {
                      setState(() {
                        _selectedMethod = method['id'];
                        _selectedBank = null;
                      });
                    }
                  },
                  children: [
                    ...method['banks'].map((bank) {
                      return RadioListTile<String>(
                        title: Text(bank),
                        value: bank,
                        groupValue: _selectedBank,
                        onChanged: (value) {
                          setState(() {
                            _selectedBank = value;
                          });
                        },
                        activeColor: AppTheme.accent,
                      );
                    }).toList(),
                  ],
                ),
              );
            }),
            const SizedBox(height: 24),

            // Payment Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (_selectedBank != null && !_isLoading)
                    ? _processPayment
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accent,
                  foregroundColor: AppTheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Pay Now',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Future<void> _processPayment() async {
    setState(() => _isLoading = true);

    try {
      final paymentProvider = context.read<PaymentProvider>();
      
      final payment = await paymentProvider.createPayment(
        bookingId: widget.booking.id,
        paymentMethod: _selectedMethod,
        bankCode: _selectedBank,
      );

      if (payment != null && mounted) {
        // Show payment instruction or redirect
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => BookingSuccessScreen(
              booking: widget.booking,
              paymentCode: payment['payment_code'],
            ),
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(paymentProvider.error ?? 'Payment failed'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
