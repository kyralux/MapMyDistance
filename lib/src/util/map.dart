import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:mapgoal/src/data/goal.dart';
import 'package:flutter_map_math/flutter_geo_math.dart';
import 'package:mapgoal/src/util/goals.dart';
import 'dart:math';

class MapUtils {
  List<Marker> markers = [];
  List<Polyline> polylines = [];
  double zoomLevel = 5.0;

  final MapController _mapController = MapController();

  void drawMap(LatLng coordinates, Goal goal, ColorScheme colors) {
    markers.addAll([
      Marker(
          point: LatLng(goal.latStart, goal.longStart),
          child: Icon(Icons.fiber_manual_record, color: colors.secondary)),
      Marker(
          point: LatLng(goal.latEnd, goal.longEnd),
          child: Icon(Icons.flag, color: colors.secondary)),
      Marker(
          point: coordinates,
          child: const Icon(Icons.person, color: Colors.black))
    ]);

    polylines.add(Polyline(points: [
      LatLng(goal.latEnd, goal.longEnd),
      LatLng(goal.latStart, goal.longStart),
    ], color: Colors.grey, strokeWidth: 4.0));
    polylines.add(Polyline(points: [
      LatLng(coordinates.latitude, coordinates.longitude),
      LatLng(goal.latStart, goal.longStart),
    ], color: colors.tertiary, strokeWidth: 4.0));
  }

  Widget getMap(LatLng coordinates, bool isDarkMode) {
    var url = isDarkMode
        ? "https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png"
        : "https://tile.openstreetmap.org/{z}/{x}/{y}.png";

    return Flexible(
        flex: 10,
        child: FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            backgroundColor: Colors.black,
            minZoom: 1.0,
            maxZoom: 20.0,
            interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag),
            initialCenter: coordinates,
            initialZoom: validateZoomLevel(zoomLevel),
          ),
          children: [
            TileLayer(
              urlTemplate: url,
              userAgentPackageName: 'dev.fleaflet.flutter_map.example',
            ),
            PolylineLayer(polylines: polylines),
            MarkerLayer(markers: markers),
          ],
        ));
  }

  Widget getLocationPickerMap(LatLng coordinates, MapController mapController) {
    return Stack(
      children: [
        // Flexible(
        //   flex: 10,
        // child:
        FlutterMap(
          mapController: mapController,
          options: MapOptions(
            minZoom: 1.0,
            maxZoom: 20.0,
            interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag),
            initialCenter: coordinates,
            initialZoom: validateZoomLevel(zoomLevel),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'dev.fleaflet.flutter_map.example',
            ),
          ],
        ),
        const Center(
          child: Icon(
            Icons.location_pin,
            size: 50,
            color: Colors.red,
          ),
        ) //,),
        // mapUtils.getLocationPickerMap(
        //   goalHandler.goallist.isNotEmpty
        //       ? LatLng(goalHandler.curGoal.latStart,
        //           goalHandler.curGoal.longStart)
        //       : const LatLng(49.843, 9.902056),
        //   _mapControllerDialog, //center of EU apparently,
        // ),
      ],
    );
  }

  double validateZoomLevel(double zoom) {
    if (zoom.isNaN || zoom.isInfinite || zoom < 0) {
      return 5.0;
    }
    return zoom;
  }

// // Convert degrees to radians
//   double toRadians(double degrees) {
//     return degrees * pi / 180;
//   }

// // Convert radians to degrees
//   double toDegrees(double radians) {
//     return radians * 180 / pi;
//   }

// // Haversine formula to calculate the total distance between two points
//   double haversineDistance(double lat1, double lon1, double lat2, double lon2) {
//     const double R = 6371; // Radius of the Earth in kilometers
//     double dLat = toRadians(lat2 - lat1);
//     double dLon = toRadians(lon2 - lon1);
//     lat1 = toRadians(lat1);
//     lat2 = toRadians(lat2);

//     double a = sin(dLat / 2) * sin(dLat / 2) +
//         cos(lat1) * cos(lat2) * sin(dLon / 2) * sin(dLon / 2);
//     double c = 2 * atan2(sqrt(a), sqrt(1 - a));

//     return R * c; // Distance in kilometers
//   }

// // Spherical interpolation (Slerp) to find the intermediate point
//   LatLng sphericalInterpolate(
//       double lat1, double lon1, double lat2, double lon2, double fraction) {
//     lat1 = toRadians(lat1);
//     lon1 = toRadians(lon1);
//     lat2 = toRadians(lat2);
//     lon2 = toRadians(lon2);

//     // Calculate the angular distance between the points
//     double angularDistance =
//         haversineDistance(lat1, lon1, lat2, lon2) / 6371; // in radians

//     double sinAngularDistance = sin(angularDistance);

//     if (sinAngularDistance == 0) {
//       // The points are the same
//       return LatLng(lat1, lon1);
//     }

//     // Slerp (spherical linear interpolation) formula
//     double A = sin((1 - fraction) * angularDistance) / sinAngularDistance;
//     double B = sin(fraction * angularDistance) / sinAngularDistance;

//     double x = A * cos(lat1) * cos(lon1) + B * cos(lat2) * cos(lon2);
//     double y = A * cos(lat1) * sin(lon1) + B * cos(lat2) * sin(lon2);
//     double z = A * sin(lat1) + B * sin(lat2);

//     double newLat = atan2(z, sqrt(x * x + y * y));
//     double newLon = atan2(y, x);

//     return {'lat': toDegrees(newLat), 'lon': toDegrees(newLon)};
//   }

