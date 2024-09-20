import 'package:flutter/material.dart';

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
    Goal(
        name: "Huhu",
        latStart: 0.0,
        longStart: 1.0,
        latEnd: 5.5,
        longEnd: 50.5,
        finished: false,
        totalDistance: 50.0)
  ];
  late int curGoalIndex;

  @override
  void initState() {
    super.initState();
    loadGoalList();
    curGoalIndex = 0;
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
                  curGoalIndex =
                      goallist.indexWhere((goal) => goal.id == newValue!.id);
                });
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
        Text("Map"),
        Row(
          children: [
            FilledButton(
                onPressed: () {
                  showWorkoutPopup(context, null);
                },
                child: Text("huhu")),
            // Text("Button"),
            Column(
              children: [
                Text(
                    "Remaining Distance: ${goallist[curGoalIndex].totalDistance - goallist[curGoalIndex].curDistance}"),
                Text("Schon geschafft: ${goallist[curGoalIndex].curDistance}")
              ],
            )
          ],
        )
      ],
    );
  }

  void showPopup(BuildContext context, Goal? goal) {
    TextEditingController goalController =
        TextEditingController(text: goal?.name);
    TextEditingController descriptionController =
        TextEditingController(text: goal?.description);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Neues Goal hinzufügen'),
          content: Column(
            children: [
              TextField(
                  controller: goalController,
                  decoration: const InputDecoration(hintText: "Name")),
              TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(hintText: "Beschreibung")),
              Text("Startpunkt"),
              Text("Endpunkt"),
              Text("berechnete Distanz zwischen Start- und Endpunkt: ${8} ")
            ],
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
                addGoal(goalController.text, "Viva Canada", 0.0, 1.0, 50.5,
                    50.0, false, 100.0, 50.0);
                Navigator.of(context).pop();
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
    TextEditingController typeController =
        TextEditingController(text: goal?.name);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Neues Workout hinzufügen'),
          content: Column(children: [
            TextField(
                controller: distanceController,
                decoration: const InputDecoration(hintText: "Distance")),
            TextField(
                controller: typeController,
                decoration: const InputDecoration(hintText: "Type"))
          ]),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Abbrechen'),
            ),
            TextButton(
              onPressed: () {
                addGoal("name", "Description", 0.0, 1.0, 50.5, 50.0, false,
                    100.0, 50.0);
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

  void editGoal(String newname, Goal Goal) {
    Goal.name = newname;
    DatabaseHelper.updateGoal(Goal);

    setState(() {
      goallist[goallist.indexWhere((item) => item.id == Goal.id)] = Goal;
    });
  }

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
