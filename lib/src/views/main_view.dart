import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:mapgoal/src/settings/settings_controller.dart';
import 'package:mapgoal/src/util/goals.dart';

import 'package:percent_indicator/percent_indicator.dart';

import 'package:mapgoal/src/data/goal.dart';
import 'package:mapgoal/src/util/map.dart';
import 'package:mapgoal/src/settings/settings_view.dart';

class GoalListView extends StatefulWidget {
  const GoalListView({super.key, required this.controller});
  static const routeName = '/';

  final SettingsController controller;

  @override
  State<GoalListView> createState() => _GoalListViewState();
}

class _GoalListViewState extends State<GoalListView> {
  double calculatedDistance = 0.0;
  late NumberFormat f = NumberFormat.decimalPattern("en_en");
  final MapUtils mapUtils = MapUtils();
  GoalHandler goalHandler = GoalHandler();
  final MapController _mapControllerDialog = MapController();

  @override
  void initState() {
    super.initState();

    goalHandler.loadGoalList(context);
    Future.delayed(const Duration(milliseconds: 500), () {
      if (goalHandler.goallist.isNotEmpty) {
        mapUtils.updateMap(context, goalHandler,
            goalHandler.goallist[goalHandler.curGoalIndex]);
      }
    });
  }

  @override
  void dispose() {
    //_mapController.dispose();
    // _mapControllerDialog.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    setState(() {
      if (goalHandler.goallist.isNotEmpty) {
        mapUtils.updateMap(context, goalHandler,
            goalHandler.goallist[goalHandler.curGoalIndex]);
      }
    });

    final locale = Localizations.localeOf(context);
    f = NumberFormat.decimalPattern(locale.toString());
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
              onPressed: () async {
                var result = await Navigator.restorablePushNamed(
                    context, SettingsView.routeName);
              }),
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
        child: goalHandler.goallist.isNotEmpty
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
          goalHandler.goallist.isNotEmpty ? _buildActionButton(context) : null,
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
            ))
      ],
    );
  }

  String formatNumber(double distance) {
    return f.format(
        widget.controller.distanceUnit.name == DistanceUnit.miles.name
            ? mapUtils.convertKilometerMiles(distance)
            : distance);
  }

  Widget getProgressBar() {
    return Stack(
      children: [
        LinearPercentIndicator(
          padding: const EdgeInsets.all(0),
          lineHeight: 30.0,
          percent: goalHandler.curGoal.evalFinished()
              ? 1.0
              : goalHandler.curGoal.curDistance /
                  goalHandler.curGoal.totalDistance,
          backgroundColor: Colors.white,
          progressColor: Colors.transparent,
          animation: true,
        ),
        Positioned.fill(
          child: FractionallySizedBox(
            widthFactor: goalHandler.curGoal.curDistance /
                goalHandler.curGoal.totalDistance,
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
          '${(goalHandler.curGoal.curDistance / goalHandler.curGoal.totalDistance * 100).toStringAsFixed(2)}%',
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                getDropDownRow(context),
                mapUtils.getMap(
                  LatLng(goalHandler.curGoal.latStart,
                      goalHandler.curGoal.longStart),
                ),
                Padding(
                  padding: const EdgeInsets.all(0),
                  child: getProgressBar(),
                ),
                Text(
                  "${formatNumber(goalHandler.curGoal.curDistance)} / ${formatNumber(goalHandler.curGoal.totalDistance)} ${widget.controller.distanceUnit.name}",
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  void showPopup(BuildContext context, Goal? goal) {
    LatLng? selectedLocationStart;
    LatLng? selectedLocationEnd;
    TextEditingController goalController =
        TextEditingController(text: goal?.name);
    TextEditingController startPositionController = TextEditingController();
    TextEditingController endPositionController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(builder: (context, StateSetter setState) {
          return AlertDialog(
            title: Text(AppLocalizations.of(context)!.newGoalTitle),
            content: SingleChildScrollView(
                child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller: goalController,
                          decoration: InputDecoration(
                              hintText:
                                  AppLocalizations.of(context)!.newGoalName),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return AppLocalizations.of(context)!.newGoalName;
                            }
                            if (value.length > 100) {
                              return AppLocalizations.of(context)!
                                  .errorGoalNameLong;
                            }
                            return null;
                          },
                        ),
                        Row(children: [
                          Expanded(
                              child: TextFormField(
                                  readOnly: true,
                                  controller: startPositionController,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return AppLocalizations.of(context)!
                                          .newGoaStart;
                                    }
                                    return null;
                                  },
                                  decoration: InputDecoration(
                                      hintText: AppLocalizations.of(context)!
                                          .newGoaStart))),
                          FilledButton(
                            onPressed: () async {
                              selectedLocationStart = await showLocationPicker(
                                  context,
                                  AppLocalizations.of(context)!
                                      .locationPickerStart);
                              if (selectedLocationStart != null) {
                                startPositionController.text =
                                    selectedLocationStart.toString();
                              }
                              if (selectedLocationEnd != null) {
                                setState(() {
                                  calculatedDistance =
                                      mapUtils.calculateDistance(
                                          selectedLocationStart?.latitude,
                                          selectedLocationStart?.longitude,
                                          selectedLocationEnd?.latitude,
                                          selectedLocationEnd?.longitude);
                                });
                              }
                            },
                            style: ButtonStyle(
                                backgroundColor: WidgetStatePropertyAll(
                                    Theme.of(context).colorScheme.secondary)),
                            child: Icon(
                              Icons.add_location,
                              color: Theme.of(context).colorScheme.onSecondary,
                            ),
                          )
                        ]),
                        Row(children: [
                          Expanded(
                              child: TextFormField(
                                  readOnly: true,
                                  controller: endPositionController,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return AppLocalizations.of(context)!
                                          .newGoalEnde;
                                    }
                                    return null;
                                  },
                                  decoration: InputDecoration(
                                      hintText: AppLocalizations.of(context)!
                                          .locationPickerEnd))),
                          FilledButton(
                            onPressed: () async {
                              selectedLocationEnd = await showLocationPicker(
                                  context,
                                  AppLocalizations.of(context)!
                                      .locationPickerEnd);
                              if (selectedLocationEnd != null) {
                                endPositionController.text =
                                    selectedLocationEnd.toString();
                                if (selectedLocationStart != null) {
                                  setState(() {
                                    calculatedDistance =
                                        mapUtils.calculateDistance(
                                            selectedLocationStart?.latitude,
                                            selectedLocationStart?.longitude,
                                            selectedLocationEnd?.latitude,
                                            selectedLocationEnd?.longitude);
                                  });
                                }
                              }
                            },
                            style: ButtonStyle(
                                backgroundColor: WidgetStatePropertyAll(
                                    Theme.of(context).colorScheme.secondary)),
                            child: Icon(
                              Icons.add_location,
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
                                  "${formatNumber(calculatedDistance)} ${widget.controller.distanceUnit.name}",
                                  style:
                                      Theme.of(context).textTheme.bodyMedium),
                            )),
                      ],
                    ))),
            actions: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      FilledButton(
                          style: ButtonStyle(
                              backgroundColor: WidgetStateProperty.all(
                                  Color.fromARGB(255, 223, 223, 223))),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: Text(AppLocalizations.of(context)!.cancel,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium!
                                  .copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface))),
                      FilledButton(
                          style: ButtonStyle(
                              backgroundColor: WidgetStateProperty.all(
                                  Theme.of(context).colorScheme.secondary)),
                          onPressed: () {
                            if (formKey.currentState?.validate() ?? false) {
                              setState(() {
                                if (selectedLocationEnd != null &&
                                    selectedLocationStart != null) {
                                  goalHandler.addGoal(
                                      context,
                                      goalController.text,
                                      "",
                                      selectedLocationStart!.latitude,
                                      selectedLocationStart!.longitude,
                                      selectedLocationEnd!.latitude,
                                      selectedLocationEnd!.longitude,
                                      false,
                                      calculatedDistance,
                                      0.0);
                                  calculatedDistance = 0;
                                  Navigator.of(context).pop();
                                }
                              });
                            }
                          },
                          child: Text(AppLocalizations.of(context)!.save,
                              maxLines: 1,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium!
                                  .copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface))),
                    ]),
              )
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
              child: mapUtils.getLocationPickerMap(
                  goalHandler.goallist.isNotEmpty
                      ? LatLng(goalHandler.curGoal.latStart,
                          goalHandler.curGoal.longStart)
                      : const LatLng(49.843, 9.902056),
                  _mapControllerDialog)),
          actions: [
            FittedBox(
              child: Row(
                children: [
                  FilledButton(
                    style: ButtonStyle(
                        backgroundColor: WidgetStateProperty.all(
                            Color.fromARGB(255, 223, 223, 223))),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Text(
                      AppLocalizations.of(context)!.cancel,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  FilledButton(
                    style: ButtonStyle(
                        backgroundColor: WidgetStateProperty.all(
                            Theme.of(context).colorScheme.secondary)),
                    onPressed: () {
                      Navigator.of(context)
                          .pop(_mapControllerDialog.camera.center);
                    },
                    child: Text(
                      AppLocalizations.of(context)!.save,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            )
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
          content: SingleChildScrollView(
              child: Form(
                  key: formKey,
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Text(AppLocalizations.of(context)!.distanceDescription),
                    const SizedBox(height: 10),
                    Row(children: [
                      Expanded(
                          child: TextFormField(
                        controller: distanceController,
                        decoration: InputDecoration(
                            hintText:
                                AppLocalizations.of(context)!.distanceHint,
                            border: OutlineInputBorder()),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return AppLocalizations.of(context)!.distanceHint;
                          }
                          try {
                            num? doubleValue = f.parse(value);
                            if (doubleValue == null) {
                              return AppLocalizations.of(context)!
                                  .errorValidNumber;
                            }
                          } catch (e) {
                            return AppLocalizations.of(context)!
                                .errorValidNumber;
                          }

                          return null;
                        },
                      )),
                      const SizedBox(width: 10),
                      Text(widget.controller.distanceUnit.name)
                    ]),
                  ]))),
          actions: [
            FittedBox(
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
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
                          goalHandler.addWorkout(context,
                              f.parse(distanceController.text).toDouble());
                          Navigator.of(context).pop();
                          if (goalHandler.curGoal.evalFinished()) {
                            getCongratulationsPopup(context);
                          }
                        });
                      }
                    },
                    child: Text(AppLocalizations.of(context)!.save,
                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                            color: Theme.of(context).colorScheme.onSurface)),
                  )
                ])),
          ],
        );
      },
    );
  }

  void getCongratulationsPopup(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
            title: Text(AppLocalizations.of(context)!.congratsTitle),
            content: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(
                Icons.celebration,
                color: Theme.of(context).colorScheme.secondary,
                size: MediaQuery.of(context).size.width * 0.4,
              ),
              Text(AppLocalizations.of(context)!.congratsDesc)
            ]),
            actions: [
              Center(
                  child: FilledButton(
                      style: ButtonStyle(
                          backgroundColor: WidgetStateProperty.all(
                              const Color.fromARGB(255, 223, 223, 223))),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: Text(AppLocalizations.of(context)!.okay,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium!
                              .copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface))))
            ]);
      },
    );
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
                Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                        border: Border.all(
                            width: 2,
                            color: Theme.of(context).colorScheme.error)),
                    child: Text(goal.name,
                        style: Theme.of(context).textTheme.bodyLarge))
              ]),
          actions: [
            FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      FilledButton(
                        style: ButtonStyle(
                            backgroundColor: WidgetStateProperty.all(
                                Color.fromARGB(255, 223, 223, 223))),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: Text(AppLocalizations.of(context)!.cancel,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium!
                                .copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface)),
                      ),
                      FilledButton(
                        style: ButtonStyle(
                            backgroundColor: WidgetStateProperty.all(
                                Theme.of(context).colorScheme.error)),
                        onPressed: () {
                          Navigator.of(context).pop();
                          setState(() {
                            goalHandler.deleteGoal(context, goal);
                          });
                        },
                        child: Text(
                            AppLocalizations.of(context)!.deletionSubmit,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium!
                                .copyWith(
                                    color:
                                        Theme.of(context).colorScheme.onError)),
                      ),
                    ]))
          ],
        );
      },
    );
  }

  Widget getDropDownRow(BuildContext context) {
    if (goalHandler.curGoalIndex == -1 && goalHandler.goallist.isNotEmpty) {
      mapUtils.updateMap(context, goalHandler, goalHandler.goallist[0]);
    }

    return Container(
        color: Theme.of(context).colorScheme.secondary,
        child: Row(
          children: [
            const Padding(padding: EdgeInsets.only(left: 10)),
            SizedBox(
                width: MediaQuery.of(context).size.width * 0.60,
                child: DropdownButton(
                  isExpanded: true,
                  value: goalHandler.goallist.isNotEmpty
                      ? goalHandler.curGoal
                      : null,
                  icon: const Icon(Icons.keyboard_arrow_down),
                  dropdownColor: Theme.of(context).colorScheme.secondary,
                  iconEnabledColor: Theme.of(context).colorScheme.onSecondary,
                  items: goalHandler.goallist.map((Goal item) {
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
                      mapUtils.updateMap(context, goalHandler, newGoal!);
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
                showDeleteConfirmationPopUp(context, goalHandler.curGoal);
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

/// weite wege, die schräg sind da läuft unser user icon vom weg runter
/// bar prozent ist nicht mittig
///
/// 1.0:
///
/// Overall:
/// - make popups pretty
/// - make button style
///
/// logic:
/// - fix schräg issues
/// - fix issue with moving the map after something is updated
///
/// Settings:
/// - add dark theme
/// wenn ich bei distanz 1.0 hinzufüge ist alles weird, komma ist jetzt super
///