import 'package:flutter/material.dart';


class Enemy {
  Offset position;
  double speed;
  double size;
  int shape;
  Color color;
  String image; // Add this property

  Enemy({
    required this.position,
    required this.speed,
    required this.size,
    required this.shape,
    required this.color,
    required this.image, // Include image in the constructor
  });
}
