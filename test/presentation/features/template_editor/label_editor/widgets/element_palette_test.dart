import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stickify/domain/domain.dart';
import 'package:stickify/presentation/features/template_editor/label_editor/bloc/editor_cubit.dart';
import 'package:stickify/presentation/features/template_editor/label_editor/widgets/element_palette.dart';

class MockTemplateRepository extends Mock implements TemplateRepository {}

Widget buildTestApp({required Widget child, double width = 400}) {
  return MaterialApp(
    home: Scaffold(
      body: SizedBox(
        width: width,
        child: child,
      ),
    ),
  );
}

void main() {
  group('ElementPalette', () {
    testWidgets('renders palette items', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          child: BlocProvider<EditorCubit>(
            create: (_) => EditorCubit(MockTemplateRepository(), 'temp-123'),
            child: const ElementPalette(),
          ),
          width: 400,
        ),
      );

      expect(find.text('Product Name'), findsOneWidget);
      expect(find.byIcon(Icons.title), findsOneWidget);
    });
  });
}

