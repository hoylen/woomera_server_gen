part of '../woomera_server_gen.dart';

//################################################################
/// Generate a summary of the Server and its pipelines.

String generateSummary(ServerDefinition def, {bool verbose = false}) =>
    verbose ? _server2verboseSummary(def) : _server2briefSummary(def);

//----------------------------------------------------------------

String _server2briefSummary(ServerDefinition def) {
  final buf = StringBuffer('server:\n');

  // Output server exception handler and server raw exception handler, if any

  if (def.exceptionHandler != null) {
    buf.writeln('  server_exception_handler: true');
  }
  if (def.exceptionHandlerRaw != null) {
    buf.writeln('  server_raw_exception_handler: true');
  }

  // Output wrapper, if any

  if (def.wrapperFunction != null) {
    buf.writeln('  request_wrapper: true');
  }

  // Output pipelines

  if (def.pipelines.isNotEmpty) {
    buf.writeln('  pipelines:');
  }

  // Output the pipelines

  for (final p in def.pipelines) {
    final name = p.name;

    buf.writeln(
        name != ServerPipeline.defaultName ? '    "$name":' : '    "":');

    // Output existence of pipeline exception handler, if any

    if (p.exceptionHandler != null) {
      buf.writeln('      pipeline_exception_handler: true');
    }

    buf.writeln('      num_request_handlers: ${p.requestHandlers.length}');
  }

  return buf.toString();
}

//----------------------------------------------------------------

String _server2verboseSummary(ServerDefinition def) {
  final buf = StringBuffer('server:\n');

  // Output server exception handler and server raw exception handler, if any

  final srEH = def.exceptionHandlerRaw != null ? 'true' : 'false';
  buf.writeln('  server_raw_exception_handler: $srEH');

  final sEH = def.exceptionHandler != null ? 'true' : 'false';
  buf.writeln('  server_exception_handler: $sEH');

  // Output wrapper, if any

  final wf = def.wrapperFunction != null ? 'true' : 'false';
  buf.writeln('  request_wrapper: $wf');

  // The pipelines

  if (def.pipelines.isNotEmpty) {
    buf.writeln('  pipelines:');
  } else {
    buf.writeln('  # no pipelines');
  }

  // Output the pipelines

  for (final p in def.pipelines) {
    final name = p.name;

    buf.writeln(name != ServerPipeline.defaultName
        ? '    "$name":'
        : '    "": # default pipeline');

    // Output existence of pipeline exception handler, if any

    final pEH = p.exceptionHandler != null ? 'true' : 'false';
    buf.writeln('      pipeline_exception_handler: $pEH');

    // Output counts of the request handlers in the pipeline

    if (p.requestHandlers.isNotEmpty) {
      buf.writeln('      request_handlers:');
    } else {
      buf.writeln('      # no request handlers');
    }

    final httpMethodCount = <String, int>{};

    for (final h in p.requestHandlers) {
      final a = h.annotation as Handles; // request handlers should only be this

      final httpMethodName = a.httpMethod!;

      final count = httpMethodCount[httpMethodName] ?? 0;
      httpMethodCount[httpMethodName] = count + 1;
    }

    for (final entry in httpMethodCount.entries) {
      buf.writeln('        ${entry.key}: ${entry.value}');
    }
  }

  return buf.toString();
}
