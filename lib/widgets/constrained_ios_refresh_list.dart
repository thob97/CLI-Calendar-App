import 'package:flutter/cupertino.dart';

class ConstrainediOSRefreshList extends StatelessWidget {
  const ConstrainediOSRefreshList({
    super.key,
    required this.child,
    required this.onRefresh,
    required this.columnAlignment,
  });

  final List<Widget> child;
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
                ConstrainedBox(
                  constraints: BoxConstraints(
                    minWidth: constraints.maxWidth,
                    minHeight: constraints.maxHeight,
                  ),
                  child: Column(
                    mainAxisAlignment: columnAlignment,
                    children: child,
                  ),
                ),
              ]),
            ),
          ],
        );
      },
    );
  }
}
