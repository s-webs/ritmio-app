import 'package:flutter/material.dart';

import 'wave_loader.dart';

/// Pull-to-refresh wrapper that shows [WaveLoader] instead of the default spinner.
///
/// The [child] must be a scrollable widget (ListView, CustomScrollView, etc.)
/// that uses [AlwaysScrollableScrollPhysics] so notifications fire even when
/// the list is short.
class WaveRefresh extends StatefulWidget {
  const WaveRefresh({
    super.key,
    required this.onRefresh,
    required this.child,
  });

  final Future<void> Function() onRefresh;
  final Widget child;

  @override
  State<WaveRefresh> createState() => _WaveRefreshState();
}

class _WaveRefreshState extends State<WaveRefresh> {
  static const _triggerAt = 72.0;
  static const _maxDrag = 88.0;
  static const _loaderHeight = 64.0;

  double _drag = 0;
  bool _refreshing = false;

  Future<void> _doRefresh() async {
    if (_refreshing) return;
    setState(() {
      _refreshing = true;
      _drag = 0;
    });
    try {
      await widget.onRefresh();
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  bool _handleScroll(ScrollNotification n) {
    if (_refreshing) return false;

    // Android default (ClampingScrollPhysics)
    if (n is OverscrollNotification && n.overscroll < 0) {
      setState(() {
        _drag = (_drag + (-n.overscroll) * 0.55).clamp(0, _maxDrag);
      });
    }

    // iOS / BouncingScrollPhysics — pixels can go negative
    if (n is ScrollUpdateNotification &&
        n.dragDetails != null &&
        n.metrics.pixels < 1) {
      final delta = n.scrollDelta ?? 0;
      if (delta < 0) {
        setState(() {
          _drag = (_drag + (-delta) * 0.55).clamp(0, _maxDrag);
        });
      }
    }

    if (n is ScrollEndNotification) {
      if (_drag >= _triggerAt) {
        _doRefresh();
      } else if (_drag > 0) {
        setState(() => _drag = 0);
      }
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    final isActive = _refreshing || _drag > 0;

    final targetH = _refreshing
        ? _loaderHeight
        : (_drag / _triggerAt * _loaderHeight).clamp(0.0, _loaderHeight);

    final opacity = _refreshing
        ? 1.0
        : (_drag / _triggerAt).clamp(0.0, 1.0);

    return Column(
      children: [
        AnimatedContainer(
          duration: isActive
              ? Duration.zero
              : const Duration(milliseconds: 260),
          curve: Curves.easeOut,
          height: targetH,
          child: Center(
            child: Opacity(
              opacity: opacity,
              child: const WaveLoader(scale: 1.1),
            ),
          ),
        ),
        Expanded(
          child: NotificationListener<ScrollNotification>(
            onNotification: _handleScroll,
            child: widget.child,
          ),
        ),
      ],
    );
  }
}
