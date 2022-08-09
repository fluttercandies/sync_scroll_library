import 'package:flutter/material.dart';

import 'drag_hold_controller.dart';
import 'sync_scroll_minxin.dart';

/// The [SyncScrollController] to sync pixels for all of positions
class SyncScrollController extends ScrollController with SyncControllerMixin {
  /// Creates a scroll controller that continually updates its
  /// [initialScrollOffset] to match the last scroll notification it received.
  SyncScrollController({
    double initialScrollOffset = 0.0,
    bool keepScrollOffset = true,
    String? debugLabel,
    this.parent,
  }) : super(
          initialScrollOffset: initialScrollOffset,
          keepScrollOffset: keepScrollOffset,
          debugLabel: debugLabel,
        );

  /// The Outer SyncScrollController, for example [ExtendedTabBarView] or [ExtendedPageView]
  /// It make better experience when scroll on horizontal direction
  @override
  final SyncControllerMixin? parent;
}

/// The [SyncPageController] to scroll Pages(PageView or TabBarView) when [FlexGrid] is reach the horizontal boundary
class SyncPageController extends PageController with SyncControllerMixin {
  /// Creates a page controller.
  ///
  /// The [initialPage], [keepPage], and [viewportFraction] arguments must not be null.
  SyncPageController({
    int initialPage = 0,
    bool keepPage = true,
    double viewportFraction = 1.0,
    this.parent,
  }) : super(
          initialPage: initialPage,
          keepPage: keepPage,
          viewportFraction: viewportFraction,
        );

  /// The Outer SyncScrollController, for example [ExtendedTabBarView] or [ExtendedPageView]
  /// It make better experience when scroll on horizontal direction
  @override
  final SyncControllerMixin? parent;
}

/// The mixin for [ScrollController] to sync pixels for all of positions
mixin SyncControllerMixin on ScrollController {
  final Map<ScrollPosition, DragHoldController> _positionToListener =
      <ScrollPosition, DragHoldController>{};

  // The parent from user
  SyncControllerMixin? get parent;
  // The parent from link
  SyncControllerMixin? _parent;

  // The actual used parent
  SyncControllerMixin? get _internalParent => parent ?? _parent;

  // The current actived controller
  SyncControllerMixin? _activedParent;

  bool get parentIsNotNull => _internalParent != null;

  bool get isSelf => _activedParent == null;

  void linkParent<S extends StatefulWidget, T extends SyncScrollStateMinxin<S>>(
      BuildContext context) {
    _parent = context.findAncestorStateOfType<T>()?.syncController;
  }

  void unlinkParent() {
    _parent = null;
  }

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

  void handleDragDown(DragDownDetails? details) {
    for (final DragHoldController item in _positionToListener.values) {
      item.handleDragDown(details);
    }
  }

  void handleDragStart(DragStartDetails details) {
    for (final DragHoldController item in _positionToListener.values) {
      item.handleDragStart(details);
    }
  }

  void handleDragUpdate(DragUpdateDetails details) {
    if (_activedParent != null && _activedParent!.hasDrag) {
      _activedParent!.handleDragUpdate(details);
    } else {
      for (final DragHoldController item in _positionToListener.values) {
        item.handleDragUpdate(details);
      }
    }
  }

  void handleDragEnd(DragEndDetails details) {
    _activedParent?.handleDragEnd(details);

    for (final DragHoldController item in _positionToListener.values) {
      item.handleDragEnd(details);
    }
  }

  void handleDragCancel() {
    _activedParent?.handleDragCancel();
    _activedParent = null;

    for (final DragHoldController item in _positionToListener.values) {
      item.handleDragCancel();
    }
  }

  void forceCancel() {
    _activedParent?.forceCancel();
    _activedParent = null;

    for (final DragHoldController item in _positionToListener.values) {
      item.forceCancel();
    }
  }

  double get extentAfter =>
      _activedParent != null ? _activedParent!.extentAfter : _extentAfter;

  double get extentBefore =>
      _activedParent != null ? _activedParent!.extentBefore : _extentBefore;

  double get _extentAfter => _positionToListener.keys.isEmpty
      ? 0
      : _positionToListener.keys.first.extentAfter;

  double get _extentBefore => _positionToListener.keys.isEmpty
      ? 0
      : _positionToListener.keys.first.extentBefore;

  bool get hasDrag =>
      _activedParent != null ? _activedParent!.hasDrag : _hasDrag;
  bool get hasHold =>
      _activedParent != null ? _activedParent!.hasHold : _hasHold;

  bool get _hasDrag => _positionToListener.values
      .any((DragHoldController element) => element.hasDrag);
  bool get _hasHold => _positionToListener.values
      .any((DragHoldController element) => element.hasHold);

  SyncControllerMixin? getParent(bool test(SyncControllerMixin parent)) {
    if (_internalParent == null) {
      return null;
    }
    if (test(_internalParent!)) {
      return _internalParent!;
    }

    return _internalParent!.getParent(test);
  }

  void findActivedParent(double delta, DragUpdateDetails details) {
    if (_activedParent != null) {
      return;
    }
    SyncControllerMixin? activedParent;
    if (delta < 0 && _extentAfter == 0) {
      activedParent =
          getParent((SyncControllerMixin parent) => parent._extentAfter != 0);
    } else if (delta > 0 && _extentBefore == 0) {
      activedParent =
          getParent((SyncControllerMixin parent) => parent._extentBefore != 0);
    }

    if (activedParent != null) {
      _activedParent = activedParent;
      activedParent.handleDragDown(null);
      activedParent.handleDragStart(
        DragStartDetails(
          globalPosition: details.globalPosition,
          localPosition: details.localPosition,
          sourceTimeStamp: details.sourceTimeStamp,
        ),
      );
    }
  }
}