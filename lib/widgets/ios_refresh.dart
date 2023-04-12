import 'package:flutter/cupertino.dart';

class IOSRefresh extends StatelessWidget {
  const IOSRefresh({
    super.key,
    required this.child,
    required this.onRefresh,
  });

  final Widget child;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return CustomScrollView(
          shrinkWrap: true,
          slivers: [
            CupertinoSliverRefreshControl(
              onRefresh: onRefresh,
            ),
            SliverList(
              delegate: SliverChildListDelegate.fixed([
                child,
              ]),
            ),
          ],
        );
      },
    );
  }
}
