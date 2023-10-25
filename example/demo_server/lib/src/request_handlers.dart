part of '../demo_server.dart';

// Internal paths for the different resources that process HTTP GET and POST
// requests.
//
// Woomera uses internal paths, which are strings that always start with "~/".
// They need to be converted into real URLs when they are served to clients
// (e.g. when included as hyperlinks on HTML pages), by calling "rewriteURL".
//
// Constants are used for these so that the same value is used throughout the
// application if the values are changed (i.e. so the link URL always matches
// the path to the handler).
//
// The various parameter names are also defined as constants, so the same value
// is used in both the URL/form and when it is processed.

// For the general example showing path parameters

const String testPattern = '~/example/:foo/:bar/baz';
//const String _uParamFoo = 'foo';
//const String _uParamBar = 'bar';
//const testPattern2 = '~/example/:$_uParamFoo/:$_uParamBar/baz';

// For the POST request example

const String iPathFormHandler = '~/welcome';
const String _pParamName = 'personName';

// For the exception throwing example

const String iPathExceptionGenerator = '~/throw-exception';
const String _qParamProcessedBy = 'for';

//----------------------------------------------------------------
/// Home page

@Handles.get('~/')
Future<Response> homePage(Request req) async {
  assert(req.method == 'GET');

  // The response can be built up by calling [write] multiple times on the
  // ResponseBuffered object. But for this simple page, the whole page is
  // produced with a single write.

  // Note the use of "req.ura" to convert an internal path (a string that starts
  // with "~/") into a URL, and to encode that URL so it is suitable for
  // inclusion in a HTML attribute. The method "ura" is a short way of using
  // `HEsc.attr(req.rewriteUrl(...))`.

  final resp = ResponseBuffered(ContentType.html)..write('''
<!DOCTYPE html>
<html lang="en">
<head>
      <title>Example</title>
</head>

<body>
      <header>
        <h1>Example</h1>
      </header>

      <h2>Request handlers</h2>
      
      <p>The framework finds a <em>request handler</em> to process the HTTP
      request. A match is found if the HTTP method is the same and the request
      URL path matches the pattern.
      When a match is found, any path parameters (as defined by the pattern),
      query parameters and POST parameters are passed to the request handler.</p>
      
      <p>In the first two sets of links, this pattern will be matched:
       <code>${HEsc.text(testPattern)}</code></p>
       
      <ul>
        <li>
          Examples with path parameters:    
          <a href="${req.ura('~/example/first/second/baz')}">1</a>
          <a href="${req.ura('~/example/alpha/beta/baz')}">2</a>
          <a href="${req.ura('~/example/barComponentIsEmpty//baz')}">3</a>
        </li>
        <li>
          Example with query parameters:
          <a href="${req.ura('~/example/a/b/baz?alpha=1&beta=two&gamma=three')}">1</a>
          <a href="${req.ura('~/example/a/b/baz?delta=query++parameters&delta=are&delta=repeatable')}">2</a>
          <a href="${req.ura('~/example/a/b/baz?emptyString=')}">3</a>
        </li>
        <li>
          Example with form parameters:
          <form method="POST" action="${req.ura(iPathFormHandler)}">
            <input type="text" name="${HEsc.attr(_pParamName)}">
            <input type="submit">
          </form>
        </li>
      </ul>
    
      
      <h2>Exception handling</h2>
      
      <h3>Not found exceptions</h3>
      
      <p>If a <em>request handler</em> cannot be found, the framework throws a
      <em>NotFoundException</em>, which triggers the
      <em>server exception handler</em>.</p>
    
      <ul>
        <li><a href="${req.ura('~/no/such/page')}">
           Does not match any pattern</a></li>
         <li><a href="${req.ura('~/example/first/second/noMatch')}">
           A partial match is still not a match</a></li>
      </ul>
        
      <p>A <em>server exception handler</em> is configured with the
      <code>Server.exceptionHandler</code> property.</p>
      
      <h3>Other exceptions</h3>
      
      <p>If the <em>request handler</em> throws an exception, it triggers the
      <em>pipeline exception handler</em> from the pipeline the request
      handler was on. If there is no pipeline exception handler, or it also
      throws an exception, the <em>server exception handler</em> is
      triggered.</p>
      
      <ul>
        <li>
          <a href="${req.ura(iPathExceptionGenerator)}">Case 1</a>:
          Exception thrown by the request handler. It is processed by the
          pipeline exception handler.
        </li>
       <li>
          <a href="${req.ura('$iPathExceptionGenerator?$_qParamProcessedBy=server')}">
          Case 2</a>:
          Exception thrown by the request handler. It is processed by the
          pipeline exception handler, but it throws an exception. That second
          exception is processed by the server pipeline exception handler.
        </li>
        <li>
          <a href="${req.ura('$iPathExceptionGenerator?$_qParamProcessedBy=defaultServer')}">
          Case 3</a>:
          Exception thrown by the request handler. It is processed by the
          pipeline exception handler, but it throws an exception. That second
          exception is processed by the server exception handler, but it
          throws an exception. That third exception causes the built-in
          default server exception handler to run.
        </li>
      </ul>
      
      <p>A <em>pipeline exception handler</em> is configured using the
      <code>ServerPipeline.exceptionHandler</code> property.
      A <em>server exception handler</em>
      is defined using a <code>Server.exceptionHandler</code> property.</p>
      
      <p>There is also a <em>server raw exception handler</em> which is
      triggered in edge-case situations, when the normal server or
      pipeline exception handlers cannot be used. It is configured
      using the <code>Server.exceptionHandlerRaw</code> property.
      This example does not demonstrate the <em>raw exception handler</em>,
      since it is not easy to trigger it.</p>
      
      <h2>Other features</h2>

          <ul>
            <li>Request handler that produces a response from a stream:
              <a href="${req.ura('~/stream')}">no delay</a>,
              <a href="${req.ura('~/stream?milliseconds=200')}">with delay</a></li>
            <li><a href="${req.ura('~/json')}">JSON response instead of HTML</a></li>
          </ul>
      

      <footer>
        <p style="font-size: small">Demo of the
        <a style="text-decoration: none; color: inherit;"
           href="https://pub.dartlang.org/packages/woomera">Woomera Dart Package</a>
        </p>
      </footer>
</body>
</html>
''');

  // Note: the default status is HTTP 200 "OK", so it doesn't need to be changed

  return resp;
}

