class Workout {
  Workout({
    this.id,
    required this.distance,
    required this.goalId,
    DateTime? timestamp,
    this.activityType = "",
  }) : timestamp = timestamp ?? DateTime.now();

  int? id;
  late double distance;
  DateTime timestamp;
  int? goalId;
  String activityType;

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'distance': distance,
      'timestamp': timestamp,
      'goalId': goalId,
      'activityType': activityType,
    };
  }

  // @override
  // String toString() {
  //   return 'Goal{id: $id, name: $name, description: $description}';
  // }
}
