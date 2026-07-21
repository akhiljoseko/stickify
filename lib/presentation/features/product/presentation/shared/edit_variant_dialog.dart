import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stickify/core/core.dart';
import 'package:stickify/domain/domain.dart';
import 'package:stickify/presentation/widgets/template_selector.dart';

/// A reusable dialog widget for editing a [ProductVariant].
class EditVariantDialog extends StatefulWidget {
  const EditVariantDialog({
    required this.product,
    required this.variant,
    required this.onSave,
    super.key,
  });

  final Product product;
  final ProductVariant variant;
  final FutureOr<void> Function(ProductVariant updatedVariant) onSave;

  /// Displays the variant edit dialog over [context].
  static Future<void> show(
    BuildContext context, {
    required Product product,
    required ProductVariant variant,
    required FutureOr<void> Function(ProductVariant updatedVariant) onSave,
  }) {
    return showDialog<void>(
      context: context,
      builder: (context) => EditVariantDialog(
        product: product,
        variant: variant,
        onSave: onSave,
      ),
    );
  }

  @override
  State<EditVariantDialog> createState() => _EditVariantDialogState();
}

class _EditVariantDialogState extends State<EditVariantDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _skuController;
  late final TextEditingController _quantityController;
  late final TextEditingController _unitController;
  late final TextEditingController _wholesaleController;
  late final TextEditingController _mrpController;
  final _formKey = GlobalKey<FormState>();
  String? _selectedTemplateId;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final prefix = widget.product.sku.isNotEmpty
        ? '${widget.product.sku}-'
        : '';
    final suffix = widget.variant.sku.startsWith(prefix)
        ? widget.variant.sku.substring(prefix.length)
        : widget.variant.sku;

    _nameController = TextEditingController(text: widget.variant.name);
    _skuController = TextEditingController(text: suffix);
    _quantityController = TextEditingController(
      text: widget.variant.quantity.toString(),
    );
    _unitController = TextEditingController(text: widget.variant.unit);
    _wholesaleController = TextEditingController(
      text: widget.variant.wholesale.toString(),
    );
    _mrpController = TextEditingController(text: widget.variant.mrp.toString());
    _selectedTemplateId = widget.variant.defaultTemplateId;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _skuController.dispose();
    _quantityController.dispose();
    _unitController.dispose();
    _wholesaleController.dispose();
    _mrpController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSaving = true;
      });

      try {
        final suffixVal = _skuController.text.trim();
        final newSku = widget.product.sku.isNotEmpty
            ? '${widget.product.sku}-$suffixVal'
            : suffixVal;

        final updatedVariant = ProductVariant(
          name: _nameController.text.trim(),
          sku: newSku,
          quantity: double.parse(_quantityController.text),
          unit: _unitController.text.trim(),
          wholesale: double.parse(_wholesaleController.text),
          mrp: double.parse(_mrpController.text),
          defaultTemplateId: _selectedTemplateId,
        );

        await widget.onSave(updatedVariant);
        if (mounted) {
          Navigator.pop(context);
        }
      } catch (e) {
        // Show error if save fails
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to save variant: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isSaving = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return AlertDialog(
      constraints: BoxConstraints(
        minWidth: size.width * 0.5,
        maxWidth: size.width * 0.5,
        minHeight: size.height * 0.7,
        maxHeight: size.height * 0.7,
      ),
      title: Text('Edit Variant - ${widget.variant.name}'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Variant Name'),
                validator: (val) => (val == null || val.trim().isEmpty)
                    ? 'Name is required'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _skuController,
                decoration: InputDecoration(
                  labelText: 'SKU',
                  prefixText: widget.product.sku.isNotEmpty
                      ? '${widget.product.sku}-'
                      : null,
                ),
                validator: (val) => (val == null || val.trim().isEmpty)
                    ? 'SKU is required'
                    : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _quantityController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(labelText: 'Quantity'),
                      validator: (val) =>
                          (val == null || double.tryParse(val) == null)
                          ? 'Must be a number'
                          : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue:
                          const [
                            'pcs',
                            'ml',
                            'gm',
                            'kg',
                            'L',
                          ].contains(_unitController.text)
                          ? _unitController.text
                          : 'gm',
                      decoration: const InputDecoration(labelText: 'Unit'),
                      items: const [
                        DropdownMenuItem(value: 'pcs', child: Text('pcs')),
                        DropdownMenuItem(value: 'ml', child: Text('ml')),
                        DropdownMenuItem(value: 'gm', child: Text('gm')),
                        DropdownMenuItem(value: 'kg', child: Text('kg')),
                        DropdownMenuItem(value: 'L', child: Text('L')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          _unitController.text = val;
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _wholesaleController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Wholesale Price (₹)',
                      ),
                      validator: (val) =>
                          (val == null || double.tryParse(val) == null)
                          ? 'Must be a number'
                          : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _mrpController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(labelText: 'MRP (₹)'),
                      validator: (val) =>
                          (val == null || double.tryParse(val) == null)
                          ? 'Must be a number'
                          : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              FutureBuilder<List<LabelTemplate>>(
                future: (() async {
                  final repo = context.read<TemplateRepository>();
                  final result = await repo.fetchTemplates();
                  return switch (result) {
                    Success(value: final templates) =>
                      templates.where((t) => t.isFinalized).toList(),
                    Failure() => <LabelTemplate>[],
                  };
                })(),
                builder: (context, snapshot) {
                  final templates = (snapshot.data ?? <LabelTemplate>[])
                    ..sort((a, b) => a.name.compareTo(b.name));
                  final isLoading =
                      snapshot.connectionState != ConnectionState.done;
                  return TemplateSelectorField(
                    templates: templates,
                    selectedTemplateId: _selectedTemplateId,
                    labelText: 'Default Template (optional)',
                    allowNone: true,
                    onChanged: isLoading
                        ? null
                        : (val) {
                            setState(() {
                              _selectedTemplateId = val;
                            });
                          },
                  );
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _handleSave,
          child: _isSaving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save Variant'),
        ),
      ],
    );
  }
}
