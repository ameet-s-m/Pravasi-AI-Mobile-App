import 'package:flutter/cupertino.dart';

class FeatureScreen extends StatelessWidget {
  const FeatureScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text('Features'),
      ),
      child: Center(
        child: Text('Feature Screen'),
      ),
    );
  }
}