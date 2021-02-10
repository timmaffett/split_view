library split_view;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// SplitView
class SplitView extends StatefulWidget {
  /// The top or left [Widget] for the [SplitView]
  final Widget view1;

  /// The bottom or right [Widget] for the [SplitView]
  final Widget view2;

  /// Specify vertical or horizontal using [SplitViewMode.Vertical] or [SplitViewMode.Horizontal]
  final SplitViewMode viewMode;

  /// Initial weight of view1 (left or top) as a percentage of container width or height
  final double initialWeight;

  /// Size of grip in pixels
  final double gripSize;

  /// Color of the [SplitView] grip (default is [Color.grey])
  final Color gripColor;

  /// Optional callback to be called when [SplitView] is adjusted by user
  final ValueChanged<double> onWeightChanged;

  /// Set [dragHandle] to true to include drag handle on grip, default is false
  final bool dragHandle;

  /// Optionally set the [IconData] to use for the grip drag handle. Defaults to [Icons.drag_handle_sharp]
  final IconData dragIcon;

  /// Pixel based [positionLimit] can be used to specify the top/bottom or left/right limits (from edge) in pixels for drag handle
  double positionLimit;

  ///  Weight based [positionWeightLimit] can be used to specify the top/bottom or left/right limits (from edge) in %width/%height of container for drag handle
  double positionWeightLimit;

  /// If Weight based [positionWeightLowLimit] is specified then this becomes the LEFT or TOP limit (from edge) as a %width/height, and [positionWeightLimit] will be used for RIGHT or BOTTOM (from edge) limit
  double positionWeightLowLimit;

  SplitView({
    @required this.view1,
    @required this.view2,
    @required this.viewMode,
    this.gripSize = 12.0,
    this.initialWeight = 0.5,
    this.gripColor = Colors.grey,
    this.positionLimit = 20.0,
    this.dragHandle = false,
    this.dragIcon = Icons.drag_handle_sharp, //drag_handle,
    this.positionWeightLimit = 0,
    this.positionWeightLowLimit = 0,
    this.onWeightChanged,
  }) {
    if( positionWeightLowLimit!=0 ) assert( positionWeightLimit!=0 );
    if (this.positionWeightLimit != 0 || this.positionWeightLowLimit!=0) {
      this.positionLimit = 0;
    }
  }

  @override
  State createState() => _SplitViewState();
}

class _SplitViewState extends State<SplitView> {
  double defaultWeight;
  ValueNotifier<double> weight;
  double _prevWeight;

  @override
  void initState() {
    super.initState();
    this._prevWeight = this.defaultWeight = widget.initialWeight;
  }

  @override
  Widget build(BuildContext context) {
    defaultWeight = _prevWeight;  // reset defaultWeight to _prevWeight so RE-Build() calls *WONT* RESET splitter

    weight = ValueNotifier(defaultWeight);

    return LayoutBuilder(
      builder: (context, constraints) {
        return ValueListenableBuilder<double>(
          valueListenable: weight,
          builder: (_, w, __) {
            if (widget.onWeightChanged != null && _prevWeight != w) {
              _prevWeight = w;
              widget.onWeightChanged(w);
            }
            if (widget.viewMode == SplitViewMode.Vertical) {
              return _buildVerticalView(context, constraints, w);
            } else {
              return _buildHorizontalView(context, constraints, w);
            }
          },
        );
      },
    );
  }

  Stack _buildVerticalView(
      BuildContext context, BoxConstraints constraints, double w) {
    double top = constraints.maxHeight * w;
    double bottom = constraints.maxHeight * (1.0 - w);

    return Stack(
      children: <Widget>[
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          bottom: bottom - widget.gripSize / 2.0,
          child: widget.view1,
        ),
        Positioned(
          top: top + widget.gripSize / 2.0,
          left: 0,
          right: 0,
          bottom: 0,
          child: widget.view2,
        ),
        Positioned(
          top: top - widget.gripSize / 2.0,
          left: 0,
          right: 0,
          bottom: bottom - widget.gripSize / 2.0,
          child: MouseRegion(
            cursor: SystemMouseCursors.resizeRow,
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onVerticalDragUpdate: (detail) {
                final RenderBox container =
                    context.findRenderObject() as RenderBox;
                final pos = container.globalToLocal(detail.globalPosition);
                if (widget.positionWeightLowLimit != 0) {
                  double posLimit =
                      widget.positionWeightLimit * container.size.height;
                  double posLowLimit =
                      widget.positionWeightLowLimit * container.size.height;
                  if (pos.dy > posLowLimit &&
                      pos.dy < (container.size.height - posLimit)) {
                    weight.value = pos.dy / container.size.height;
                  }
                } else if (widget.positionWeightLimit != 0) {
                  double posLimit =
                      widget.positionWeightLimit * container.size.height;
                  if (pos.dy > posLimit &&
                      pos.dy < (container.size.height - posLimit)) {
                    weight.value = pos.dy / container.size.height;
                  }
                } else if (pos.dy > widget.positionLimit &&
                    pos.dy < (container.size.height - widget.positionLimit)) {
                  weight.value = pos.dy / container.size.height;
                }
              },
              child: Container(
                color: widget.gripColor,
                child: widget.dragHandle
                    ? Icon(widget.dragIcon, size: widget.gripSize)
                    : null, //drag_handle
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHorizontalView(
      BuildContext context, BoxConstraints constraints, double w) {
    final double left = constraints.maxWidth * w;
    final double right = constraints.maxWidth * (1.0 - w);

    return Stack(
      children: <Widget>[
        Positioned(
          top: 0,
          left: 0,
          right: right - widget.gripSize / 2.0,
          bottom: 0,
          child: widget.view1,
        ),
        Positioned(
          top: 0,
          left: left + widget.gripSize / 2.0,
          right: 0,
          bottom: 0,
          child: widget.view2,
        ),
        Positioned(
          top: 0,
          left: left - widget.gripSize / 2.0,
          right: right - widget.gripSize / 2.0,
          bottom: 0,
          child: MouseRegion(
            cursor: SystemMouseCursors.resizeColumn,
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onVerticalDragUpdate: (detail) {
                final RenderBox container =
                    context.findRenderObject() as RenderBox;
                final pos = container.globalToLocal(detail.globalPosition);
                if (widget.positionWeightLowLimit != 0) {
                  double posLimit =
                      widget.positionWeightLimit * container.size.width;
                  double posLowLimit =
                      widget.positionWeightLowLimit * container.size.width;
                  if (pos.dx > posLowLimit &&
                      pos.dx < (container.size.width - posLimit)) {
                    weight.value = pos.dx / container.size.width;
                  }
                } else if (widget.positionWeightLimit != 0) {
                  double posLimit =
                      widget.positionWeightLimit * container.size.width;
                  if (pos.dx > posLimit &&
                      pos.dx < (container.size.width - posLimit)) {
                    weight.value = pos.dx / container.size.width;
                  }
                } else if (pos.dx > widget.positionLimit &&
                    pos.dx < (container.size.width - widget.positionLimit)) {
                  weight.value = pos.dx / container.size.width;
                }
              },
              child: Container(
                color: widget.gripColor,
                child: !widget.dragHandle
                    ? null
                    : RotationTransition(
                        child: Icon(widget.dragIcon, size: widget.gripSize * 2),
                        turns: AlwaysStoppedAnimation(0.25),
                      ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

enum SplitViewMode {
  Vertical,
  Horizontal,
}
