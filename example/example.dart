#!/usr/bin/env dart

import 'dart:io';

import 'package:args/args.dart';
import 'package:logging/logging.dart';
import 'package:woomera_server_gen/woomera_server_gen.dart';

//################################################################
// MODIFY THIS SECTION if using this utility to process annotations from a
// different library.

// Import the library with the annotations to process.
//
// Nothing is invoked in it, but it must be imported so the annotations in it
// can be found by the dart:mirror package.

// ignore: unused_import, avoid_relative_lib_imports, directives_ordering
import 'demo_server/lib/demo_server.dart';

/// Name of the library being scanned for annotations.
///
/// Set to the empty string, if the annotations are not a part of any library.

const libraryName = 'demo_server';

//################################################################

const program = 'example';
const version = '1.0.0';

//----------------------------------------------------------------
/// Enumeration of the three formats of output produced by this program.

enum OutputType {
  summary,
  details,
  dart,
}

//################################################################
/// Options from the command line.

class Options {
  //================================================================
  // Constructors

  //----------------------------------------------------------------
  /// Construct options from command line arguments.
  ///
  /// The [program] and [version] are displayed when the `--version` option is
  /// used. The should follow the convention described in
  /// <https://www.gnu.org/prep/standards/html_node/_002d_002dversion.html>.
  ///
  /// The [args] are the command line options that are parsed for the options.
  ///
  /// Exits with a exit status of 2, if there is an error.

  Options(String program, String version, List<String> args)
      : exeName = Platform.script.pathSegments.last.replaceAll('.dart', '') {
    try {
      var showHelp = false;
      var showVersion = false;

      final parser = ArgParser()
        ..addOption('format',
            abbr: 'f',
            help: 'output format',
            valueHelp: 'FORMAT',
            allowed: OutputType.values.map((x) => x.name),
            defaultsTo: OutputType.summary.name,
            callback: (v) => outputType = OutputType.values.byName(v!))
        ..addOption('output',
            abbr: 'o',
            help: 'output file',
            valueHelp: 'FILE',
            callback: (v) => outfileName = v)
        ..addFlag('debug',
            help: 'set logging level to ALL',
            negatable: false,
            callback: (v) => debug = v)
        ..addFlag('verbose',
            abbr: 'v',
            help: 'output extra information when running',
            negatable: false,
            callback: (v) => verbose = v)
        ..addFlag('version',
            help: 'display version information and exit',
            negatable: false,
            callback: (v) => showVersion = v)
        ..addFlag('help',
            abbr: 'h',
            help: 'display this help and exit',
            negatable: false,
            callback: (v) => showHelp = v);

      final results = parser.parse(args);

      if (showHelp) {
        // Show help message
        stdout.write('Usage: $exeName [options] inputFile\n${parser.usage}\n');
        exit(0);
      }
      if (showVersion) {
        // Show version message
        stdout.writeln('$program $version');
        exit(0);
      }

      // Arguments

      if (results.rest.isNotEmpty) {
        _usageError(exeName, 'too many arguments');
      }
    } on FormatException catch (e) {
      _usageError(exeName, e.message);
    }
  }

  //================================================================
  // Members

  /// Name of program being executed.

  String exeName;

  /// Name of the output file.
  ///
  /// Null means output to stdout.

  String? outfileName;

  /// Debug mode

  bool debug = false;

  /// Verbose mode: show extra status messages if true.

  bool verbose = false;

  /// Type of output to generate

  OutputType outputType = OutputType.summary;

  //================================================================
  // Static methods

  //----------------------------------------------------------------
  /// Output a "usage error" message to stdout and exits with an error status.

  static Never _usageError(String exeName, String message) {
    stderr.write('$exeName: usage error: $message\n');
    exit(2);
  }
}

//################################################################

//----------------------------------------------------------------

void setupLogging({bool debug = false}) {
  hierarchicalLoggingEnabled = true;

  Logger.root.onRecord.listen((r) {
    final ts = r.time.toString().substring(0, 23);

    // ${r.loggerName}
    stderr.write('$ts ${r.level.name.padRight(7)} ${r.message}\n');
  });

  // Set the logging level for all loggers from the woomera_server_gen package.
  //
  // Note: the woomera package also has a _loggers_ variable, but we don't
  // care about them.

  for (final logger in loggers) {
    logger.level = debug ? Level.ALL : Level.INFO;
  }
}

//################################################################

void main(List<String> args) {
  final options = Options(program, version, args);

  setupLogging(debug: options.debug);

  final serverDef = ServerDefinition();

  String outputText;
  switch (options.outputType) {
    case OutputType.summary:
      outputText = generateSummary(serverDef, verbose: options.verbose);
      break;

    case OutputType.details:
      outputText = serverDef.toString();
      break;

    case OutputType.dart:
      outputText = generateDart(serverDef,
          libraryName: libraryName,
          fromLocationComments: options.verbose,
          comment: '''
Generated by ${options.exeName}.

This Dart file was generated by _${options.exeName}_ from the annotations
found in the "$libraryName" library.''');
      break;
  }

  final fName = options.outfileName;
  if (fName == null) {
    stdout.write(outputText);
  } else {
    File(fName).writeAsStringSync(outputText);
  }
}
