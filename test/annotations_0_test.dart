// No annotations

import 'package:woomera_server_gen/woomera_server_gen.dart';
import 'package:test/test.dart';

//================================================================

const expectedSummary = 'server:\n';

//----------------------------------------------------------------

const expectedDart = '''
Server serverBuilder() {
  return Server(numberOfPipelines: 0)
    ..pipelines.addAll([]);
}
''';

//----------------------------------------------------------------

void _testAnnotations(ServerDefinition annotations) {
  // Nothing should be found

  test('no server raw exception handler', () {
    expect(annotations.exceptionHandlerRaw, isNull);
  });

  test('no server exception handler', () {
    expect(annotations.exceptionHandler, isNull);
  });

  test('no pipeline', () {
    expect(annotations.pipelines, isEmpty);
  });
}

//================================================================

void main() {
  final serverDef = ServerDefinition();

  group('no annotations', () {
    //----------------

    group('annotations', () {
      _testAnnotations(serverDef);
    });

    //----------------

    test('toString', () {
      const expectedToString = '';
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
