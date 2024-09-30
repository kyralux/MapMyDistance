import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:math' show cos, sqrt, asin;

import 'package:percent_indicator/percent_indicator.dart';

import 'package:mapgoal/src/data/goal.dart';
import 'package:mapgoal/src/settings/settings_view.dart';

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
          'MapMyDistance',
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
      body: buildView(),
      floatingActionButton:
          goallist.isNotEmpty ? _buildActionButton(context) : null,
    );
  }

  Widget _buildActionButton(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        FloatingActionButton(
          onPressed: () => showWorkoutPopup(context, null),
          heroTag: 'addWorkoutButton',
          backgroundColor: Theme.of(context).colorScheme.secondary,
          child: Icon(
            Icons.add,
            color: Theme.of(context).colorScheme.onSecondary,
          ),
        ),
      ],
    );
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

  Widget getProgressBar() {
    return Stack(
      children: [
        LinearPercentIndicator(
          padding: const EdgeInsets.all(0),
          lineHeight: 30.0,
          percent: goallist[curGoalIndex].curDistance /
              goallist[curGoalIndex].totalDistance,
          backgroundColor: Colors.white,
          progressColor: Colors.transparent,
          animation: true,
        ),
        Positioned.fill(
          child: FractionallySizedBox(
            widthFactor: goallist[curGoalIndex].curDistance /
                goallist[curGoalIndex].totalDistance,
            alignment: Alignment.centerLeft,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFFf9bb00),
                    Color(0xFFFF8C00),
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
            ),
          ),
        ),
        Center(
            child: Text(
          '${(goallist[curGoalIndex].curDistance / goallist[curGoalIndex].totalDistance * 100).toStringAsFixed(1)}%',
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        )),
      ],
    );
  }

  Widget _buildEmptyView(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Erstelle dein erstes Ziel',
            style: TextStyle(fontSize: 18.0),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FloatingActionButton(
                onPressed: () => showPopup(context, null),
                heroTag: 'addButton',
                backgroundColor: Theme.of(context).colorScheme.secondary,
                child: Icon(
                  Icons.add,
                  color: Theme.of(context).colorScheme.onSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildHeader() {
    return Stack(
      children: [
        Container(
          height: MediaQuery.of(context).size.height * 0.24,
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                  color: Colors.grey.shade600, spreadRadius: 1, blurRadius: 15)
            ],
            color: Theme.of(context).colorScheme.primary,
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(50),
            ),
          ),
        ),
        Column(
          children: [
            const SizedBox(
              height: 40,
            ),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text("Deine Goals",
                  style: Theme.of(context).textTheme.headlineLarge),
              IconButton(
                  icon: const Icon(Icons.settings),
                  onPressed: () {
                    Navigator.of(context).pop();
                  })
            ])
          ],
        ),
      ],
    );
  }

  Widget buildView() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.secondary
          ],
        ),
      ),
      child: goallist.isNotEmpty
          ? Column(
              children: [
                const SizedBox(height: 10),
                _buildGoalCard(context),
                const SizedBox(
                  height: 50,
                )
              ],
            )
          : _buildEmptyView(context),
    );
  }

  // Widget _buildGoalDescription(BuildContext context) {
  //   if (goallist[curGoalIndex].description.isNotEmpty) {
  //     return Container(
  //         alignment: Alignment.center,
  //         child: Text(
  //           goallist[curGoalIndex].description,
  //           style: Theme.of(context).textTheme.bodyMedium,
  //         ));
  //   }

  //   return const SizedBox.shrink(); // Return an empty widget if no description
  // }

  Widget _buildGoalCard(BuildContext context) {
    return Flexible(
      flex: 10,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Card(
          shape: RoundedRectangleBorder(
            side: BorderSide(
              color: Theme.of(context).colorScheme.primary,
              width: 2.0,
            ),
            borderRadius: BorderRadius.circular(16.0),
          ),
          elevation: 5,
          child: ClipRRect(
              borderRadius: BorderRadius.circular(16.0),
              child: Flexible(
                flex: 10,
                child: Column(
                  children: [
                    getDropDownRow(),
                    getMap(goallist[curGoalIndex]),
                    Padding(
                      padding: const EdgeInsets.all(0),
                      child: getProgressBar(),
                    ),
                    Text(
                      "${goallist[curGoalIndex].curDistance} / ${double.parse((goallist[curGoalIndex].totalDistance - goallist[curGoalIndex].curDistance).toStringAsFixed(2))} km",
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge,
                    )
                  ],
                ),
              )),
        ),
      ),
    );
  }

  void updateMap(Goal? newValue) {
    markers.clear();
    curGoalIndex = goallist.indexWhere((goal) => goal.id == newValue!.id);
    LatLng coordinates = calculateUserPosition(goallist[curGoalIndex]);
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
          point: coordinates,
          child: const Icon(Icons.person, color: Colors.black))
    ]);
    polylines.clear();
    polylines.add(Polyline(points: [
      LatLng(goallist[curGoalIndex].latEnd, goallist[curGoalIndex].longEnd),
      LatLng(goallist[curGoalIndex].latStart, goallist[curGoalIndex].longStart),
    ], color: Colors.blue, strokeWidth: 4.0));
    polylines.add(Polyline(points: [
      LatLng(coordinates.latitude, coordinates.longitude),
      LatLng(goallist[curGoalIndex].latStart, goallist[curGoalIndex].longStart),
    ], color: Colors.yellow, strokeWidth: 4.0));

    //_mapController.move(coordinates, _mapController.camera.zoom);
  }

  Widget getMap(Goal curGoal) {
    return Flexible(
        flex: 10,
        child: FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: LatLng(curGoal.latStart, curGoal.longStart),
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

  double validateZoomLevel(double zoom) {
    if (zoom.isNaN || zoom.isInfinite || zoom < 0) {
      return 5.0; // Default zoom level
    }
    return zoom;
  }

  void showPopup(BuildContext context, Goal? goal) {
    LatLng? selectedLocationStart;
    LatLng? selectedLocationEnd;
    TextEditingController goalController =
        TextEditingController(text: goal?.name);
    TextEditingController startPositionController = TextEditingController();
    TextEditingController endPositionController = TextEditingController();
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
                          context, "Endposition setzen");
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
    LatLng coordinates = calculateUserPosition(goallist[curGoalIndex]);
    markers.removeLast();
    markers.add(Marker(
        point: coordinates,
        child: const Icon(Icons.person, color: Colors.black)));
    _mapController.move(
        coordinates, _mapController.camera.zoom); // = coordinates;
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

  Widget getDropDownRow() {
    return Container(
        color: Theme.of(context).colorScheme.secondary,
        child: Row(
          children: [
            const Padding(padding: EdgeInsets.only(left: 10)),
            SizedBox(
                width: MediaQuery.of(context).size.width * 0.62,
                child: DropdownButton(
                  isExpanded: true,
                  value: goallist[curGoalIndex],
                  icon: const Icon(Icons.keyboard_arrow_down),
                  dropdownColor: Theme.of(context).colorScheme.secondary,
                  iconEnabledColor: Theme.of(context).colorScheme.onSecondary,
                  focusColor: Colors.black,
                  items: goallist.map((Goal item) {
                    return DropdownMenuItem(
                      value: item,
                      child: Text(
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.onSecondary),
                        overflow: TextOverflow.ellipsis,
                        item.name,
                      ),
                    );
                  }).toList(),
                  onChanged: (Goal? newGoal) {
                    setState(() {
                      updateMap(newGoal);
                    });
                  },
                )),
            IconButton(
              onPressed: () {
                showPopup(context, null);
              },
              color: Theme.of(context).colorScheme.secondary,
              icon: Icon(
                Icons.add,
                color: Theme.of(context).colorScheme.onSecondary,
              ),
            ),
            IconButton(
              onPressed: () {
                showDeleteConfirmationPopUp(context, goallist[curGoalIndex]);
              },
              color: Theme.of(context).colorScheme.secondary,
              icon: Icon(
                Icons.delete,
                color: Theme.of(context).colorScheme.onSecondary,
              ),
            ),
          ],
        ));
  }
}

// slower
// map usability improvement: erst später drehen,
// restore button um ma wieder richtig auszurichten? oder rotaten komplett entfernen?
// anderes map dingens probieren?
// schön machen
// multilanguage https://docs.flutter.dev/ui/accessibility-and-internationalization/internationalization (1-2h Arbeit)

// ?
// in textcontrolling field nicht latlng() printen
// weite wege, die schräg sind da läuft unser user icon vom weg runter
// 
// validierungen und nur digits und son kram für felder, exception funsies
// bei goal hinzufügen overflowed das fenster
// splash screen adden
// now:   



///  remaining, bar und adden in DraggableScrollableSheet?
/// keine app bar
/// wohin mit dropdown und +/-? (bleibt neben dropdown, aber in segmented buttons?
/// map in eine card damit man den hintergrund noch sieht?
/// 
/// 
/// 
/// put + to add distance in the thumb area
/// where to put the geschafft/total?
/// 
/// gelb wird nicht gemalt nach dem adden
/// es gibt keinen settings button beim empty goals screen
/// bar prozent ist nicht mittig