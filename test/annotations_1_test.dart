// Annotations with one pipeline.

import 'dart:io' show HttpRequest, ContentType;

import 'package:woomera/woomera.dart';
import 'package:woomera_server_gen/woomera_server_gen.dart';
import 'package:test/test.dart';

const pattern = '~/foo/bar';

//================================================================

const expectedHandlers = [
  ('GET', '~/foo/bar', 'foobarGet'),
  ('GET', '~/', 'rootGet'),
  ('POST', '~/foo/bar', 'foobarPost'),
];

//----------------------------------------------------------------

const expectedToString = '''
raw-server-exception-handler => serverREH
server-exception-handler => serverEH
pipeline <default>:
  pipeline-exception-handler => pipelineEH
  GET ~/foo/bar => foobarGet
  GET ~/ => rootGet
  POST ~/foo/bar => foobarPost
''';

//----------------------------------------------------------------

const expectedSummary = '''
server:
  server_exception_handler: true
  server_raw_exception_handler: true
  pipelines:
    "":
      pipeline_exception_handler: true
      num_request_handlers: 3
''';

//----------------------------------------------------------------

const expectedDart = '''
Server serverBuilder() {
  final p1 = ServerPipeline(ServerPipeline.defaultName)
    ..exceptionHandler = pipelineEH
    ..get('~/foo/bar', foobarGet)
    ..get('~/', rootGet)
    ..post('~/foo/bar', foobarPost);

  return Server(numberOfPipelines: 0)
    ..exceptionHandlerRaw = serverREH
    ..exceptionHandler = serverEH
    ..pipelines.addAll([p1]);
}
''';

//----------------------------------------------------------------

void _testAnnotations(ServerDefinition serverAnnotations) {
  test('server raw exception handler', () {
    final af = serverAnnotations.exceptionHandlerRaw;
    expect(af, isNotNull);
    expect(af!.annotation, isA<ServerExceptionHandlerRaw>());
    expect(af.methodMirror.simpleName, equals(Symbol('serverREH')));
  });

  test('no server exception handler', () {
    final af = serverAnnotations.exceptionHandler;
    expect(af, isNotNull);
    expect(af!.annotation, isA<ServerExceptionHandler>());
    expect(af.methodMirror.simpleName, equals(Symbol('serverEH')));
  });

  test('pipeline', () {
    // There is one pipeline: the default pipeline

    expect(serverAnnotations.pipelines.length, equals(1));

    _testPipeline(serverAnnotations.pipelines.first);
  });
}

//----------------

void _testPipeline(PipelineDefinition pipelineAnnotations) {
  // Name is the default

  expect(pipelineAnnotations.name, equals(ServerPipeline.defaultName));

  // The pipeline has a pipeline exception handler

  final af = pipelineAnnotations.exceptionHandler;
  expect(af, isNotNull);
  if (af != null) {
    expect(af.annotation, isA<PipelineExceptionHandler>());
    expect(af.methodMirror.simpleName, equals(Symbol('pipelineEH')));
  }

  // The pipeline has three request handlers

  expect(pipelineAnnotations.requestHandlers.length,
      equals(expectedHandlers.length),
      reason: 'wrong number of handlers in "${pipelineAnnotations.name}"');

  var index = 0;
  for (final p in pipelineAnnotations.requestHandlers) {
    expect(p.annotation, isA<Handles>());
    final (expectedMethod, expectedPattern, expectedFunction) =
        expectedHandlers[index];

    final h = p.annotation as Handles;

    expect(h.isRequestHandler, isTrue);

    expect(h.httpMethod, equals(expectedMethod),
        reason: 'wrong method in handler[$index]');
    expect(h.pattern, equals(expectedPattern),
        reason: 'wrong pattern in handler[$index]');
    expect(h.pipeline, equals(ServerPipeline.defaultName),
        reason: 'wrong pipeline name in handler[$index]');
    expect(p.methodMirror.simpleName, equals(Symbol(expectedFunction)),
        reason: 'wrong function in handler[$index]');

    index++;
  }
}

//================================================================

void main() {
  final serverDef = ServerDefinition();

  group('one pipeline', () {
    //----------------

    group('annotations', () {
      _testAnnotations(serverDef);
    });

    //----------------

    test('toString', () {
      expect(serverDef.toString(), equals(expectedToString));
    });

    //----------------

    test('generating summary', () {
      expect(generateSummary(serverDef), equals(expectedSummary));
    });

    //----------------

    test('generating dart', () {
      expect(generateDart(serverDef), endsWith(expectedDart));
    });
  });
}

//################################################################
// Annotated functions

@ServerExceptionHandlerRaw()
Future<Response> serverREH(HttpRequest r, Object ex, StackTrace st) async {
  throw NotFoundException(NotFoundException.foundNoResource);
}

@ServerExceptionHandler()
Future<Response> serverEH(Request req, Object ex, StackTrace st) async {
  throw NotFoundException(NotFoundException.foundNoResource);
}

@PipelineExceptionHandler()
Future<Response> pipelineEH(
    Request req, Object exception, StackTrace st) async {
  throw NotFoundException(NotFoundException.foundNoResource);
}

@Handles.get('~/')
Future<Response> rootGet(Request req) async =>
    ResponseBuffered(ContentType.text)..write('Root\n');

@Handles.get(pattern)
Future<Response> foobarGet(Request req) async =>
    ResponseBuffered(ContentType.text)..write('foobar got\n');

@Handles.post(pattern)
Future<Response> foobarPost(Request req) async =>
    ResponseBuffered(ContentType.text)..write('foobar posted\n');
