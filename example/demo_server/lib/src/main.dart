part of '../demo_server.dart';

//================================================================
// Globals

/// Application logger.

Logger log = Logger('app');
Logger simLog = Logger('simulation');

//----------------------------------------------------------------
// Set up logging
//
// Change this to the level and type of logging desired.

void _loggingSetup() {
  hierarchicalLoggingEnabled = true;
  Logger.root.onRecord.listen((rec) {
    print('${rec.time}: ${rec.loggerName}: ${rec.level.name}: ${rec.message}');
  });

  Logger.root.level = Level.OFF;

  final commonLevel = Level.INFO;

  Logger('app').level = commonLevel;
  Logger('simulation').level = commonLevel;

  Logger('woomera.server').level = commonLevel;
  Logger('woomera.request').level = Level.FINE; // FINE prints each URL
  Logger('woomera.request.header').level = commonLevel;
  Logger('woomera.request.param').level = commonLevel;
  Logger('woomera.response').level = commonLevel;
  Logger('woomera.session').level = commonLevel;

  // To see the Handles annotations that have been found, set this to
  // FINE. Set it to FINER for more details. Set it to FINEST to see what
  // files and/or libraries were scanned and not scanned for annotations.
  Logger('woomera.handles').level = commonLevel;
}

//----------------------------------------------------------------

const int defaultPort = 1024;

Future<void> run(List<String> arguments) async {
  final quietMode = arguments.contains('-q'); // quiet mode

  if (!quietMode) {
    _loggingSetup();
  }

  // Create the server and run it

  final server = serverBuilder()
    ..bindAddress = InternetAddress.anyIPv6
    ..v6Only = false // false = any IPv4 or IPv6 address (not just IPv6)
    ..bindPort = defaultPort;

  await server.run(); // run Web server
}
