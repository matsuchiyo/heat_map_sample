
import 'package:google_maps_flutter/google_maps_flutter.dart';

extension LatLngBoundsExtension on LatLngBounds {
  LatLng get center => LatLng(
    (northeast.latitude + southwest.latitude) / 2,
    (northeast.longitude + southwest.longitude) / 2,
  );
}