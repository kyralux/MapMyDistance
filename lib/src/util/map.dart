import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:mapgoal/src/data/goal.dart';
import 'package:flutter_map_math/flutter_geo_math.dart';
import 'package:mapgoal/src/util/goals.dart';

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

  Widget getMap(LatLng coordinates) {
    return Flexible(
        flex: 10,
        child: FlutterMap(
          mapController: _mapController,
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

  LatLng calculateUserPosition(Goal curGoal) {
    // double bearing = FlutterMapMath().bearingBetween(
    //   curGoal.latStart,
    //   curGoal.longStart,
    //   curGoal.latEnd,
    //   curGoal.longEnd,
    // );

    // LatLng destinationPoint = FlutterMapMath().destinationPoint(
    //     curGoal.latStart,
    //     curGoal.longStart,
    //     curGoal.curDistance * 1000,
    //     bearing);

    double percentage = curGoal.curDistance / curGoal.totalDistance;
    double userLat =
        curGoal.latStart + (curGoal.latEnd - curGoal.latStart) * percentage;
    double userLong =
        curGoal.longStart + (curGoal.longEnd - curGoal.longStart) * percentage;

    return LatLng(userLat, userLong);
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
        child: const Icon(Icons.person, color: Colors.black)));
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
