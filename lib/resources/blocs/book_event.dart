abstract class BookEvent{}

class FetchBook extends BookEvent {
  @override
  String toString() => 'Fetch Book';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FetchBook && runtimeType == other.runtimeType;

  @override
  int get hashCode => runtimeType.hashCode;

}