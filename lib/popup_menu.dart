library popup_menu;

import 'dart:core';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';

import 'triangle_painter.dart';

abstract class MenuItemProvider {
  String get menuTitle;
  Widget get menuImage;
  TextStyle get menuTextStyle;
  TextAlign get menuTextAlign;
  dynamic get menuUserInfo;
}

class MenuItem extends MenuItemProvider {
  Widget image;
  String title;
  var userInfo;
  TextStyle textStyle;
  TextAlign textAlign;

  MenuItem({
    this.title,
    this.image,
    this.userInfo,
    this.textStyle,
    this.textAlign,
  });

  @override
  Widget get menuImage => image;

  @override
  String get menuTitle => title;

  @override
  dynamic get menuUserInfo => userInfo;

  @override
  TextStyle get menuTextStyle =>
      textStyle ?? TextStyle(color: Color(0xffc5c5c5), fontSize: 10.0);

  @override
  TextAlign get menuTextAlign => textAlign ?? TextAlign.center;
}

enum MenuType { big, oneLine }

typedef MenuClickCallback = Function(MenuItemProvider item);
typedef PopupMenuStateChanged = Function(bool isShow, dynamic userInfo);
typedef DismissCallback = Function(dynamic userInfo);

class PopupMenu {
  final double itemWidth;
  final double itemHeight;
  final double arrowHeight;
  OverlayEntry _entry;
  List<MenuItemProvider> items;
  var userInfo;
  double elevation;

  /// row count
  int _row;

  /// col count
  int _col;

  /// The left top point of this menu.
  Offset _offset;

  /// Menu will show at above or under this rect
  Rect _showRect;

  /// if false menu is show above of the widget, otherwise menu is show under the widget
  bool _isDown = true;

  /// The max column count, default is 4.
  int _maxColumn;

  /// callback
  DismissCallback dismissCallback;
  MenuClickCallback onClickMenu;
  PopupMenuStateChanged stateChanged;

  Size _screenSize; // 屏幕的尺寸

  /// Cannot be null
  static BuildContext context;

  /// style
  Color _backgroundColor;
  Color _highlightColor;
  Color _lineColor;

  /// It's showing or not.
  bool _isShow = false;
  bool get isShow => _isShow;

  PopupMenu({
    this.itemWidth = 72.0,
    this.itemHeight = 65.0,
    this.arrowHeight = 10.0,
    MenuClickCallback onClickMenu,
    BuildContext context,
    DismissCallback onDismiss,
    int maxColumn,
    Color backgroundColor,
    Color highlightColor,
    Color lineColor,
    PopupMenuStateChanged stateChanged,
    List<MenuItemProvider> items,
    this.userInfo,
    this.elevation = 4.0,
  }) {
    this.onClickMenu = onClickMenu;
    this.dismissCallback = onDismiss;
    this.stateChanged = stateChanged;
    this.items = items;
    this._maxColumn = maxColumn ?? 4;
    this._backgroundColor = backgroundColor ?? Color(0xff232323);
    this._lineColor = lineColor ?? Color(0xff353535);
    this._highlightColor = highlightColor ?? Color(0x55000000);
    if (context != null) {
      PopupMenu.context = context;
    }
  }

  void show({Rect rect, GlobalKey widgetKey, List<MenuItemProvider> items}) {
    if (rect == null && widgetKey == null) {
      print("'rect' and 'key' can't be both null");
      return;
    }

    this.items = items ?? this.items;
    this._showRect = rect ?? PopupMenu.getWidgetGlobalRect(widgetKey);
    this._screenSize = window.physicalSize / window.devicePixelRatio;
    this.dismissCallback = dismissCallback;

    _calculatePosition(PopupMenu.context);

    _entry = OverlayEntry(builder: (context) {
      return buildPopupMenuLayout(_offset);
    });

    Overlay.of(PopupMenu.context).insert(_entry);
    _isShow = true;
    if (this.stateChanged != null) {
      this.stateChanged(true, userInfo);
    }
  }

  static Rect getWidgetGlobalRect(GlobalKey key) {
    RenderBox renderBox = key.currentContext.findRenderObject();
    var offset = renderBox.localToGlobal(Offset.zero);
    return Rect.fromLTWH(
        offset.dx, offset.dy, renderBox.size.width, renderBox.size.height);
  }

  // calculate row count
  int _calculateRowCount() {
    if (items == null || items.length == 0) {
      debugPrint('error menu items can not be null');
      return 0;
    }

    int itemCount = items.length;

    if (_calculateColCount() == 1) {
      return itemCount;
    }

    int row = (itemCount - 1) ~/ _calculateColCount() + 1;

    return row;
  }

