import 'package:flutter/material.dart';
import 'package:mapgoal/src/data/goal.dart';
import 'package:mapgoal/src/storage/database_helper.dart';
import 'package:mapgoal/src/util/map.dart';

class GoalHandler {
  List<Goal> goallist = [];
  int curGoalIndex = 0;
  late Goal curGoal;
  MapUtils mapUtils = MapUtils();

  void updateCurGoal() {
    curGoal = goallist[curGoalIndex];
  }

  void addGoal(
      BuildContext context,
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

    //setState(() {
    goallist.add(goal);
    //});
    return mapUtils.updateMap(context, this, goal);
  }

  void deleteGoal(BuildContext context, Goal goal) {
    //setState(() {
    goallist.removeAt(curGoalIndex);
    if (goallist.isNotEmpty) {
      mapUtils.updateMap(
          context, this, goallist[curGoalIndex]); // viel geändert
    } else {
      curGoalIndex = -1;
    }
    DatabaseHelper.deleteGoal(goal.id!);
    //}//);
  }

  void addWorkout(BuildContext context, double distance) {
    goallist[curGoalIndex].curDistance += distance;
    mapUtils.updateUserMarker(context, goallist[curGoalIndex]);
    DatabaseHelper.editGoal(goallist[curGoalIndex]);
  }

  Future<void> loadGoalList(BuildContext context) async {
    List<Goal> v = await DatabaseHelper.getGoals();

    //setState(() {
    if (v.isNotEmpty) {
      goallist = v;
      updateCurGoal();
      //updateMap(context, goallist[curGoalIndex]); this breaks the controller thingy
    }

    //});
  }
}
