// lib/screens/receipt_scanning_screen.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import '../services/ocr_service.dart';
import '../services/expense_tracking_service.dart';

// Conditional import for File
import 'dart:io' if (dart.library.html) 'dart:html' as io;

class ReceiptScanningScreen extends StatefulWidget {
  const ReceiptScanningScreen({super.key});

  @override
  State<ReceiptScanningScreen> createState() => _ReceiptScanningScreenState();
}

class _ReceiptScanningScreenState extends State<ReceiptScanningScreen> {
  final OCRService _ocrService = OCRService();
  final ExpenseTrackingService _expenseService = ExpenseTrackingService();
  dynamic _selectedImage;
  bool _isProcessing = false;
  Map<String, String?> _extractedData = {};
  final _amountController = TextEditingController();
  final _categoryController = TextEditingController();
  final _descriptionController = TextEditingController();

  final List<String> _categories = [
    'Transport',
    'Food',
    'Accommodation',
    'Shopping',
    'Entertainment',
    'Other',
  ];

  @override
  void dispose() {
    _amountController.dispose();
    _categoryController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage({bool fromCamera = true}) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = fromCamera
          ? await picker.pickImage(source: ImageSource.camera)
          : await picker.pickImage(source: ImageSource.gallery);
      
      if (image != null) {
        setState(() {
          if (!kIsWeb) {
            _selectedImage = io.File(image.path);
          } else {
            _selectedImage = image; // Use XFile on web
          }
          _isProcessing = true;
          _extractedData = {}; // Clear previous data
        });

        // Extract data from receipt
        final extracted = await _ocrService.extractTripDetails(_selectedImage);
        
        setState(() {
          _extractedData = extracted;
          _isProcessing = false;
          
          // Try to extract amount
          final amountText = _extractAmount(extracted['rawText'] ?? '');
          if (amountText.isNotEmpty) {
            _amountController.text = amountText;
          }
          
          // Try to extract category from text
          final category = _extractCategory(extracted['rawText'] ?? '');
          if (category.isNotEmpty) {
            _categoryController.text = category;
          }
          
          // Auto-fill description if available
          if (extracted['rawText'] != null && extracted['rawText']!.isNotEmpty) {
            final rawText = extracted['rawText']!;
            if (_descriptionController.text.isEmpty && rawText.length > 20) {
              _descriptionController.text = rawText.substring(0, rawText.length > 100 ? 100 : rawText.length);
            }
          }
        });
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });
      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Error'),
            content: Text('Failed to process image: $e'),
            actions: [
              CupertinoDialogAction(
                child: const Text('OK'),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      }
    }
  }

  String _extractAmount(String text) {
    // Look for currency patterns
    final patterns = [
      RegExp(r'₹\s*(\d+[.,]?\d*)', caseSensitive: false),
      RegExp(r'(\d+[.,]?\d*)\s*₹', caseSensitive: false),
      RegExp(r'Total[:\s]+₹?\s*(\d+[.,]?\d*)', caseSensitive: false),
      RegExp(r'Amount[:\s]+₹?\s*(\d+[.,]?\d*)', caseSensitive: false),
    ];
    
    for (var pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        return match.group(1)?.replaceAll(',', '') ?? '';
      }
    }
    return '';
  }

  String _extractCategory(String text) {
    final lowerText = text.toLowerCase();
    if (lowerText.contains('taxi') || lowerText.contains('uber') || lowerText.contains('ola')) {
      return 'Transport';
    } else if (lowerText.contains('restaurant') || lowerText.contains('food') || lowerText.contains('cafe')) {
      return 'Food';
    } else if (lowerText.contains('hotel') || lowerText.contains('accommodation')) {
      return 'Accommodation';
    } else if (lowerText.contains('shop') || lowerText.contains('store')) {
      return 'Shopping';
    }
    return '';
  }

  Future<void> _saveExpense() async {
    if (_amountController.text.isEmpty) {
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('Missing Amount'),
          content: const Text('Please enter the amount'),
          actions: [
            CupertinoDialogAction(
              child: const Text('OK'),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );
      return;
    }

    final amount = double.tryParse(_amountController.text) ?? 0.0;
    final category = _categoryController.text.isNotEmpty 
        ? _categoryController.text 
        : 'Other';
    final description = _descriptionController.text.isNotEmpty
        ? _descriptionController.text
        : 'Receipt scanned expense';

    // Save to database using expense service
    final tripId = 'receipt_${DateTime.now().millisecondsSinceEpoch}';
    await _expenseService.addExpense(
      tripId: tripId,
      category: category,
      amount: amount,
      description: description,
    );

    if (mounted) {
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('Expense Saved'),
          content: Text('₹${amount.toStringAsFixed(2)} saved successfully'),
          actions: [
            CupertinoDialogAction(
              child: const Text('OK'),
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  _selectedImage = null;
                  _extractedData = {};
                  _amountController.clear();
                  _categoryController.clear();
                  _descriptionController.clear();
                });
              },
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Scan Receipt'),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Header Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    CupertinoColors.systemBlue,
                    CupertinoColors.systemPurple,
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Icon(
                    CupertinoIcons.doc_text_fill,
                    color: CupertinoColors.white,
                    size: 48,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Smart Receipt Scanner',
                    style: TextStyle(
                      color: CupertinoColors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Automatically extract expense details from receipts',
                    style: TextStyle(
                      color: CupertinoColors.white.withValues(alpha: 0.9),
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Instructions Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: CupertinoColors.systemGrey6,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        CupertinoIcons.info_circle_fill,
                        color: CupertinoColors.systemBlue,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'How to Use',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildInstructionItem('1. Tap "Take Photo" or "Choose from Gallery"'),
                  _buildInstructionItem('2. Capture or select your receipt image'),
                  _buildInstructionItem('3. Wait for automatic data extraction'),
                  _buildInstructionItem('4. Review and edit the extracted details'),
                  _buildInstructionItem('5. Save your expense'),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Image Preview
            if (_selectedImage != null)
              Container(
                height: 300,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: CupertinoColors.separator),
                  boxShadow: [
                    BoxShadow(
                      color: CupertinoColors.black.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: kIsWeb
                          ? Image.network(
                              _selectedImage.path,
                              fit: BoxFit.contain,
                            )
                          : Image.file(
                              _selectedImage as io.File,
                              fit: BoxFit.contain,
                            ),
                    ),
                    if (_isProcessing)
                      Container(
                        color: CupertinoColors.black.withValues(alpha: 0.5),
                        child: const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CupertinoActivityIndicator(
                                color: CupertinoColors.white,
                                radius: 20,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'Processing receipt...',
                                style: TextStyle(
                                  color: CupertinoColors.white,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),

            // Action Buttons
            if (_selectedImage == null) ...[
              Row(
                children: [
                  Expanded(
                    child: CupertinoButton.filled(
                      color: CupertinoColors.systemBlue,
                      onPressed: _isProcessing ? null : () => _pickImage(fromCamera: true),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(CupertinoIcons.camera_fill),
                          SizedBox(width: 8),
                          Text('Take Photo'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CupertinoButton.filled(
                      color: CupertinoColors.systemPurple,
                      onPressed: _isProcessing ? null : () => _pickImage(fromCamera: false),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(CupertinoIcons.photo_fill),
                          SizedBox(width: 8),
                          Text('Gallery'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ] else ...[
              Row(
                children: [
                  Expanded(
                    child: CupertinoButton(
                      onPressed: _isProcessing
                          ? null
                          : () {
                              setState(() {
                                _selectedImage = null;
                                _extractedData = {};
                                _amountController.clear();
                                _categoryController.clear();
                                _descriptionController.clear();
                              });
                            },
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(CupertinoIcons.refresh),
                          SizedBox(width: 8),
                          Text('Scan Another'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CupertinoButton.filled(
                      onPressed: _isProcessing ? null : () => _pickImage(fromCamera: true),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(CupertinoIcons.camera_fill),
                          SizedBox(width: 8),
                          Text('Retake'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 24),

            // Extracted Data
            if (_extractedData.isNotEmpty && !_isProcessing) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: CupertinoColors.systemGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: CupertinoColors.systemGreen.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          CupertinoIcons.check_mark_circled_solid,
                          color: CupertinoColors.systemGreen,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Extracted Information',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (_extractedData['price'] != null && _extractedData['price']!.isNotEmpty)
                      _buildExtractedItem('Amount', '₹${_extractedData['price']}'),
                    if (_extractedData['origin'] != null && _extractedData['origin']!.isNotEmpty)
                      _buildExtractedItem('Origin', _extractedData['origin']!),
                    if (_extractedData['destination'] != null && _extractedData['destination']!.isNotEmpty)
                      _buildExtractedItem('Destination', _extractedData['destination']!),
                    if (_extractedData['vehicle'] != null && _extractedData['vehicle']!.isNotEmpty)
                      _buildExtractedItem('Vehicle', _extractedData['vehicle']!),
                    if (_extractedData['date'] != null && _extractedData['date']!.isNotEmpty)
                      _buildExtractedItem('Date', _extractedData['date']!),
                    if (_extractedData['time'] != null && _extractedData['time']!.isNotEmpty)
                      _buildExtractedItem('Time', _extractedData['time']!),
                    if (_extractedData['rawText'] != null && _extractedData['rawText']!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        height: 1,
                        color: CupertinoColors.separator,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Raw Text (Preview)',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: CupertinoColors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _extractedData['rawText']!.length > 200
                              ? '${_extractedData['rawText']!.substring(0, 200)}...'
                              : _extractedData['rawText']!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: CupertinoColors.secondaryLabel,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Expense Form
            CupertinoFormSection.insetGrouped(
              header: const Text('EXPENSE DETAILS'),
              children: [
                CupertinoTextFormFieldRow(
                  prefix: const Text('Amount'),
                  placeholder: '₹0.00',
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                ),
                CupertinoListTile(
                  title: const Text('Category'),
                  trailing: CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () {
                      showCupertinoModalPopup(
                        context: context,
                        builder: (context) => Container(
                          height: 250,
                          padding: const EdgeInsets.only(top: 6),
                          margin: EdgeInsets.only(
                            bottom: MediaQuery.of(context).viewInsets.bottom,
                          ),
                          color: CupertinoColors.systemBackground.resolveFrom(context),
                          child: SafeArea(
                            top: false,
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    CupertinoButton(
                                      child: const Text('Cancel'),
                                      onPressed: () => Navigator.pop(context),
                                    ),
                                    const Text(
                                      'Select Category',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    CupertinoButton(
                                      child: const Text('Done'),
                                      onPressed: () => Navigator.pop(context),
                                    ),
                                  ],
                                ),
                                Expanded(
                                  child: CupertinoPicker(
                                    itemExtent: 40,
                                    scrollController: FixedExtentScrollController(
                                      initialItem: _categoryController.text.isNotEmpty
                                          ? _categories.indexOf(_categoryController.text)
                                          : 0,
                                    ),
                                    onSelectedItemChanged: (index) {
                                      setState(() {
                                        _categoryController.text = _categories[index];
                                      });
                                    },
                                    children: _categories
                                        .map((cat) => Center(child: Text(cat)))
                                        .toList(),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                    child: Text(
                      _categoryController.text.isEmpty
                          ? 'Select Category'
                          : _categoryController.text,
                      style: TextStyle(
                        color: _categoryController.text.isEmpty
                            ? CupertinoColors.secondaryLabel
                            : CupertinoColors.label,
                      ),
                    ),
                  ),
                ),
                CupertinoTextFormFieldRow(
                  prefix: const Text('Description'),
                  placeholder: 'Optional',
                  controller: _descriptionController,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Save Button
            if (_amountController.text.isNotEmpty) ...[
              CupertinoButton.filled(
                color: CupertinoColors.systemGreen,
                onPressed: _saveExpense,
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(CupertinoIcons.check_mark_circled_solid),
                    SizedBox(width: 8),
                    Text('Save Expense'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInstructionItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            CupertinoIcons.circle_fill,
            size: 6,
            color: CupertinoColors.secondaryLabel,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                color: CupertinoColors.label,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExtractedItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: CupertinoColors.secondaryLabel,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

