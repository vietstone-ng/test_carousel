import 'dart:math';

import 'package:flutter/material.dart';

int numItems = 10;
var onFrontCard = FrontCardNotifier(0);

class FrontCardNotifier with ChangeNotifier {
  FrontCardNotifier(this._value);

  int _value = 0;
  int get value => _value;
  set value(int val) {
    _value = val;
    notifyListeners();
  }
}

class RotationSceneV3 extends StatefulWidget {
  const RotationSceneV3({super.key});

  @override
  _RotationSceneV3State createState() => _RotationSceneV3State();
}

class _RotationSceneV3State extends State<RotationSceneV3> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: const SceneCardSelector(),
      body: Container(
        decoration: const BoxDecoration(
            gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xff74ABE4), Color(0xffA892ED)],
          stops: [0, 1],
        )),
        child: const MyScener(),
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

class _MyScenerState extends State<MyScener> with TickerProviderStateMixin {
  late AnimationController _frontCardCtrl;

  List<CardData> cardData = [];
  double radio = 200.0;
  double radioStep = 0;

  double _dragX = 0;
  double frontAngle = 0;
  double angleOffset = 0;

  @override
  void initState() {
    cardData = List.generate(numItems, (index) => CardData(index)).toList();
    radioStep = (pi * 2) / numItems;

    _frontCardCtrl = AnimationController.unbounded(vsync: this);
    _frontCardCtrl.addListener(() => setState(() {}));

    // we want to center the front card
    onFrontCard.addListener(() {
      var idx = onFrontCard.value;
      _dragX = 0;
      frontAngle = -idx * radioStep;

      var beginAngle = angleOffset - pi / 2;
      // because one point can be expressed by multiple different angles in a trigonometric circle
      // we need to find the closest to the front angle.
      if (beginAngle < frontAngle) {
        while ((frontAngle - beginAngle).abs() > pi) {
          beginAngle += pi * 2;
        }
      } else {
        while ((frontAngle - beginAngle).abs() > pi) {
          beginAngle -= pi * 2;
        }
      }

      // animate the front card to the front angle
      _frontCardCtrl.value = beginAngle;
      _frontCardCtrl.animateTo(
        frontAngle,
        duration: const Duration(milliseconds: 300),
      );
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    angleOffset = pi / 2 + (-_dragX * .006);
    angleOffset += _frontCardCtrl.value;

    // positioning cards in a circle
    for (var i = 0; i < cardData.length; ++i) {
      var c = cardData[i];
      double ang = angleOffset + c.idx * radioStep;
      c.angle = ang;
      c.x = cos(ang) * radio;
      c.y = sin(ang) * 100;
      c.z = sin(ang) * radio;
    }

    // sort in Z axis.
    cardData.sort((a, b) => a.z.compareTo(b.z));

    // transform the cards
    var list = cardData.map((vo) {
      var c = addCard(vo);
      var mt2 = Matrix4.identity();
      mt2.setEntry(3, 2, 0.001);

      // position the card based on x,y,z
      mt2.translate(vo.x, vo.y, -vo.z);

      // scale the card based on z position
      double scale = 1 + (vo.z / radio) * 0.5;
      mt2.scale(scale, scale);

      c = Transform(
        alignment: Alignment.center,
        origin: const Offset(0.0, 0.0),
        transform: mt2,
        child: c,
      );

      return c;
    }).toList();

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanDown: (e) {},
      onPanUpdate: (e) {
        _dragX += e.delta.dx;
        setState(() {});
      },
      onPanEnd: (e) {
        // Find the front card (with biggest z value), and re-center it.
        var maxZ =
            cardData.reduce((curr, next) => curr.z > next.z ? curr : next);
        onFrontCard.value = maxZ.idx;
      },
      child: Container(
        alignment: Alignment.center,
        child: Stack(
          alignment: Alignment.center,
          children: list,
        ),
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

class SceneCardSelector extends StatelessWidget {
  const SceneCardSelector({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      height: 80,
      child: Row(
        children: List.generate(
            numItems,
            (index) => Expanded(
                  child: SizedBox(
                    height: 80,
                    child: OutlinedButton(
                      child: Text(index.toString(),
                          style: const TextStyle(color: Colors.white)),
                      onPressed: () => onFrontCard.value = index,
                    ),
                  ),
                )),
      ),
    );
  }
}
