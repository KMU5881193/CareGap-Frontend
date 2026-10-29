import 'package:flutter/material.dart';

class LoadingView extends StatefulWidget {
  const LoadingView({super.key, this.message = '불러오는 중이에요'});
  final String message;
  @override
  State<LoadingView> createState() => _LoadingViewState();
}

class _LoadingViewState extends State<LoadingView>
    with SingleTickerProviderStateMixin {
  late final animation = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1150),
  );
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      animation.stop();
    } else {
      animation.repeat();
    }
  }

  @override
  void dispose() {
    animation.dispose();
    super.dispose();
  }

  Widget block(double height, {double? width}) => Container(
    height: height,
    width: width,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
    ),
  );
  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    label: widget.message,
    child: ExcludeSemantics(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.message, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 22),
            AnimatedBuilder(
              animation: animation,
              builder: (context, child) => ShaderMask(
                blendMode: BlendMode.srcATop,
                shaderCallback: (bounds) => LinearGradient(
                  begin: Alignment(-3 + 4 * animation.value, 0),
                  end: Alignment(-1 + 4 * animation.value, 0),
                  colors: const [
                    Color(0xFFE9EEEA),
                    Color(0xFFF6F8F5),
                    Color(0xFFE9EEEA),
                  ],
                ).createShader(bounds),
                child: child,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      block(58, width: 58),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            block(18, width: 130),
                            const SizedBox(height: 12),
                            block(12, width: 190),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  block(130),
                  const SizedBox(height: 16),
                  block(130),
                  const SizedBox(height: 24),
                  block(18, width: 150),
                  const SizedBox(height: 16),
                  block(86),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
