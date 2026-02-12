import 'package:flutter/material.dart';

/// Simple object pool for reusing particles and reducing allocations
class ObjectPool<T> {
  final List<T> _available = [];
  final List<T> _inUse = [];
  final T Function() _factory;
  final void Function(T)? _reset;
  final int _maxSize;

  ObjectPool({
    required T Function() factory,
    void Function(T)? reset,
    int maxSize = 100,
  }) : _factory = factory,
       _reset = reset,
       _maxSize = maxSize;

  /// Get an object from the pool
  T acquire() {
    if (_available.isEmpty) {
      final obj = _factory();
      _inUse.add(obj);
      return obj;
    }

    final obj = _available.removeLast();
    _inUse.add(obj);
    return obj;
  }

  /// Return an object to the pool
  void release(T obj) {
    if (!_inUse.remove(obj)) return;

    if (_available.length < _maxSize) {
      _reset?.call(obj);
      _available.add(obj);
    }
  }

  /// Release all objects
  void releaseAll() {
    for (final obj in _inUse.toList()) {
      release(obj);
    }
  }

  /// Clear the pool
  void clear() {
    _available.clear();
    _inUse.clear();
  }

  int get availableCount => _available.length;
  int get inUseCount => _inUse.length;
  int get totalCount => _available.length + _inUse.length;
}

/// Pooled particle data
class PooledParticle {
  Offset position = Offset.zero;
  Offset velocity = Offset.zero;
  Color color = Colors.white;
  double size = 1.0;
  double life = 1.0;
  double maxLife = 1.0;

  void reset() {
    position = Offset.zero;
    velocity = Offset.zero;
    color = Colors.white;
    size = 1.0;
    life = 1.0;
    maxLife = 1.0;
  }
}
