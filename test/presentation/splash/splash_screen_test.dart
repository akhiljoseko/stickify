import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stickify/auth/auth.dart';
import 'package:stickify/presentation/splash/splash_screen.dart';

import '../../helpers/pump_app.dart';

class MockAuthCubit extends Mock implements AuthCubit {}

void main() {
  late AuthCubit authCubit;
  late StreamController<AuthState> authStateController;

  setUp(() {
    authCubit = MockAuthCubit();
    authStateController = StreamController<AuthState>.broadcast();
    when(() => authCubit.stream).thenAnswer((_) => authStateController.stream);
    when(() => authCubit.close()).thenAnswer((_) async {});
  });

  tearDown(() {
    authStateController.close();
  });

  Widget buildTestableWidget() {
    return BlocProvider<AuthCubit>.value(
      value: authCubit,
      child: const SplashScreen(),
    );
  }

  group('SplashScreen Widget Tests', () {
    testWidgets('renders logo, powered by text, and loading indicator', (
      tester,
    ) async {
      when(() => authCubit.state).thenReturn(const AuthInitial());

      await tester.pumpApp(buildTestableWidget());
      await tester.pump();

      expect(find.text('POWERED BY'), findsOneWidget);
      expect(find.byType(Image), findsAtLeastNWidgets(2));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}
