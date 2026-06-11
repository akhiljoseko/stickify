import 'package:flutter/material.dart';

/// Input field for editing numerical values in the template configuration wizard.
///
/// Features focus-based state synchronization to avoid cursor jumps.
class SetupNumberField extends StatefulWidget {
  /// Creates a [SetupNumberField] instance.
  const SetupNumberField({
    required this.value,
    required this.onChanged,
    required this.labelText,
    this.keyString,
    this.isDecimal = true,
    this.border = const OutlineInputBorder(),
    this.contentPadding,
    super.key,
  });

  /// The active numeric value.
  final double value;

  /// Callback when the value has changed.
  final ValueChanged<double> onChanged;

  /// Label display text for the text input.
  final String labelText;

  /// Optional widget key string identifier.
  final String? keyString;

  /// Whether the input allows fractional numbers.
  final bool isDecimal;

  /// Input border decoration style.
  final InputBorder border;

  /// Content padding decoration style.
  final EdgeInsetsGeometry? contentPadding;

  @override
  State<SetupNumberField> createState() => _SetupNumberFieldState();
}

class _SetupNumberFieldState extends State<SetupNumberField> {
  late TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _formatValue(widget.value));
    _focusNode.addListener(_onFocusChange);
  }

  String _formatValue(double val) {
    if (widget.isDecimal) {
      if (val == val.toInt()) {
        return val.toInt().toString();
      }
      return val.toString();
    } else {
      return val.toInt().toString();
    }
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus) {
      final text = _formatValue(widget.value);
      if (_controller.text != text) {
        _controller.text = text;
      }
    }
  }

  @override
  void didUpdateWidget(covariant SetupNumberField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value) {
      final parsed = double.tryParse(_controller.text);
      if (parsed != widget.value) {
        if (!_focusNode.hasFocus || parsed == null) {
          final text = _formatValue(widget.value);
          _controller.value = TextEditingValue(
            text: text,
            selection: TextSelection.collapsed(offset: text.length),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode
      ..removeListener(_onFocusChange)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      key: widget.keyString != null ? ValueKey(widget.keyString) : null,
      controller: _controller,
      focusNode: _focusNode,
      decoration: InputDecoration(
        labelText: widget.labelText,
        border: widget.border,
        contentPadding: widget.contentPadding,
      ),
      keyboardType: TextInputType.numberWithOptions(decimal: widget.isDecimal),
      onChanged: (val) {
        final parsed = double.tryParse(val);
        if (parsed != null) {
          widget.onChanged(parsed);
        }
      },
    );
  }
}

/// Input field for editing integer values in the template configuration wizard.
///
/// Features focus-based state synchronization to avoid cursor jumps.
class SetupIntField extends StatefulWidget {
  /// Creates a [SetupIntField] instance.
  const SetupIntField({
    required this.value,
    required this.onChanged,
    required this.labelText,
    this.keyString,
    super.key,
  });

  /// The active integer value.
  final int value;

  /// Callback when the value has changed.
  final ValueChanged<int> onChanged;

  /// Label display text for the text input.
  final String labelText;

  /// Optional widget key string identifier.
  final String? keyString;

  @override
  State<SetupIntField> createState() => _SetupIntFieldState();
}

class _SetupIntFieldState extends State<SetupIntField> {
  late TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value.toString());
    _focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus) {
      final text = widget.value.toString();
      if (_controller.text != text) {
        _controller.text = text;
      }
    }
  }

  @override
  void didUpdateWidget(covariant SetupIntField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value) {
      final parsed = int.tryParse(_controller.text);
      if (parsed != widget.value) {
        if (!_focusNode.hasFocus || parsed == null) {
          final text = widget.value.toString();
          _controller.value = TextEditingValue(
            text: text,
            selection: TextSelection.collapsed(offset: text.length),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode
      ..removeListener(_onFocusChange)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      key: widget.keyString != null ? ValueKey(widget.keyString) : null,
      controller: _controller,
      focusNode: _focusNode,
      decoration: InputDecoration(
        labelText: widget.labelText,
        border: const OutlineInputBorder(),
      ),
      keyboardType: TextInputType.number,
      onChanged: (val) {
        final parsed = int.tryParse(val);
        if (parsed != null) {
          widget.onChanged(parsed);
        }
      },
    );
  }
}
