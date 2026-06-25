import 'dart:async';
import 'dart:ui';

import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';
import 'package:stickify/app/app.dart';
import 'package:stickify/core/services/logging/composite_logger_service.dart';
import 'package:stickify/core/services/logging/console_logger_service.dart';
import 'package:stickify/core/services/logging/file_logger_service.dart';
import 'package:stickify/core/services/logging/logger_service.dart';
import 'package:stickify/core/services/pdf/pdf_element_renderer_registry.dart';
import 'package:stickify/firebase_options.dart';

/// Custom [BlocObserver] that logs Bloc state changes and errors.
class AppBlocObserver extends BlocObserver {
  /// Creates an [AppBlocObserver] instance.
  const AppBlocObserver();

  @override
  void onChange(BlocBase<dynamic> bloc, Change<dynamic> change) {
    super.onChange(bloc, change);
    // BLoC state changes are intentionally not logged here to reduce noise.
    // Use explicit Log.* calls inside cubits for meaningful traceability.
  }

  @override
  void onError(BlocBase<dynamic> bloc, Object error, StackTrace stackTrace) {
    Log.error(
      'onError(${bloc.runtimeType}, $error)',
      tag: 'Bloc',
      error: error,
      stackTrace: stackTrace,
    );
    super.onError(bloc, error, stackTrace);
  }
}

/// Global initialization block to configure cross-flavor logic and launch the application.
Future<void> bootstrap(
  FutureOr<Widget> Function(AppServiceLocator locator) builder, {
  LogLevel minLevel = LogLevel.info,
  bool enableFileLogging = true,
}) async {
  // 1. Initialize logging framework first to capture subsequent initializations
  final loggers = <LoggerService>[
    const ConsoleLoggerService(),
  ];

  if (enableFileLogging) {
    loggers.add(FileLoggerService());
  }

  final compositeLogger = CompositeLoggerService(loggers);
  await compositeLogger.init();

  Log.initialize(
    logger: compositeLogger,
    minLevel: minLevel,
  );

  Log.info(
    'Logging initialized. MinLevel: $minLevel, FileLogging: $enableFileLogging',
    tag: 'Bootstrap',
  );

  WidgetsFlutterBinding.ensureInitialized();

  // Redirect Flutter framework errors to Log.fatal
  FlutterError.onError = (details) {
    Log.fatal(
      details.exceptionAsString(),
      tag: 'FlutterError',
      error: details.exception,
      stackTrace: details.stack,
    );
  };

  // Redirect asynchronous errors outside Flutter framework to Log.fatal
  PlatformDispatcher.instance.onError = (error, stackTrace) {
    Log.fatal(
      'Uncaught async error',
      tag: 'PlatformDispatcher',
      error: error,
      stackTrace: stackTrace,
    );
    return true;
  };

  // Wire custom BlocObserver
  Bloc.observer = const AppBlocObserver();

  Log.info('Registering default PDF element renderers...', tag: 'Bootstrap');
  PdfElementRendererRegistry.registerDefaults();

  Log.info('Initializing Firebase...', tag: 'Bootstrap');
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
  );

  Log.info('Creating AppServiceLocator...', tag: 'Bootstrap');
  final locator = await AppServiceLocator.create();

  Log.info('Bootstrap completed. Starting application...', tag: 'Bootstrap');
  runApp(await builder(locator));
}
