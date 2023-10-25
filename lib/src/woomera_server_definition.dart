part of '../woomera_server_gen.dart';

//################################################################
/// Information needed to create a Woomera server.
///
/// May contain:
///
/// - server [exceptionHandlerRaw];
/// - server [exceptionHandler];
/// - [wrapperFunction]; and
/// - the definition of the [pipelines].

class ServerDefinition {
  //================================================================
  // Constructors

  //----------------------------------------------------------------
  /// Scan the current program for Woomera annotations.
  ///
  /// # Ordering of pipelines
  ///
  /// The existence of pipelines are implicitly defined by the _Handles_
  /// and _PipelineExceptionHandler_ annotations.
  ///
  /// If there are multiple pipelines, they are ordered according to their
  /// names and these rules:
  ///
  /// 1. Any pipeline name present in [pipelineOrder] is placed before all
  ///    other names that are not in that list. The default pipeline name
  ///    (i.e. the empty string) may be a part of this list.
  /// 2. Pipeline names not in _pipelineOrder_ are ordered into three groups:
  ///     a. Names not starting with an underscore are in the first group;
  ///     b. The default pipeline is in the second group; and
  ///     c. Names starting with an underscore are in the last group.
  ///
  /// In the first and last group, the names are sorted in String order.
  ///
  /// For example, if _pipelineOrder_ is empty, pipelines could be:
  ///
  /// 1. bar
  /// 2. baz
  /// 3. foo
  /// 4. The default pipeline (name is the empty string)
  /// 5. _bar
  /// 6. _baz
  /// 7. _foo
  ///
  /// But if _pipelineOrder_ contained `["_foo", "foo"]` then the order of
  /// the pipelines will be:
  ///
  /// 1. _foo
  /// 2. foo
  /// 3. bar
  /// 4. baz
  /// 5. The default pipeline (name is the empty string)
  /// 6. _bar
  /// 7. _baz
  ///
  /// # Libraries scanned
  ///
  /// The libraries to be scanned for annotations can be specified by
  /// [librariesToScan].
  ///
  /// Since scanning all the libraries is relatively fast, it is recommended
  /// that _librariesToScan_ is left undefined. The only good reason to
  /// specify libraries to scan is if some libraries contains annotations
  /// that should not be found.

  ServerDefinition(
      {List<String> pipelineOrder = const [], Iterable<Uri>? librariesToScan}) {
    final scannedAnnotations = _Scanner(librariesToScan);

    _fromScannerResult(scannedAnnotations, pipelineOrder: pipelineOrder);
  }

  //----------------

  _fromScannerResult(_Scanner scannedAnnotations,
      {required List<String> pipelineOrder}) {
    // Loop over all the annotations and group them according to the pipeline
    // they belong to; and identify any server raw and non-raw exception
    // handlers that don't belong to any pipeline.

    // The pipeline related functions are first gathered into this temporary
    // variable. While the server-wide exception and raw exception handlers
    // will set the respective members when they are encountered.

    final tmpPipelines = <String, PipelineDefinition>{};

    for (final annotatedFunction in scannedAnnotations.handlers.values) {
      final annotation = annotatedFunction.annotation;

      if (annotation is ServerExceptionHandlerRaw) {
        _recordServerRawExceptionHandler(annotatedFunction);
      } else if (annotation is ServerExceptionHandler) {
        _recordServerExceptionHandler(annotatedFunction);
      } else if (annotation is RequestHandlerWrapper) {
        _recordRequestHandlerWrapper(annotatedFunction);
      } else if (annotation is PipelineExceptionHandler) {
        _recordPipelineExceptionHandler(
            _lookupOrCreatePipeline(tmpPipelines, annotation.pipeline),
            annotatedFunction);

        // The above code is for the new annotation classes introduced in
        // woomera 8.0.0.
        //
        // The code below also supports the implementation that was deprecated
        // in woomera 8.0.0. That implementation used the Handles class to
        // represent the different types of exception handlers (as well as
        // for request handlers).
      } else if (annotation is Handles) {
        // Request handler
        //
        // Except this also needs to handle the three types of exception
        // handlers which the legacy implementation overloaded this class
        // with.

        if (annotation.isRequestHandler) {
          // Handles object for a request handler always has a non-null name
          final pipelineName = annotation.pipeline!;

          _recordRequestHandler(
              _lookupOrCreatePipeline(tmpPipelines, pipelineName),
              annotation,
              annotatedFunction);
        } else {
          _legacyAnnotation(tmpPipelines, annotation, annotatedFunction);
        }
      } else {
        throw StateError(
            'unexpected annotation type: ${annotation.runtimeType}');
      }
    }

    if (pipelineOrder.isNotEmpty) {
      // Check for pipelines annotations which were found, but were not
      // listed in the ordered list. Since these will be placed after the
      // default pipeline, that might be unexpected behaviour.
      for (final name in tmpPipelines.keys) {
        if (!pipelineOrder.contains(name)) {
          _log.warning('pipeline "$name" not in the ordered list,'
              ' will be after the default pipeline');
        }
      }
    }
    // Check if all the pipelines named in [pipelineOrder] were found.
    // Note: the list does not have to contain all (or any) of the pipelines
    // from the annotations. But if it mentions one, there must be at least
    // one annotation for it.

    for (final name in pipelineOrder) {
      if (!tmpPipelines.containsKey(name)) {
        throw ArgumentError.value(pipelineOrder, 'pipelineOrder',
            'no annotations for pipeline "$name"');
      }
    }

    // Populate [pipelines] in the order required by the server.
    //
    // This order is defined by [pipelineOrder] or defaults to alphabetical with
    // the default pipeline last. The order is overridden if for any names
    // in [pipelineOrder].
    //
    // Since _pipelines_ is a [LinkedHashMap], the order in which the entries
    // are added is preserved.

    // Sort the names.

    final pNames = tmpPipelines.keys.toList();
    pNames.sort(_pipelineNameCompare(pipelineOrder));

    // Populate the pipelines member.

    assert(pipelines.isEmpty, 'already populated');

    for (final name in pNames) {
      _pipelines[name] = tmpPipelines[name]!;
    }
  }

