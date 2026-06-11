import 'package:flutter/material.dart';

/// Desktop-specific Print Setup layout (side-by-side panels).
class DesktopPrintSetupScreen extends StatelessWidget {
  /// Creates a [DesktopPrintSetupScreen].
  const DesktopPrintSetupScreen({
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 4, child: parametersPanel),
        const SizedBox(width: 24),
        Expanded(flex: 8, child: sheetsPreview),
      ],
    );
  }
}