//----------------------------------------------------------------
/// Request handler that displays the parameters.
///
/// The [debugHandler] is a request handler that simply displays out all the
/// request parameters on the HTML page that is returned.

@Handles.get(testPattern)
Future<Response> myDebugHandler(Request req) async => debugHandler(req);

//----------------------------------------------------------------
/// Example request handler for a POST request
///
/// This handles the POST request when the form is submitted.

@Handles.post(iPathFormHandler)
Future<Response> dateCalcPostHandler(Request req) async {
  assert(req.method == 'POST');

  // Get the input values from the form
  //
  // HTTP requests with MIME type of "application/x-www-form-urlencoded"
  // (e.g. from a HTTP POST request for a HTML form) will populate the request's
  // postParams member.

  final pParams = req.postParams;

  if (pParams != null) {
    // The input values can be retrieved as strings from postParams.

    var name = pParams[_pParamName];

    // The list access operator on postParams (pathParams and queryParams too)
    // cleans up values by collapsing multiple whitespaces into a single space,
    // and trimming whitespace from both ends. It always returns a string value
    // (i.e. it never returns null), so it returns an empty string if the value
    // does not exist. To tell the difference between a missing value and a value
    // that is the empty string (or only contains whitespace), use the
    // [RequestParams.values] method instead of the list access operator.
    // That [RequestParams.values] method can also be used to obtain the actual
    // value without any whitespace processing.

    assert(pParams['np'] == '');
    assert(pParams.values('np', mode: ParamsMode.standard).isEmpty);
    assert(pParams.values('np', mode: ParamsMode.rawLines).isEmpty);
    assert(pParams.values('np', mode: ParamsMode.raw).isEmpty);

    // Produce the response

    if (name.isEmpty) {
      name = 'world'; // default value if no name was provided
    }

    // Produce the response

    // Note: values that cannot be trusted should be escaped, in case they
    // contain reserved characters or malicious text. Text in HTML content can
    // be escaped by calling `HEsc.text`. Text in attributes can be escaped by
    // calling `HEsc.attr` (e.g. "... <a title="${HEsc.attr(value)} href=...").

    final resp = ResponseBuffered(ContentType.html)..write('''
<!DOCTYPE html>
<html lang="en">
<head>
  <title>Welcome</title>
</head>

<body>
  <header>
    <h1>Welcome</h1>
  </header>
    
  <p>Hello ${HEsc.text(name)}</p>

  <p><a href="${req.ura('~/')}">Home</a></p>
</body>
</html>
''');

    return resp;
  } else {
    // POST request did not contain POST parameters
    throw const FormatException('Invalid request');
  }
}

