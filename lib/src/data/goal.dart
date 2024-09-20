class Goal {
  Goal({
    this.id,
    required this.name,
    this.description = "",
    required this.latStart,
    required this.longStart,
    required this.latEnd,
    required this.longEnd,
    required this.finished,
    required this.totalDistance,
    this.curDistance = 0.0,
  });

  int? id;
  late String name;
  late String description;
  late double latStart;
  late double longStart;
  late double latEnd;
  late double longEnd;
  late bool finished;
  late double totalDistance;
  late double curDistance;

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'latStart': latStart,
      'longStart': longStart,
      'latEnd': latEnd,
      'longEnd': longEnd,
      'finished': finished,
      'totalDistance': totalDistance,
      'curDistance': curDistance
    };
  }

  // @override
  // bool operator ==(Object other) {
  //   return other is Goal && id == other.id;
  // }

  // @override
  // int get hashCode => id.hashCode;
}
