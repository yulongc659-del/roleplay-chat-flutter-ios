import 'dart:ui';

import 'package:flutter/material.dart';

import 'app_theme.dart';

class AppBackdrop extends StatelessWidget {
  const AppBackdrop({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF11101A), AppColors.background, Color(0xFF0D0C13)],
          stops: [0, 0.5, 1],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          const Positioned(
            top: -180,
            right: -120,
            child: _AmbientGlow(size: 390, color: Color(0x269D7CFF)),
          ),
          const Positioned(
            bottom: -220,
            left: -150,
            child: _AmbientGlow(size: 430, color: Color(0x167A68B8)),
          ),
          child,
        ],
      ),
    );
  }
}

class _AmbientGlow extends StatelessWidget {
  const _AmbientGlow({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SizedBox.square(
        dimension: size,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              colors: [color, color.withValues(alpha: 0)],
            ),
          ),
        ),
      ),
    );
  }
}

class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.borderRadius = 24,
    this.tint,
    this.blur = 22,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final Color? tint;
  final double blur;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(borderRadius);
    final baseTint = tint ?? Colors.white;
    return RepaintBoundary(
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: radius,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  baseTint.withValues(alpha: 0.085),
                  baseTint.withValues(alpha: 0.038),
                ],
              ),
              border: Border.all(color: Colors.white.withValues(alpha: 0.075)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x42000000),
                  blurRadius: 32,
                  offset: Offset(0, 16),
                ),
              ],
            ),
            child: Padding(padding: padding, child: child),
          ),
        ),
      ),
    );
  }
}

class PressScale extends StatefulWidget {
  const PressScale({
    super.key,
    required this.child,
    required this.onTap,
    this.semanticLabel,
    this.pressedScale = 0.96,
  });

  final Widget child;
  final VoidCallback? onTap;
  final String? semanticLabel;
  final double pressedScale;

  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale> {
  bool _pressed = false;
  bool _hovered = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.semanticLabel,
      child: MouseRegion(
        cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
        onEnter: enabled ? (_) => setState(() => _hovered = true) : null,
        onExit: enabled
            ? (_) {
                setState(() => _hovered = false);
                _setPressed(false);
              }
            : null,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onTap,
          onTapDown: enabled ? (_) => _setPressed(true) : null,
          onTapUp: enabled ? (_) => _setPressed(false) : null,
          onTapCancel: enabled ? () => _setPressed(false) : null,
          child: AnimatedScale(
            scale: _pressed ? widget.pressedScale : 1,
            duration: const Duration(milliseconds: 110),
            curve: Curves.easeOutCubic,
            child: AnimatedOpacity(
              opacity: enabled ? (_hovered ? 0.88 : 1) : 0.42,
              duration: const Duration(milliseconds: 150),
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}

class GlassIconButton extends StatelessWidget {
  const GlassIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    required this.tooltip,
    this.size = 44,
    this.iconSize = 20,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String tooltip;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: PressScale(
        onTap: onPressed,
        semanticLabel: tooltip,
        child: ClipOval(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: size,
              height: size,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.075),
                border: Border.all(color: Colors.white.withValues(alpha: 0.09)),
              ),
              child: Icon(icon, size: iconSize, color: AppColors.textPrimary),
            ),
          ),
        ),
      ),
    );
  }
}

class GlassActionButton extends StatelessWidget {
  const GlassActionButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return PressScale(
      onTap: loading ? null : onPressed,
      semanticLabel: label,
      child: Container(
        constraints: const BoxConstraints(minWidth: 68, minHeight: 44),
        padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 11),
        decoration: BoxDecoration(
          color: AppColors.accent.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(17),
          border: Border.all(color: AppColors.accent.withValues(alpha: 0.24)),
        ),
        alignment: Alignment.center,
        child: loading
            ? const SizedBox.square(
                dimension: 17,
                child: CircularProgressIndicator(
                  strokeWidth: 1.8,
                  color: AppColors.accent,
                ),
              )
            : Text(
                label,
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(color: AppColors.accent),
              ),
      ),
    );
  }
}

class GlassInput extends StatefulWidget {
  const GlassInput({
    super.key,
    required this.controller,
    this.hintText,
    this.obscureText = false,
    this.enabled = true,
    this.keyboardType,
    this.textInputAction,
    this.minLines = 1,
    this.maxLines = 1,
    this.trailing,
    this.focusNode,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String? hintText;
  final bool obscureText;
  final bool enabled;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final int minLines;
  final int maxLines;
  final Widget? trailing;
  final FocusNode? focusNode;
  final ValueChanged<String>? onSubmitted;

  @override
  State<GlassInput> createState() => _GlassInputState();
}

class _GlassInputState extends State<GlassInput> {
  FocusNode? _internalFocus;

  FocusNode get _focusNode => widget.focusNode ?? _internalFocus!;

  @override
  void initState() {
    super.initState();
    if (widget.focusNode == null) _internalFocus = FocusNode();
    _focusNode.addListener(_focusChanged);
  }

  @override
  void didUpdateWidget(covariant GlassInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode == widget.focusNode) return;
    (oldWidget.focusNode ?? _internalFocus)?.removeListener(_focusChanged);
    _internalFocus?.dispose();
    _internalFocus = widget.focusNode == null ? FocusNode() : null;
    _focusNode.addListener(_focusChanged);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_focusChanged);
    _internalFocus?.dispose();
    super.dispose();
  }

  void _focusChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final focused = _focusNode.hasFocus;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      constraints: const BoxConstraints(minHeight: 52),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: focused ? 0.25 : 0.18),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: focused
              ? AppColors.accent.withValues(alpha: 0.54)
              : Colors.white.withValues(alpha: 0.055),
        ),
        boxShadow: focused
            ? [
                BoxShadow(
                  color: AppColors.accent.withValues(alpha: 0.08),
                  blurRadius: 18,
                ),
              ]
            : const [],
      ),
      child: Row(
        crossAxisAlignment: widget.maxLines > 1
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.center,
        children: [
          Expanded(
            child: TextField(
              controller: widget.controller,
              focusNode: _focusNode,
              obscureText: widget.obscureText,
              enabled: widget.enabled,
              autocorrect: false,
              enableSuggestions: !widget.obscureText,
              keyboardType: widget.keyboardType,
              textInputAction: widget.textInputAction,
              minLines: widget.obscureText ? 1 : widget.minLines,
              maxLines: widget.obscureText ? 1 : widget.maxLines,
              onSubmitted: widget.onSubmitted,
              cursorColor: AppColors.accent,
              style: Theme.of(context).textTheme.bodyLarge,
              decoration: InputDecoration(
                hintText: widget.hintText,
                hintStyle: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppColors.textTertiary),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                isCollapsed: true,
                contentPadding: EdgeInsets.fromLTRB(
                  16,
                  widget.maxLines > 1 ? 15 : 0,
                  12,
                  widget.maxLines > 1 ? 15 : 0,
                ),
              ),
            ),
          ),
          if (widget.trailing != null) ...[
            Padding(
              padding: const EdgeInsets.only(right: 6, bottom: 4, top: 4),
              child: widget.trailing!,
            ),
          ],
        ],
      ),
    );
  }
}

class GlassIconBadge extends StatelessWidget {
  const GlassIconBadge({super.key, required this.icon, this.accent = false});

  final IconData icon;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: accent
            ? AppColors.accent.withValues(alpha: 0.14)
            : Colors.white.withValues(alpha: 0.055),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Icon(
        icon,
        size: 20,
        color: accent ? AppColors.accent : AppColors.textSecondary,
      ),
    );
  }
}
