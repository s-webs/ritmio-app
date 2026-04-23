import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class WaveLoader extends StatefulWidget {
  const WaveLoader({super.key, this.scale = 1.5});

  /// Scale relative to the original SVG size (73 × 42).
  final double scale;

  @override
  State<WaveLoader> createState() => _WaveLoaderState();
}

class _WaveLoaderState extends State<WaveLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  static const _svgW = 73.0;
  static const _svgH = 42.0;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = _svgW * widget.scale;
    final h = _svgH * widget.scale;

    return ShaderMask(
      shaderCallback: (bounds) => const LinearGradient(
        colors: [Colors.transparent, Colors.white, Colors.white, Colors.transparent],
        stops: [0.0, 0.18, 0.82, 1.0],
      ).createShader(bounds),
      blendMode: BlendMode.dstIn,
      child: SizedBox(
        width: w,
        height: h,
        child: ClipRect(
          child: AnimatedBuilder(
            animation: _ctrl,
            builder: (_, child) {
              final offset = _ctrl.value * w;
              return Stack(
                children: [
                  Positioned(left: -offset, top: 0, width: w, height: h, child: child!),
                  Positioned(left: w - offset, top: 0, width: w, height: h, child: child),
                ],
              );
            },
            child: SvgPicture.asset(
              'assets/images/wave.svg',
              width: w,
              height: h,
            ),
          ),
        ),
      ),
    );
  }
}
