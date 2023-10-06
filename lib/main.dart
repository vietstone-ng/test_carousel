import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:test_carousel/rotation_scene.dart';
import 'package:test_carousel/rotation_scene_v1.dart';
import 'package:test_carousel/rotation_scene_v2.dart';
import 'package:test_carousel/rotation_scene_v3.dart';

int numItems = 10;
var onSelectCard = ValueNotifier<int>(0);

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      darkTheme:
          ThemeData(platform: TargetPlatform.iOS, brightness: Brightness.dark),
      home: const Column(
        children: [
          Expanded(child: RotationSceneV1()),
          Expanded(child: RotationSceneV3()),
        ],
      ),
    );
  }
}
