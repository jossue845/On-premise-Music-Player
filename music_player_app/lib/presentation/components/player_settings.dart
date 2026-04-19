import 'package:flutter/material.dart';
class PlayerSettings extends StatelessWidget{
  final Widget? child;

  const PlayerSettings({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context){
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade400,
            blurRadius: 12,
            offset: const Offset(4, 4),
          ),
          BoxShadow(
            color: Colors.white,
            blurRadius: 12,
            offset: const Offset(-4, -4),
          ),

        ]),
      padding: EdgeInsets.all(16),
      child: child,
    );
  }
}