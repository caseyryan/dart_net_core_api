import 'package:dart_core_doc_viewer/ui/snack_bar_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CopyButton extends StatelessWidget {
  const CopyButton({
    super.key,
    required this.text,
  });

  final String text;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () async {
        await Clipboard.setData(ClipboardData(text: text));
        showInformation(text: 'The text has been copied to the clipboard.');
      },
      icon: const Icon(
        Icons.copy,
        size: 18.0,
      ),
    );
  }
}
