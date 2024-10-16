import 'dart:ffi';

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
  bool isDataLoaded = false;

  void _loadData() {
    setState(() {
      goalHandler.loadGoalList(Theme.of(context).colorScheme).then((_) {
        setState(() {
          Future.delayed(const Duration(milliseconds: 500), () {
            if (goalHandler.goallist.isNotEmpty) {
              mapUtils.updateMap(
                  goalHandler,
                  goalHandler.goallist[goalHandler.curGoalIndex],
                  Theme.of(context).colorScheme);
            }
          });
        });
      });
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!isDataLoaded) {
      _loadData();
      isDataLoaded = true;
    }
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    mapUtils.disposeController();
    _mapControllerDialog.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    setState(() {
      if (goalHandler.goallist.isNotEmpty) {
        mapUtils.updateMap(
            goalHandler,
            goalHandler.goallist[goalHandler.curGoalIndex],
            Theme.of(context).colorScheme);
      }
    });

    final locale = Localizations.localeOf(context);
    f = NumberFormat.decimalPatternDigits(
        locale: locale.toString(),
        decimalDigits: 2); //.decimalPattern(locale.toString());
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Image.asset(
                "assets/images/gradientGPS-empty.PNG",
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
                Navigator.restorablePushNamed(context, SettingsView.routeName);
              }),
        ],
      ),
      body: SingleChildScrollView(
          child: Container(
        height: MediaQuery.of(context).size.height * 0.9,
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
      )),
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

  double calculateProgress() {
    var result = 0.0;
    try {
      result =
          goalHandler.curGoal.curDistance / goalHandler.curGoal.totalDistance;
    } catch (e) {
      return 1;
    }
    return result;
  }

  Widget getProgressBar() {
    return Stack(
      children: [
        LinearPercentIndicator(
          padding: const EdgeInsets.all(0),
          lineHeight: 30.0,
          percent:
              goalHandler.curGoal.evalFinished() ? 1.0 : calculateProgress(),
          backgroundColor: Theme.of(context).colorScheme.surface,
          progressColor: Colors.transparent,
          animation: true,
        ),
        goalHandler.curGoal.totalDistance > 0
            ? Positioned.fill(
                child: FractionallySizedBox(
                  widthFactor: goalHandler.curGoal.curDistance /
                      goalHandler.curGoal.totalDistance,
                  alignment: Alignment.centerLeft,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).brightness == Brightness.dark
                              ? Color.fromARGB(255, 41, 0, 130)
                              : Color.fromARGB(255, 255, 247, 0),
                          // Color(0xFFFF8C00),
                          Theme.of(context).colorScheme.tertiary,
                        ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                    ),
                  ),
                ),
              )
            : Container(),
        Container(
            padding: const EdgeInsets.only(top: 4),
            alignment: Alignment.center,
            child: Text(
              '${(calculateProgress() * 100).toStringAsFixed(2)}%',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            )),
      ],
    );
  }

  Widget _buildEmptyView(BuildContext context) {
    goalHandler.goallist = goalHandler
        .goallist; // seems like i need this so it reacts on the change later and shows the first goal;
    return Padding(
      padding: const EdgeInsets.all(16.0),
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
              SizedBox(height: MediaQuery.of(context).size.height * 0.7),
              Container(
                  width: double.infinity,
                  color: Theme.of(context).colorScheme.tertiary,
                  child: Text(
                    "0 / 0 ${widget.controller.distanceUnit.short}",
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge,
                  )),
            ],
          ),
        ),
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
                  Theme.of(context).brightness == Brightness.dark,
                ),
                Padding(
                  padding: const EdgeInsets.all(0),
                  child: getProgressBar(),
                ),
                Container(
                    width: double.infinity,
                    color: Theme.of(context).colorScheme.tertiary,
                    child: Text(
                      "${formatNumber(goalHandler.curGoal.curDistance)} / ${formatNumber(goalHandler.curGoal.totalDistance)} ${widget.controller.distanceUnit.short}",
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge,
                    )),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void showGoalDialog(BuildContext context, Goal? goal) {
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
              titlePadding: EdgeInsets.zero,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.zero,
              ),
              title: Container(
                  color: Theme.of(context).colorScheme.secondary,
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.newGoalTitle,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSecondary,
                        ),
                      ),
                      IconButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          icon: const Icon(Icons.close))
                    ],
                  )),
              content: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    FocusScope.of(context).requestFocus(FocusNode());
                  },
                  child: SingleChildScrollView(
                      child: Form(
                          key: formKey,
                          child: Column(
                            children: [
                              TextFormField(
                                focusNode: FocusNode(),
                                cursorColor:
                                    Theme.of(context).colorScheme.secondary,
                                controller: goalController,
                                decoration: InputDecoration(
                                  hintStyle:
                                      const TextStyle(color: Colors.grey),
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .secondary,
                                      width: 2.0,
                                    ),
                                  ),
                                  hintText:
                                      AppLocalizations.of(context)!.newGoalName,
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return AppLocalizations.of(context)!
                                        .newGoalName;
                                  }
                                  if (value.length > 100) {
                                    return AppLocalizations.of(context)!
                                        .errorGoalNameLong;
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(
                                height: 20,
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
                                        decoration: InputDecoration.collapsed(
                                            hintStyle: const TextStyle(
                                                color: Colors.grey),
                                            hintText:
                                                AppLocalizations.of(context)!
                                                    .newGoaStart))),
                                FilledButton(
                                  onPressed: () async {
                                    selectedLocationStart =
                                        await showLocationPicker(
                                            context,
                                            AppLocalizations.of(context)!
                                                .locationPickerStart);
                                    if (selectedLocationStart != null) {
                                      startPositionController.text =
                                          AppLocalizations.of(context)!.set;

                                      if (selectedLocationEnd != null) {
                                        setState(() {
                                          calculatedDistance =
                                              mapUtils.calculateDistance(
                                                  selectedLocationStart
                                                      ?.latitude,
                                                  selectedLocationStart
                                                      ?.longitude,
                                                  selectedLocationEnd?.latitude,
                                                  selectedLocationEnd
                                                      ?.longitude);
                                        });
                                      }
                                    }
                                  },
                                  style: ButtonStyle(
                                      backgroundColor: WidgetStatePropertyAll(
                                          Theme.of(context)
                                              .colorScheme
                                              .tertiary)),
                                  child: Icon(
                                    Icons.add_location,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onTertiary,
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
                                        decoration: InputDecoration.collapsed(
                                            hintStyle: const TextStyle(
                                                color: Colors.grey),
                                            hintText:
                                                AppLocalizations.of(context)!
                                                    .newGoalEnde))),
                                FilledButton(
                                  onPressed: () async {
                                    selectedLocationEnd =
                                        await showLocationPicker(
                                            context,
                                            AppLocalizations.of(context)!
                                                .locationPickerEnd);
                                    if (selectedLocationEnd != null) {
                                      endPositionController.text =
                                          AppLocalizations.of(context)!.set;
                                      if (selectedLocationStart != null) {
                                        setState(() {
                                          calculatedDistance =
                                              mapUtils.calculateDistance(
                                                  selectedLocationStart
                                                      ?.latitude,
                                                  selectedLocationStart
                                                      ?.longitude,
                                                  selectedLocationEnd?.latitude,
                                                  selectedLocationEnd
                                                      ?.longitude);
                                        });
                                      }
                                    }
                                  },
                                  style: ButtonStyle(
                                      backgroundColor: WidgetStatePropertyAll(
                                          Theme.of(context)
                                              .colorScheme
                                              .tertiary)),
                                  child: Icon(
                                    Icons.add_location,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onTertiary,
                                  ),
                                ),
                              ]),
                              const SizedBox(
                                height: 20,
                              ),
                              FittedBox(
                                  child: Row(
                                children: [
                                  Text(
                                      AppLocalizations.of(context)!
                                          .newGoaDistance,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium),
                                  SizedBox(
                                    width: 10,
                                  ),
                                  Text(
                                    "${formatNumber(calculatedDistance)} ${widget.controller.distanceUnit.short}",
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .tertiary,
                                        ),
                                  ),
                                ],
                              )),
                            ],
                          )))),
              actions: [
                Center(
                    child: ElevatedButton.icon(
                  style: ButtonStyle(
                      backgroundColor: WidgetStateProperty.all(
                          Theme.of(context).colorScheme.secondary)),
                  label: Text(AppLocalizations.of(context)!.save,
                      style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                          color: Theme.of(context).colorScheme.onSecondary)),
                  icon: Icon(
                    Icons.add,
                    color: Theme.of(context).colorScheme.onSecondary,
                  ),
                  onPressed: () {
                    if (formKey.currentState?.validate() ?? false) {
                      setState(() {
                        if (selectedLocationEnd != null &&
                            selectedLocationStart != null) {
                          goalHandler.addGoal(
                              goalController.text,
                              "",
                              selectedLocationStart!.latitude,
                              selectedLocationStart!.longitude,
                              selectedLocationEnd!.latitude,
                              selectedLocationEnd!.longitude,
                              false,
                              calculatedDistance,
                              0.0,
                              Theme.of(context).colorScheme);
                          calculatedDistance = 0;
                          Navigator.of(context).pop();
                        }
                      });
                    }
                  },
                ))
              ]);
        });
      },
    );
  }

  Future<LatLng?> showLocationPicker(
    BuildContext context,
    String titletext,
  ) {
    return showDialog<LatLng?>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          titlePadding: EdgeInsets.zero,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.zero,
          ),
          title: Container(
              color: Theme.of(context).colorScheme.secondary,
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    titletext,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSecondary,
                    ),
                  ),
                  IconButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      icon: const Icon(Icons.close))
                ],
              )),
          content: SizedBox(
              width: double.maxFinite,
              child: mapUtils.getLocationPickerMap(
                  goalHandler.goallist.isNotEmpty
                      ? LatLng(goalHandler.curGoal.latStart,
                          goalHandler.curGoal.longStart)
                      : const LatLng(49.843, 9.902056),
                  _mapControllerDialog,
                  Theme.of(context).colorScheme)),
          actions: [
            Container(
              alignment: Alignment.center,
              child: ElevatedButton.icon(
                style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.all(
                        Theme.of(context).colorScheme.secondary)),
                label: Text(AppLocalizations.of(context)!.save,
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        color: Theme.of(context).colorScheme.onSecondary)),
                icon: Icon(
                  Icons.add,
                  color: Theme.of(context).colorScheme.onSecondary,
                ),
                onPressed: () {
                  Navigator.of(context).pop(_mapControllerDialog.camera.center);
                },
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
          titlePadding: EdgeInsets.zero,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.zero,
          ),
          title: Container(
              color: Theme.of(context).colorScheme.secondary,
              padding: const EdgeInsets.all(16), // Add padding
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AppLocalizations.of(context)!.distanceTitle,
                    style: TextStyle(
                      color: Theme.of(context)
                          .colorScheme
                          .onSecondary, // Text color
                    ),
                  ),
                  IconButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      icon: Icon(
                        Icons.close,
                        color: Theme.of(context).colorScheme.onSecondary,
                      ))
                ],
              )),
          content: SingleChildScrollView(
              child: Form(
                  key: formKey,
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Text(AppLocalizations.of(context)!.distanceDescription),
                    const SizedBox(height: 10),
                    Row(children: [
                      Expanded(
                          child: TextFormField(
                        cursorColor: Theme.of(context).colorScheme.secondary,
                        controller: distanceController,
                        decoration: InputDecoration(
                          hintStyle: const TextStyle(color: Colors.grey),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: Theme.of(context).colorScheme.secondary,
                              width: 2.0,
                            ),
                          ),
                          hintText: AppLocalizations.of(context)!.distanceHint,
                        ),
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
                      Text(widget.controller.distanceUnit.short)
                    ]),
                  ]))),
          actions: [
            Center(
              child: ElevatedButton.icon(
                  style: ButtonStyle(
                      backgroundColor: WidgetStateProperty.all(
                          Theme.of(context).colorScheme.secondary)),
                  label: Text(AppLocalizations.of(context)!.save,
                      style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                          color: Theme.of(context).colorScheme.onSecondary)),
                  icon: Icon(
                    Icons.add,
                    color: Theme.of(context).colorScheme.onSecondary,
                  ),
                  onPressed: () {
                    if (formKey.currentState?.validate() ?? false) {
                      setState(() {
                        goalHandler.addWorkout(
                            f.parse(distanceController.text).toDouble(),
                            Theme.of(context).colorScheme);
                        Navigator.of(context).pop();
                        if (!goalHandler.curGoal.finished &&
                            goalHandler.curGoal.evalFinished()) {
                          getCongratulationsPopup(context);
                          goalHandler.curGoal.finished = true;
                        }
                      });
                    }
                  }),
            ),
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
            titlePadding: EdgeInsets.zero,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.zero,
            ),
            title: Container(
              color: Theme.of(context).colorScheme.secondary,
              padding: const EdgeInsets.all(16),
              child: Text(
                AppLocalizations.of(context)!.congratsTitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color:
                      Theme.of(context).colorScheme.onSecondary, // Text color
                ),
              ),
            ),
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
                              Theme.of(context).colorScheme.tertiary)),
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
                                      .onTertiary))))
            ]);
      },
    );
  }

  void showDeleteConfirmationPopUp(BuildContext context, Goal goal) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          titlePadding: EdgeInsets.zero,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.zero,
          ),
          title: Container(
              color: Theme.of(context)
                  .colorScheme
                  .error, // Set background color for title
              padding: const EdgeInsets.all(16), // Add padding
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AppLocalizations.of(context)!.deletionTitle,
                    style: TextStyle(
                      color:
                          Theme.of(context).colorScheme.onError, // Text color
                    ),
                  ),
                  IconButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      icon: Icon(
                        Icons.close,
                        color: Theme.of(context).colorScheme.onError,
                      ))
                ],
              )),
          content: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(AppLocalizations.of(context)!.deletionDescription,
                    style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 10),
                Container(
                    padding: const EdgeInsets.all(10),
                    child: Text(goal.name,
                        style: Theme.of(context).textTheme.titleLarge))
              ]),
          actions: [
            Center(
              child: FilledButton(
                style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.all(
                        Theme.of(context).colorScheme.error)),
                onPressed: () {
                  Navigator.of(context).pop();
                  setState(() {
                    goalHandler.deleteGoal(goal, Theme.of(context).colorScheme);
                  });
                },
                child: Text(AppLocalizations.of(context)!.deletionSubmit,
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        color: Theme.of(context).colorScheme.onError)),
              ),
            )
          ],
        );
      },
    );
  }

  Widget getDropDownRow(BuildContext context) {
    if (goalHandler.curGoalIndex == -1 && goalHandler.goallist.isNotEmpty) {
      mapUtils.updateMap(
          goalHandler, goalHandler.goallist[0], Theme.of(context).colorScheme);
    }

    return Container(
        color: Theme.of(context).colorScheme.secondary,
        child: Row(
          children: [
            const Padding(padding: EdgeInsets.only(left: 10)),
            SizedBox(
                width: MediaQuery.of(context).size.width * 0.60,
                child: DropdownButton(
                  hint: Text(AppLocalizations.of(context)!.emptyText),
                  underline: Container(),
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
                      mapUtils.updateMap(
                          goalHandler, newGoal!, Theme.of(context).colorScheme);
                    });
                  },
                )),
            IconButton(
              onPressed: () {
                showGoalDialog(context, null);
              },
              color: Theme.of(context).colorScheme.secondary,
              icon: Icon(
                Icons.add,
                color: Theme.of(context).colorScheme.onSecondary,
              ),
            ),
            goalHandler.goallist.isNotEmpty
                ? IconButton(
                    onPressed: () {
                      showDeleteConfirmationPopUp(context, goalHandler.curGoal);
                    },
                    color: Theme.of(context).colorScheme.secondary,
                    icon: Icon(
                      Icons.delete,
                      color: Theme.of(context).colorScheme.onSecondary,
                    ),
                  )
                : Container(),
          ],
        ));
  }
}
