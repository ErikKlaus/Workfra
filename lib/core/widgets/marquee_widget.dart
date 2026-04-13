import 'package:flutter/material.dart';

class MarqueeWidget extends StatefulWidget {
  final Widget child;
  final Duration animationDuration;
  final Duration backDuration;
  final Duration pauseDuration;

  const MarqueeWidget({
    super.key,
    required this.child,
    this.animationDuration = const Duration(milliseconds: 6000),
    this.backDuration = const Duration(milliseconds: 800),
    this.pauseDuration = const Duration(milliseconds: 800),
  });

  @override
  State<MarqueeWidget> createState() => _MarqueeWidgetState();
}

class _MarqueeWidgetState extends State<MarqueeWidget> {
  late ScrollController scrollController;
  bool _isScrolling = true;

  @override
  void initState() {
    scrollController = ScrollController();
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      scroll();
    });
  }

  @override
  void dispose() {
    _isScrolling = false;
    scrollController.dispose();
    super.dispose();
  }

  void scroll() async {
    while (_isScrolling && mounted) {
      if (scrollController.hasClients) {
        if (scrollController.position.maxScrollExtent > 0) {
          await Future.delayed(widget.pauseDuration);
          if (!mounted || !_isScrolling) break;

          await scrollController.animateTo(
            scrollController.position.maxScrollExtent,
            duration: widget.animationDuration,
            curve: Curves.linear,
          );

          if (!mounted || !_isScrolling) break;
          await Future.delayed(widget.pauseDuration);

          if (!mounted || !_isScrolling) break;
          scrollController.jumpTo(0.0);
        } else {
          await Future.delayed(const Duration(seconds: 1));
        }
      } else {
        await Future.delayed(const Duration(milliseconds: 500));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: scrollController,
      scrollDirection: Axis.horizontal,
      physics: const NeverScrollableScrollPhysics(),
      child: widget.child,
    );
  }
}
