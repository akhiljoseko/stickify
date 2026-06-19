import 'dart:async';
import 'dart:developer';

import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';
import 'package:stickify/app/app.dart';
import 'package:stickify/core/services/pdf/pdf_element_renderer_registry.dart';
import 'package:stickify/firebase_options.dart';

/// Custom [BlocObserver] that logs Bloc state changes and errors.
class AppBlocObserver extends BlocObserver {
  /// Creates an [AppBlocObserver] instance.
  const AppBlocObserver();

  @override
  void onChange(BlocBase<dynamic> bloc, Change<dynamic> change) {
    super.onChange(bloc, change);
    log('onChange(${bloc.runtimeType}, $change)');
  }

  @override
  void onError(BlocBase<dynamic> bloc, Object error, StackTrace stackTrace) {
    log('onError(${bloc.runtimeType}, $error, $stackTrace)');
    super.onError(bloc, error, stackTrace);
  }
}

/// Global initialization block to configure cross-flavor logic and launch the application.
Future<void> bootstrap(
  FutureOr<Widget> Function(AppServiceLocator locator) builder,
) async {
  WidgetsFlutterBinding.ensureInitialized();

  PdfElementRendererRegistry.registerDefaults();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
  );

  FlutterError.onError = (details) {
    log(details.exceptionAsString(), stackTrace: details.stack);
  };

  // Bloc.observer = const AppBlocObserver();

  // Add cross-flavor configuration here
  final locator = await AppServiceLocator.create();

  runApp(await builder(locator));
}
