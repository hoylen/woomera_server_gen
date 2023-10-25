part of '../woomera_server_gen.dart';

//################################################################
/// Generate Dart code to instantiate a server and its pipelines.
///
/// The code is a complete Dart file containing a single function named
/// [functionName] (which defaults to `serverBuilder`). The function returns
/// a _Server_. The invoker of that function may wish to set the server's
/// listening address and port, before running it.
///
/// If [libraryName] is specified, a `part of` statement is added and
/// the functions are assumed to be from that library.
///
/// If a [comment] is provided, it is used as a comment at the beginning of
/// the file. The comment string may have multiple lines.
///
/// If [fromLocationComments] is true, comments are also added to the code to
/// indicate where the function and annotation came from.
/// This can be useful for debugging.
///
/// If [timestamp] is true, a comment with the current time is included in
/// the comments. Normally, it should be left as false; so a regenerated file
/// does not change if there has been no actual change to the code.

String generateDart(ServerDefinition def,
    {String functionName = 'serverBuilder',
    String libraryName = '',
    bool timestamp = false,
    bool fromLocationComments = false,
    String? comment}) {
  // TODO(any): is importedLibraries no longer needed?
  // This used to be a parameter.
  Iterable<String> importedLibraries = const <String>[];

  const defaultComment = '''
Generated by a program using the `GenerateCode.generateDart` method
from the woomera_server_gen package.

See <https://pub.dev/documentation/woomera_server_gen>''';

  //final genComment = (comment ?? defaultComment).replaceAll('\n', '\n// ');

  final genComment = (comment ?? defaultComment)
      .split('\n')
      .map((line) => line.isEmpty ? '//' : '// $line')
      .join('\n');

  final buf = StringBuffer('''
// WARNING: DO NOT EDIT

$genComment
''');

  // Timestamp comment

  if (timestamp) {
    final timestamp = DateTime.now().toUtc().toString();
    assert(timestamp.endsWith('Z'), 'unexpected timezone: $timestamp');
    buf.write('//\n// Generated: ${timestamp.substring(0, 19)}Z\n\n');
  } else {
    buf.write('\n');
  }

  // "part of" statement

  if (libraryName.isNotEmpty) {
    buf.write('// ignore: use_string_in_part_of_directives\n'
        'part of $libraryName;\n\n');
  }

  final libraryPrefixes = <String>[];
  if (libraryName.isNotEmpty) {
    libraryPrefixes.add(libraryName);
  }
  for (var name in importedLibraries) {
    if (name.isNotEmpty) {
      libraryPrefixes.addAll(importedLibraries);
    }
  }

  // The generated function

  buf.write('''
/// Creates a [Server]. with all the [ServerPipeline] and handlers registered.
///
/// The server will have all the pipelines. Each pipeline will have any
/// _pipeline exception handler_ set and all of its _request handlers_
/// registered. The server will also have any _server raw exception handler_
/// and/or normal _server exception handler_ set.
///
/// This function was automatically generated from `woomera` annotations,
/// by a program using the `woomera_server_gen` package. To change it,
/// please change the annotations and re-generate it.

Server $functionName() {
''');

  // Wrapper

  String wName;

  final hw = def.wrapperFunction;

  if (hw != null) {
    wName = _functionName(hw.function, libraryPrefixes);
    final wLoc = _functionLocation(hw.function);
    buf.write('\n  // Handles.handlerWrapper\n'
        '\n'
        '  const _wrap = $wName;');
    if (fromLocationComments) {
      buf.write('\n  // request handler wrapper from $wLoc');
    }
    buf.write('\n\n');
  } else {
    wName = ''; // no wrapper function
  }

  // Pipelines

  final pipelineVariables = <String>[];

  var num = 0;

  for (final p in def.pipelines) {
    final pipelineVariable = 'p${++num}';
    pipelineVariables.add(pipelineVariable);

    // This is the string displayed to represent the default pipeline name
    // value. It is actually the name of the constant itself, from the
    // [ServerPipeline] class, since this is generating code to reference it.

    const def = 'ServerPipeline.defaultName';

    final nameStr = p.name != ServerPipeline.defaultName ? "'${p.name}'" : def;

    buf.write('  final $pipelineVariable = ServerPipeline($nameStr)');

    // Pipeline's exception handler

    final eh = p.exceptionHandler;
    if (eh != null) {
      final loc = _functionLocation(eh.function);
      final fName = _functionName(eh.function, libraryPrefixes);

      buf.write('\n    ..exceptionHandler = $fName');
      if (fromLocationComments) {
        buf.write('\n        // pipeline exception handler from $loc');
      }
    }

    // Pipeline's request handlers

    for (final scanResult in p.requestHandlers) {
      final annotation = scanResult.annotation as Handles;
      final func = scanResult.function;

      final method = annotation.httpMethod;
      final pattern = annotation.pattern;
      var fName = _functionName(func, libraryPrefixes); // the function

      if (wName.isNotEmpty) {
        // Wrapper exists: wrap the function name

        final handlesArgs = <String>["'$method'", "'$pattern'"];

        if (annotation.priority != 0) {
          handlesArgs.add('priority: ${annotation.priority}');
        }
        if (annotation.pipeline != ServerPipeline.defaultName) {
          handlesArgs.add("pipeline: '${annotation.pipeline}'");
        }

        // Code that wraps the function
        fName =
            '_wrap(const Handles.request(${handlesArgs.join(', ')}), $fName)';
      }

      final convenience = {
        'GET': 'get',
        'POST': 'post',
        'PUT': 'put',
        'PATCH': 'patch',
        'DELETE': 'delete',
        'HEAD': 'head',
      }[method];
      if (convenience != null) {
        buf.write("\n    ..$convenience('$pattern', $fName)");
      } else {
        buf.write("\n    ..register('$method', '$pattern', $fName)");
      }
      if (fromLocationComments) {
        final loc = _functionLocation(func);
        buf.write('\n        // from $loc');
      }
    } // for over request handlers in the pipeline

    buf.write(';\n\n');
  } // for over pipelines

  // Code to create the server and register the request handlers

  buf.write('  return Server(numberOfPipelines: 0)');

  // Server raw exception handler

  final rawEH = def.exceptionHandlerRaw;
  if (rawEH != null) {
    // Dump code to set the raw exception handler

    final loc = _functionLocation(rawEH.function);
    final fName = _functionName(rawEH.function, libraryPrefixes);

    buf.write('\n    ..exceptionHandlerRaw = $fName');
    if (fromLocationComments) {
      buf.write('\n    // server raw exception handler from $loc');
    }
  }

  // Server (normal) exception handler

  final serverEH = def.exceptionHandler;
  if (serverEH != null) {
    // Dump code to set the server exception handler

    final loc = _functionLocation(serverEH.function);
    final fName = _functionName(serverEH.function, libraryPrefixes);

    buf.write('\n    ..exceptionHandler = $fName');
    if (fromLocationComments) {
      buf.write('\n    // server exception handler from $loc');
    }
  }

  buf.write('\n    ..pipelines.addAll([${pipelineVariables.join(', ')}]);\n'
      '}\n');

  return buf.toString();
}

//----------------
/// Determine the function name to use in the generated dart code.

String _functionName(Function f, Iterable<String> libraryPrefixes) {
  final r1 = reflect(f);
  if (r1 is ClosureMirror) {
    var fName = MirrorSystem.getName(r1.function.qualifiedName);
    if (fName.startsWith('.')) {
      fName = fName.substring(1); // remove leading '.'
    }

    for (final prefix in libraryPrefixes) {
      if (fName.startsWith('$prefix.')) {
        fName = fName.substring(prefix.length + 1);
      }
    }

    return fName;
  } else {
    throw StateError('not a function');
  }
}

//----------------
/// Determine the function's location for comments in the generated dart code.

SourceLocation _functionLocation(Function f) {
  final r1 = reflect(f);
  if (r1 is ClosureMirror) {
    final loc = r1.function.location;
    if (loc != null) {
      return loc;
    } else {
      throw StateError('no location');
    }
  } else {
    throw StateError('not a function');
  }
}