import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
//import 'dart:math' show cos, sqrt, asin;

import 'package:percent_indicator/percent_indicator.dart';

import 'package:mapgoal/src/data/goal.dart';
import 'package:mapgoal/src/settings/settings_view.dart';

import 'package:mapgoal/src/storage/database_helper.dart';
import 'package:flutter_map_math/flutter_geo_math.dart';

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
  String unit = "km";

  @override
  void initState() {
    loadGoalList();
    super.initState();
  }

  @override
  void dispose() {
    _mapController.dispose();
    _mapControllerDialog.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Image.asset(
                "image/gradientGPS-empty.PNG",
                height: MediaQuery.of(context).size.height * 0.05,
              ),
            ),
            Text(
              'MapMyDistance',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ],
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
      body: Container(
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
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 10),
                  _buildGoalCard(context),
                  const SizedBox(
                    height: 50,
                  )
                ],
              )
            : _buildEmptyView(context),
      ),
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
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            AppLocalizations.of(context)!.emptyText,
            style: const TextStyle(fontSize: 18.0),
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

  // Widget buildHeader() {
  //   return Stack(
  //     children: [
  //       Container(
  //         height: MediaQuery.of(context).size.height * 0.24,
  //         decoration: BoxDecoration(
  //           boxShadow: [
  //             BoxShadow(
  //                 color: Colors.grey.shade600, spreadRadius: 1, blurRadius: 15)
  //           ],
  //           color: Theme.of(context).colorScheme.primary,
  //           borderRadius: const BorderRadius.vertical(
  //             bottom: Radius.circular(50),
  //           ),
  //         ),
  //       ),
  //       Column(
  //         children: [
  //           const SizedBox(
  //             height: 40,
  //           ),
  //           Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
  //             Text("Your Goals",
  //                 style: Theme.of(context).textTheme.headlineLarge),
  //             IconButton(
  //                 icon: const Icon(Icons.settings),
  //                 onPressed: () {
  //                   Navigator.of(context).pop();
  //                 })
  //           ])
  //         ],
  //       ),
  //     ],
  //   );
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
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Flexible(
                  flex: 10,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      getDropDownRow(),
                      getMap(
                          LatLng(goallist[curGoalIndex].latStart,
                              goallist[curGoalIndex].longStart),
                          polylines,
                          markers,
                          _mapController),
                      Padding(
                        padding: const EdgeInsets.all(0),
                        child: getProgressBar(),
                      ),
                      Text(
                        "${goallist[curGoalIndex].curDistance} / ${double.parse((goallist[curGoalIndex].totalDistance - goallist[curGoalIndex].curDistance).toStringAsFixed(2))} $unit",
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge,
                      )
                    ],
                  ),
                )
              ])),
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
          child: Icon(Icons.fiber_manual_record,
              color: Theme.of(context).colorScheme.secondary)),
      Marker(
          point: LatLng(
              goallist[curGoalIndex].latEnd, goallist[curGoalIndex].longEnd),
          child:
              Icon(Icons.flag, color: Theme.of(context).colorScheme.secondary)),
      Marker(
          point: coordinates,
          child: const Icon(Icons.person, color: Colors.black))
    ]);
    polylines.clear();
    polylines.add(Polyline(points: [
      LatLng(goallist[curGoalIndex].latEnd, goallist[curGoalIndex].longEnd),
      LatLng(goallist[curGoalIndex].latStart, goallist[curGoalIndex].longStart),
    ], color: Colors.grey, strokeWidth: 4.0));
    polylines.add(Polyline(points: [
      LatLng(coordinates.latitude, coordinates.longitude),
      LatLng(goallist[curGoalIndex].latStart, goallist[curGoalIndex].longStart),
    ], color: Theme.of(context).colorScheme.tertiary, strokeWidth: 4.0));

    // somehow this only works after the first loading of the app
    //_mapController.move(coordinates, _mapController.camera.zoom);
  }

  Widget getMap(LatLng coordinates, List<Polyline> polylist,
      List<Marker> markerlist, MapController mapController) {
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
            PolylineLayer(polylines: polylist),
            MarkerLayer(markers: markerlist),
          ],
        ));
  }

  double validateZoomLevel(double zoom) {
    if (zoom.isNaN || zoom.isInfinite || zoom < 0) {
      return 5.0;
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
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(builder: (context, StateSetter setState) {
          return AlertDialog(
            title: Text(AppLocalizations.of(context)!.newGoalTitle),
            content: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                    controller: goalController,
                    decoration: InputDecoration(
                        hintText: AppLocalizations.of(context)!.newGoalName)),
                Row(children: [
                  Expanded(
                      child: TextField(
                          controller: startPositionController,
                          decoration: InputDecoration(
                              hintText:
                                  AppLocalizations.of(context)!.newGoaStart))),
                  FilledButton(
                    onPressed: () async {
                      selectedLocationStart = await showLocationPicker(context,
                          AppLocalizations.of(context)!.locationPickerStart);
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
                          decoration: InputDecoration(
                              hintText: AppLocalizations.of(context)!
                                  .locationPickerEnd))),
                  FilledButton(
                    onPressed: () async {
                      selectedLocationEnd = await showLocationPicker(context,
                          AppLocalizations.of(context)!.locationPickerEnd);
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
                const SizedBox(
                  height: 50,
                ),
                Text(AppLocalizations.of(context)!.newGoaDistance,
                    style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(
                  height: 10,
                ),
                Card(
                    color: Theme.of(context).colorScheme.secondary,
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Text(
                          "${double.parse((calculatedDistance).toStringAsFixed(2))} $unit",
                          style: Theme.of(context).textTheme.bodyMedium),
                    )),
              ],
            ),
            actions: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                FilledButton(
                  style: ButtonStyle(
                      backgroundColor: WidgetStateProperty.all(
                          Color.fromARGB(255, 223, 223, 223))),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(AppLocalizations.of(context)!.cancel,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium!
                              .copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface))),
                ),
                FilledButton(
                  style: ButtonStyle(
                      backgroundColor: WidgetStateProperty.all(
                          Theme.of(context).colorScheme.secondary)),
                  onPressed: () {
                    if (selectedLocationEnd != null &&
                        selectedLocationStart != null) {
                      addGoal(
                          goalController.text,
                          "",
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
                  child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(AppLocalizations.of(context)!.save,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium!
                              .copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface))),
                ),
              ])
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
                  getMap(
                      LatLng(goallist[curGoalIndex].latStart,
                          goallist[curGoalIndex].longStart),
                      List<Polyline>.empty(),
                      List<Marker>.empty(),
                      _mapControllerDialog),
                  // FlutterMap(
                  //   mapController: _mapControllerDialog,
                  //   options: MapOptions(
                  //     initialCenter: const LatLng(51.435146, 6.762692),
                  //     initialZoom: zoomLevel,
                  //   ),
                  //   children: [
                  //     TileLayer(
                  //       urlTemplate:
                  //           'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  //       userAgentPackageName:
                  //           'dev.fleaflet.flutter_map.example',
                  //     )
                  //   ],
                  // ),
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
              child: Text(
                AppLocalizations.of(context)!.cancel,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(_mapControllerDialog.camera.center);
              },
              child: Text(
                AppLocalizations.of(context)!.save,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        );
      },
    );
  }

  void showWorkoutPopup(BuildContext context, Goal? goal) {
    TextEditingController distanceController =
        TextEditingController(text: goal?.name);
    final formKey = GlobalKey<FormState>();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.distanceTitle),
          content: Form(
              key: formKey,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text(AppLocalizations.of(context)!.distanceDescription),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(
                      child: TextFormField(
                    controller: distanceController,
                    decoration: InputDecoration(
                        hintText: AppLocalizations.of(context)!.distanceHint,
                        border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return AppLocalizations.of(context)!.distanceHint;
                      }
                      final doubleValue = double.tryParse(value);
                      if (doubleValue == null) {
                        return AppLocalizations.of(context)!.errorValidNumber;
                      }
                      return null;
                    },
                  )),
                  const SizedBox(width: 10),
                  Text(unit)
                ]),
              ])),
          actions: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
              FilledButton(
                style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.all(
                        Color.fromARGB(255, 223, 223, 223))),
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text(AppLocalizations.of(context)!.cancel,
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        color: Theme.of(context).colorScheme.onSurface)),
              ),
              FilledButton(
                style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.all(
                        Theme.of(context).colorScheme.secondary)),
                onPressed: () {
                  if (formKey.currentState?.validate() ?? false) {
                    setState(() {
                      addWorkout(double.parse(distanceController.text));
                      Navigator.of(context).pop();
                    });
                  }
                },
                child: Text(AppLocalizations.of(context)!.save,
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        color: Theme.of(context).colorScheme.onSurface)),
              )
            ]),
            // TextButton(
            //   onPressed: () {
            //     Navigator.of(context).pop();
            //   },
            //   child: Text(AppLocalizations.of(context)!.cancel,
            //       style: Theme.of(context).textTheme.bodyMedium),
            // ),
            // TextButton(
            //   onPressed: () {
            //     if (formKey.currentState?.validate() ?? false) {
            //       setState(() {
            //         addWorkout(double.parse(distanceController.text));
            //         Navigator.of(context).pop();
            //       });
            //     }
            //   },
            //   child: Text(AppLocalizations.of(context)!.save,
            //       style: Theme.of(context).textTheme.bodyMedium),
            // ),
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
    polylines.removeLast();
    polylines.add(Polyline(points: [
      LatLng(coordinates.latitude, coordinates.longitude),
      LatLng(goallist[curGoalIndex].latStart, goallist[curGoalIndex].longStart),
    ], color: Theme.of(context).colorScheme.tertiary, strokeWidth: 4.0));
    _mapController.move(coordinates, _mapController.camera.zoom);
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
          title: Text(AppLocalizations.of(context)!.deletionTitle),
          content: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(AppLocalizations.of(context)!.deletionDescription,
                    style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 10),
                Text(goal.name, style: Theme.of(context).textTheme.bodyLarge)
              ]),
          actions: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
              FilledButton(
                style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.all(
                        Color.fromARGB(255, 223, 223, 223))),
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text(AppLocalizations.of(context)!.cancel,
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        color: Theme.of(context).colorScheme.onSurface)),
              ),
              FilledButton(
                style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.all(
                        Theme.of(context).colorScheme.error)),
                onPressed: () {
                  Navigator.of(context).pop();
                  deleteGoal(goal);
                },
                child: Text(AppLocalizations.of(context)!.deletionSubmit,
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        color: Theme.of(context).colorScheme.onError)),
              ),
            ])
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
                width: MediaQuery.of(context).size.width * 0.60,
                child: DropdownButton(
                  isExpanded: true,
                  value: goallist[curGoalIndex],
                  icon: const Icon(Icons.keyboard_arrow_down),
                  dropdownColor: Theme.of(context).colorScheme.secondary,
                  iconEnabledColor: Theme.of(context).colorScheme.onSecondary,
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
/// 
/// gelb wird nicht gemalt nach dem adden
/// es gibt keinen settings button beim empty goals screen
/// bar prozent ist nicht mittig
/// 
/// add popup when goal is reached
/// validate input 