import 'package:flutter/material.dart';

class Orb extends StatefulWidget {
  final VoidCallback onTap;
  final bool isListening;

  const Orb({
    super.key,
    required this.onTap,
    required this.isListening,
  });

  @override
  State<Orb> createState() => _OrbState();
}

class _OrbState extends State<Orb> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          double scaleValue =
              1.0 + (_controller.value * (widget.isListening ? 0.15 : 0.08));
          return Transform.scale(
            scale: scaleValue,
            child: Container(
              height: 600,
              width: 600,
              child: Image.asset(
                "assets/orb.gif",
                fit: BoxFit.cover,
              ),
            ),
          );
        },
      ),
    );
  }
}