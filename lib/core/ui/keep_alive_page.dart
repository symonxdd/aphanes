import 'package:flutter/material.dart';

/// Keeps a [PageView] child mounted (preserving scroll offset and local
/// state) across swipes, since [PageView] only keeps the current and
/// adjacent pages alive by default.
class KeepAlivePage extends StatefulWidget {
  const KeepAlivePage({required this.child, super.key});

  final Widget child;

  @override
  State<KeepAlivePage> createState() => _KeepAlivePageState();
}

class _KeepAlivePageState extends State<KeepAlivePage>
    with AutomaticKeepAliveClientMixin<KeepAlivePage> {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Material(type: MaterialType.transparency, child: widget.child);
  }
}
