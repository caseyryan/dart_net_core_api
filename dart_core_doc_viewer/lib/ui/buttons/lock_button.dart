import 'package:flutter/material.dart';

class LockButton extends StatelessWidget {
  const LockButton({
    super.key,
    this.tooltip = '',
  });

  final String tooltip;


  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: () async {
        
      },
      icon: const Icon(
        Icons.lock,
        size: 20.0,
      ),
    );
  }
}
