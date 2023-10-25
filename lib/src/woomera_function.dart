part of '../woomera_server_gen.dart';

//################################################################
/// A function and its Woomera annotation.
///
/// The details of a function that has been annotated with a
/// Woomera annotation.
///
/// This is used to represent all the types of functions found through
/// annotations: request handlers, wrapper function and the three types
/// of exception handlers.

class WoomeraFunction {
  //================================================================
  // Constructors

  WoomeraFunction(this.annotation, this.methodMirror, this.function);

  //================================================================
  // Members

  /// The annotation.
  ///
  /// For backward compatibility, exception handlers might be annotated with
  /// [Handles] objects (to support the woomera <= 8.0.0) as well
  /// as the specific exception handler objects defined in woomera 8.0.0
  /// (i.e. [PipelineExceptionHandler], [ServerExceptionHandler] and
  /// [ServerExceptionHandlerRaw]).

  final WoomeraAnnotation annotation;

  /// The method mirror of the function.
  ///
  /// This is the metadata about the function provided by the _dart:mirror_
  /// package.

  final MethodMirror methodMirror;

  /// The function itself.

  final Function function;
}
