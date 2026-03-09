// lib/features/documents/presentation/document_request_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/document_bloc.dart';
import '../data/document_model.dart';

class DocumentRequestScreen extends StatefulWidget {
  const DocumentRequestScreen({super.key});

  @override
  State<DocumentRequestScreen> createState() => _DocumentRequestScreenState();
}

class _DocumentRequestScreenState extends State<DocumentRequestScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _propertyAddressController = TextEditingController();
  final _transactionValueController = TextEditingController();
  final _supplementaryTextController = TextEditingController();

  // Dropdown Values
  String? _selectedDocumentType;
  String? _selectedJurisdiction;
  String? _selectedTransactionType;

  // FR-DOC-01: Dropdown Options
  final List<String> _documentTypes = [
    'Stamp Duty Assessment',
    'Clause Validation',
    'Property Transfer',
    'Lease Agreement',
  ];

  final List<String> _jurisdictions = [
    'Maharashtra',
    'Delhi',
    'Karnataka',
    'Tamil Nadu',
    'Gujarat',
    'Rajasthan',
    'Uttar Pradesh',
  ];

  final List<String> _transactionTypes = [
    'Sale',
    'Purchase',
    'Lease',
    'Transfer',
    'Mortgage',
  ];

  @override
  void dispose() {
    _propertyAddressController.dispose();
    _transactionValueController.dispose();
    _supplementaryTextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<DocumentBloc, DocumentState>(
      listener: (context, state) {
        if (state is DocumentRequestSubmitted) {
          // Request submit ho gayi!
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Request submitted! ID: ${state.requestId}',
              ),
              backgroundColor: Colors.green,
            ),
          );
          // Form clear karo
          _formKey.currentState?.reset();
          setState(() {
            _selectedDocumentType = null;
            _selectedJurisdiction = null;
            _selectedTransactionType = null;
          });
        } else if (state is DocumentError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'New Document Request',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Info Card
                _buildInfoCard(),
                const SizedBox(height: 24),

                // FR-DOC-01: Document Type Dropdown
                _buildSectionTitle('Document Details'),
                const SizedBox(height: 12),
                _buildDropdown(
                  label: 'Document Type',
                  value: _selectedDocumentType,
                  items: _documentTypes,
                  icon: Icons.description_outlined,
                  onChanged: (value) {
                    setState(() => _selectedDocumentType = value);
                  },
                  validator: (value) {
                    if (value == null) return 'Document type select karo';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // FR-DOC-01: Jurisdiction Dropdown
                _buildDropdown(
                  label: 'Jurisdiction',
                  value: _selectedJurisdiction,
                  items: _jurisdictions,
                  icon: Icons.location_on_outlined,
                  onChanged: (value) {
                    setState(() => _selectedJurisdiction = value);
                  },
                  // FR-DOC-02: Jurisdiction validation
                  validator: (value) {
                    if (value == null) return 'Jurisdiction select karo';
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // FR-DOC-01: Transaction Details
                _buildSectionTitle('Transaction Details'),
                const SizedBox(height: 12),

                // Transaction Type
                _buildDropdown(
                  label: 'Transaction Type',
                  value: _selectedTransactionType,
                  items: _transactionTypes,
                  icon: Icons.swap_horiz,
                  onChanged: (value) {
                    setState(() => _selectedTransactionType = value);
                  },
                  validator: (value) {
                    if (value == null) return 'Transaction type select karo';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // FR-DOC-02: Transaction Value — numeric validation
                TextFormField(
                  controller: _transactionValueController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Transaction Value (₹)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.currency_rupee),
                    hintText: 'e.g. 5000000',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Transaction value required hai';
                    }
                    // FR-DOC-02: Numeric validation
                    final number = double.tryParse(value);
                    if (number == null) {
                      return 'Valid number enter karo';
                    }
                    if (number <= 0) {
                      return 'Value 0 se zyada honi chahiye';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Property Address
                TextFormField(
                  controller: _propertyAddressController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Property Address',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.home_outlined),
                    hintText: 'Full property address enter karo',
                    alignLabelWithHint: true,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Property address required hai';
                    }
                    if (value.length < 10) {
                      return 'Poora address enter karo';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Supplementary Text — Optional
                _buildSectionTitle('Additional Information (Optional)'),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _supplementaryTextController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Supplementary Text',
                    border: OutlineInputBorder(),
                    hintText: 'Koi additional details...',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 32),

                // FR-DOC-03: Submit Button
                BlocBuilder<DocumentBloc, DocumentState>(
                  builder: (context, state) {
                    final isLoading = state is DocumentLoading;
                    return FilledButton.icon(
                      // FR-DOC-03: Loading mein disable karo
                      onPressed: isLoading ? null : _onSubmit,
                      icon: isLoading
                          ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                          : const Icon(Icons.send),
                      label: Text(
                        isLoading ? 'Submitting...' : 'Submit Request',
                      ),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Submit Logic
  void _onSubmit() {
    // FR-DOC-02: Form validate karo
    if (_formKey.currentState!.validate()) {
      final request = DocumentRequest(
        documentType: _selectedDocumentType!,
        jurisdiction: _selectedJurisdiction!,
        transactionType: _selectedTransactionType!,
        transactionValue: double.parse(_transactionValueController.text),
        propertyAddress: _propertyAddressController.text.trim(),
        supplementaryText: _supplementaryTextController.text.trim(),
      );

      // FR-DOC-03: BLoC se submit karo
      context.read<DocumentBloc>().add(SubmitDocumentRequest(request));
    }
  }

  // Info Card Widget
  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A237E).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF1A237E).withValues(alpha: 0.3),
        ),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.info_outline,
            color: Color(0xFF1A237E),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Fill in the details below to generate your legal document. All fields marked are mandatory.',
              style: TextStyle(
                color: Color(0xFF1A237E),
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Section Title Widget
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Color(0xFF1A237E),
      ),
    );
  }

  // Reusable Dropdown Widget
  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required IconData icon,
    required void Function(String?) onChanged,
    required String? Function(String?) validator,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        prefixIcon: Icon(icon),
      ),
      items: items.map((item) {
        return DropdownMenuItem(
          value: item,
          child: Text(item),
        );
      }).toList(),
      onChanged: onChanged,
      validator: validator,
    );
  }
}