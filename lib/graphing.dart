import 'dart:math';

import 'package:flutter/material.dart';
//import 'db_model.dart';

class DayGraph extends StatefulWidget {
  ///Dimensions used for the canvas boundaries
  final Size dimensions;

  const DayGraph({
    super.key,
    required this.dimensions
  });

  @override
  State<StatefulWidget> createState() => DayGraphState();
}


class DayGraphState extends State<DayGraph> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: SegmentedCircle(),
      //size: widget.dimensions,
      child: Container(
        height: widget.dimensions.height,
        width: widget.dimensions.width,
        alignment: Alignment.center,
        child: Text("WIP")
      )
    );
  }
}


class SegmentedCircle extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Offset.zero & size;
    final Paint style = Paint();

    //Styling the general arc details
    style.style = PaintingStyle.stroke;
    style.strokeCap = StrokeCap.round;
    style.strokeWidth = 5;

    //Offset for the start/end of arc segments - strokeCap extends past the endpoint
    //of drawn arcs, so adjacent arcs must be offset to fit nicely
    const double roundOffset = pi/36;

    //TODO: Dynamically populate arc segments using meals/nutrition from db
    style.color = Color.fromARGB(200, 155, 155, 155);
    canvas.drawArc(rect, 0, pi-roundOffset, false, style);
    style.color = Color.fromARGB(200, 229, 91, 0);
    canvas.drawArc(rect, pi+roundOffset, pi/6-2*roundOffset, false, style);
    style.color = Color.fromARGB(200, 22, 255, 190);
    canvas.drawArc(rect, pi+(pi/6)+roundOffset, pi/4-2*roundOffset, false, style);
  }

  // TODO: Update when meal data changes
  @override
  bool shouldRepaint(SegmentedCircle oldDelegate) => false;
}