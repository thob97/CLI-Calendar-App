import 'package:flutter/material.dart';

class CustomFutureBuilder extends StatelessWidget {
  const CustomFutureBuilder({
    required this.futureData,
    required this.builder,
    this.errorMsg,
  });

  final Future<dynamic>? futureData;
  final Widget Function(Object?) builder;
  final String? errorMsg;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: futureData,
      builder: (context, snapshot) {
        switch (snapshot.connectionState) {
          case ConnectionState.waiting:
            return const _WaitingWidget();
          default:
            return snapshot.hasError
                ? _ErrorWidget(errorMsg)
                : builder(snapshot.data);
        }
      },
    );
  }
}

class _ErrorWidget extends StatelessWidget {
  const _ErrorWidget(this.customErrorMsg);

  final String? customErrorMsg;

  ///Style
  static const String _errorMsg = 'Something went wrong...';

  @override
  Widget build(BuildContext context) {
    return Center(child: Text(customErrorMsg ?? _errorMsg));
  }
}

class _WaitingWidget extends StatelessWidget {
  const _WaitingWidget();

  @override
  Widget build(BuildContext context) {
    return const Align(
      alignment: Alignment.bottomCenter,
      child: LinearProgressIndicator(),
    );
  }
}
