import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

class AppLogger {
  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 8,
      lineLength: 120,
      colors: true,
      printEmojis: false,
    ),
  );

  static void d(Object? message, {Object? error, StackTrace? stackTrace}) {
    if (!kDebugMode) return;
    _logger.d(message?.toString() ?? 'null', error: error, stackTrace: stackTrace);
  }

  static void i(Object? message, {Object? error, StackTrace? stackTrace}) {
    _logger.i(message?.toString() ?? 'null', error: error, stackTrace: stackTrace);
  }

  static void w(Object? message, {Object? error, StackTrace? stackTrace}) {
    _logger.w(message?.toString() ?? 'null', error: error, stackTrace: stackTrace);
  }

  static void e(Object? message, {Object? error, StackTrace? stackTrace}) {
    _logger.e(message?.toString() ?? 'null', error: error, stackTrace: stackTrace);
  }
}