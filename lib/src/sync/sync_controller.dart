import 'package:flutter/widgets.dart';
import 'package:sync_scroll_library/src/drag_hold_controller.dart';
import 'package:sync_scroll_library/src/gesture/gesture_mixin.dart';

/// The [SyncScrollController] to sync pixels for all of positions
class SyncScrollController extends ScrollController
    with SyncScrollControllerMixin {
  /// Creates a scroll controller that continually updates its
  /// [initialScrollOffset] to match the last scroll notification it received.
  SyncScrollController({
    double initialScrollOffset = 0.0,
    bool keepScrollOffset = true,
    String? debugLabel,
  }) : super(
          initialScrollOffset: initialScrollOffset,
          keepScrollOffset: keepScrollOffset,
          debugLabel: debugLabel,
        );
}

/// The mixin for [ScrollController] to sync pixels for all of positions
mixin SyncScrollControllerMixin on ScrollController implements GestureMixin {
  final Map<ScrollPosition, DragHoldController> _positionToListener =
      <ScrollPosition, DragHoldController>{};
  Map<ScrollPosition, DragHoldController> get positionToListener =>
      _positionToListener;
  @override
  void attach(ScrollPosition position) {
    super.attach(position);
    assert(!_positionToListener.containsKey(position));
    if (_positionToListener.isNotEmpty) {
      final double pixels = _positionToListener.keys.first.pixels;
      if (position.pixels != pixels) {
        position.correctPixels(pixels);
      }
    }

    _positionToListener[position] = DragHoldController(position);
  }

  @override
  void detach(ScrollPosition position) {
    assert(_positionToListener.containsKey(position));
    _positionToListener[position]!.forceCancel();
    _positionToListener.remove(position);

    super.detach(position);
  }

  @override
  void dispose() {
    forceCancel();
    super.dispose();
  }

  @override
  void handleDragDown(DragDownDetails? details) {
    for (final DragHoldController item in _positionToListener.values) {
      item.handleDragDown(details);
    }
  }

  @override
  void handleDragStart(DragStartDetails details) {
    for (final DragHoldController item in _positionToListener.values) {
      item.handleDragStart(details);
    }
  }

  @override
  void handleDragUpdate(DragUpdateDetails details) {
    for (final DragHoldController item in _positionToListener.values) {
      if (!item.hasDrag) {
        item.handleDragStart(
          DragStartDetails(
            globalPosition: details.globalPosition,
            localPosition: details.localPosition,
            sourceTimeStamp: details.sourceTimeStamp,
          ),
        );
      }
      item.handleDragUpdate(details);
    }
  }

  @override
  void handleDragEnd(DragEndDetails details) {
    for (final DragHoldController item in _positionToListener.values) {
      item.handleDragEnd(details);
    }
  }

  @override
  void handleDragCancel() {
    for (final DragHoldController item in _positionToListener.values) {
      item.handleDragCancel();
    }
  }

  @override
  void forceCancel() {
    for (final DragHoldController item in _positionToListener.values) {
      item.forceCancel();
    }
  }
}
