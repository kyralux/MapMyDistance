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

  void drawMap(BuildContext context, LatLng coordinates, Goal goal) {
    markers.addAll([
      Marker(
          point: LatLng(goal.latStart, goal.longStart),
          child: Icon(Icons.fiber_manual_record,
              color: Theme.of(context).colorScheme.secondary)),
      Marker(
          point: LatLng(goal.latEnd, goal.longEnd),
          child:
              Icon(Icons.flag, color: Theme.of(context).colorScheme.secondary)),
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
    ], color: Theme.of(context).colorScheme.tertiary, strokeWidth: 4.0));
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
    return Flexible(
        flex: 10,
        child: FlutterMap(
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
        ));
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

  void updateMap(BuildContext context, GoalHandler goalHandler, Goal newValue) {
    markers.clear();
    polylines.clear();
    var curGoalIndex = goalHandler.curGoalIndex;
    if (goalHandler.goallist.isNotEmpty) {
      print("update map");
      goalHandler.curGoalIndex =
          goalHandler.goallist.indexWhere((goal) => goal.id == newValue.id);
      goalHandler.updateCurGoal();
      LatLng coordinates = calculateUserPosition(goalHandler.curGoal);
      drawMap(context, coordinates, goalHandler.curGoal);
      try {
        _mapController.move(calculateUserPosition(newValue), zoomLevel);
      } catch (e) {
        return;
        // goalHandler;
      }

      return;
      // goalHandler;
    }
    goalHandler.curGoalIndex =
        0; // kann ich das anders machen als goal handler hier zu übergeben?
    return;

    ///goalHandler;
  }

  void updateUserMarker(BuildContext context, Goal goal) {
    LatLng coordinates = calculateUserPosition(goal);
    markers.removeLast();
    markers.add(Marker(
        point: coordinates,
        child: const Icon(Icons.person, color: Colors.black)));
    polylines.removeLast();
    polylines.add(Polyline(points: [
      LatLng(coordinates.latitude, coordinates.longitude),
      LatLng(goal.latStart, goal.longStart),
    ], color: Theme.of(context).colorScheme.tertiary, strokeWidth: 4.0));
    _mapController.move(coordinates, _mapController.camera.zoom);
  }
}
