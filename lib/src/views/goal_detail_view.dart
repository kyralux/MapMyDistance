// import 'package:flutter/material.dart';
// import 'package:taskvision/src/data/goal.dart';

// class GoalDetailView extends StatefulWidget {
//   final Goal goal;
//   const GoalDetailView({super.key, required this.goal});
//   static const routeName = '/goal';

//   @override
//   State<GoalDetailView> createState() => _GoalDetailViewState(goal);
// }

// class _GoalDetailViewState extends State<GoalDetailView> {
//   final Goal goal;
//   _GoalDetailViewState(this.goal);

//   @override
//   void initState() {
//     super.initState();
//   }

//   @override
//   void dispose() {
//     super.dispose();
//   }

//   @override
//   void deactivate() {
//     super.deactivate();
//   }

//   @override
//   Widget build(BuildContext context) {
//     List<String> taskList = ["goal 1", "goal 2"];
//     List<String> featured = ["feature 1", "feature 2"];
//     List<String> mastered = ["master 1", "master 2"];
//     return Scaffold(
//       //appBar: AppBar(backgroundColor: Colors.purple),
//       body: SingleChildScrollView(
//           child: Column(children: [
//         Stack(
//           children: [
//             ConstrainedBox(
//               constraints: const BoxConstraints(minHeight: 80),
//               child: buildHeader(),
//             ),
//             Positioned(
//               top: 800,
//               child: const Text(
//                 "I'm currently working on",
//                 style: TextStyle(
//                   fontSize: 28,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//             ),
//             Positioned(
//               left: 36,
//               child: buildFeaturedGoals(featured),
//             ),
//           ],
//         ),
//         const SizedBox(height: 30),
//         const Text(
//           "Future Goals",
//           style: TextStyle(
//             fontSize: 28,
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//         buildFutureGoals(taskList),
//         const SizedBox(height: 30),
//         const Text(
//           "Mastered Goals",
//           style: TextStyle(
//             fontSize: 28,
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//         buildMasteredGoals(mastered),
//         const SizedBox(height: 30),
//         const SizedBox(height: 70)
//       ])),
//     );
//   }

//   Widget buildFeaturedGoals(List featured) {
//     return SizedBox(
//       child: Card(
//         child: Container(
//           decoration: BoxDecoration(
//             gradient: LinearGradient(
//               colors: [
//                 Theme.of(context).scaffoldBackgroundColor,
//                 Colors.pink.shade100,
//               ],
//               begin: Alignment.topCenter,
//               end: Alignment.bottomCenter,
//             ),
//           ),
//           child: ConstrainedBox(
//             constraints: const BoxConstraints(maxHeight: 150),
//             child: SizedBox(
//               child: ListView.builder(
//                 shrinkWrap: true,
//                 physics: const ClampingScrollPhysics(),
//                 restorationId: 'featureView',
//                 itemCount: featured.length,
//                 itemBuilder: (BuildContext context, int index) {
//                   var item = featured[index];

//                   return ListTile(
//                     title: Text(
//                       item,
//                       style: const TextStyle(
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                     subtitle: Text("Description von Goal"),
//                   );
//                 },
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget buildFutureGoals(List taskList) {
//     return ConstrainedBox(
//       constraints: const BoxConstraints(maxHeight: 150),
//       child: SizedBox(
//         // Backlog goal List
//         child: ListView.builder(
//           shrinkWrap: true,
//           physics: const ClampingScrollPhysics(),
//           restorationId: 'taskView',
//           itemCount: taskList.length,
//           itemBuilder: (BuildContext context, int index) {
//             var item = taskList[index];

//             return ListTile(
//               title: Text(
//                 item,
//                 style: const TextStyle(
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//               subtitle: Text("Description von Goal"),
//             );
//           },
//         ),
//       ),
//     );
//   }

//   buildMasteredGoals(List mastered) {
//     return ConstrainedBox(
//       constraints: const BoxConstraints(maxHeight: 150),
//       child: SizedBox(
//         // featured goals List
//         child: ListView.builder(
//           shrinkWrap: true,
//           physics: const ClampingScrollPhysics(),
//           restorationId: 'featureView',
//           itemCount: mastered.length,
//           itemBuilder: (BuildContext context, int index) {
//             var item = mastered[index];

//             return ListTile(
//               title: Text(
//                 item,
//                 style: const TextStyle(
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//               subtitle: Text("Description von Goal"),
//             );
//           },
//         ),
//       ),
//     );
//   }

//   Widget buildHeader() {
//     return Container(
//       height: 200,
//       decoration: BoxDecoration(
//         gradient: LinearGradient(
//             colors: [Colors.yellow.shade200, Colors.pink.shade100],
//             begin: Alignment.topLeft,
//             end: Alignment.bottomCenter),
//         borderRadius: const BorderRadius.vertical(
//           bottom: Radius.circular(140),
//         ),
//       ),
//       child: Center(
//         child: Text(
//           goal.name,
//           style: const TextStyle(
//             color: Colors.pink,
//             fontSize: 38,
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//       ),
//     );
//   }
// }
