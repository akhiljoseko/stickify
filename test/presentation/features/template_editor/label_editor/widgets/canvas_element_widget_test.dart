import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stickify/domain/domain.dart';
import 'package:stickify/presentation/features/template_editor/label_editor/bloc/editor_cubit.dart';
import 'package:stickify/presentation/features/template_editor/label_editor/widgets/canvas_element_widget.dart';

class MockTemplateRepository extends Mock implements TemplateRepository {}

void main() {
  group('CanvasElementWidget', () {
    testWidgets('renders text element on canvas', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BlocProvider<EditorCubit>(
              create: (_) => EditorCubit(MockTemplateRepository(), 'temp-123'),
              child: Stack(
                children: [
                  CanvasElementWidget(
                    blueprint: const TextElementBlueprint(
                      id: 'elem-1',
                      x: 10,
                      y: 10,
                      width: 80,
                      height: 20,
                      rotation: 0,
                      content: 'Test Label',
                      isDynamic: false,
                      fontSize: 12,
                      fontWeightValue: 400,
                      textAlign: BlueprintTextAlign.left,
                      colorHex: 0xFF000000,
                    ),
                    isSelected: false,
                    onTap: () {},
                    zoomLevel: 1,
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.text('Test Label'), findsOneWidget);
    });
  });
}
