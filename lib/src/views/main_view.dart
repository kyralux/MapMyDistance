import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:math' show cos, sqrt, asin;

import 'package:percent_indicator/percent_indicator.dart';

import 'package:mapgoal/src/settings/settings_view.dart';
import 'package:mapgoal/src/data/goal.dart';

import 'package:mapgoal/src/storage/database_helper.dart';

class GoalListView extends StatefulWidget {
  const GoalListView({super.key});
  static const routeName = '/';

  @override
  State<GoalListView> createState() => _GoalListViewState();
}

class _GoalListViewState extends State<GoalListView> {
  List<Goal> goallist = [];
  int curGoalIndex = 0;
  final MapController _mapController = MapController();
  final MapController _mapControllerDialog = MapController();
  List<Marker> markers = [];
  List<Polyline> polylines = [];
  double zoomLevel = 5.0;
  double calculatedDistance = 0.0;

  @override
  void initState() {
    loadGoalList();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(
            'Goals',
            style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
          ),
          backgroundColor: Theme.of(context).primaryColor,
          actions: [
            IconButton(
              icon: const Icon(Icons.settings),
              color: Theme.of(context).colorScheme.onPrimary,
              onPressed: () {
                Navigator.restorablePushNamed(context, SettingsView.routeName);
              },
            ),
          ],
        ),
        body: buildView());
  }

  LatLng calculateUserPosition(Goal curGoal) {
    double percentage = curGoal.curDistance / curGoal.totalDistance;
    double userLat =
        curGoal.latStart + (curGoal.latEnd - curGoal.latStart) * percentage;
    double userLong =
        curGoal.longStart + (curGoal.longEnd - curGoal.longStart) * percentage;

    return LatLng(userLat, userLong);
  }

  double calculateDistanceGoal(Goal curGoal) {
    var p = 0.017453292519943295;
    var a = 0.5 -
        cos((curGoal.latEnd - curGoal.latStart) * p) / 2 +
        cos(curGoal.latStart * p) *
            cos(curGoal.latEnd * p) *
            (1 - cos((curGoal.longEnd - curGoal.longStart) * p)) /
            2;
    return 12742 * asin(sqrt(a));
  }

  double calculateDistance(lat1, lon1, lat2, lon2) {
    var p = 0.017453292519943295;
    var c = cos;
    var a = 0.5 -
        c((lat2 - lat1) * p) / 2 +
        c(lat1 * p) * c(lat2 * p) * (1 - c((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a));
  }

  Widget buildView() {
    return goallist.isNotEmpty
        ? Column(
            children: [
              Expanded(
                  child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.max,
                children: [
                  goallist.isNotEmpty
                      ? DropdownButton(
                          value: goallist[curGoalIndex],
                          icon: const Icon(Icons.keyboard_arrow_down),
                          items: goallist.map((Goal item) {
                            return DropdownMenuItem(
                              value: item,
                              child: Text(item.name),
                            );
                          }).toList(),
                          onChanged: (Goal? newGoal) {
                            setState(() {
                              updateMap(newGoal);
                            });
                            _mapController.move(
                                LatLng(goallist[curGoalIndex].latStart,
                                    goallist[curGoalIndex].longStart),
                                zoomLevel);
                          },
                        )
                      : const Text('Keine Goals bisher'),
                  FloatingActionButton(
                    onPressed: () {
                      showPopup(context, null);
                    },
                    heroTag: 'addButton',
                    backgroundColor: Theme.of(context).colorScheme.secondary,
                    child: Icon(
                      Icons.add,
                      color: Theme.of(context).colorScheme.onSecondary,
                    ),
                  ),
                  FloatingActionButton(
                    onPressed: () {
                      showDeleteConfirmationPopUp(
                          context, goallist[curGoalIndex]);
                    },
                    heroTag: 'deleteButton',
                    backgroundColor: Theme.of(context).colorScheme.secondary,
                    child: Icon(
                      Icons.delete,
                      color: Theme.of(context).colorScheme.onSecondary,
                    ),
                  ),
                ],
              )),
              goallist[curGoalIndex].description.isNotEmpty
                  ? Text(goallist[curGoalIndex].description)
                  : Container(),
              Flexible(
                flex: 10,
                child: getMap(goallist[curGoalIndex]),
              ),
              LinearPercentIndicator(
                lineHeight: 14.0,
                percent: goallist[curGoalIndex].curDistance /
                    goallist[curGoalIndex].totalDistance,
                backgroundColor: Colors.black,
                progressColor: Colors.pink,
              ),
              Row(
                children: [
                  FilledButton(
                      onPressed: () {
                        showWorkoutPopup(context, null);
                      },
                      child: const Text("KM adden")),
                  Column(
                    children: [
                      Text(
                          "Remaining: ${double.parse((goallist[curGoalIndex].totalDistance - goallist[curGoalIndex].curDistance).toStringAsFixed(2))} km"),
                      Text(
                          "Schon geschafft: ${goallist[curGoalIndex].curDistance} km")
                    ],
                  )
                ],
              )
            ],
          )
        : Row(
            children: [
              const Text('Keine Goals bisher'),
              FloatingActionButton(
                onPressed: () {
                  showPopup(context, null);
                },
                heroTag: 'addButton',
                backgroundColor: Theme.of(context).colorScheme.secondary,
                child: Icon(
                  Icons.add,
                  color: Theme.of(context).colorScheme.onSecondary,
                ),
              ),
              FloatingActionButton(
                onPressed: () {
                  showDeleteConfirmationPopUp(context, goallist[curGoalIndex]);
                },
                heroTag: 'deleteButton',
                backgroundColor: Theme.of(context).colorScheme.secondary,
                child: Icon(
                  Icons.delete,
                  color: Theme.of(context).colorScheme.onSecondary,
                ),
              ),
            ],
          );
  }

  void updateMap(Goal? newValue) {
    markers.clear();
    curGoalIndex = goallist.indexWhere((goal) => goal.id == newValue!.id);
    markers.addAll([
      Marker(
          point: LatLng(goallist[curGoalIndex].latStart,
              goallist[curGoalIndex].longStart),
          child: const Icon(Icons.location_on, color: Colors.pink)),
      Marker(
          point: LatLng(
              goallist[curGoalIndex].latEnd, goallist[curGoalIndex].longEnd),
          child: const Icon(Icons.location_on, color: Colors.blue)),
      Marker(
          point: calculateUserPosition(goallist[curGoalIndex]),
          child: const Icon(Icons.person, color: Colors.black))
    ]);
    polylines.clear();
    polylines.add(Polyline(points: [
      LatLng(goallist[curGoalIndex].latEnd, goallist[curGoalIndex].longEnd),
      LatLng(goallist[curGoalIndex].latStart, goallist[curGoalIndex].longStart),
    ], color: Colors.blue, strokeWidth: 4.0));
  }

  Widget getMap(Goal curGoal) {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: LatLng(curGoal.latStart, curGoal.longStart),
        initialZoom: zoomLevel,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'dev.fleaflet.flutter_map.example',
        ),
        PolylineLayer(polylines: polylines),
        MarkerLayer(markers: markers),
      ],
    );
  }

  void showPopup(BuildContext context, Goal? goal) {
    LatLng? selectedLocationStart;
    LatLng? selectedLocationEnd;
    TextEditingController goalController =
        TextEditingController(text: goal?.name);
    TextEditingController startPositionController =
        TextEditingController(text: selectedLocationStart.toString());
    TextEditingController endPositionController =
        TextEditingController(text: selectedLocationEnd.toString());
    //'${selectedLocationEnd.latitude}, ${selectedLocationEnd.longitude}');
    TextEditingController descriptionController =
        TextEditingController(text: goal?.description);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(builder: (context, StateSetter setState) {
          return AlertDialog(
            title: const Text('Neues Goal hinzufügen'),
            content: Column(
              children: [
                TextField(
                    controller: goalController,
                    decoration: const InputDecoration(hintText: "Name")),
                TextField(
                    controller: descriptionController,
                    decoration:
                        const InputDecoration(hintText: "Beschreibung")),
                Row(children: [
                  Expanded(
                      child: TextField(
                          controller: startPositionController,
                          decoration: const InputDecoration(
                              hintText: "Startposition"))),
                  FilledButton(
                    onPressed: () async {
                      selectedLocationStart = await showLocationPicker(
                          context, "Startpunkt setzen");
                      if (selectedLocationStart != null) {
                        startPositionController.text =
                            selectedLocationStart.toString();
                      }
                      if (selectedLocationEnd != null) {
                        setState(() {
                          calculatedDistance = calculateDistance(
                              selectedLocationStart?.latitude,
                              selectedLocationStart?.longitude,
                              selectedLocationEnd?.latitude,
                              selectedLocationEnd?.longitude);
                        });
                      }
                    },
                    child: Icon(
                      Icons.gps_fixed,
                      color: Theme.of(context).colorScheme.onSecondary,
                    ),
                  )
                ]),
                Row(children: [
                  Expanded(
                      child: TextField(
                          controller: endPositionController,
                          decoration:
                              const InputDecoration(hintText: "Endposition"))),
                  FilledButton(
                    onPressed: () async {
                      selectedLocationEnd = await showLocationPicker(
                          context, "Startpunkt setzen");
                      if (selectedLocationEnd != null) {
                        endPositionController.text =
                            selectedLocationEnd.toString();
                        if (selectedLocationStart != null) {
                          setState(() {
                            calculatedDistance = calculateDistance(
                                selectedLocationStart?.latitude,
                                selectedLocationStart?.longitude,
                                selectedLocationEnd?.latitude,
                                selectedLocationEnd?.longitude);
                          });
                        }
                      }
                    },
                    child: Icon(
                      Icons.gps_fixed,
                      color: Theme.of(context).colorScheme.onSecondary,
                    ),
                  ),
                ]),
                Text(
                  "Berechnete Distanz zwischen Start- und Endpunkt: ${double.parse((calculatedDistance).toStringAsFixed(2))} km",
                ),
              ], // probleme: start und end sind nicht unbedingt in der richtigen reihenfolge besettz. ich muss das quasi berechnen sobald beide gesetzt sind. but how?
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Abbrechen'),
              ),
              TextButton(
                onPressed: () {
                  if (selectedLocationEnd != null &&
                      selectedLocationStart != null) {
                    addGoal(
                        goalController.text,
                        descriptionController.text,
                        selectedLocationStart!.latitude,
                        selectedLocationStart!.longitude,
                        selectedLocationEnd!.latitude,
                        selectedLocationEnd!.longitude,
                        false,
                        calculatedDistance,
                        0.0);
                  }
                  calculatedDistance = 0;
                  Navigator.of(context).pop();
                },
                child: const Text('Speichern'),
              ),
            ],
          );
        });
      },
    );
  }

  Future<LatLng?> showLocationPicker(
    BuildContext context,
    String title,
  ) {
    return showDialog<LatLng?>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: SizedBox(
              width: double.maxFinite,
              height: 400,
              child: Stack(
                children: [
                  FlutterMap(
                    mapController: _mapControllerDialog,
                    options: MapOptions(
                      initialCenter: const LatLng(51.435146, 6.762692),
                      initialZoom: zoomLevel,
                      interactionOptions:
                          InteractionOptions(rotationThreshold: 50),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName:
                            'dev.fleaflet.flutter_map.example',
                      )
                    ],
                  ),
                  const Center(
                    child: Icon(
                      Icons.location_pin,
                      size: 50,
                      color: Colors.red,
                    ),
                  ),
                ],
              )),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Abbrechen'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(_mapControllerDialog.camera.center);
              },
              child: const Text('Speichern'),
            ),
          ],
        );
      },
    );
  }

  void showWorkoutPopup(BuildContext context, Goal? goal) {
    TextEditingController distanceController =
        TextEditingController(text: goal?.name);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Distanz zurückgelegt'),
          content: TextField(
              controller: distanceController,
              decoration: const InputDecoration(hintText: "km")),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Abbrechen'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  addWorkout(double.parse(distanceController.text));
                });
                Navigator.of(context).pop();
              },
              child: const Text('Speichern'),
            ),
          ],
        );
      },
    );
  }

  void addWorkout(double distance) {
    goallist[curGoalIndex].curDistance += distance;
    updateUserMarker();
    DatabaseHelper.editGoal(goallist[curGoalIndex]);
  }

  void updateUserMarker() {
    markers.removeLast();
    markers.add(Marker(
        point: calculateUserPosition(goallist[curGoalIndex]),
        child: const Icon(Icons.person, color: Colors.black)));
  }

  Future<void> loadGoalList() async {
    List<Goal> v = await DatabaseHelper.getGoals();

    setState(() {
      if (v.isNotEmpty) {
        goallist = v;
        updateMap(goallist[curGoalIndex]);
      }
    });
  }

  void addGoal(
      String name,
      String description,
      double latStart,
      double longStart,
      double latEnd,
      double longEnd,
      bool finished,
      double totalDistance,
      double curDistance) {
    var goal = Goal(
        name: name,
        description: description,
        latStart: latStart,
        longStart: longStart,
        latEnd: latEnd,
        longEnd: longEnd,
        finished: finished,
        totalDistance: totalDistance,
        curDistance: curDistance);

    DatabaseHelper.insertGoal(goal);

    setState(() {
      goallist.add(goal);
    });
    updateMap(goal);
  }

  void deleteGoal(Goal goal) {
    setState(() {
      goallist.removeAt(curGoalIndex);
      curGoalIndex = 0;
      if (goallist.isNotEmpty) updateMap(goallist[curGoalIndex]);
      DatabaseHelper.deleteGoal(goal.id!);
    });
  }

  void showDeleteConfirmationPopUp(BuildContext context, Goal goal) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Löschen bestätigen"),
          content: Text("Wirklich das Goal \"${goal.name}\" löschen?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                deleteGoal(goal);
              },
              child: const Text('Löschen'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Abbrechen'),
            ),
          ],
        );
      },
    );
  }

  // void toggleSelectItem(Goal item) {
  //   setState(() {
  //     if (selectedGoals.contains(item)) {
  //       selectedGoals.remove(item);
  //     } else {
  //       selectedGoals.add(item);
  //     }
  //   });
  // }

  // void toggleEditMode() {
  //   setState(() {
  //     _editMode = !_editMode;
  //   });
  // }
}

// slower
// map usability improvement: erst später drehen,
// restore button um ma wieder richtig auszurichten? oder rotaten komplett entfernen?
// anderes map dingens probieren?
// schön machen

// ?
// in textcontrolling field nicht latlng() printen
// weite wege, die schräg sind da läuft unser user icon vom weg runter
// center map on user icon

// now:   
