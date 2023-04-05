import 'package:flutter/cupertino.dart';

class ConstrainediOSRefresh extends StatelessWidget {
  const ConstrainediOSRefresh({
    super.key,
    required this.child,
    required this.onRefresh,
    required this.columnAlignment,
  });

  final Widget child;
  final Future<void> Function() onRefresh;
  final MainAxisAlignment columnAlignment;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return CustomScrollView(
          slivers: [
            CupertinoSliverRefreshControl(
              onRefresh: onRefresh,
            ),
            SliverList(
              delegate: SliverChildListDelegate.fixed([
                SizedBox(
                  width: constraints.maxWidth,
                  height: constraints.maxHeight,
                  child: child,
                ),
              ]),
            ),
          ],
        );
      },
    );
  }
}
