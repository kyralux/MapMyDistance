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
      String name,
      String description,
      double latStart,
      double longStart,
      double latEnd,
      double longEnd,
      bool finished,
      double totalDistance,
      double curDistance,
      ColorScheme colors) {
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
    mapUtils.updateMap(this, goal, colors);
  }

  void deleteGoal(Goal goal, ColorScheme colors) {
    goallist.removeAt(curGoalIndex);
    if (goallist.isNotEmpty) {
      mapUtils.updateMap(this, goallist[0], colors);
    } else {
      curGoalIndex = -1;
    }
    DatabaseHelper.deleteGoal(goal.id!);
  }

  void addWorkout(double distance, ColorScheme colors) {
    goallist[curGoalIndex].curDistance += distance;
    mapUtils.updateUserMarker(goallist[curGoalIndex], colors);
    DatabaseHelper.editGoal(goallist[curGoalIndex]);
  }

  Future<void> loadGoalList(ColorScheme colors) async {
    List<Goal> v = await DatabaseHelper.getGoals();

    if (v.isNotEmpty) {
      goallist = v;
      updateCurGoal();
      mapUtils.updateMap(this, curGoal, colors);
    }
  }
}
