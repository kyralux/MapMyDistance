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

    goallist.add(goal);
    mapUtils.updateMap(context, this, goal);
  }

  void deleteGoal(BuildContext context, Goal goal) {
    goallist.removeAt(curGoalIndex);
    if (goallist.isNotEmpty) {
      mapUtils.updateMap(context, this, goallist[0]);
    } else {
      curGoalIndex = -1;
    }
    DatabaseHelper.deleteGoal(goal.id!);
  }

  void addWorkout(BuildContext context, double distance) {
    goallist[curGoalIndex].curDistance += distance;
    mapUtils.updateUserMarker(context, goallist[curGoalIndex]);
    DatabaseHelper.editGoal(goallist[curGoalIndex]);
  }

  Future<void> loadGoalList(BuildContext context) async {
    List<Goal> v = await DatabaseHelper.getGoals();

    if (v.isNotEmpty) {
      goallist = v;
      updateCurGoal();
      mapUtils.updateMap(
          context, this, curGoal); //this breaks the controller thingy
    }
  }
}
// adding new goals doesnt work right now