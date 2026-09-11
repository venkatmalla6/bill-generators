// lib/features/payment_details/presentation/screens/create_payment_details_screen.dart
// Screen to record Payment Done Details with bill screenshots and photo uploads

import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/image_picker_helper.dart';
import '../../../../shared/widgets/common/loading_overlay.dart';
import '../providers/payment_details_provider.dart';

class CreatePaymentDetailsScreen extends ConsumerStatefulWidget {
  const CreatePaymentDetailsScreen({super.key});

  @override
  ConsumerState<CreatePaymentDetailsScreen> createState() =>
      _CreatePaymentDetailsScreenState();
}

class _CreatePaymentDetailsScreenState
    extends ConsumerState<CreatePaymentDetailsScreen> {
  final _formKey = GlobalKey<FormState>();

  // Text controllers
  final _shopNameController = TextEditingController();
  final _billNumberController = TextEditingController();
  final _amountController = TextEditingController();
  final _transactionDetailsController = TextEditingController();
  final _remarksController = TextEditingController();

  // Form states
  DateTime _selectedDate = DateTime.now();
  String _paymentType = 'Online'; // 'Online' | 'Offline'
  String _paymentMode = 'UPI'; // 'UPI', 'Bank Transfer', 'Card', 'Cash', 'Other'
  final List<PickedImageData> _attachedImages = [];

  final List<String> _onlineModes = [
    'UPI',
    'Bank Transfer / NEFT / IMPS',
    'Credit / Debit Card',
    'Net Banking',
  ];

  final List<String> _offlineModes = [
    'Cash',
    'Cheque',
    'Demand Draft',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _amountController.addListener(_onAmountChanged);
  }

  void _onAmountChanged() {
    final text = _amountController.text.trim();
    if (text.isEmpty) {
      ref.read(createPaymentControllerProvider.notifier).updateAmount(0);
      return;
    }
    final amount = double.tryParse(text);
    if (amount != null && amount > 0) {
      ref.read(createPaymentControllerProvider.notifier).updateAmount(amount);
    } else {
      ref.read(createPaymentControllerProvider.notifier).updateAmount(0);
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 30)),
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

  Future<void> _pickImage(bool fromCamera) async {
    if (fromCamera) {
      final img = await ImagePickerHelper.pickFromCamera();
      if (img != null) {
        setState(() => _attachedImages.add(img));
      }
    } else {
      final imgs = await ImagePickerHelper.pickFromGallery(allowMultiple: true);
      if (imgs.isNotEmpty) {
        setState(() => _attachedImages.addAll(imgs));
      }
    }
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Upload Bill Screenshot / Photo',
                  style: GoogleFonts.lato(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.navyPrimary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.camera_alt, color: AppColors.navyPrimary),
                  ),
                  title: Text(
                    'Take Photo with Camera',
                    style: GoogleFonts.lato(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    'Capture bill paper or physical receipt',
                    style: GoogleFonts.lato(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(true);
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.gold.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.photo_library, color: AppColors.gold),
                  ),
                  title: Text(
                    'Choose from Gallery / Screenshots',
                    style: GoogleFonts.lato(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    'Upload payment screenshot, UPI receipt, etc.',
                    style: GoogleFonts.lato(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(false);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _removeImage(int index) {
    setState(() => _attachedImages.removeAt(index));
  }

  void _previewFullImage(PickedImageData img) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 28),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              Flexible(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.memory(
                    img.bytes,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final amount = double.tryParse(_amountController.text.trim()) ?? 0.0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid amount greater than 0'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final imagesBase64 = _attachedImages.map((e) => e.base64String).toList();

    final created =
        await ref.read(createPaymentControllerProvider.notifier).submitPayment(
              shopName: _shopNameController.text,
              billNumber: _billNumberController.text,
              date: _selectedDate,
              amount: amount,
              paymentType: _paymentType,
              paymentMode: _paymentMode,
              transactionDetails: _transactionDetailsController.text.isNotEmpty
                  ? _transactionDetailsController.text
                  : null,
              remarks: _remarksController.text.isNotEmpty
                  ? _remarksController.text
                  : null,
              imagesBase64: imagesBase64,
            );

    if (mounted && created != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Payment Voucher ${created.voucherNumber} created!'),
              ),
            ],
          ),
          backgroundColor: AppColors.statusValid,
          behavior: SnackBarBehavior.floating,
        ),
      );

      // Navigate to Payment Voucher Preview & PDF
      context.push('/payment-details/${created.id}');
    }
  }

  @override
  void dispose() {
    _amountController.removeListener(_onAmountChanged);
    _shopNameController.dispose();
    _billNumberController.dispose();
    _amountController.dispose();
    _transactionDetailsController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(createPaymentControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Payment Done Details',
          style: GoogleFonts.lato(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_outlined),
            tooltip: 'Payment History',
            onPressed: () => context.push('/payment-details'),
          ),
        ],
      ),
      body: LoadingOverlay(
        isLoading: state.isLoading,
        message: 'Generating Voucher & PDF...',
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header card
                _buildHeaderCard(),
                const SizedBox(height: 18),

                // Form section
                _buildFormCard(state),
                const SizedBox(height: 18),

                // Bill screenshots / photos upload section
                _buildPhotoUploadCard(),
                const SizedBox(height: 24),

                // Submit Button
                ElevatedButton.icon(
                  onPressed: state.isLoading ? null : _handleSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.navyPrimary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 3,
                  ),
                  icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
                  label: Text(
                    'Save & Create PDF with Bill Photos',
                    style: GoogleFonts.lato(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.receipt_long, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Record Bill & Payment',
                  style: GoogleFonts.lato(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Upload screenshot/photos to generate a complete voucher PDF with attached bills',
                  style: GoogleFonts.lato(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.85),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard(CreatePaymentState state) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.dividerColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bill & Merchant Information',
            style: GoogleFonts.lato(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.navyPrimary,
            ),
          ),
          const SizedBox(height: 16),

          // Shop Name
          TextFormField(
            controller: _shopNameController,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: 'Shop Name *',
              hintText: 'e.g. Sri Krishna Stores / Reliance Digital',
              prefixIcon: const Icon(Icons.storefront_outlined, color: AppColors.navyPrimary),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter shop/vendor name';
              }
              return null;
            },
          ),
          const SizedBox(height: 14),

          // Bill No & Date Row
          Row(
            children: [
              Expanded(
                flex: 5,
                child: TextFormField(
                  controller: _billNumberController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    labelText: 'Bill No *',
                    hintText: 'e.g. INV-2025-01',
                    prefixIcon: const Icon(Icons.tag, color: AppColors.navyPrimary),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Enter bill number';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 5,
                child: InkWell(
                  onTap: _selectDate,
                  borderRadius: BorderRadius.circular(10),
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Date *',
                      prefixIcon: const Icon(Icons.calendar_today_outlined, color: AppColors.navyPrimary),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text(
                      DateFormatter.toDisplayDate(_selectedDate),
                      style: GoogleFonts.lato(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Amount Field
          TextFormField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
            ],
            decoration: InputDecoration(
              labelText: 'Amount (₹) *',
              hintText: '0.00',
              prefixIcon: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Text(
                  '₹',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.navyPrimary,
                  ),
                ),
              ),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter amount';
              }
              final val = double.tryParse(value);
              if (val == null || val <= 0) {
                return 'Amount must be greater than 0';
              }
              return null;
            },
          ),
          if (state.amountInWords.isNotEmpty) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.navyPrimary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.navyPrimary.withOpacity(0.15)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.spellcheck, size: 16, color: AppColors.navyPrimary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      state.amountInWords,
                      style: GoogleFonts.lato(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.navyPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 18),

          // Payment Type: Online vs Offline
          Text(
            'Payment Type *',
            style: GoogleFonts.lato(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment<String>(
                value: 'Online',
                label: Text('Online'),
                icon: Icon(Icons.phone_android),
              ),
              ButtonSegment<String>(
                value: 'Offline',
                label: Text('Offline'),
                icon: Icon(Icons.money),
              ),
            ],
            selected: {_paymentType},
            onSelectionChanged: (Set<String> newSelection) {
              setState(() {
                _paymentType = newSelection.first;
                _paymentMode = _paymentType == 'Online'
                    ? _onlineModes.first
                    : _offlineModes.first;
              });
            },
            style: ButtonStyle(
              backgroundColor: MaterialStateProperty.resolveWith<Color>((states) {
                if (states.contains(MaterialState.selected)) {
                  return AppColors.navyPrimary;
                }
                return Colors.white;
              }),
              foregroundColor: MaterialStateProperty.resolveWith<Color>((states) {
                if (states.contains(MaterialState.selected)) {
                  return Colors.white;
                }
                return AppColors.navyPrimary;
              }),
            ),
          ),
          const SizedBox(height: 14),

          // Payment Mode Dropdown
          DropdownButtonFormField<String>(
            value: _paymentMode,
            decoration: InputDecoration(
              labelText: 'Payment Mode *',
              prefixIcon: Icon(
                _paymentType == 'Online' ? Icons.payment : Icons.account_balance_wallet,
                color: AppColors.navyPrimary,
              ),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
            items: (_paymentType == 'Online' ? _onlineModes : _offlineModes)
                .map((mode) => DropdownMenuItem(value: mode, child: Text(mode)))
                .toList(),
            onChanged: (val) {
              if (val != null) setState(() => _paymentMode = val);
            },
          ),
          const SizedBox(height: 14),

          // Transaction Details
          TextFormField(
            controller: _transactionDetailsController,
            decoration: InputDecoration(
              labelText: _paymentType == 'Online'
                  ? 'Transaction Details (UTR / Ref ID / UPI No) *'
                  : 'Transaction / Cash Details (Optional)',
              hintText: _paymentType == 'Online'
                  ? 'e.g. UPI Ref: 319201948210 / GPay UTR'
                  : 'e.g. Cash handed over / Cheque #',
              prefixIcon: const Icon(Icons.receipt, color: AppColors.navyPrimary),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
            validator: (value) {
              if (_paymentType == 'Online' && (value == null || value.trim().isEmpty)) {
                return 'Please enter transaction reference or UTR';
              }
              return null;
            },
          ),
          const SizedBox(height: 14),

          // Remarks
          TextFormField(
            controller: _remarksController,
            maxLines: 2,
            decoration: InputDecoration(
              labelText: 'Purpose / Remarks (Optional)',
              hintText: 'e.g. Purchase of stationery for cultural event',
              prefixIcon: const Icon(Icons.notes, color: AppColors.navyPrimary),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoUploadCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.dividerColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Bill Upload Screenshots / Photos',
                style: GoogleFonts.lato(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.navyPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _attachedImages.isNotEmpty
                      ? AppColors.statusValid.withOpacity(0.12)
                      : Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_attachedImages.length} attached',
                  style: GoogleFonts.lato(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _attachedImages.isNotEmpty
                        ? AppColors.statusValid
                        : AppColors.textMuted,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Add photos or screenshots of the bill, store invoice, or payment receipt. These will be embedded in the PDF.',
            style: GoogleFonts.lato(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 14),

          // Upload action box
          InkWell(
            onTap: _showImagePickerOptions,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.navyPrimary.withOpacity(0.03),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.navyPrimary.withOpacity(0.3),
                  style: BorderStyle.solid,
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.navyPrimary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.add_a_photo_outlined,
                      color: AppColors.navyPrimary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Upload Bill Screenshot / Photo',
                        style: GoogleFonts.lato(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.navyPrimary,
                        ),
                      ),
                      Text(
                        'Tap to select from Gallery or Camera',
                        style: GoogleFonts.lato(
                          fontSize: 11.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Thumbnails grid
          if (_attachedImages.isNotEmpty) ...[
            const SizedBox(height: 14),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.0,
              ),
              itemCount: _attachedImages.length,
              itemBuilder: (context, index) {
                final img = _attachedImages[index];
                return Stack(
                  children: [
                    InkWell(
                      onTap: () => _previewFullImage(img),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.dividerColor),
                          image: DecorationImage(
                            image: MemoryImage(img.bytes),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: InkWell(
                        onTap: () => _removeImage(index),
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            size: 14,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 4,
                      left: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '#${index + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}
