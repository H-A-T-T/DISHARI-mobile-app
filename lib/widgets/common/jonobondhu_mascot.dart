import 'dart:async';
import 'package:flutter/material.dart';

enum MascotSide { right, left }

class JonobondhuMascot extends StatefulWidget {
  final MascotSide side;
  final bool isSpeaking;
  final bool isListening;
  final bool isOpen;
  final VoidCallback? onTap;
  final double width;
  final double height;

  const JonobondhuMascot({
    super.key,
    this.side = MascotSide.right,
    this.isSpeaking = false,
    this.isListening = false,
    this.isOpen = false,
    this.onTap,
    this.width = 76,
    this.height = 98,
  });

  @override
  State<JonobondhuMascot> createState() => _JonobondhuMascotState();
}

class _JonobondhuMascotState extends State<JonobondhuMascot> {
  Timer? _animTimer;
  int _stepIndex = 0;
  String _activeFrame = 'eyesopen_mouthclose_waveup';

  static const List<String> _idleSeq = [
    'eyesopen_mouthclose_waveup',
    'eyesclose_mouthclose_waveup',
    'eyesopen_mouthclose_wavedown',
    'eyesclose_mouthclose_wavedown',
    'eyesopen_mouthclose_wavedown',
    'eyesopen_mouthclose_waveup',
  ];

  static const List<String> _openSeq = [
    'eyesopen_mouthopen_waveup',
    'eyesclose_mouthopen_waveup',
    'eyesopen_mouthopen_waveup',
    'eyesopen_mouthclose_waveup',
  ];

  static const List<String> _speakingSeq = [
    'eyesopen_mouthopen_waveup',
    'eyesopen_mouthclose_waveup',
    'eyesclose_mouthopen_waveup',
    'eyesopen_mouthclose_waveup',
  ];

  @override
  void initState() {
    super.initState();
    _startAnimation();
  }

  @override
  void didUpdateWidget(covariant JonobondhuMascot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isSpeaking != widget.isSpeaking ||
        oldWidget.isListening != widget.isListening ||
        oldWidget.isOpen != widget.isOpen) {
      _startAnimation();
    }
  }

  void _startAnimation() {
    _animTimer?.cancel();

    if (widget.isListening) {
      setState(() => _activeFrame = 'eyesopen_mouthopen_waveup');
      return;
    }

    if (widget.isSpeaking) {
      _animTimer = Timer.periodic(const Duration(milliseconds: 190), (_) {
        if (!mounted) return;
        _stepIndex = (_stepIndex + 1) % _speakingSeq.length;
        setState(() => _activeFrame = _speakingSeq[_stepIndex]);
      });
      return;
    }

    if (widget.isOpen) {
      _animTimer = Timer.periodic(const Duration(milliseconds: 480), (_) {
        if (!mounted) return;
        _stepIndex = (_stepIndex + 1) % _openSeq.length;
        setState(() => _activeFrame = _openSeq[_stepIndex]);
      });
      return;
    }

    // Default gentle idle wave and blink loop
    _animTimer = Timer.periodic(const Duration(milliseconds: 520), (_) {
      if (!mounted) return;
      _stepIndex = (_stepIndex + 1) % _idleSeq.length;
      setState(() => _activeFrame = _idleSeq[_stepIndex]);
    });
  }

  @override
  void dispose() {
    _animTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget content = Image.asset(
      'assets/mascot/frames/$_activeFrame.png',
      width: widget.width,
      height: widget.height,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => Image.asset(
        'assets/mascot/jonobondhu_head.png',
        width: widget.width,
        height: widget.height,
        fit: BoxFit.contain,
      ),
    );

    if (widget.side == MascotSide.left) {
      content = Transform(
        alignment: Alignment.center,
        transform: Matrix4.diagonal3Values(-1.0, 1.0, 1.0),
        child: content,
      );
    }

    return GestureDetector(
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: content,
    );
  }
}
