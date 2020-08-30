import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

class PopupMenuBorder extends ShapeBorder {
  final bool usePadding;
  final double radius;
  final double arrowHeight;
  final bool isDown;
  final bool drawArrow;
  final double arrowX;

  const PopupMenuBorder({
    this.isDown = true,
    this.radius,
    this.arrowHeight = 10,
    this.usePadding = false,
    @required this.arrowX,
  }) : this.drawArrow = arrowHeight > 0.0;

  void trianglePathFromAlignment(
      {Path path, Rect rect, double size, double radius, bool isDown}) {
    if (isDown) {
      final Offset arrowOffset = Offset(arrowX, rect.bottom);
      path
        ..moveTo(arrowOffset.dx + size, arrowOffset.dy)
        ..lineTo(arrowOffset.dx, arrowOffset.dy + size)
        ..lineTo(arrowOffset.dx - size, arrowOffset.dy);
    } else {
      final Offset arrowOffset = Offset(arrowX, rect.top);
      path
        ..moveTo(arrowOffset.dx - size, arrowOffset.dy)
        ..lineTo(arrowOffset.dx, arrowOffset.dy - size)
        ..lineTo(arrowOffset.dx + size, arrowOffset.dy);
    }
  }

  @override
  EdgeInsetsGeometry get dimensions =>
      EdgeInsets.only(bottom: usePadding ? 20 : 0);

  @override
  Path getInnerPath(Rect rect, {TextDirection textDirection}) => null;

  @override
  Path getOuterPath(Rect rect, {TextDirection textDirection}) {
    rect = Rect.fromPoints(rect.topLeft, rect.bottomRight);
    var path = Path()
      ..addRRect(RRect.fromRectAndRadius(
          rect, Radius.circular(radius ?? rect.height / 2)));
    if (drawArrow) {
      trianglePathFromAlignment(
          path: path,
          rect: rect,
          size: arrowHeight,
          radius: radius,
          isDown: isDown);
    }
    path.close();
    return path;
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection textDirection}) {}

  @override
  ShapeBorder scale(double t) => this;
}
