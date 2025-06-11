import 'package:flutter/material.dart';


class PowerUp {
  Offset position;
  PowerUpType type;

  PowerUp(this.position, this.type);
}

enum PowerUpType { shield, multiBullet, speedBoost, healthRestore }