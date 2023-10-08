import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';

class RotationSceneV1 extends StatefulWidget {
  const RotationSceneV1({super.key});

  @override
  _RotationSceneV1State createState() => _RotationSceneV1State();
}

class _RotationSceneV1State extends State<RotationSceneV1> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
            gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xff74ABE4), Color(0xffA892ED)],
          stops: [0, 1],
        )),
        child: const Center(child: MyScener()),
      ),
    );
  }
}

class CardData {
  late Color color;
  late double x, y, z, angle;
  final int idx;
  double alpha = 0;

  Color get lightColor {
    var val = HSVColor.fromColor(color);
    return val.withSaturation(.5).withValue(.8).toColor();
  }

  CardData(this.idx) {
    color = Colors.primaries[idx % Colors.primaries.length];
    x = 0;
    y = 0;
    z = 0;
  }
}

class MyScener extends StatefulWidget {
  const MyScener({super.key});

  @override
  _MyScenerState createState() => _MyScenerState();
}

class _MyScenerState extends State<MyScener>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  List<CardData> cardData = [];
  int numItems = 9;
  double radio = 200.0;
  late double radioStep;
  int centerIdx = 1;

  @override
  void initState() {
    cardData = List.generate(numItems, (index) => CardData(index)).toList();
    radioStep = (pi * 2) / numItems;

    _animationController =
        AnimationController(vsync: this, duration: const Duration(seconds: 5));

    _animationController.addListener(() => setState(() {}));
    _animationController.addStatusListener((status) async {
      if (status == AnimationStatus.completed) {
        _animationController.value = 0;
        _animationController.animateTo(1);
        ++centerIdx;
      }

      // if (status == AnimationStatus.completed) {
      //   print("inside");
      //   print(_animationController.value);
      //   // _animationController.value = 0;
      //   // _animationController.animateTo(1);
      //   // print(centerIdx);
      //   // ++centerIdx;
      // }
    });

    _animationController.forward();
    // _animationController.reverse(from: 1);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var ratio = _animationController.value;
    double animValue = centerIdx + ratio; // radians
    // process positions.
    for (var i = 0; i < cardData.length; ++i) {
      var c = cardData[i];
      double ang = c.idx * radioStep + animValue; // radians
      c.angle = ang + pi / 2;
      c.x = cos(ang) * radio;
      c.y = sin(ang) * 100;
      c.z = sin(ang) * radio;
    }

    // sort in Z axis.
    cardData.sort((a, b) => a.z.compareTo(b.z));

    var list = cardData.map((vo) {
      var c = addCard(vo);
      var mt2 = Matrix4.identity();
      mt2.setEntry(3, 2, 0.001);
      mt2.translate(vo.x, vo.y, -vo.z);

      double scale = 1 + (vo.z / radio) * 0.5;
      mt2.scale(scale, scale); // add this line to scale the card

      // mt2.rotateY(vo.angle + pi);
      c = Transform(
        alignment: Alignment.center,
        origin: const Offset(0.0, -0.0),
        transform: mt2,
        child: c,
      );

      // depth of field... doesnt work on web.
//      var blur = .4 + ((1 - vo.z / radio) / 2) * 2;
//      c = BackdropFilter(
//        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
//        child: c,
//      );

      return c;
    }).toList();

    return Container(
      alignment: Alignment.center,
      child: Stack(
        alignment: Alignment.center,
        children: list,
      ),
    );
  }

  Widget addCard(CardData vo) {
    var alpha = ((1 - vo.z / radio) / 2) * .6;
    Widget c;
    c = Container(
      margin: const EdgeInsets.all(12),
      width: 150,
      height: 100,
      alignment: Alignment.center,
      foregroundDecoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.black.withOpacity(alpha),
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: const [0.1, .9],
          colors: [vo.lightColor, vo.color],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(.2 + alpha * .2),
              spreadRadius: 1,
              blurRadius: 12,
              offset: const Offset(0, 2))
        ],
      ),
      child: Text('ITEM ${vo.idx}'),
    );
    return c;
  }
}