  // calculate col count
  int _calculateColCount() {
    if (items == null || items.length == 0) {
      debugPrint('error menu items can not be null');
      return 0;
    }

    int itemCount = items.length;
    if (_maxColumn != 4 && _maxColumn > 0) {
      return _maxColumn;
    }

    if (itemCount == 4) {
      // 4个显示成两行
      return 2;
    }

    if (itemCount <= _maxColumn) {
      return itemCount;
    }

    if (itemCount == 5) {
      return 3;
    }

    if (itemCount == 6) {
      return 3;
    }

    return _maxColumn;
  }

  void _calculatePosition(BuildContext context) {
    _col = _calculateColCount();
    _row = _calculateRowCount();
    _offset = _calculateOffset(PopupMenu.context);
  }

  Offset _calculateOffset(BuildContext context) {
    double dx = _showRect.left + _showRect.width / 2.0 - menuWidth() / 2.0;
    if (dx < 10.0) {
      dx = 10.0;
    }

    if (dx + menuWidth() > _screenSize.width && dx > 10.0) {
      double tempDx = _screenSize.width - menuWidth() - 10;
      if (tempDx > 10) dx = tempDx;
    }

    double dy = _showRect.top - menuHeight();
    if (dy <= MediaQuery.of(context).padding.top + 10) {
      // The have not enough space above, show menu under the widget.
      dy = arrowHeight + _showRect.height + _showRect.top;
      _isDown = false;
    } else {
      dy -= arrowHeight;
      _isDown = true;
    }

    return Offset(dx, dy);
  }

  double menuWidth() {
    return itemWidth * _col;
  }

  // This height exclude the arrow
  double menuHeight() {
    return itemHeight * _row;
  }

  bool _tapOutside(Offset tapPosition, Offset offset) {
    double w = menuWidth();
    double h = menuHeight();
    bool outsideX =
        tapPosition.dx < offset.dx || tapPosition.dx >= offset.dx + w;
    bool outsideY =
        tapPosition.dy < offset.dy || tapPosition.dy >= offset.dy + h;

    return outsideX || outsideY;
  }

  LayoutBuilder buildPopupMenuLayout(Offset offset) {
    return LayoutBuilder(builder: (context, constraints) {
      return _PopupMenuLayout(popupMenu: this);
    });
  }

  void dismiss() {
    if (!_isShow) {
      // Remove method should only be called once
      return;
    }

    _entry.remove();
    _isShow = false;
    if (dismissCallback != null) {
      dismissCallback(userInfo);
    }

    if (this.stateChanged != null) {
      this.stateChanged(false, userInfo);
    }
  }
}

class _PopupMenuLayout extends StatefulWidget {
  final PopupMenu popupMenu;

