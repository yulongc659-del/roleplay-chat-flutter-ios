import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../data/app_database.dart';
import '../models/chat_models.dart';
import '../models/persona.dart';
import '../services/api_client.dart';
import '../services/chat_service.dart';
import '../services/settings_controller.dart';
import '../ui/app_theme.dart';
import '../ui/glass_components.dart';
import 'settings_screen.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({
    super.key,
    required this.persona,
    required this.database,
    required this.settings,
    required this.service,
  });

  final Persona persona;
  final AppDatabase database;
  final SettingsController settings;
  final ChatService service;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  List<ChatMessage> _messages = [];
  RelationshipState _relationship = const RelationshipState();
  String _memory = '';
  String? _notice;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    try {
      final messages = await widget.database.allMessages();
      final relationship = await widget.database.relationship();
      final memory = await widget.database.memory();
      if (!mounted) return;
      setState(() {
        _messages = messages;
        _relationship = relationship;
        _memory = memory;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    } catch (error) {
      if (mounted) setState(() => _notice = error.toString());
    }
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty || _sending) return;

    late ApiConfiguration configuration;
    try {
      configuration = widget.settings.configuration();
    } catch (error) {
      setState(() => _notice = error.toString());
      await _openSettings();
      return;
    }

    setState(() {
      _sending = true;
      _notice = null;
      _input.clear();
    });
    try {
      final result = await widget.service.send(text, configuration);
      await _refresh();
      if (!mounted) return;
      setState(() {
        _relationship = result.relationship;
        _notice = result.warnings.isEmpty ? null : result.warnings.join('\n');
      });
    } catch (error) {
      if (!mounted) return;
      _input.text = text;
      setState(() => _notice = error.toString());
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _openSettings() async {
    await Navigator.of(context).push(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 280),
        reverseTransitionDuration: const Duration(milliseconds: 220),
        pageBuilder: (_, animation, _) =>
            SettingsScreen(settings: widget.settings),
        transitionsBuilder: (_, animation, _, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          );
          return FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.035, 0.02),
                end: Offset.zero,
              ).animate(curved),
              child: child,
            ),
          );
        },
      ),
    );
    if (mounted) setState(() {});
  }

  void _showMemory() {
    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: '关闭长期记忆',
      barrierColor: Colors.black.withValues(alpha: 0.68),
      transitionDuration: const Duration(milliseconds: 230),
      pageBuilder: (dialogContext, _, _) => SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Material(
                color: Colors.transparent,
                child: GlassCard(
                  borderRadius: 28,
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const GlassIconBadge(
                            icon: CupertinoIcons.book,
                            accent: true,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              '长期记忆',
                              style: Theme.of(
                                dialogContext,
                              ).textTheme.titleLarge,
                            ),
                          ),
                          GlassIconButton(
                            icon: CupertinoIcons.xmark,
                            tooltip: '关闭',
                            onPressed: () => Navigator.of(dialogContext).pop(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 360),
                        child: SingleChildScrollView(
                          child: SelectableText(
                            _memory.isEmpty ? '还没有形成长期记忆。' : _memory,
                            style: Theme.of(dialogContext).textTheme.bodyLarge
                                ?.copyWith(color: AppColors.textSecondary),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      transitionBuilder: (_, animation, _, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.96, end: 1).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  void _scrollToBottom() {
    if (!_scroll.hasClients) return;
    _scroll.animateTo(
      _scroll.position.maxScrollExtent,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppBackdrop(
        child: SafeArea(
          bottom: false,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 820),
              child: Column(
                children: [
                  _ChatHeader(
                    name: widget.persona.name,
                    onMemory: _showMemory,
                    onSettings: _openSettings,
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
                    child: _RelationshipCard(state: _relationship),
                  ),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 260),
                      switchInCurve: Curves.easeOut,
                      child: _messages.isEmpty
                          ? const _EmptyChat(key: ValueKey('empty'))
                          : ListView.builder(
                              key: const ValueKey('messages'),
                              controller: _scroll,
                              keyboardDismissBehavior:
                                  ScrollViewKeyboardDismissBehavior.onDrag,
                              padding: const EdgeInsets.fromLTRB(
                                20,
                                22,
                                20,
                                12,
                              ),
                              itemCount: _messages.length + (_sending ? 1 : 0),
                              itemBuilder: (context, index) {
                                if (index == _messages.length) {
                                  return _TypingBubble(
                                    personaName: widget.persona.name,
                                  );
                                }
                                return _MessageBubble(
                                  message: _messages[index],
                                  personaName: widget.persona.name,
                                );
                              },
                            ),
                    ),
                  ),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    child: _notice == null
                        ? const SizedBox.shrink()
                        : _NoticeCard(
                            key: ValueKey(_notice),
                            message: _notice!,
                          ),
                  ),
                  _BottomComposer(
                    controller: _input,
                    sending: _sending,
                    onSend: _send,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ChatHeader extends StatelessWidget {
  const _ChatHeader({
    required this.name,
    required this.onMemory,
    required this.onSettings,
  });

  final String name;
  final VoidCallback onMemory;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 17, 18, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: Theme.of(context).textTheme.displaySmall),
                const SizedBox(height: 6),
                Text('继续你们的故事', style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          GlassIconButton(
            icon: CupertinoIcons.person_crop_circle,
            tooltip: '角色资料与记忆',
            onPressed: onMemory,
          ),
          const SizedBox(width: 10),
          GlassIconButton(
            icon: CupertinoIcons.slider_horizontal_3,
            tooltip: 'API 设置',
            onPressed: onSettings,
          ),
        ],
      ),
    );
  }
}

class _RelationshipCard extends StatelessWidget {
  const _RelationshipCard({required this.state});

  final RelationshipState state;

  @override
  Widget build(BuildContext context) {
    final stats = [
      ('熟悉', state.familiarity),
      ('信任', state.trust),
      ('好感', state.affection),
      ('芥蒂', state.grudge),
    ];
    return GlassCard(
      borderRadius: 25,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 17),
      child: Row(
        children: [
          for (var index = 0; index < stats.length; index++) ...[
            Expanded(
              child: _RelationItem(
                label: stats[index].$1,
                value: stats[index].$2,
              ),
            ),
            if (index != stats.length - 1)
              Container(
                width: 1,
                height: 31,
                color: Colors.white.withValues(alpha: 0.065),
              ),
          ],
        ],
      ),
    );
  }
}

class _RelationItem extends StatelessWidget {
  const _RelationItem({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 240),
          child: Text(
            '$value',
            key: ValueKey(value),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontSize: 23,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: Theme.of(context).textTheme.labelMedium),
      ],
    );
  }
}

