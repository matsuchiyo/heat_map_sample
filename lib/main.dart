import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
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
  LatLng? _visibleRegionCenter;

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
                        _visibleRegionCenter = null;
                      });
                    },
                    // (2) onCameraIdleで、ユーザーのスクロール完了を検知します。スクロール完了時のvisibleRegionで、ヒートマップに表示するデータを再取得するようにします。
                    onCameraIdle: () async {
                      final controller = await _controllerCompleter.future;
                      final visibleRegion = await controller.getVisibleRegion();
                      setState(() {
                        _visibleRegionCenter = visibleRegion.center;
                      });
                    },
                  );
                },
              ),
              _visibleRegionCenter == null ? const SizedBox() : FutureBuilder(
                future: _getData(_visibleRegionCenter!).then((weightedLatLngList) {
                  return _controllerCompleter.future.then((controller) {
                    return _convertLatLngListToPointList(weightedLatLngList, controller);
                  });
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

  Future<List<WeightedPoint>> _convertLatLngListToPointList(List<WeightedLatLng> latLngList, GoogleMapController controller) {
    return latLngList.map((latLng) => _convertLatLngToPoint(latLng, controller))
        .toList()
        .wait;
  }

  Future<WeightedPoint> _convertLatLngToPoint(WeightedLatLng latLng, GoogleMapController controller) async {
    final screenCoordinate = await controller.getScreenCoordinate(LatLng(latLng.latitude, latLng.longitude));
    return WeightedPoint(
      screenCoordinate.x.toDouble(),
      screenCoordinate.y.toDouble(),
      latLng.weight,
    );
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