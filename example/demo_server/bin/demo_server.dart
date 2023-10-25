#!/usr/bin/env dart

import 'package:demo_server/demo_server.dart' as impl;

Future<void> main(List<String> arguments) async {
  await impl.run(arguments);
}
