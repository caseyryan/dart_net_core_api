import 'package:flutter/cupertino.dart';

class CupertinoLoader extends StatelessWidget {
  const CupertinoLoader({
    super.key,
    this.isSliver = false,
    this.color,
  });

  final bool isSliver;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final loader = SizedBox(
      width: double.infinity,
      height: 100.0,
      child: Center(
        child: CupertinoActivityIndicator(
          animating: true,
          color: color,
        ),
      ),
    );
    if (isSliver) {
      return SliverToBoxAdapter(
        child: loader,
      );
    }

    return loader;
  }
}
