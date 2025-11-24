import 'dart:math';

import 'package:flutter/material.dart';

class DayGraph extends StatefulWidget {
  ///Dimensions used for the canvas boundaries
  final Size dimensions;
  final double fillPercentage;

  const DayGraph({
    super.key,
    required this.dimensions,
    required this.fillPercentage
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
      painter: SegmentedCircle(widget.fillPercentage),
      //size: widget.dimensions,
      child: Container(
        height: widget.dimensions.height,
        width: widget.dimensions.width,
        alignment: Alignment.center,
        child: Text("${widget.fillPercentage * 100}%")
      )
    );
  }
}


class SegmentedCircle extends CustomPainter {
  double fillPercentage;
  SegmentedCircle(this.fillPercentage);

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
    canvas.drawArc(rect, 0, pi+(pi/2)-roundOffset, false, style);
    // style.color = Color.fromARGB(200, 229, 91, 0);
    // canvas.drawArc(rect, pi+roundOffset, pi/6-2*roundOffset, false, style);
    style.color = Color.fromARGB(200, 22, 255, 190);
    canvas.drawArc(rect, 0, (pi+pi/2)*fillPercentage-roundOffset, false, style);
  }

  // TODO: Update when meal data changes
  @override
  bool shouldRepaint(SegmentedCircle oldDelegate) => false;
}


class StepGraph extends StatefulWidget {
  final double height;

  const StepGraph({
    super.key,
    required this.height
  });

  @override
  State<StatefulWidget> createState() => StepGraphState();
}


class StepGraphState extends State<StepGraph> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: StepBars(),
      child: SizedBox(
        height: widget.height,
      )
    );
  }
}


class StepBars extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint style = Paint();

    //Styling bar details
    //style.style = PaintingStyle.stroke;
    style.strokeCap = StrokeCap.round;
    style.strokeWidth = 8;
    style.color = Color.fromARGB(200, 115, 115, 115);

    //Placeholder bar graph
    //TODO: Populate using step data, when step data is implemented
    var scales = [5, 15, 20, 10, 30, 50, 45, 52, 50, 25, 10, 4, 23, 21, 48];
    //canvas.drawLine(Offset(10,10), Offset(20,20), style);
    for (int i = 0; i < scales.length; i++) {
      canvas.drawLine(Offset(i*12.0+10, 58.0), Offset(i*12.0+10, 58.0-scales[i]), style);
    }

  }

  //TODO: Update when step data changes
  @override
  bool shouldRepaint(StepBars oldDelegate) => false;

}