/// Base for catalog fakes of an actions interface. Every method call returns
/// a completed `Future<void>`, which also satisfies `void` methods.
/// Actions interfaces must only declare methods returning `void` or
/// `Future<void>`. Usage: `class _NoopNotes extends NoOpActions implements NotesActions {}`
abstract class NoOpActions {
  @override
  dynamic noSuchMethod(Invocation invocation) => Future<void>.value();
}
