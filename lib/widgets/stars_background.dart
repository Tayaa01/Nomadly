import 'package:flutter/material.dart';
import 'dart:math';

class StarsBackground extends StatelessWidget {
  final int numberOfStars;

  const StarsBackground({super.key, this.numberOfStars = 100});

  @override
  Widget build(BuildContext context) {
    final random = Random();
    final size = MediaQuery.of(context).size;

    return Stack(
      children: List.generate(numberOfStars, (index) {
        final starSize = random.nextDouble() * 1.5 + 0.5; // Star size between 0.5 and 2.0
        final top = random.nextDouble() * size.height;
        final left = random.nextDouble() * size.width;
        // Vary star opacity for twinkling effect
        final opacity = random.nextDouble() * 0.5 + 0.3; // Opacity between 0.3 and 0.8

        return Positioned(
          top: top,
          left: left,
          child: Container(
            width: starSize,
            height: starSize,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(opacity),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withOpacity(opacity * 0.5),
                  blurRadius: starSize * 2,
                  spreadRadius: starSize * 0.5,
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}
