import 'package:flutter/material.dart';

/// A class that encapsulates the positional information of a widget.
///
/// This class is used to store and manage the geometric and positional
/// information, primarily for managing dropdowns, tooltips, etc.
class PositionForm {
  /// The size of the widget.
  ///
  /// Contains information about the width and height.
  final Size size;

  /// The bottom-left coordinate of the widget.
  final Offset bottomLeft;

  /// The bottom-right coordinate of the widget.
  final Offset bottomRight;

  /// Constructs a new `PositionForm`.
  ///
  /// All parameters are optional and have default values.
  const PositionForm([
    this.size = Size.zero,
    this.bottomLeft = Offset.zero,
    this.bottomRight = Offset.zero,
  ]);

  /// Constructs a new `PositionForm` from a [Rect] object.
  ///
  /// If the provided `Rect` is null, returns an empty `PositionForm`.
  factory PositionForm.fromRect(Rect? globalPaintBounds) {
    final size = globalPaintBounds?.size;
    final bottomLeft = globalPaintBounds?.bottomLeft;
    final bottomRight = globalPaintBounds?.bottomRight;

    if (bottomLeft == null || bottomRight == null || size == null) {
      return const PositionForm();
    }

    return PositionForm(size, bottomLeft, bottomRight);
  }

  /// Checks whether this `PositionForm` contains valid data.
  ///
  /// Returns `false` if it's an empty `PositionForm`.
  bool get valid => this != const PositionForm();

  /// Returns the area represented by this `PositionForm` as a [Rect].
  Rect get area {
    return Rect.fromPoints(
      Offset(
        bottomLeft.dx,
        bottomLeft.dy - size.height,
      ),
      Offset(
        bottomLeft.dx + size.width,
        bottomLeft.dy,
      ),
    );
  }

  /// Wraps a child widget under the area represented by this `PositionForm`.
  ///
  /// **Parameters:**
  /// - `child`: The widget to be wrapped. Defaults to an empty [SizedBox].
  Widget wrapAreaUnder({Widget child = const SizedBox.shrink()}) {
    return Positioned(
      top: bottomLeft.dy,
      left: 0,
      right: 0,
      child: child,
    );
  }

  /// Overrides the equality operator.
  ///
  /// Two `PositionForm` objects are considered equal if all their fields are equal.
  @override
  operator ==(dynamic other) =>
      other is PositionForm &&
      other.bottomLeft == bottomLeft &&
      other.bottomRight == bottomRight &&
      other.size == size;

  /// Overrides the hashCode getter.
  ///
  /// The hash code is computed based on the `bottomLeft` and `bottomRight` offsets.
  @override
  int get hashCode => (bottomLeft + bottomRight).hashCode;
}
