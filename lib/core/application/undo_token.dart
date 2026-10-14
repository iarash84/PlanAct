/// An opaque durable operation identity, never a snapshot held only by a widget.
class UndoToken {
  const UndoToken(this.id);
  final String id;
}
