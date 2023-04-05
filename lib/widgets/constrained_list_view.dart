import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ConstrainedListView extends StatelessWidget {
  const ConstrainedListView({
    super.key,
    required this.children,
    required this.columnAlignment,
  });

  final List<Widget> children;
  final MainAxisAlignment columnAlignment;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: constraints.maxWidth,
              minHeight: constraints.maxHeight,
            ),
            child: Column(
              mainAxisAlignment: columnAlignment,
              children: children,
            ),
          ),
        );
      },
    );
  }
}