  // Legacy implementation for when Handles is also used to annotation
  // exception handlers. This has been deprecated in favour of the
  // specialised annotation classes.

  void _legacyAnnotation(Map<String, PipelineDefinition> tmpPipelines,
      Handles annotation, WoomeraFunction annotatedFunction) {
    assert(!annotation.isRequestHandler, 'not legacy Handles');

    if (annotation.isPipelineExceptionHandler) {
      _recordPipelineExceptionHandler(
          _lookupOrCreatePipeline(tmpPipelines, annotation.pipeline!),
          annotatedFunction);
    } else if (annotation.isServerExceptionHandler) {
      _recordServerExceptionHandler(annotatedFunction);
    } else if (annotation.isServerRawExceptionHandler) {
      _recordServerRawExceptionHandler(annotatedFunction);
    } else {
      throw StateError('unexpected Handles annotation: $annotation');
    }
  }

  PipelineDefinition _lookupOrCreatePipeline(
      Map<String, PipelineDefinition> map, String pipelineName) {
    // The pipelineName is a String? with the name of the pipeline
    // (which is the empty string for the default pipeline).
    // It is null for the server raw and non-raw exception handlers.

    // Annotation is for a pipeline

    // Get the pipeline's SplayTreeMap of handlers, or create a new one
    // if this is the first time an annotation for this pipeline is
    // encountered. A SplayTreeMap is used to order the URI path patterns.

    var thePipeline = map[pipelineName];
    if (thePipeline == null) {
      thePipeline = PipelineDefinition(pipelineName);
      map[pipelineName] = thePipeline;
    }

    return thePipeline;
  }

  void _recordServerRawExceptionHandler(WoomeraFunction f) {
    exceptionHandlerRaw = f;
  }

  void _recordServerExceptionHandler(WoomeraFunction f) {
    exceptionHandler = f;
  }

  void _recordRequestHandlerWrapper(WoomeraFunction f) {
    wrapperFunction = f;
  }

  void _recordPipelineExceptionHandler(
      PipelineDefinition thePipeline, WoomeraFunction f) {
    thePipeline.exceptionHandler = f;
  }

  void _recordRequestHandler(
      PipelineDefinition thePipeline, Handles annotation, WoomeraFunction f) {
    thePipeline._requestHandlersMap[annotation] = f;
  }

  /*


      if (annotation.isRequestHandler) {
        // thePipeline
        thePipeline.requestHandlers[annotation] = annotatedFunction;
      } else if (annotation.isPipelineExceptionHandler) {
        thePipeline.exceptionHandler = annotatedFunction;
      } else {
        throw StateError('bad pipeline annotation: $annotation');
      }
    } else {
      // Annotation is for the server (i.e. not for a pipeline)

      if (annotation.isServerExceptionHandler) {
        exceptionHandler = annotatedFunction;
      } else if (annotation.isServerRawExceptionHandler) {
        rawExceptionHandler = annotatedFunction;
      } else {
        throw StateError('bad server annotation: $annotation');
      }
    }
  }


   */
  //================================================================
  // Members

  /// Server exception handler annotation.
  WoomeraFunction? exceptionHandler;

  /// Server raw exception handler annotation.
  WoomeraFunction? exceptionHandlerRaw;

  /// Wrapper function annotation.
  WoomeraFunction? wrapperFunction;

  /// Pipeline annotations.
  ///
  /// The keys are the pipeline names and they are ordered.
  final _pipelines = <String, PipelineDefinition>{};

  //----------------------------------------------------------------

