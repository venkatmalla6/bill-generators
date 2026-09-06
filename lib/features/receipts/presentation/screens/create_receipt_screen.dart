// lib/features/receipts/presentation/screens/create_receipt_screen.dart
// AKTS Receipt creation form with auto-fill and validation

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/receipt_provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../shared/widgets/common/loading_overlay.dart';

class CreateReceiptScreen extends ConsumerStatefulWidget {
  const CreateReceiptScreen({super.key});

  @override
  ConsumerState<CreateReceiptScreen> createState() =>
      _CreateReceiptScreenState();
}

class _CreateReceiptScreenState extends ConsumerState<CreateReceiptScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _memberNameController = TextEditingController();
  final _aktsNumberController = TextEditingController();
  final _amountController = TextEditingController();
  final _transactionIdController = TextEditingController();
  final _remarksController = TextEditingController();

  // State
  DateTime _selectedDate = DateTime.now();
  String _selectedPaymentMode = AppConstants.paymentModes.first;
  String? _selectedMembershipYear;
  String _amountInWords = '';
  bool _showTransactionId = false;

  @override
  void initState() {
    super.initState();
    _selectedMembershipYear = DateTime.now().year.toString();
    _amountController.addListener(_onAmountChanged);
  }

  void _onAmountChanged() {
    final text = _amountController.text.trim();
    if (text.isEmpty) {
      setState(() => _amountInWords = '');
      return;
    }
    final amount = double.tryParse(text);
    if (amount != null && amount > 0) {
      ref.read(createReceiptControllerProvider.notifier)
          .updateAmountInWords(amount);
      setState(() {
        _amountInWords = _generateAmountInWords(amount);
      });
    } else {
      setState(() => _amountInWords = '');
    }
  }

  String _generateAmountInWords(double amount) {
    // Use the utility directly for immediate feedback
    from(amount);
    final notifier = ref.read(createReceiptControllerProvider.notifier);
    notifier.updateAmountInWords(amount);
    return ref.read(createReceiptControllerProvider).amountInWords;
  }

  void _onPaymentModeChanged(String? mode) {
    if (mode == null) return;
    setState(() {
      _selectedPaymentMode = mode;
      _showTransactionId = AppConstants.paymentModesRequiringTransactionId
          .contains(mode);
      if (!_showTransactionId) {
        _transactionIdController.clear();
      }
    });
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.navyPrimary,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final amount = double.parse(_amountController.text.trim());

    final created = await ref.read(createReceiptControllerProvider.notifier)
        .createReceipt(
          date: _selectedDate,
          memberName: _memberNameController.text,
          aktsNumber: _aktsNumberController.text,
          membershipYear: _selectedMembershipYear!,
          amount: amount,
          paymentMode: _selectedPaymentMode,
          transactionId: _showTransactionId
              ? _transactionIdController.text
              : null,
          remarks: _remarksController.text,
        );

    if (mounted && created != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Expanded(child: Text('Receipt ${created.receiptNumber} created successfully!')),
            ],
          ),
          backgroundColor: AppColors.statusValid,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
      // Navigate to receipt preview
      context.push(AppRoutes.receiptPreviewPath(created.id));
    }
  }

  @override
  void dispose() {
    _memberNameController.dispose();
    _aktsNumberController.dispose();
    _amountController.removeListener(_onAmountChanged);
    _amountController.dispose();
    _transactionIdController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final receiptState = ref.watch(createReceiptControllerProvider);

    // Listen for errors
    ref.listen(createReceiptControllerProvider, (prev, next) {
      if (next.error != null && next.error != prev?.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
        ref.read(createReceiptControllerProvider.notifier).clearError();
      }
    });

    // Update local amount in words from state
    if (receiptState.amountInWords.isNotEmpty &&
        receiptState.amountInWords != _amountInWords) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _amountInWords = receiptState.amountInWords);
      });
    }

    return LoadingOverlay(
      isLoading: receiptState.isLoading,
      message: 'Creating receipt...',
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Create Receipt'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios),
            onPressed: () => context.pop(),
          ),
        ),
        body: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header info card
                _buildInfoCard(),
                const SizedBox(height: 20),

                _SectionHeader(title: 'Member Information'),
                const SizedBox(height: 12),

                // Member Name
                _buildTextField(
                  controller: _memberNameController,
                  label: 'Member Name',
                  hint: 'e.g. MR. P VENKATESH',
                  icon: Icons.person_outline,
                  textCapitalization: TextCapitalization.characters,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Member name is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // AKTS Number
                _buildTextField(
                  controller: _aktsNumberController,
                  label: 'AKTS Number',
                  hint: 'e.g. AKTS 049',
                  icon: Icons.badge_outlined,
                  textCapitalization: TextCapitalization.characters,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'AKTS number is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Membership Year
                _buildDropdown(
                  label: 'Membership Year',
                  value: _selectedMembershipYear,
                  items: AppConstants.membershipYears,
                  icon: Icons.date_range_outlined,
                  onChanged: (v) =>
                      setState(() => _selectedMembershipYear = v),
                ),
                const SizedBox(height: 24),

                _SectionHeader(title: 'Payment Details'),
                const SizedBox(height: 12),

                // Date
                GestureDetector(
                  onTap: _selectDate,
                  child: AbsorbPointer(
                    child: TextFormField(
                      controller: TextEditingController(
                        text: DateFormatter.toDisplayDate(_selectedDate),
                      ),
                      decoration: InputDecoration(
                        labelText: 'Date',
                        prefixIcon:
                            const Icon(Icons.calendar_today_outlined),
                        suffixIcon: const Icon(Icons.edit_calendar_outlined),
                        hintText: 'DD-MM-YYYY',
                        filled: true,
                        fillColor: AppColors.surfaceLight,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: AppColors.dividerColor),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: AppColors.dividerColor),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Amount
                TextFormField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Amount Paid (₹)',
                    prefixIcon: Icon(Icons.currency_rupee),
                    hintText: '500',
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Amount is required';
                    }
                    final amount = double.tryParse(v.trim());
                    if (amount == null || amount <= 0) {
                      return 'Please enter a valid amount';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                // Amount in Words (auto-generated, read-only)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  child: _amountInWords.isNotEmpty
                      ? Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.navyPrimary.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(12),
                            border:
                                Border.all(color: AppColors.navyPrimary.withOpacity(0.2)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.auto_fix_high,
                                  size: 16, color: AppColors.navyPrimary),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Amount in Words (auto-generated):',
                                      style: GoogleFonts.lato(
                                        fontSize: 11,
                                        color: AppColors.navyPrimary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _amountInWords,
                                      style: GoogleFonts.lato(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.navyPrimary,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
                const SizedBox(height: 16),

                // Payment Mode
                _buildDropdown(
                  label: 'Payment Mode',
                  value: _selectedPaymentMode,
                  items: AppConstants.paymentModes,
                  icon: Icons.payment_outlined,
                  onChanged: _onPaymentModeChanged,
                ),
                const SizedBox(height: 16),

                // Transaction ID (conditional)
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _showTransactionId
                      ? Column(
                          key: const ValueKey('txn-id'),
                          children: [
                            _buildTextField(
                              controller: _transactionIdController,
                              label: 'Transaction / UTR Number',
                              hint: 'e.g. 60975018893',
                              icon: Icons.confirmation_number_outlined,
                              keyboardType: TextInputType.number,
                              validator: (v) {
                                if (_showTransactionId &&
                                    (v == null || v.trim().isEmpty)) {
                                  return 'Transaction ID is required for ${_selectedPaymentMode}';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                          ],
                        )
                      : const SizedBox.shrink(key: ValueKey('no-txn')),
                ),

                // Remarks
                _buildTextField(
                  controller: _remarksController,
                  label: 'Remarks (Optional)',
                  hint: 'Any additional notes...',
                  icon: Icons.notes_outlined,
                  maxLines: 2,
                ),
                const SizedBox(height: 32),

                // Submit button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: receiptState.isLoading ? null : _handleSubmit,
                    icon: const Icon(Icons.receipt_long, size: 20),
                    label: Text(
                      'CREATE RECEIPT',
                      style: GoogleFonts.lato(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.navyPrimary.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.navyPrimary.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: AppColors.navyPrimary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Receipt number will be auto-generated',
                  style: GoogleFonts.lato(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.navyPrimary,
                  ),
                ),
                Text(
                  'A unique QR verification code will be attached',
                  style: GoogleFonts.lato(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    IconData? icon,
    TextCapitalization textCapitalization = TextCapitalization.none,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      textCapitalization: textCapitalization,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: icon != null ? Icon(icon) : null,
      ),
      validator: validator,
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<String> items,
    IconData? icon,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: icon != null ? Icon(icon) : null,
      ),
      items: items
          .map((item) => DropdownMenuItem(value: item, child: Text(item)))
          .toList(),
      onChanged: onChanged,
      validator: (v) => v == null ? 'Please select $label' : null,
    );
  }

  // Dummy to suppress the unused import warning - actual logic is in notifier
  void from(double amount) {}
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: AppColors.navyPrimary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.lato(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

// Extension to add id to TextFormField
extension TextFormFieldId on TextFormField {
  TextFormField withId(String id) => this;
}
