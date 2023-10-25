part of '../woomera_server_gen.dart';

//################################################################

class _Scanner {
  //----------------------------------------------------------------

  _Scanner([Iterable<Uri>? libraries]) {
    // Scan all the libraries for registrations

    final scannedLibraries = _scanSystem(libraries);

    // Check all the requested libraries were processed

    if (libraries != null) {
      final missing = libraries.where((u) => !scannedLibraries.contains(u));

      if (missing.isNotEmpty) {
        // TODO: throw LibraryNotFound(missing);
        final str = missing.map((x) => x.toString()).join(', ');
        throw StateError('libraries not found: $str');
      }
    }
  }

  //================================================================
  // Members

  final handlers = <WoomeraAnnotation, WoomeraFunction>{};

  //================================================================
  // Methods

  //----------------------------------------------------------------

  Iterable<Uri> _scanSystem([Iterable<Uri>? librariesToScan]) {
    final librariesProcessed = <Uri, bool>{};

    final mirrorSys = currentMirrorSystem();
    ArgumentError.checkNotNull(
        mirrorSys, 'cannot scan for annotations: no mirror system');

    for (final entry in mirrorSys.libraries.entries) {
      final libUrl = entry.key;
      final libMirror = entry.value;

      if (libUrl.scheme == 'dart') {
        // Skip: never scan built-in Dart libraries
      } else {
        if (!librariesProcessed.containsKey(libUrl)) {
          if (librariesToScan == null || librariesToScan.contains(libUrl)) {
            // Scan this library, since either the invoker wants all libraries
            // to be scanned (i.e. because it is null) or does want this
            // particular library to be scanned (i.e. it is in the list).
            _scanLibrary(libUrl, libMirror);
          }

          librariesProcessed[libUrl] = true;
        }
      }
    }

    return librariesProcessed.keys;
  }

  //----------------------------------------------------------------

  void _scanLibrary(Uri libUri, LibraryMirror libMirror) {
    //_logHandles.finest('scanning $libUrl');
    // TODO: _scanLibrary(libUrl, library);

    for (final declaration in libMirror.declarations.values) {
      if (declaration is ClassMirror) {
        // Scan the class
        _scanClass(libUri, declaration);
      } else if (declaration is MethodMirror) {
        // Non-class
        //
        // Process only top-level functions. Ignore everything else.

        try {
          final cm = libMirror.getField(declaration.simpleName);
          final dynamic item = cm.hasReflectee ? cm.reflectee : null;

          if (item is Function) {
            // Scan functions
            _scanFunction(libUri, declaration, item);
          } else {
            // Ignore non-functions
            _logHandles.finest('not a function (${item.runtimeType}):'
                ' $libUri ${declaration.qualifiedName}');
          }
          // ignore: avoid_catching_errors
        } on NoSuchMethodError {
          final name = MirrorSystem.getName(declaration.simpleName);
          if (name.contains('.')) {
            // Dart extensions result in top level methods/functions whose names
            // are "ExtensionName.MethodName". Ignore the exceptions cause by
            // these.
            _logHandles.finer('ignored extension method: $name');
          } else {
            // Some other cause
            _logHandles.finer('ignored method: $name');
            // TODO(any): what to do here?
            // rethrow;
          }
        } catch (ex) {
          _logHandles.finer('_scanLibrary exception: $ex');
          // ignore?
          // TODO(any): what to do here?
          // rethrow;
        }
      }
    }
  }

  //----------------------------------------------------------------
  // Scan a class for static members with [Handles] annotations.

  void _scanClass(Uri libUri, ClassMirror classMirror) {
    // Class: process its static methods

    for (final staticMember in classMirror.staticMembers.values) {
      if (!(staticMember.isGetter ||
          staticMember.isSetter ||
          staticMember.isOperator)) {
        final cm = classMirror.getField(staticMember.simpleName);
        final dynamic item = cm.hasReflectee ? cm.reflectee : null;

        if (item is Function) {
          // Scan functions
          _scanFunction(libUri, staticMember, item);
        } else {
          // Ignore non-functions
          _logHandles.finest('not a function (${item.runtimeType}): '
              '$libUri ${staticMember.qualifiedName}');
        }
      }
    }
  }

  //----------------------------------------------------------------
  /// Scan a function or static method for [Handles] annotations.
  ///
  /// For all the registration annotations found on it, a
  /// [_AnnotatedRequestHandler] object is created and appended to the
  /// [_found] list under the pipeline identified in the
  /// annotation.
  ///
  /// Note: a method may have more than one registration annotation on it.
  /// Each one will result in its own annotated request handler.

  void _scanFunction(
      Uri library, MethodMirror methodMirror, Function theFunction) {
    for (final instanceMirror in methodMirror.metadata) {
      if (instanceMirror.hasReflectee) {
        // The annotation is an instance of the [Registration] class

        final dynamic annotation = instanceMirror.reflectee;

        if (annotation is WoomeraAnnotation) {
          // A Woomera annotation

          final previouslyFound = handlers[annotation];
          if (previouslyFound != null) {
            throw StateError(
                'duplicate: $annotation: ${previouslyFound.methodMirror} $methodMirror');
          }

          // Add annotated handler function to the results

          handlers[annotation] =
              WoomeraFunction(annotation, methodMirror, theFunction);
        } else {
          // ignore all other types of annotation
        }
      }
    }
  }
}
