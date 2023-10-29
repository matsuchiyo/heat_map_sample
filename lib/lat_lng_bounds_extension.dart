
import 'package:google_maps_flutter/google_maps_flutter.dart';

extension LatLngBoundsExtension on LatLngBounds {
  LatLng get center => LatLng(
    (northeast.latitude + southwest.latitude) / 2,
    (northeast.longitude + southwest.longitude) / 2,
  );

  // 「% 360」はregionが東経〜西経だった場合のため。例: regionが東経150 ~ 西経150だったら、(-150 - 150) % 360 = 60となる。
  double get widthInDegree => (northeast.longitude - southwest.longitude) % 360;

  double get heightInDegree => (northeast.latitude - southwest.latitude);
}