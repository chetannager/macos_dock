import 'dart:ui';

import 'package:flutter/material.dart';

/// Entrypoint of the application.
void main() {
  runApp(const MyApp());
}

/// [Widget] building the [MaterialApp].
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "MacOs Dock",
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.white,
        body: Container(
          alignment: Alignment.bottomCenter,
          margin: const EdgeInsets.only(bottom: 25.0),
          child: Dock(
            items: const [
              Icons.person,
              Icons.message,
              Icons.call,
              Icons.camera,
              Icons.photo,
            ],
            builder: (e, isHovered, isDragging,index,getTranslationY,getScaledSize) {
              return AnimatedScale(
                duration: const Duration(milliseconds: 200),
                scale: isHovered ? 1.4 : (isDragging ? 1.2 : 1.0),
                child: AnimatedContainer(
                  duration: const Duration(
                    milliseconds: 300,
                  ),
                  transform: Matrix4.identity()
                    ..translate(
                      0.0,
                      getTranslationY(index),
                      0.0,
                    ),
                  //height: getScaledSize(index),
                  //width: getScaledSize(index),
                  height:48,
                  constraints: const BoxConstraints(minWidth: 48),
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color:
                        Colors.primaries[e.hashCode % Colors.primaries.length],
                    boxShadow: isHovered
                        ? [
                            const BoxShadow(
                              color: Colors.black26,
                              blurRadius: 12,
                              offset: Offset(0, 8),
                            ),
                          ]
                        : [],
                  ),
                  child: Center(child: Icon(e, color: Colors.white)),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Dock of draggable [items].
class Dock<T extends Object> extends StatefulWidget {
  const Dock({
    super.key,
    this.items = const [],
    required this.builder,
  });

  /// Initial [T] items to put in this [Dock].
  final List<T> items;

  /// Builder building the provided [T] item with states.
  final Widget Function(T, bool isHovered, bool isDragging,int index,dynamic getTranslationY,dynamic getScaledSize) builder;

  @override
  State<Dock<T>> createState() => _DockState<T>();
}

/// State of the [Dock] used to manipulate [_items].
class _DockState<T extends Object> extends State<Dock<T>> {
  /// [T] items being manipulated.
  late final List<T> _items = widget.items.toList();

  /// Tracks the currently dragging item.
  T? _draggedItem;

  /// Tracks the original index of the dragging item.
  int? _draggedIndex;

  late int? hoveredIndex;
  late double baseItemHeight;
  late double baseTranslationY;
  late double verticalItemsPadding;

  double getScaledSize(int index) {
    return getPropertyValue(
      index: index,
      baseValue: baseItemHeight,
      maxValue: 70,
      nonHoveredMaxValue: 50,
    );
  }

  double getTranslationY(int index) {
    return getPropertyValue(
      index: index,
      baseValue: baseTranslationY,
      maxValue: -22,
      nonHoveredMaxValue: -14,
    );
  }

  double getPropertyValue({
    required int index,
    required double baseValue,
    required double maxValue,
    required double nonHoveredMaxValue,
  }) {
    late final double propertyValue;

    // 1.
    if (hoveredIndex == null) {
      return baseValue;
    }

    // 2.
    final difference = (hoveredIndex! - index).abs();

    // 3.
    final itemsAffected = _items.length;

    // 4.
    if (difference == 0) {
      propertyValue = maxValue;

      // 5.
    } else if (difference <= itemsAffected) {
      final ratio = (itemsAffected - difference) / itemsAffected;

      propertyValue = lerpDouble(baseValue, nonHoveredMaxValue, ratio)!;

      // 6.
    } else {
      propertyValue = baseValue;
    }

    return propertyValue;
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    hoveredIndex = null;
    baseItemHeight = 48;

    //verticalItemsPadding = 10;
    baseTranslationY = 0.0;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.black12,
      ),
      padding: const EdgeInsets.all(8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int i = 0; i <= _items.length; i++) ...[
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: DragTarget<T>(
                onWillAccept: (_) => true,
                onAccept: (data) {
                  setState(() {
                    _items.insert(i, data);
                    _draggedItem = null;
                    _draggedIndex = null;
                  });
                },
                builder: (context, candidateData, rejectedData) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 100),
                    width: candidateData.isNotEmpty ? 56 : 16,
                    height: 48,
                  );
                },
              ),
            ),
            if (i < _items.length)
              Draggable<T>(
                data: _items[i],
                dragAnchorStrategy: pointerDragAnchorStrategy,
                feedback: Transform.scale(
                  scale: 1.2,
                  child: widget.builder(_items[i], false, true,i,getTranslationY,getScaledSize),
                ),
                onDragStarted: () {
                  setState(() {
                    _draggedItem = _items[i];
                    _draggedIndex = i;
                    _items.removeAt(i);
                  });
                },
                onDragEnd: (details) {
                  setState(() {
                    if (_draggedItem != null && _draggedIndex != null) {
                      _items.insert(_draggedIndex!, _draggedItem!);
                    }
                    _draggedItem = null;
                    _draggedIndex = null;
                  });
                },
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  onEnter: ((event) {
                    setState(() {
                      hoveredIndex = i;
                    });
                  }),
                  onExit: (event) {
                    setState(() {
                      hoveredIndex = null;
                    });
                  },
                  child: DragTarget<T>(
                    onWillAccept: (_) => false,
                    builder: (context, candidateData, rejectedData) {
                      return widget.builder(_items[i], false, false,i,getTranslationY,getScaledSize);
                    },
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
