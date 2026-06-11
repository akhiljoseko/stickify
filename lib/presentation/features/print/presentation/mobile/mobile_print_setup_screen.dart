import 'package:flutter/material.dart';

/// Mobile-specific Print Setup layout (stacked panels).
class MobilePrintSetupScreen extends StatelessWidget {
  /// Creates a [MobilePrintSetupScreen].
  const MobilePrintSetupScreen({
    required this.parametersPanel,
    required this.sheetsPreview,
    super.key,
  });

  /// The parameters configuration panel.
  final Widget parametersPanel;

  /// The sheet preview layout.
  final Widget sheetsPreview;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        parametersPanel,
        const SizedBox(height: 24),
        sheetsPreview,
      ],
    );
  }
}
