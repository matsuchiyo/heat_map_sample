
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:heat_map_sample/lat_lng_bounds_extension.dart';

extension GoogleMapControllerExtension on GoogleMapController {
  Future<LatLngBounds> getVisibleRegionIncludingPadding({
    required Size googleMapSizeIncludingPadding,
    required EdgeInsets? googleMapPadding,
  }) async {


    // 緯度の差分、経度の差分を、画面上の長さに換算して計算する。Google Mapsはメルカトル図法のようなので、この方法で問題ないはず。
    // ↓ iOS Maps SDKのdocumentには記述が見当たらなかったが、Javascript APIには、メルカトル図法がデフォルトとの記述があった。
    // This example creates a map using the Gall-Peters projection, rather than the default Mercator projection.
    // https://developers.google.com/maps/documentation/javascript/examples/map-projection-simple

    final visibleRegion = await getVisibleRegion();
    if (googleMapPadding == null) return visibleRegion;

    final googleMapSizeWithoutPadding = Size(
      googleMapSizeIncludingPadding.width - (googleMapPadding.left + googleMapPadding.right),
      googleMapSizeIncludingPadding.height - (googleMapPadding.top + googleMapPadding.bottom),
    );

    final topPaddingInDegree = googleMapPadding.top * visibleRegion.heightInDegree / googleMapSizeWithoutPadding.height;
    final bottomPaddingInDegree = googleMapPadding.bottom * visibleRegion.heightInDegree / googleMapSizeWithoutPadding.height;
    final leftPaddingInDegree = googleMapPadding.left * visibleRegion.widthInDegree / googleMapSizeWithoutPadding.width;
    final rightPaddingInDegree = googleMapPadding.right * visibleRegion.widthInDegree / googleMapSizeWithoutPadding.width;

    final southwestLng = visibleRegion.southwest.longitude - leftPaddingInDegree;
    final fixedSouthwestLng = southwestLng >= -180 ? southwestLng : (southwestLng + 360); // 西経170(-170) - 20 = 西経190(-190) = 東経170

    final northeastLng = visibleRegion.northeast.longitude + rightPaddingInDegree;
    final fixedNortheastLng = northeastLng <= 180 ? northeastLng : (northeastLng - 360); // 東経170 + 20 = 東経 190 = 西経170(-170)

    return LatLngBounds(
      southwest: LatLng(
        visibleRegion.southwest.latitude - bottomPaddingInDegree,
        fixedSouthwestLng,
      ),
      northeast: LatLng(
        visibleRegion.northeast.latitude + topPaddingInDegree,
        fixedNortheastLng,
      ),
    );
  }
}