  Iterable<PipelineDefinition> get pipelines => _pipelines.values;

  //----------------------------------------------------------------

  @override
  String toString() {
    final buf = StringBuffer();

    // Output raw and normal server exception handlers, if any

    final reh = exceptionHandlerRaw;
    if (reh != null) {
      final functionName = _functionName(reh.function, []);
      buf.writeln('raw-server-exception-handler => $functionName');
    }

    final eh = exceptionHandler;
    if (eh != null) {
      final functionName = _functionName(eh.function, []);
      buf.writeln('server-exception-handler => $functionName');
    }

    // Wrapper function

    final w = wrapperFunction;
    if (w != null) {
      // Has wrapper

      if (w.annotation is! RequestHandlerWrapper) {
        throw StateError('request handler annotation wrong: ${w.runtimeType}');
      }

      final functionName = _functionName(w.function, []);
      buf.writeln('request-wrapper => $functionName');
    }

    // Output the pipelines

    for (final p in pipelines) {
      final name = p.name;
      final n = name != ServerPipeline.defaultName ? '"$name"' : '<default>';
      buf.writeln('pipeline $n:');

      // Output the pipeline exception handler, if any

      if (p.exceptionHandler != null) {
        final functionName = _functionName(p.exceptionHandler!.function, []);
        buf.writeln('  pipeline-exception-handler => $functionName');
      }

      // Output the request handlers in the pipeline

      for (final h in p.requestHandlers) {
        final annotation = h.annotation;

        if (annotation is! Handles) {
          throw StateError('request handler annotation is not a Handles');
        }
        final a = h.annotation as Handles; // request handlers should be this

        final functionName = _functionName(h.function, []);

        buf.writeln('  ${a.httpMethod} ${a.pattern} => $functionName');
      }
    }

    return buf.toString();
  }

  //================================================================
  // Static methods

  //----------------------------------------------------------------
  /// Generates a comparison function for pipeline names.
  ///
  /// Returns a Comparator<String>. That is, an
  /// `int Function(String a, String b)` that returns:
  ///
  /// - a negative integer is a is smaller than b;
  /// - zero if a is equal to b; and
  /// - a positive integer if a is greater than b.
  ///
  /// The ordering of pipeline names follows these rules:
  ///
  /// 1. All names that appear in [preferredOrder] appear before those that
  ///    don't.
  /// 2. If both names appear in _preferredOrder_ they have the same relative
  ///    order as they do in that list.
  /// 3. If both names do not appear in _preferredOrder_, they are ordered
  ///    according to the normal Dart [String.compareTo], with the exception
  ///    that the empty string (i.e. the default pipeline name) appears after
  ///    all non-empty string; and names starting with an underscore appear
  ///    after the ones in the _preferredOrder_ and after the empty string.
  ///
  /// The empty string can be included in the _preferredOrder_ list. In which
  /// case rules 1 and 2 apply.
  ///
  /// WARNING: uppercase letters are sorted before lowercase letters.

  static int Function(String, String) _pipelineNameCompare(
          List<String> preferredOrder) =>
      (nameA, nameB) {
        final posA = preferredOrder.indexOf(nameA);
        final posB = preferredOrder.indexOf(nameB);

        if (0 <= posA && 0 <= posB) {
          // Both names are in the preferred list: order determine by index
          return posA == posB ? 0 : (posA < posB ? -1 : 1);
        } else if (0 <= posA) {
          // nameA in preferred list, but nameB is not
          assert(posB < 0, 'bad');
          return -1; // nameA goes before nameB (known before unknown)
        } else if (0 <= posB) {
          // nameB in preferred list, but nameA is not
          assert(posA < 0, 'bad');
          return 1; // nameA goes after nameB (unknown after known)
        } else {
          // Both names are not in the preferred list
          //
          // Order by alphabetically ordering the names, but putting the
          // default name (i.e. empty string) after the other values and
          // values starting with an underscore after the default name.

          assert(posA < 0 && posB < 0, 'bad');
          return _pipelineTwoNameCompare(nameA, nameB);
        }
      };

  /// Comparison for two pipeline names when the order of both is not defined.
  ///
  /// Used when both pipeline [nameA] and [nameB] are not in the
  /// _preferredOrder_ list of names.

  static int _pipelineTwoNameCompare(String nameA, String nameB) {
    // group values: -1 (normal name), 0 default, +1 (starts with underscore)

    final groupA = nameA == ServerPipeline.defaultName
        ? 0
        : nameA.startsWith('_')
            ? 1
            : -1;
    final groupB = nameB == ServerPipeline.defaultName
        ? 0
        : nameB.startsWith('_')
            ? 1
            : -1;

    if (groupA == groupB) {
      return nameA.compareTo(nameB);
    } else {
      // normal names (-1) before default name, both before underscore name
      return (groupA < groupB) ? -1 : 1;
    }
  }
}
