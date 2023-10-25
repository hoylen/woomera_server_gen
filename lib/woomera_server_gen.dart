/// Uses the _dart:mirror_ package to create a server definition
/// using the annotations defined in the _woomera_ package and generates Dart
/// code to instantiate that server from it.
///
/// # Annotations
///
/// The annotations identify the different functions that make up a Woomera
/// server:
///
/// - request handler functions;
/// - pipeline exception handlers;
/// - wrapper function;
/// - server exception handler; and
/// - server raw exception handler.
///
/// Implicit in the _request handler functions_ and the _pipeline
/// exception handlers_ are the pipelines that are a part of the server.
///
/// See the [woomera](https://pub.dev/packages/woomera) package for details.
///
/// # Usage
///
/// The server definition is created using the [ServerDefinition] default
/// constructor. It scans the current program, so the annotated functions
/// should be imported into the same program that uses this library.
///
/// The server definition can then be used to generate Dart code
/// using the [generateDart] function, or a text representation of it
/// using the [generateSummary] function or the [ServerDefinition.toString]
/// method.

library woomera_server_gen;

//================================================================

import 'dart:collection';
import 'dart:mirrors';

import 'package:logging/logging.dart';
import 'package:woomera/woomera.dart';

//================================================================

part 'src/generate_dart.dart';
part 'src/generate_summary.dart';
part 'src/loggers.dart';
part 'src/scanner.dart';
part 'src/woomera_server_definition.dart';
part 'src/woomera_function.dart';
part 'src/woomera_pipeline_definition.dart';
