

import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:image/image.dart' as img;

class HeatMapView extends StatefulWidget {
  final List<WeightedPoint> points;
  final List<Color> colors;
  final double opacity;

  const HeatMapView({
    super.key,
    required this.points,
    required this.colors,
    required this.opacity,
  });

  @override
  State<HeatMapView> createState() => _HeatMapState();
}

class _HeatMapState extends State<HeatMapView> {
  static const countOfColorsOfGradation = 100;
  static const blurRadius = 10;

  late List<Color> _colorsOfGradation;

  @override
  void initState() {
    super.initState();
    _colorsOfGradation = _createColorsOfGradation(widget.colors, countOfColorsOfGradation);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraint) {
        final maxHeight = constraint.maxHeight;
        final maxWidth = constraint.maxWidth;
        return FutureBuilder(
          future: _generateHeatMapImageBytes(widget.points, maxWidth.toInt(), maxHeight.toInt(), _colorsOfGradation)
            .catchError((error, stack) {
              print('***** error: $error, stack: $stack');
              return [];
            }),
          builder: (context, snapshot) {
            return !snapshot.hasData ? SizedBox(width: maxWidth, height: maxHeight) : Opacity(
              opacity: widget.opacity,
              child: Image.memory(
                snapshot.data!,
                width: maxWidth,
                height: maxHeight,
              ),
            );
          },
        );
      },
    );
  }

  List<Color> _createColorsOfGradation(List<Color> srcColors, int count) {
    if (srcColors.length < 2) throw 'Invalid arguments';
    List<Color> results = [];
    for (int i = 0; i < count; i++) {
      final countPer1Gradation = (count / (srcColors.length - 1)).ceil();
      final color1Index = (i / countPer1Gradation).floor();
      final color1 = srcColors[color1Index];
      final color2 = srcColors[color1Index + 1];
      final double color2Weight = (i % countPer1Gradation) / countPer1Gradation;
      final resultColor = Color.fromARGB(
        (color1.alpha * (1.0 - color2Weight) + color2.alpha * color2Weight).toInt(),
        (color1.red * (1.0 - color2Weight) + color2.red * color2Weight).toInt(),
        (color1.green * (1.0 - color2Weight) + color2.green * color2Weight).toInt(),
        (color1.blue * (1.0 - color2Weight) + color2.blue * color2Weight).toInt(),
      );
      results.add(resultColor);
    }
    return results;
  }

  Future<Uint8List> _generateHeatMapImageBytes(List<WeightedPoint> data, int width, int height, List<Color> colorsOfGradation) async {
    final img.Image image = img.Image(
      width: width,
      height: height,
      numChannels: 1,
    );

    for (final point in data) {
      final x = point.x.toInt();
      final y = point.y.toInt();
      if (x < 0 || x >= width || y < 0 || y >= height) continue;

      final oldPixel = image.getPixel(x, y);

      final color = img.ColorInt8(1)
        ..rNormalized = min(1.0, oldPixel.rNormalized + point.weight);

      // image.setPixel(x, y, color);

      const circleRadius = blurRadius * 2 + 1;
      img.fillCircle(image, x: x, y: y, radius: circleRadius, color: color);
    }

    final blurredImage = img.gaussianBlur(image, radius: blurRadius);

    final img.Image resultImage = img.Image(width: width, height: height, numChannels: 4);
    for (int i = 0; i < width; i++) {
      for (int j = 0; j < height; j++) {
        final oldPixel = blurredImage.getPixel(i, j);
        final value = oldPixel.rNormalized;
        if (value > 0) {
          final colorIndex = min(100 - 1, value * 100).floor();
          final color = colorsOfGradation[colorIndex];
          resultImage.setPixelRgba(i, j, color.red, color.green, color.blue, color.alpha);
        }
      }
    }
    return img.encodePng(resultImage);
  }
}

class WeightedPoint {
  final double x; // 0.0 <= x <= 1.0
  final double y; // 0.0 <= y <= 1.0
  final double weight; // 0.0 <= weight <= 1.0
  WeightedPoint(this.x, this.y, this.weight);
}