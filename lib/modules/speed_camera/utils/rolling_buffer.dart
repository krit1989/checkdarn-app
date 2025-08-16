/// Rolling Buffer implementation for efficient memory management
/// O(1) operations for push, access, and automatic overflow handling
class RollingBuffer<T> {
  final int capacity;
  final List<T?> _buffer;
  int _start = 0;
  int _length = 0;

  RollingBuffer(this.capacity) : _buffer = List.filled(capacity, null);

  /// Current number of items in buffer
  int get length => _length;

  /// Whether buffer is empty
  bool get isEmpty => _length == 0;

  /// Whether buffer has items
  bool get isNotEmpty => _length > 0;

  /// Whether buffer is at maximum capacity
  bool get isFull => _length == capacity;

  /// Add item to buffer (O(1) operation)
  void push(T item) {
    if (_length == capacity) {
      // Buffer full, overwrite oldest item
      _buffer[_start] = item;
      _start = (_start + 1) % capacity;
    } else {
      // Buffer not full, add to end
      final index = (_start + _length) % capacity;
      _buffer[index] = item;
      _length++;
    }
  }

  /// Get item at index (0 = oldest, length-1 = newest)
  T operator [](int index) {
    if (index < 0 || index >= _length) {
      throw RangeError.index(index, this, 'index', null, _length);
    }
    return _buffer[(_start + index) % capacity]!;
  }

  /// Get first (oldest) item or null if empty
  T? get firstOrNull => isEmpty ? null : this[0];

  /// Get last (newest) item or null if empty
  T? get lastOrNull => isEmpty ? null : this[_length - 1];

  /// Get last N items as iterable
  Iterable<T> last(int count) {
    if (count <= 0) return [];
    final actualCount = count > _length ? _length : count;
    final startIndex = _length - actualCount;
    return Iterable.generate(actualCount, (i) => this[startIndex + i]);
  }

  /// Convert to list (preserves order: oldest to newest)
  List<T> toList() {
    return List.generate(_length, (i) => this[i]);
  }

  /// Clear all items
  void clear() {
    _start = 0;
    _length = 0;
  }

  /// Iterate over all items (oldest to newest)
  void forEach(void Function(T) action) {
    for (int i = 0; i < _length; i++) {
      action(this[i]);
    }
  }
}

/// Specialized RollingBuffer for position data
class PositionHistory<T> extends RollingBuffer<T> {
  static const int defaultCapacity = 60; // 1 minute at 1Hz
  static const int minPositionsForAnalysis = 3;

  PositionHistory({int capacity = defaultCapacity}) : super(capacity);

  /// Get recent positions (last N items, default 3)
  List<T> getRecentPositions([int count = 3]) {
    return last(count).toList();
  }

  /// Check if we have enough data for analysis
  bool hasEnoughData([int minRequired = minPositionsForAnalysis]) {
    return length >= minRequired;
  }
}

/// Specialized RollingBuffer for speed data
class SpeedHistory<T> extends RollingBuffer<T> {
  static const int defaultCapacity = 120; // 2 minutes at 1Hz
  static const int minSpeedsForAnalysis = 5;

  SpeedHistory({int capacity = defaultCapacity}) : super(capacity);

  /// Get recent speeds (last N items, default 10)
  List<T> getRecentSpeeds([int count = 10]) {
    return last(count).toList();
  }

  /// Check if we have enough data for speed analysis
  bool hasEnoughDataForAnalysis([int minRequired = minSpeedsForAnalysis]) {
    return length >= minRequired;
  }
}