class _EmptyChat extends StatelessWidget {
  const _EmptyChat({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => Align(
        alignment: const Alignment(0, -0.08),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 30, 24, 70),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: math.max(0, constraints.maxHeight - 100),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GlassCard(
                  borderRadius: 26,
                  padding: EdgeInsets.zero,
                  child: const SizedBox.square(
                    dimension: 76,
                    child: Icon(
                      CupertinoIcons.chat_bubble_2,
                      size: 34,
                      color: AppColors.accent,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text('开始一段对话', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 11),
                Text(
                  '消息和记忆会保存在这台设备上',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message, required this.personaName});

  final ChatMessage message;
  final String personaName;

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == MessageRole.user;
    return LayoutBuilder(
      builder: (context, constraints) {
        final maximum = math.min(560.0, constraints.maxWidth * 0.82);
        return Align(
          alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            constraints: BoxConstraints(maxWidth: maximum),
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            decoration: BoxDecoration(
              gradient: isUser
                  ? const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF9D7CFF), Color(0xFF8267DC)],
                    )
                  : null,
              color: isUser ? null : Colors.white.withValues(alpha: 0.065),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(21),
                topRight: const Radius.circular(21),
                bottomLeft: Radius.circular(isUser ? 21 : 7),
                bottomRight: Radius.circular(isUser ? 7 : 21),
              ),
              border: isUser
                  ? null
                  : Border.all(color: Colors.white.withValues(alpha: 0.055)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isUser ? '你' : personaName,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: isUser
                        ? Colors.white.withValues(alpha: 0.68)
                        : AppColors.textTertiary,
                  ),
                ),
                const SizedBox(height: 6),
                SelectableText(
                  message.content,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isUser ? Colors.white : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble({required this.personaName});

  final String personaName;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.fromLTRB(16, 11, 16, 13),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(21),
            topRight: Radius.circular(21),
            bottomLeft: Radius.circular(7),
            bottomRight: Radius.circular(21),
          ),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(personaName, style: Theme.of(context).textTheme.labelSmall),
            const SizedBox(width: 11),
            const _TypingDots(),
          ],
        ),
      ),
    );
  }
}

