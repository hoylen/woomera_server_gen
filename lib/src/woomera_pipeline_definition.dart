part of '../woomera_server_gen.dart';

//################################################################
/// Information needed to create a Woomera pipeline.
///
/// **Note:** most programs would not need to instantiate this class directly.
/// The [ServerDefinition] constructor automatically instantiates them, when
/// it comes across an annotation for a pipeline.
///
/// The pipeline has a [name] and may contain:
///
/// - pipeline [exceptionHandler]; and
/// - the [requestHandlers].

class PipelineDefinition {
  //================================================================
  // Constructors

  /// Create a pipeline definition.
  ///
  /// Requires the [name] of the pipeline.

  PipelineDefinition(this.name);

  //================================================================
  // Members

  //----------------------------------------------------------------
  /// Name of the pipeline.
  ///
  /// The value for the default pipeline will have [ServerPipeline.defaultName]
  /// (i.e. empty string).

  final String name;

  //----------------------------------------------------------------
  /// Pipeline exception handler.
  ///
  /// Null means the pipeline has not been defined with a pipeline exception
  /// handler.

  WoomeraFunction? exceptionHandler;

  //----------------------------------------------------------------
  /// Request handlers in this pipeline.
  ///
  /// Map of URI path patterns to [WoomeraFunction].

  final _requestHandlersMap =
      SplayTreeMap<Handles, WoomeraFunction>(_handlesRequestsCompare);

  //================================================================
  // Methods

  /// Ordered request handlers in this pipeline.

  Iterable<WoomeraFunction> get requestHandlers => _requestHandlersMap.values;

  //================================================================
  // Static methods

  //----------------------------------------------------------------

  static int _handlesRequestsCompare(Handles h1, Handles h2) {
    // Compare by HTTP method

    final method1 = h1.httpMethod;
    final method2 = h2.httpMethod;
    assert(method1 != null, 'not a request handler: exception handler?');
    assert(method2 != null, 'not a request handler: exception handler?');

    final a = method1!.compareTo(method2!);
    if (a != 0) {
      return a; // HTTP method determines order
    }

    // Compare by priority

    final priority1 = h1.priority;
    final priority2 = h2.priority;
    assert(priority1 != null, 'not a request handler: exception handler?');
    assert(priority2 != null, 'not a request handler: exception handler?');

    final b = priority1!.compareTo(priority2!);
    if (b != 0) {
      return -b; // priority order: negate so higher priority appears earlier
    }

    // Compare by pattern

    assert(h1.pattern != null, 'not a request handler: exception handler?');
    assert(h2.pattern != null, 'not a request handler: exception handler?');
    final pattern1 = Pattern(h1.pattern!);
    final pattern2 = Pattern(h2.pattern!);

    return pattern1.compareTo(pattern2); // pattern determines order
  }
}
