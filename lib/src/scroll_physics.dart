import 'package:flutter/material.dart';
import 'package:flutter/physics.dart' as physics;

class NeverScrollableClampingScrollPhysics extends ClampingScrollPhysics
    with LessSpringScrollPhysics {
  const NeverScrollableClampingScrollPhysics()
      : super(parent: const NeverScrollableScrollPhysics());
}

/// reduce animation time
mixin LessSpringScrollPhysics on ScrollPhysics {
  @override
  physics.SpringDescription get spring =>
      physics.SpringDescription.withDampingRatio(
        mass: 0.5,
        stiffness: 1000.0, // Increase this value as you wish.
        ratio: 1.1,
      );
}

class LessSpringClampingScrollPhysics extends ClampingScrollPhysics
    with LessSpringScrollPhysics {
  const LessSpringClampingScrollPhysics()
      : super(parent: const ClampingScrollPhysics());
}
