/*
    Author: Jpeng
    Email: peng8350@gmail.com
    createTime:2018-05-14 15:39
 */

import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart';
import 'default_constants.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'refreshsliver.dart';

abstract class Wrapper extends StatefulWidget {
  final ValueNotifier<RefreshStatus> modeListener;

  final IndicatorBuilder builder;

  final bool up;

  final double triggerDistance;

  bool get _isRefreshing => this.mode == RefreshStatus.refreshing;

  bool get _isComplete =>
      this.mode != RefreshStatus.idle &&
      this.mode != RefreshStatus.refreshing &&
      this.mode != RefreshStatus.canRefresh;

  RefreshStatus get mode => this.modeListener.value;

  set mode(RefreshStatus mode) => this.modeListener.value = mode;

  Wrapper(
      {Key key,
      @required this.up,
      @required this.modeListener,
      this.builder,
      this.triggerDistance})
      : assert(up != null, modeListener != null),
        super(key: key);

  bool _isScrollToOutSide(ScrollNotification notification) {
    if (up) {
      if (notification.metrics.minScrollExtent - notification.metrics.pixels >
          0) {
        return true;
      }
    } else {
      if (notification.metrics.pixels - notification.metrics.maxScrollExtent >
          0) {
        return true;
      }
    }
    return false;
  }

}

//idle,refreshing,completed,failed,canRefresh
class RefreshWrapper extends Wrapper {
  final int completeDuration;

  final Function onOffsetChange;

  final double height;

  RefreshWrapper({
    Key key,
    IndicatorBuilder builder,
    ValueNotifier<RefreshStatus> modeLis,
    this.onOffsetChange,
    this.completeDuration: default_completeDuration,
    double triggerDistance: default_refresh_triggerDistance,
    this.height: default_height,
    bool up: true,
  })  : assert(up != null),
        super(
          up: up,
          key: key,
          modeListener: modeLis,
          builder: builder,
          triggerDistance: triggerDistance,
        );

  @override
  State<StatefulWidget> createState() {
    // TODO: implement createState
    return RefreshWrapperState();
  }
}

class RefreshWrapperState extends State<RefreshWrapper>
    with TickerProviderStateMixin
    implements GestureProcessor {

  bool hasLayout = false;

  RefreshStatus get mode => widget.modeListener.value;

  double _measure(ScrollNotification notification) {
    if (widget.up) {
      return (notification.metrics.minScrollExtent -
              notification.metrics.pixels) /
          widget.triggerDistance;
    } else {
      return (notification.metrics.pixels -
              notification.metrics.maxScrollExtent) /
          widget.triggerDistance;
    }
  }

  @override
  void onDragStart(ScrollStartNotification notification) {
    // TODO: implement onDragStart
  }

  @override
  void onDragMove(ScrollUpdateNotification notification) {
    // TODO: implement onDragMove
    if (!widget._isScrollToOutSide(notification)) {
      return;
    }
    if (widget._isComplete || widget._isRefreshing) return;

    double offset = _measure(notification);
    if (offset >= 1.0) {
      widget.mode = RefreshStatus.canRefresh;
    } else{
      widget.mode = RefreshStatus.idle;
    }
  }

  @override
  void onDragEnd(ScrollNotification notification) {
    // TODO: implement onDragEnd
    if (!widget._isScrollToOutSide(notification)) {
      return;
    }
    if (widget._isComplete || widget._isRefreshing) return;
    bool reachMax = _measure(notification) >= 1.0;
    if(reachMax) {
      widget.mode = RefreshStatus.refreshing;
    }
  }


  void _handleModeChange() {

    switch (mode) {
      case RefreshStatus.refreshing:
        hasLayout = true;
        setState(() {});
        break;
      case RefreshStatus.completed:
        Future.delayed(Duration(milliseconds: widget.completeDuration), () {
          hasLayout = false;

          setState(() {});
        });
        break;
      case RefreshStatus.failed:
        Future.delayed(Duration(milliseconds: widget.completeDuration), () {
          hasLayout = false;
          setState(() {});
        });
        break;
      default:
        break;
    }

  }

  @override
  void dispose() {
    // TODO: implement dispose
    widget.modeListener.removeListener(_handleModeChange);
    super.dispose();
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    widget.modeListener.addListener(_handleModeChange);
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    if (widget.up) {
      return SliverRefresh(
        hasLayoutExtent: hasLayout,
        refreshIndicatorLayoutExtent: widget.height,
        refreshStyle: RefreshStyle.Follow,
        up: widget.up,
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
              return widget.builder(
                context,widget.mode
              );
          },
        ),
      );
    }
//    return Column(
//      children: <Widget>[
//        SliverRefresh(
//          child: widget.builder(context, widget.mode,),
//          refreshStyle: RefreshStyle.Follow,
//          up: false,
//        ),
//        SliverToBoxAdapter(child: SizeTransition(
//          sizeFactor: _sizeController,
//          child: Container(height: widget.height),
//        ),)
//
//      ],
//    );
  }
}

//status: failed,nomore,idle,refreshing
class LoadWrapper extends Wrapper {
  final bool autoLoad;

  LoadWrapper(
      {Key key,
      @required bool up,
      @required ValueNotifier<RefreshStatus> modeListener,
      double triggerDistance: default_load_triggerDistance,
      this.autoLoad,
      IndicatorBuilder builder})
      : assert(up != null, modeListener != null),
        super(
          key: key,
          up: up,
          builder: builder,
          modeListener: modeListener,
          triggerDistance: triggerDistance,
        );

  @override
  State<StatefulWidget> createState() {
    // TODO: implement createState
    return LoadWrapperState();
  }
}

class LoadWrapperState extends State<LoadWrapper> implements GestureProcessor {
  Function _updateListener;

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return SliverToBoxAdapter(child: widget.builder(context, widget.mode),);
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _updateListener = () {
      setState(() {});
    };
    widget.modeListener.addListener(_updateListener);
  }

  @override
  void dispose() {
    // TODO: implement dispose
    widget.modeListener.removeListener(_updateListener);
    super.dispose();
  }

  @override
  void onDragStart(ScrollStartNotification notification) {
    // TODO: implement onDragStart
  }

  @override
  void onDragMove(ScrollUpdateNotification notification) {
    // TODO: implement onDragMove
//    if (!widget._isScrollToOutSide(notification)) {
//      return;
//    }
    if (widget._isRefreshing || widget._isComplete) return;
    if (widget.autoLoad) {
      if (widget.up &&
          notification.metrics.extentBefore <= widget.triggerDistance &&
          notification.scrollDelta < 1.0)
        widget.mode = RefreshStatus.refreshing;
      if (!widget.up &&
          notification.metrics.extentAfter <= widget.triggerDistance &&
          notification.scrollDelta > 1.0)
        widget.mode = RefreshStatus.refreshing;
    }
  }

  @override
  void onDragEnd(ScrollNotification notification) {
    // TODO: implement onDragEnd
    if (widget._isRefreshing || widget._isComplete) return;
    if (widget.autoLoad) {
      if (widget.up &&
          notification.metrics.extentBefore <= widget.triggerDistance)
        widget.mode = RefreshStatus.refreshing;
      if (!widget.up &&
          notification.metrics.extentAfter <= widget.triggerDistance)
        widget.mode = RefreshStatus.refreshing;
    }
  }
}

abstract class GestureProcessor {
  void onDragStart(ScrollStartNotification notification);

  void onDragMove(ScrollUpdateNotification notification);

  void onDragEnd(ScrollNotification notification);
}


