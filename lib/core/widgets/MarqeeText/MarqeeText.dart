import 'package:flutter/material.dart';
import 'package:medixcel_new/core/config/themes/CustomColors.dart';

class MarqueeText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final double velocity; // pixels per second

  const MarqueeText({
    Key? key,
    required this.text,
    this.style,
    this.velocity = 50,
  }) : super(key: key);

  @override
  State<MarqueeText> createState() => _MarqueeTextState();
}

class _MarqueeTextState extends State<MarqueeText> with SingleTickerProviderStateMixin {
  late final ScrollController _scrollController;
  late final double _textWidth;
  late double _containerWidth;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();

    WidgetsBinding.instance.addPostFrameCallback((_) => _startScrolling());
  }

  void _startScrolling() async {
    while (mounted) {
      final maxScroll = _scrollController.position.maxScrollExtent;
      final duration = Duration(
        milliseconds: ((maxScroll + _containerWidth) / widget.velocity * 1000).toInt(),
      );

      await _scrollController.animateTo(
        maxScroll,
        duration: duration,
        curve: Curves.linear,
      );

      // reset immediately without reversing
      _scrollController.jumpTo(0);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _containerWidth = constraints.maxWidth;
        return ClipRect(
          child: SingleChildScrollView(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            physics: const NeverScrollableScrollPhysics(),
            child: Row(
              children: [
                Text(widget.text, style: widget.style ?? const TextStyle(color: AppColors.onSurface)),
                const SizedBox(width: 50),
                Text(widget.text, style: widget.style ?? const TextStyle(color: AppColors.onSurface)),
              ],
            ),
          ),
        );
      },
    );
  }
}
