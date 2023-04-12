import 'package:flutter/cupertino.dart';

class iOSRefresh extends StatelessWidget {
  const iOSRefresh({
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
