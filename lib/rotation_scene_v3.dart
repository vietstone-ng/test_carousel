import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

// int numItems = 10;

class RotationSceneV3 extends StatefulWidget {
  const RotationSceneV3({super.key});

  @override
  State<RotationSceneV3> createState() => _RotationSceneV3State();
}

class _RotationSceneV3State extends State<RotationSceneV3> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // bottomNavigationBar: const SceneCardSelector(),
      backgroundColor: Colors.blueAccent,
      // bottomNavigationBar: const PageIndicator(),
      body: Container(
        decoration: const BoxDecoration(
            gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xff74ABE4), Color(0xffA892ED)],
          stops: [0, 1],
        )),
        child: CigCarousel(
          children: List.generate(
              10,
              (index) => Container(
                    color: Colors.primaries[index % Colors.primaries.length],
                    alignment: Alignment.center,
                    child: Text(
                      index.toString(),
                      style: const TextStyle(color: Colors.white),
                    ),
                  )),
        ),
      ),
    );
  }
}

class CardData {
  late double x, y, z, angle;
  final int idx;
  final Widget widget;

  CardData(this.idx, this.widget) {
    x = 0;
    y = 0;
    z = 0;
    angle = 0;
  }
}

class CigCarousel extends StatefulWidget {
  const CigCarousel({super.key, this.children = const []});

  final List<Widget> children;

  @override
  State<CigCarousel> createState() => _CigCarouselState();
}

