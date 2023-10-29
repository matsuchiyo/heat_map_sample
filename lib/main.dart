import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:heat_map_sample/google_map_controller_extension.dart';
import 'package:heat_map_sample/heat_map_view.dart';
import 'package:heat_map_sample/lat_lng_bounds_extension.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  static const mapPadding = EdgeInsets.zero;
  static const initialLocation = LatLng(37.3802798, -122.153151);

  late final List<WeightedLatLng> _mockData;

  final _controllerCompleter = Completer<GoogleMapController>();
  LatLngBounds? _visibleRegion;

  @override
  void initState() {
    super.initState();
    _mockData = _createMockData(initialLocation);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: SizedBox(
          width: 300,
          height: 300,
          child: Stack(
            children: [
              LayoutBuilder(
                builder: (context, constraint) {
                  return GoogleMap(
                    padding: mapPadding,
                    initialCameraPosition: const CameraPosition(
                      target: initialLocation,
                      zoom: 15,
                    ),
                    myLocationEnabled: true,
                    myLocationButtonEnabled: false,
                    onMapCreated: (controller) => _controllerCompleter.complete(controller),
                    buildingsEnabled: false,
                    indoorViewEnabled: false,
                    trafficEnabled: false,
                    zoomControlsEnabled: false,
                    onCameraMoveStarted: () {
                      setState(() {
                        _visibleRegion = null;
                      });
                    },
                    // (2) onCameraIdleで、ユーザーのスクロール完了を検知します。スクロール完了時のvisibleRegionで、ヒートマップに表示するデータを再取得するようにします。
                    onCameraIdle: () async {
                      final controller = await _controllerCompleter.future;
                      final visibleRegion = await controller.getVisibleRegionIncludingPadding(
                        googleMapSizeIncludingPadding: Size(constraint.maxWidth, constraint.maxHeight),
                        googleMapPadding: mapPadding,
                      );
                      setState(() {
                        _visibleRegion = visibleRegion;
                      });
                    },
                  );
                },
              ),
              _visibleRegion == null ? const SizedBox() : FutureBuilder(
                future: _getData(_visibleRegion!.center).then((weightedLatLngList) {
                  return _convertLatLngToPoint(weightedLatLngList, _visibleRegion!);
                }),
                builder: (context, snapshot) => !snapshot.hasData
                  ? const Center(
                    child: CircularProgressIndicator(),
                  )
                  // (1) 前編で実装したHeatMapViewをGoogleMapの手前に表示します。後ろ側にあるGoogleMapをスクロールできるようにIgnorePointerを使います。
                  : IgnorePointer(
                    child: HeatMapView(
                      points: snapshot.data!,
                      colors: const [
                        Color(0xff00ffff),
                        Color(0xff00ff00),
                        Color(0xffffff00),
                        Color(0xffff0000),
                      ],
                      opacity: 0.5,
                    ),
                  ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<List<WeightedLatLng>> _getData(LatLng location) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return _mockData;
  }

  List<WeightedPoint> _convertLatLngToPoint(List<WeightedLatLng> latLngList, LatLngBounds visibleRegion) {
    final regionWestLng = visibleRegion.southwest.longitude;
    final regionWidthInDegree = visibleRegion.widthInDegree;
    final regionNorthLat = visibleRegion.northeast.latitude;
    final regionHeightInDegree = visibleRegion.heightInDegree;
    return latLngList.map((latLng) {
      final lat = latLng.latitude;
      final lng = latLng.longitude;
      return WeightedPoint(
        ((lng - regionWestLng) % 360) / regionWidthInDegree, // % 360 してあげると、regionが東経〜西経だった場合でも、距離(in 経度)が求められる。
        (regionNorthLat - lat) / regionHeightInDegree,
        latLng.weight,
      );
    }).toList();
  }

  List<WeightedLatLng> _createMockData(LatLng location) {
    final random = Random(0);
    List<WeightedLatLng> result = [];
    for (int i = 0; i < 50; i++) {
      result.add(WeightedLatLng(
        location.latitude + (random.nextDouble() - 0.5) * 0.01,
        location.longitude + (random.nextDouble() - 0.5) * 0.01,
        random.nextDouble(),
      ));
    }
    return result;
  }
}

class WeightedLatLng {
  final double latitude;
  final double longitude;
  final double weight;
  WeightedLatLng(this.latitude, this.longitude, this.weight);
}