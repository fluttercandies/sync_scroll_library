import 'package:flutter/gestures.dart';

class GestureMixin {
  void handleDragDown(DragDownDetails details) {}

  void handleDragStart(DragStartDetails details) {}

  void handleDragUpdate(DragUpdateDetails details) {}

  void handleDragEnd(DragEndDetails details) {}

  void handleDragCancel() {}

  void forceCancel() {}
}