class _CigCarouselState extends State<CigCarousel>
    with TickerProviderStateMixin {
  AnimationController? _frontCardCtrl;
  AnimationController? _frictionCtrl;

  List<CardData> cardData = [];
  double radius = 200.0;

  double angleStep = 0;

  double _dragX = 0;
  double _velocityX = 0;
  double frontAngle = 0;
  double angleOffset = 0;

  Timer? _autoSlideTimer;

  @override
  void initState() {
    super.initState();

    cardData = widget.children
        .asMap()
        .map((key, value) => MapEntry(key, CardData(key, value)))
        .values
        .toList();
    angleStep = -(pi * 2) / widget.children.length;

    _frontCardCtrl?.dispose();
    _frontCardCtrl = AnimationController.unbounded(vsync: this);
    _frontCardCtrl?.addListener(() => setState(() {}));

    _frictionCtrl?.dispose();
    _frictionCtrl = AnimationController.unbounded(vsync: this);
    _frictionCtrl?.addListener(() => setState(() {}));

    _autoSlide();
  }

  @override
  void dispose() {
    _frontCardCtrl?.dispose();
    _frictionCtrl?.dispose();
    _autoSlideTimer?.cancel();

    super.dispose();
  }

  @override
  void didUpdateWidget(covariant CigCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
  }

  void _autoSlide() {
    _autoSlideTimer?.cancel();
    _autoSlideTimer = Timer(const Duration(seconds: 2), () {
      var maxZ = cardData.reduce(
        (curr, next) => curr.z > next.z ? curr : next,
      );
      var nextIdx = (maxZ.idx + 1) % widget.children.length;

      _frontCardAnimation(
        nextIdx,
        duration: const Duration(milliseconds: 350),
        whenComplete: () {
          _autoSlide();
        },
      );
    });
  }

  void _frictionAnimation() {
    _dragX = 0;
    _frontCardCtrl?.value = 0;

    var beginAngle = angleOffset - pi / 2;

    var simulate = FrictionSimulation(.00001, beginAngle, -_velocityX * .006);
    _frictionCtrl?.animateWith(simulate).whenComplete(() {
      // re-center the front card
      var maxZ = cardData.reduce(
        (curr, next) => curr.z > next.z ? curr : next,
      );
      _frontCardAnimation(maxZ.idx, whenComplete: () {
        _autoSlide();
      });
    });
  }

  void _frontCardAnimation(int idx,
      {Duration duration = const Duration(milliseconds: 150),
      VoidCallback? whenComplete}) {
    _dragX = 0;
    _frictionCtrl?.value = 0;

    frontAngle = -idx * angleStep;

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
    _frontCardCtrl?.value = beginAngle;
    _frontCardCtrl
        ?.animateTo(
          frontAngle,
          duration: duration,
          curve: Curves.easeInOut,
        )
        .whenComplete(() => whenComplete?.call());
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    radius = screenWidth * 0.93 / 2;

    angleOffset = pi / 2 + (-_dragX * .006);
    angleOffset += _frictionCtrl?.value ?? 0;
    angleOffset += _frontCardCtrl?.value ?? 0;

    // positioning cards in a circle
    for (var i = 0; i < cardData.length; ++i) {
      var c = cardData[i];
      double ang = angleOffset + c.idx * angleStep;
      c.angle = ang;
      c.x = cos(ang) * radius;
      c.y = sin(ang) * 130 - 50;
      c.z = sin(ang) * radius;
    }

    // sort in Z axis.
    cardData.sort((a, b) => a.z.compareTo(b.z));

    var maxZ = cardData.reduce(
      (curr, next) => curr.z > next.z ? curr : next,
    );

    // transform the cards
    var list = cardData.map((vo) {
      var c = addCard(vo);
      var mt2 = Matrix4.identity();
      mt2.setEntry(3, 2, 0.001);

      // position the card based on x,y,z
      mt2.translate(vo.x, vo.y, -vo.z);

      // scale the card based on z position
      double scale = 1 + (vo.z / radius) * 0.5;
      mt2.scale(scale, scale);

      c = Transform(
        alignment: Alignment.center,
        origin: const Offset(0.0, 0.0),
        transform: mt2,
        child: c,
      );

      return c;
    }).toList();

    return Column(
      children: [
        Expanded(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onPanDown: (e) {
              _frictionCtrl?.stop();
              _frontCardCtrl?.stop();
              _autoSlideTimer?.cancel();
            },
            onPanUpdate: (e) {
              _dragX += e.delta.dx;
              setState(() {});
            },
            onPanEnd: (e) {
              _velocityX = e.velocity.pixelsPerSecond.dx;
              _frictionAnimation();
            },
            onPanCancel: () {
              _autoSlide();
            },
            child: Container(
              alignment: Alignment.center,
              child: Stack(
                alignment: Alignment.center,
                children: list,
              ),
            ),
          ),
        ),
        PageIndicator(
          selectedIndex: maxZ.idx,
          length: widget.children.length,
        ),
      ],
    );
  }

  Widget addCard(CardData vo) {
    var shadowAlpha = ((1 - vo.z / radius) / 2) * .6;
    // var cardAlpha = 0.54 + 0.46 * vo.z / radio;
    var cardAlpha = 0.575 + 0.425 * vo.z / radius;

    Widget c;
    c = Opacity(
      opacity: cardAlpha,
      child: Container(
        width: 150,
        height: 100,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(.2 + shadowAlpha * .2),
                spreadRadius: 1,
                blurRadius: 12,
                offset: const Offset(0, 2))
          ],
        ),
        child: vo.widget,
      ),
    );
    return c;
  }
}

class PageIndicator extends StatelessWidget {
  const PageIndicator({
    super.key,
    required this.selectedIndex,
    required this.length,
  });

  final int selectedIndex;
  final int length;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: List.generate(
          length,
          (index) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6.0),
            child: AnimatedContainer(
                curve: Curves.easeIn,
                duration: const Duration(milliseconds: 150),
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color:
                      Colors.white.withOpacity(index == selectedIndex ? 1 : .3),
                  borderRadius: BorderRadius.circular(7),
                  boxShadow: index == selectedIndex
                      ? const [
                          BoxShadow(
                              color: Colors.white,
                              spreadRadius: 1,
                              blurRadius: 10,
                              offset: Offset(0, 0))
                        ]
                      : null,
                )),
          ),
        ),
      ),
    );
  }
}