  _PopupMenuLayout({
    Key key,
    @required this.popupMenu,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _PopupMenuLayoutState();
  }
}

class _PopupMenuLayoutState extends State<_PopupMenuLayout>
    with SingleTickerProviderStateMixin {
  AnimationController animationController;
  Animation<Offset> slideAnimation;

  @override
  void initState() {
    super.initState();
    animationController = AnimationController(
      duration: Duration(milliseconds: 400),
      vsync: this,
    );
    const double dist = 0.1;
    if (widget.popupMenu._isDown) {
      slideAnimation = Tween<Offset>(
        begin: const Offset(0.0, dist),
        end: const Offset(0.0, 0.0),
      ).animate(CurvedAnimation(
        parent: animationController,
        curve: Curves.bounceOut,
      ));
    } else {
      slideAnimation = Tween<Offset>(
        begin: const Offset(0.0, -dist),
        end: const Offset(0.0, 0.0),
      ).animate(CurvedAnimation(
        parent: animationController,
        curve: Curves.bounceOut,
      ));
    }

    animationController.forward();
  }

  @override
  void dispose() {
    animationController.dispose();
    super.dispose();
  }

  List<Widget> _createRows() {
    List<Widget> rows = [];
    for (int i = 0; i < widget.popupMenu._row; i++) {
      Widget rowWidget = Container(
        decoration: BoxDecoration(
            border: (i < widget.popupMenu._row - 1)
                ? Border(bottom: BorderSide(color: widget.popupMenu._lineColor))
                : null),
        height: widget.popupMenu.itemHeight,
        child: Row(
          children: _createRowItems(i),
        ),
      );

      rows.add(rowWidget);
    }

    return rows;
  }

  List<Widget> _createRowItems(int row) {
    List<MenuItemProvider> subItems = widget.popupMenu.items.sublist(
        row * widget.popupMenu._col,
        min(row * widget.popupMenu._col + widget.popupMenu._col,
            widget.popupMenu.items.length));
    List<Widget> itemWidgets = [];
    int i = 0;
    for (var item in subItems) {
      itemWidgets.add(_createMenuItem(
        item,
        i < (widget.popupMenu._col - 1),
      ));
      i++;
    }

    return itemWidgets;
  }

  double get screenWidth {
    double width = window.physicalSize.width;
    double ratio = window.devicePixelRatio;
    return width / ratio;
  }

  Widget _createMenuItem(MenuItemProvider item, bool showLine) {
    return _MenuItemWidget(
      itemHeight: widget.popupMenu.itemHeight,
      arrowHeight: widget.popupMenu.arrowHeight,
      itemWidth: widget.popupMenu.itemWidth,
      item: item,
      showLine: showLine,
      clickCallback: itemClicked,
      lineColor: widget.popupMenu._lineColor,
      backgroundColor: Colors.transparent,
      highlightColor: widget.popupMenu._highlightColor,
    );
  }

  void itemClicked(MenuItemProvider item) {
    if (widget.popupMenu.onClickMenu != null) {
      widget.popupMenu.onClickMenu(item);
    }

    widget.popupMenu.dismiss();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        widget.popupMenu.dismiss();
      },
      onTapDown: (TapDownDetails details) {
        if (widget.popupMenu
            ._tapOutside(details.localPosition, widget.popupMenu._offset))
          widget.popupMenu.dismiss();
      },
      onVerticalDragStart: (DragStartDetails details) {
        widget.popupMenu.dismiss();
      },
      onHorizontalDragStart: (DragStartDetails details) {
        widget.popupMenu.dismiss();
      },
      child: Container(
        child: Stack(
          children: <Widget>[
            Positioned(
              left: widget.popupMenu._offset.dx,
              top: widget.popupMenu._offset.dy,
              child: Container(
                width: widget.popupMenu.menuWidth(),
                height: widget.popupMenu.menuHeight(),
                child: SlideTransition(
                  position: slideAnimation,
                  child: FadeTransition(
                    opacity: animationController
                        .drive(CurveTween(curve: Curves.linear)),
                    child: Material(
                        elevation: widget.popupMenu.elevation,
                        shape: PopupMenuBorder(
                          radius: 10.0,
                          arrowHeight: widget.popupMenu.arrowHeight,
                          isDown: widget.popupMenu._isDown,
                          arrowX: widget.popupMenu._showRect.left +
                              widget.popupMenu._showRect.width / 2.0 -
                              widget.popupMenu._offset.dx,
                        ),
                        color: widget.popupMenu._backgroundColor,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10.0),
                          child: Container(
                            width: widget.popupMenu.menuWidth(),
                            height: widget.popupMenu.menuHeight(),
                            child: Column(
                              children: _createRows(),
                            ),
                          ),
                        )),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuItemWidget extends StatefulWidget {
  final MenuItemProvider item;
  // 是否要显示右边的分隔线
  final bool showLine;
  final Color lineColor;
  final Color backgroundColor;
  final Color highlightColor;
  final double itemWidth;
  final double itemHeight;
  final double arrowHeight;

  final Function(MenuItemProvider item) clickCallback;

  _MenuItemWidget({
    this.itemWidth = 72.0,
    this.itemHeight = 65.0,
    this.arrowHeight = 10.0,
    this.item,
    this.showLine = false,
    this.clickCallback,
    this.lineColor,
    this.backgroundColor,
    this.highlightColor,
  });

  @override
  State<StatefulWidget> createState() {
    return _MenuItemWidgetState();
  }
}

class _MenuItemWidgetState extends State<_MenuItemWidget> {
  var highlightColor = Color(0x55000000);
  var color = Color(0xff232323);

  @override
  void initState() {
    color = widget.backgroundColor;
    highlightColor = widget.highlightColor;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (details) {
        color = highlightColor;
        setState(() {});
      },
      onTapUp: (details) {
        color = widget.backgroundColor;
        setState(() {});
      },
      onLongPressEnd: (details) {
        color = widget.backgroundColor;
        setState(() {});
      },
      onTap: () {
        if (widget.clickCallback != null) {
          widget.clickCallback(widget.item);
        }
      },
      child: Container(
          width: widget.itemWidth,
          height: widget.itemHeight,
          decoration: BoxDecoration(
              color: color,
              border: Border(
                  right: BorderSide(
                      color: widget.showLine
                          ? widget.lineColor
                          : Colors.transparent))),
          child: _createContent()),
    );
  }

  Widget _createContent() {
    if (widget.item.menuImage != null && widget.item.menuTitle != null) {
      // image and text
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Container(
            width: 30.0,
            height: 30.0,
            child: widget.item.menuImage,
          ),
          Container(
            height: 22.0,
            child: Material(
              color: Colors.transparent,
              child: Text(
                widget.item.menuTitle,
                style: widget.item.menuTextStyle,
              ),
            ),
          )
        ],
      );
    } else if (widget.item.menuImage != null) {
      // only image
      return Container(
        child: Center(
          child: widget.item.menuImage,
        ),
      );
    } else {
      // only text
      return Container(
        child: Center(
          child: Material(
            color: Colors.transparent,
            child: Text(
              widget.item.menuTitle,
              style: widget.item.menuTextStyle,
              textAlign: widget.item.menuTextAlign,
            ),
          ),
        ),
      );
    }
  }
}