class _TypingDots extends StatefulWidget {
  const _TypingDots();

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (index) {
          final wave = math.sin(
            (_controller.value * math.pi * 2) - (index * 0.75),
          );
          return Container(
            width: 5,
            height: 5,
            margin: EdgeInsets.only(right: index == 2 ? 0 : 5),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.textSecondary.withValues(
                alpha: 0.38 + ((wave + 1) * 0.25),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _NoticeCard extends StatelessWidget {
  const _NoticeCard({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.error.withValues(alpha: 0.15)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 1),
              child: Icon(
                CupertinoIcons.exclamationmark_circle,
                size: 17,
                color: AppColors.error,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: const Color(0xFFD7A1A1)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomComposer extends StatefulWidget {
  const _BottomComposer({
    required this.controller,
    required this.sending,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool sending;
  final VoidCallback onSend;

  @override
  State<_BottomComposer> createState() => _BottomComposerState();
}

class _BottomComposerState extends State<_BottomComposer> {
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_changed);
  }

  @override
  void didUpdateWidget(covariant _BottomComposer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_changed);
      widget.controller.addListener(_changed);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_changed);
    _focusNode.dispose();
    super.dispose();
  }

  void _changed() => setState(() {});

  Future<void> _showMore() async {
    _focusNode.unfocus();
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.58),
      builder: (sheetContext) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: GlassCard(
            borderRadius: 26,
            child: Row(
              children: [
                const GlassIconBadge(icon: CupertinoIcons.plus, accent: true),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '更多内容',
                        style: Theme.of(sheetContext).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '图片和附件功能将在后续版本开放。',
                        style: Theme.of(sheetContext).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final enabled = !widget.sending && widget.controller.text.trim().isNotEmpty;
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 2),
        child: GlassCard(
          borderRadius: 30,
          padding: const EdgeInsets.all(8),
          blur: 26,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              GlassIconButton(
                icon: CupertinoIcons.plus,
                tooltip: '更多',
                onPressed: widget.sending ? null : _showMore,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: GlassInput(
                  controller: widget.controller,
                  focusNode: _focusNode,
                  enabled: !widget.sending,
                  hintText: '输入消息…',
                  minLines: 1,
                  maxLines: 4,
                  keyboardType: TextInputType.multiline,
                  textInputAction: TextInputAction.newline,
                ),
              ),
              const SizedBox(width: 8),
              Tooltip(
                message: '发送',
                child: PressScale(
                  onTap: enabled ? widget.onSend : null,
                  semanticLabel: '发送',
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOutCubic,
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: enabled
                          ? AppColors.accent
                          : Colors.white.withValues(alpha: 0.075),
                      boxShadow: enabled
                          ? [
                              BoxShadow(
                                color: AppColors.accent.withValues(alpha: 0.2),
                                blurRadius: 18,
                              ),
                            ]
                          : const [],
                    ),
                    child: Icon(
                      CupertinoIcons.arrow_up,
                      size: 20,
                      color: enabled
                          ? const Color(0xFF171221)
                          : AppColors.textTertiary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
