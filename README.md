Extracts woomera annotations and generates Dart code to instantiate the Server.

This package is for creating a program that scans libraries for
woomera annotations that define a Woomera _Server_ and its
pipelines. And then to generate a Dart file with code to instantiate
that woomera Server and its pipelines.

**Note: this package is only useful if you are using the [woomera
package](https://pub.dev/packages/woomera).**

The woomera package is a framework for writing Web server programs.
The functionality is implemented in a set of functions.  There are
_request handler_ functions for processing the HTTP requests into HTTP
responses. They are organised into _pipelines_. And there are various
exception handler functions for error handling. Setup code is then
required to instantiate a Server object and its pipelines, and
populate them with those functions.

This package can be used to automatically generate that setup code.
This ensures the functions and the setup code is consistent -
especially when functions are added, changed or removed.

## Getting started

### 1. Create the Dart project for the Web server program

```shell
$ dart create foobar
```

Edit the _pubspec.yaml_ file to have the _woomera_ package as a
dependency and this _woomera_server_gen_ package as a development
dependency.

```yaml
dependencies:
  woomera: ^8.0.0

dev_dependencies:
  woomera_server_gen: ^0.0.1
```

Run `dart pub get`.

### 2. Write the Web server program

Write the Web server program with its functions in a Dart library.

Annotate the _request handler_ and exception handler functions with
the annotations defined in the woomera package. Implement as many or
as few of the functions (even none), since functions can be added
later on.

In this simple example, the library will be called "foobar" and this
is its _lib/foobar.dart_ file:

```dart
library foobar;

import 'dart:io';

import 'package:woomera/woomera.dart';

part 'src/server.dart';
part 'src/example_handlers.dart';
```

And this is its _src/example_handlers.dart_ file:

```dart
part of foobar;

@Handles.get('~/')
Future<Response> myRequestHandler(Request) async {
  return ResponseBuffered(ContentType.text)..write('Hello world\n');
}

@ServerExceptionHandler()
Future<Response> myServerExceptionHandler(
    Request req, Object exception, StackTrace st) async {
  stderr.writeln('exception (${exception.runtimeType}): $exception\n$st');

return ResponseBuffered(ContentType.text)
    ..status = HttpStatus.internalServerError
    ..write('Exception: $exception\n');
}
```

Create a temporary placeholder _lib/src/server.dart_ file so the
library does not have any errors. Later, this will be replaced with
the generated Dart file.

```
part of foobar;

Server serverBuilder() => Server();
```

The program that uses this library can be _bin/foobar.dart_ containing:

```dart
import 'dart:io';

import 'package:foobar/foobar.dart' as foobar;

Future<void> main(List<String> arguments) async {
  final server = foobar.serverBuilder()
    ..bindAddress = InternetAddress.loopbackIPv4
    ..bindPort = 8080;

  await server.run();
}
```

### 3. Write the server code generation utility

The simplest program just needs to:

- import the library with the annotations;
- instantiate a _ServerDefinition_ object;
- invoke the _generateDart_ function with that object
  and the name of the library.

For example, _dev/gen_server.dart_ could contain:

```dart
import 'dart:io';
import 'package:woomera_server_gen/woomera_server_gen.dart';

// Library being scanned for annotations
import 'package:foobar/foobar.dart' ;

void main() {
  stdout.write(generateDart(ServerDefinition(), libraryName: 'foobar'));
}
```

**Tip:** instead of this simple program, copy the _example.dart_ and
modify it.

### 4. Run the utility to generate Dart

Run the utility program.

```shell
$ dart dev/server_gen.dart > lib/src/server-new.txt
```

Inspect the generated file to see if it is correct.

For example, the example above would have generated a file containing:

```dart
// WARNING: DO NOT EDIT

part of foobar;

Server serverBuilder() {
  final p1 = ServerPipeline(ServerPipeline.defaultName)
    ..get('~/', myRequestHandler)
    ;

  return Server(numberOfPipelines: 0)
    ..exceptionHandler = myServerExceptionHandler
    ..pipelines.addAll([p1]);
}
```

### 5. Updating the Dart code

If it is correct, replace the temporary placeholder file with it.

```shell
$ mv lib/src/server-new.txt lib/src/server.dart
```

## Maintaining the Dart code

If the functions and/or their annotations have changed, repeat the
above step to update the Dart file.

For example, if a new _request handler_ function and _Handles_
annotation was added to the program, the utility will generate new
Dart code that includes it.

# Feedback

Please report bugs by opening an
[issue](https://github.com/hoylen/woomera_server_gen/issues) in GitHub.
