part of '../demo_server.dart';

//================================================================
// Exceptions

enum HandledBy {
  pipelineExceptionHandler,
  serverExceptionHandler,
  defaultServerExceptionHandler
}

/// Exception that is thrown by [requestHandlerThatAlwaysThrowsException].
///
/// This is used to demonstrate how exceptions are processed by the
/// _pipeline exception handler_ and _server exception handler_.

class DemoException implements Exception {
  DemoException(this.handledBy);

  final HandledBy handledBy;
}
