part of '../woomera_server_gen.dart';

//================================================================

Logger _log = Logger('woomera_server_gen');

Logger _logHandles = Logger('${_log.fullName}.handles');

//================================================================

//----------------------------------------------------------------
/// All the loggers.
///
/// This is a List (which is not exposed outside this library).
/// It is exposed as an Iterable to prevent modification.

final _allLoggers = [
  _log,
  _logHandles,
];

//----------------------------------------------------------------
/// All the loggers used by this library.
///
/// This can be used to discover what loggers are used by this library.
///
/// These are not sorted in any particular order.

Iterable<Logger> get loggers => _allLoggers;
