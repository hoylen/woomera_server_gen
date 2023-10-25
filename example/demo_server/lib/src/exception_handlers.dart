part of '../demo_server.dart';

//================================================================
// Exception handlers
//
// Woomera will invoke these methods if an exception was raised when processing
// a HTTP request.

//----------------------------------------------------------------
/// Exception handler used on the pipeline.
///
/// This will handle all exceptions raised by the application's request
/// handlers.

@PipelineExceptionHandler()
Future<Response> pipelineExceptionHandler(
    Request req, Object exception, StackTrace st) async {
  log
    ..warning(
        'pipeline exception handler: ${exception.runtimeType}: $exception')
    ..finest('stack trace: $st');

  if (exception is DemoException) {
    if (exception.handledBy != HandledBy.pipelineExceptionHandler) {
      // Throw an exception. This will trigger the server exception handler
      // (if there is one) to process it.
      throw StateError('throw something');
    }
  }

  final resp = ResponseBuffered(ContentType.html)
    ..status = HttpStatus.internalServerError
    ..write('''
<!DOCTYPE html>
<html lang="en">
<head>
  <title>Error</title>
</head>
<body>
  <h1 style="color: red">Exception thrown</h1>

  <p style='font-size: small'>This error page was produced by the
  <strong>pipeline</strong> exception handler.
  See logs for details.</p>

  <a href="${req.ura('~/')}">Home</a>
</body>
</html>
''');

  return resp;
}

//----------------------------------------------------------------
/// Exception handler used on the server.
///
/// This will handle all exceptions raised outside the application's request
/// handlers, as well as if exceptions raised by the pipeline exception
/// handler.
///
/// Note: if there is no match a [NotFoundException] exception is raised for
/// this exception handler to process (i.e. generate a 404/405 error page for
/// the client).

@ServerExceptionHandler()
Future<Response> serverExceptionHandler(
    Request req, Object exception, StackTrace st) async {
  log
    ..warning('server exception handler: ${exception.runtimeType}: $exception')
    ..finest('stack trace: $st');

  if (exception is ExceptionHandlerException) {
    final originalException = exception.previousException;

    assert(exception.exception is StateError);

    if (originalException is DemoException) {
      if (originalException.handledBy != HandledBy.serverExceptionHandler) {
        // Throw an exception. The server raw exception handler will process it
        // (if there is one).
        throw originalException;
      }
    }
  }

  // Create a response

  final resp = ResponseBuffered(ContentType.html);

  // Set the status depending on the type of exception

  String message;
  if (exception is NotFoundException) {
    // A server exception handler gets this exception when no request handler
    // was found to process the request. HTTP has two different status codes
    // for this, depending on if the server supports the resource or not.
    resp.status = exception.resourceExists
        ? HttpStatus.methodNotAllowed
        : HttpStatus.notFound;
    message = 'Page not found';
  } else if (exception is ExceptionHandlerException) {
    // A server exception handler gets this exception if a pipeline exception
    // handler threw an exception (while it was trying to handle an exception
    // thrown by a request handler).
    resp.status = HttpStatus.badRequest;
    message = 'Pipeline exception handler threw an exception';
  } else {
    // A server exception handler gets all the exceptions thrown by a request
    // handler, if there was no pipeline exception handler.
    resp.status = HttpStatus.internalServerError;
    message = 'Internal error: unexpected exception';
  }

  resp.write('''
<!DOCTYPE html>
<html lang="en">
<head>
  <title>Exception</title>
</head>
<body>
  <h1 style="color: red">${HEsc.text(message)}</h1>

  <p style='font-size: small'>This error page was produced by the
  <strong>server</strong> exception handler.
  See logs for details.</p>

  <a href="${req.ura('~/')}">Home</a>
</body>
</html>
''');

  return resp;

  // If the server error handler raises an exception, a very basic error
  // response is sent back to the client. This situation should be avoided
  // (because that error page is very ugly and not user friendly) by making sure
  // the application's server exception handler never raises an exception.
}

//----------------------------------------------------------------
/// This is an example of a server raw exception handler.
///
/// But in this simple example, there is no way to invoke it.
/// The server raw exception handler is triggered in very rare situations.

@ServerExceptionHandlerRaw()
Future<void> myLowLevelExceptionHandler(
    HttpRequest rawRequest, String requestId, Object ex, StackTrace st) async {
  simLog.severe('[$requestId] raw exception (${ex.runtimeType}): $ex\n$st');

  final resp = rawRequest.response
    ..statusCode = HttpStatus.internalServerError
    ..headers.contentType = ContentType.html
    ..write('''<!DOCTYPE html>
<html lang="en">
<head><title>Error</title></head>
<body>
  <h1>Error</h1>
  <p>Something went wrong.</p>
  
  <p style='font-size: small'>This error page was produced by the
  server <strong>raw</strong> exception handler.
  See logs for details.</p>
</body>
</html>
''');

  await resp.close();
}