//   double calculateBearing(double lat1, double lon1, double lat2, double lon2) {
//     double phi1 = lat1 * (pi / 180);
//     double phi2 = lat2 * (pi / 180);
//     double delta = (lon2 - lon1) * (pi / 180);

//     double y = sin(delta) * cos(phi2);
//     double x = cos(phi1) * sin(phi2) - sin(phi1) * cos(phi2) * cos(delta);

//     double bearing = atan2(y, x);

//     bearing = bearing * (180 / pi);

//     return (bearing + 360) % 360;
//   }
// Convert degrees to radians
  double toRadians(double degrees) {
    return degrees * pi / 180;
  }

// Convert radians to degrees
  double toDegrees(double radians) {
    return radians * 180 / pi;
  }

// Haversine formula to calculate the total distance between two points
  double haversineDistance(double lat1, double lon1, double lat2, double lon2) {
    const double R = 6371; // Radius of the Earth in kilometers
    double dLat = toRadians(lat2 - lat1);
    double dLon = toRadians(lon2 - lon1);
    lat1 = toRadians(lat1);
    lat2 = toRadians(lat2);

    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1) * cos(lat2) * sin(dLon / 2) * sin(dLon / 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return R * c; // Distance in kilometers
  }

// Vincenty formula to calculate the destination point given a start point, bearing, and distance
  LatLng vincentyDestination(
      double lat1, double lon1, double bearing, double distance) {
    const double R = 6371; // Radius of Earth in kilometers
    double angularDistance = distance / R; // Angular distance in radians

    lat1 = toRadians(lat1);
    lon1 = toRadians(lon1);
    bearing = toRadians(bearing);

    double lat2 = asin(sin(lat1) * cos(angularDistance) +
        cos(lat1) * sin(angularDistance) * cos(bearing));
    double lon2 = lon1 +
        atan2(sin(bearing) * sin(angularDistance) * cos(lat1),
            cos(angularDistance) - sin(lat1) * sin(lat2));

    // Convert results back to degrees
    lat2 = toDegrees(lat2);
    lon2 = toDegrees(lon2);

    return LatLng(
        lat2, (lon2 + 540) % 360 - 180); // Normalize lon to -180...180
  }

// Function to calculate the initial bearing between two points
  double calculateBearing(double lat1, double lon1, double lat2, double lon2) {
    lat1 = toRadians(lat1);
    lat2 = toRadians(lat2);
    double dLon = toRadians(lon2 - lon1);

    double y = sin(dLon) * cos(lat2);
    double x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon);
    double bearing = atan2(y, x);

    return (toDegrees(bearing) + 360) % 360; // Normalize to 0-360 degrees
  }

  LatLng calculateUserPosition(Goal curGoal) {
    // double bearing = calculateBearing(
    //   curGoal.latStart,
    //   curGoal.longStart,
    //   curGoal.latEnd,
    //   curGoal.longEnd,
    // );

    double initialBearing = calculateBearing(
      curGoal.latStart,
      curGoal.longStart,
      curGoal.latEnd,
      curGoal.longEnd,
    );
    LatLng destinationPoint = vincentyDestination(curGoal.latStart,
        curGoal.longStart, initialBearing, curGoal.curDistance);
    double percentage = curGoal.curDistance / curGoal.totalDistance;
    double userLat =
        curGoal.latStart + (curGoal.latEnd - curGoal.latStart) * percentage;
    double userLong =
        curGoal.longStart + (curGoal.longEnd - curGoal.longStart) * percentage;

    return destinationPoint; // LatLng(userLat, userLong);
  }

  double calculateDistanceGoal(Goal curGoal) {
    return FlutterMapMath().distanceBetween(curGoal.latStart, curGoal.longStart,
        curGoal.latEnd, curGoal.longEnd, "kilometers");
  }

  double calculateDistance(lat1, lon1, lat2, lon2) {
    return FlutterMapMath()
        .distanceBetween(lat1, lon1, lat2, lon2, "kilometers");
  }

  double convertKilometerMiles(double distance) {
    return (distance * 1000) / 1609.344;
  }

  void updateMap(GoalHandler goalHandler, Goal newValue, ColorScheme colors) {
    markers.clear();
    polylines.clear();
    if (goalHandler.goallist.isNotEmpty) {
      goalHandler.curGoalIndex =
          goalHandler.goallist.indexWhere((goal) => goal.id == newValue.id);
      goalHandler.updateCurGoal();
      LatLng coordinates = calculateUserPosition(goalHandler.curGoal);
      drawMap(coordinates, goalHandler.curGoal, colors);
      try {
        _mapController.move(calculateUserPosition(newValue), zoomLevel);
      } catch (e) {
        return;
      }
      return;
    }
    goalHandler.curGoalIndex = 0;
    return;
  }

  void updateUserMarker(Goal goal, ColorScheme colors) {
    LatLng coordinates = calculateUserPosition(goal);
    markers.removeLast();
    markers.add(Marker(
        point: coordinates,
        child: Icon(Icons.person, color: colors.onSurface)));
    polylines.removeLast();
    polylines.add(Polyline(points: [
      LatLng(coordinates.latitude, coordinates.longitude),
      LatLng(goal.latStart, goal.longStart),
    ], color: colors.tertiary, strokeWidth: 4.0));

    try {
      _mapController.move(coordinates, _mapController.camera.zoom);
    } catch (e) {
      print(e);
    }
  }

  void disposeController() {
    _mapController.dispose();
  }
}