//----------------------------------------------------------------
/// Request handler that generates an exception.
///
/// This is used to demonstrate the different exception handlers.

@Handles.get(iPathExceptionGenerator)
Future<Response> requestHandlerThatAlwaysThrowsException(Request req) async {
  final value = req.queryParams[_qParamProcessedBy];

  switch (value) {
    case '':
    case 'pipeline':
      throw DemoException(HandledBy.pipelineExceptionHandler);
    case 'server':
      throw DemoException(HandledBy.serverExceptionHandler);
    case 'defaultServer':
      throw DemoException(HandledBy.defaultServerExceptionHandler);
    default:
      throw FormatException('unsupported value: $value');
  }
}

//----------------------------------------------------------------
/// Example of a request handler that uses a stream to generate the response.
///
/// This is an example of using a [ResponseStream] to progressively
/// create the response, instead of using [ResponseBuffered]. The other class
/// used to create a [Response] is [ResponseRedirect] when the response is
/// a HTTP redirection.

@Handles.get('~/stream')
Future<Response> streamTest(Request req) async {
  // Get parameters

  final numIterations = 10;

  var secs = 0;
  if (req.queryParams['milliseconds'].isNotEmpty) {
    secs = int.parse(req.queryParams['milliseconds']);
  }

  // Produce the stream response

  final resp = ResponseStream(ContentType.text)..status = HttpStatus.ok;
  await resp.addStream(req, _streamSource(req, numIterations, secs));

  return resp;
}

//----------------
// The stream that produces the data making up the response.
//
// It produces a stream of bytes (List<int>) that make up the contents of
// the response.
//
// The content produces [iterations] lines of output, each waiting [ms]
// milliseconds before outputting it.

Stream<List<int>> _streamSource(Request req, int iterations, int ms) async* {
  final delay = Duration(milliseconds: ms);

  yield 'Stream of $iterations items (delay: $ms milliseconds)\n'.codeUnits;

  yield 'Started: ${DateTime.now()}\n'.codeUnits;

  for (var x = 1; x <= iterations; x++) {
    final completer = Completer<int>();
    Timer(delay, () => completer.complete(0));
    await completer.future;

    yield 'Item $x\n'.codeUnits;
  }
  yield 'Finished: ${DateTime.now()}\n'.codeUnits;
}

//----------------------------------------------------------------
/// Handler that returns JSON in the response.

@Handles.get('~/json')
Future<Response> handleJson(Request req) async {
  final data = {'name': 'John Citizen', 'number': 6};

  final resp = ResponseBuffered(ContentType.json)..write(json.encode(data));
  return resp;
}
