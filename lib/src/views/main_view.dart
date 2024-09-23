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
  List<Goal> goallist = [
    // TODO: This only works on startup if list is not empty, but will be overwritten soon anyway
    Goal(
        name: "Huhu",
        latStart: 0.0,
        longStart: 1.0,
        latEnd: 5.5,
        longEnd: 50.5,
        finished: false,
        totalDistance: 50.0)
  ];
  int curGoalIndex = 0;
  final MapController _mapController = MapController();
  final MapController _mapControllerDialog = MapController();
  List<Marker> markers = [];
  List<Polyline> polylines = [];
  double zoomLevel = 5.0;
  double calculatedDistance = 0.0;

  @override
  void initState() {
    super.initState();
    loadGoalList();
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
    return Column(
      children: [
        Row(
          children: [
            DropdownButton(
              value: goallist[curGoalIndex],
              icon: const Icon(Icons.keyboard_arrow_down),
              items: goallist.map((Goal item) {
                return DropdownMenuItem(
                  value: item,
                  child: Text(item.name),
                );
              }).toList(),
              onChanged: (Goal? newValue) {
                setState(() {
                  markers.clear();
                  curGoalIndex =
                      goallist.indexWhere((goal) => goal.id == newValue!.id);
                  markers.addAll([
                    Marker(
                        point: LatLng(goallist[curGoalIndex].latStart,
                            goallist[curGoalIndex].longStart),
                        child:
                            const Icon(Icons.location_on, color: Colors.pink)),
                    Marker(
                        point: LatLng(goallist[curGoalIndex].latEnd,
                            goallist[curGoalIndex].longEnd),
                        child:
                            const Icon(Icons.location_on, color: Colors.blue)),
                    Marker(
                        point: calculateUserPosition(goallist[curGoalIndex]),
                        child: const Icon(Icons.person, color: Colors.black))
                  ]);
                  polylines.clear();
                  polylines.add(Polyline(points: [
                    LatLng(goallist[curGoalIndex].latEnd,
                        goallist[curGoalIndex].longEnd),
                    LatLng(goallist[curGoalIndex].latStart,
                        goallist[curGoalIndex].longStart),
                  ], color: Colors.blue, strokeWidth: 4.0));
                });
                _mapController.move(
                    LatLng(goallist[curGoalIndex].latStart,
                        goallist[curGoalIndex].longStart),
                    zoomLevel);
              },
            ),
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
          ],
        ),
        Text(goallist[curGoalIndex].description),
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
    );
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
                  "Berechnete Distanz zwischen Start- und Endpunkt: ${double.parse((calculatedDistance).toStringAsFixed(2))}",
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
    String title, //""
  ) {
    return showDialog<LatLng?>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Container(
              width: double.maxFinite,
              height: 400,
              child: Stack(
                children: [
                  FlutterMap(
                    mapController: _mapControllerDialog,
                    options: MapOptions(
                      initialCenter: const LatLng(51.435146, 6.762692),
                      initialZoom: zoomLevel,
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
                  goallist[curGoalIndex].curDistance +=
                      double.parse(distanceController.text);
                  markers.removeLast();
                  markers.add(Marker(
                      point: calculateUserPosition(goallist[curGoalIndex]),
                      child: const Icon(Icons.person, color: Colors.black)));
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

  Widget buildGoalsBacklog() {
    return ReorderableListView.builder(
        restorationId: 'GoalListView',
        itemCount: goallist.length,
        itemBuilder: (BuildContext context, int index) {
          var item = goallist[index];
          return Column(
            key: Key('$index'),
            children: <Widget>[
              ListTile(
                key: ObjectKey(item),
                title: Text(item.name),
              ),
              if (index != goallist.length - 1)
                const Divider(
                  indent: 70,
                  endIndent: 30,
                )
              else
                const Padding(
                  padding: EdgeInsets.all(32.0),
                )
            ],
          );
        },
        onReorder: (int oldIndex, int newIndex) {
          if (oldIndex < newIndex) {
            newIndex -= 1;
          }
          final item = goallist.removeAt(oldIndex);
          goallist.insert(newIndex, item);
        });
  }

  void loadGoalList() {
    DatabaseHelper.getGoals().then((v) => {
          setState(() {
            goallist = v;
          }),
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
  }

  // void editGoal(String newname, Goal Goal) {
  //   Goal.name = newname;
  //   DatabaseHelper.updateGoal(Goal);

  //   setState(() {
  //     goallist[goallist.indexWhere((item) => item.id == Goal.id)] = Goal;
  //   });
  // }

  // void deleteGoals(Set<Goal> goals) {
  //   setState(() {
  //     for (Goal sk in goals.toList()) {
  //       goallist.removeWhere((element) => element.id == sk.id);
  //       DatabaseHelper.deleteGoal(sk.id!);
  //     }
  //   });
  // }
  // void showPopup(BuildContext context, Goal? goal) {
  //   TextEditingController goalController =
  //       TextEditingController(text: goal?.name);
  //   showDialog(
  //     context: context,
  //     builder: (BuildContext context) {
  //       return AlertDialog(
  //         title: goal != null
  //             ? const Text('Goal editieren')
  //             : const Text('Neuen Goal hinzufügen'),
  //         content: TextField(
  //             controller: goalController,
  //             decoration: const InputDecoration(hintText: "Goalname")),
  //         actions: [
  //           TextButton(
  //             onPressed: () {
  //               Navigator.of(context).pop();
  //             },
  //             child: const Text('Abbrechen'),
  //           ),
  //           // TextButton(
  //           //   onPressed: () {
  //           //     if (goal != null) {
  //           //       editGoal(goalController.text, goal);
  //           //     } else {
  //           //       addMainGoal(goalController.text, "Desc");
  //           //     }
  //           //     Navigator.of(context).pop();
  //           //   },
  //           //   child: const Text('Speichern'),
  //           // ),
  //         ],
  //       );
  //     },
  //   );
  // }
  // void showDeleteConfirmationPopUp(BuildContext context, Set<Goal> selected) {
  //   if (selected.isNotEmpty) {
  //     showDialog(
  //       context: context,
  //       builder: (BuildContext context) {
  //         return AlertDialog(
  //           title: const Text("Löschen bestätigen"),
  //           content: Text("Wirklich ${selected.length} Goals löschen?"),
  //           actions: [
  //             TextButton(
  //               onPressed: () {
  //                 Navigator.of(context).pop();
  //               },
  //               child: const Text('Löschen'),
  //             ),
  //             TextButton(
  //               onPressed: () {
  //                 Navigator.of(context).pop();
  //               },
  //               child: const Text('Abbrechen'),
  //             ),
  //           ],
  //         );
  //       },
  //     );
  //   }
  // }
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

  Widget buildPresent() {
    return Column(children: [
      const Text("Current Goals"),
      Column(
        children: [
          SizedBox(
            height: 400,
            child: Card.filled(
              semanticContainer: true,
              color: Colors.pink.shade100,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30.0),
              ),
              margin: const EdgeInsets.all(42.0),
              child: const Column(children: [Text("huhu"), Text("Ernährung!")]),
            ),
          ),
          Card.filled(
            color: Colors.pink.shade50,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30.0),
            ),
            margin: const EdgeInsets.all(16.0),
            child: const Column(
                children: [Text("Täglisch rausgehen"), Text("Sport")]),
          )
        ],
      )
    ]);
  }

  Widget buildPast() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text("Past Successes"),
          Icon(Icons.star),
        ],
      ),
    );
  }
}
