import 'package:flutter/material.dart';

import '../data/app_database.dart';
import '../models/chat_models.dart';
import '../models/persona.dart';
import '../services/api_client.dart';
import '../services/chat_service.dart';
import '../services/settings_controller.dart';
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
      MaterialPageRoute(
        builder: (_) => SettingsScreen(settings: widget.settings),
      ),
    );
    if (mounted) setState(() {});
  }

  void _showMemory() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('长期记忆'),
        content: SingleChildScrollView(
          child: SelectableText(_memory.isEmpty ? '暂无长期记忆。' : _memory),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  void _scrollToBottom() {
    if (!_scroll.hasClients) return;
    _scroll.animateTo(
      _scroll.position.maxScrollExtent,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.persona.name),
        actions: [
          IconButton(
            onPressed: _showMemory,
            tooltip: '长期记忆',
            icon: const Icon(Icons.auto_stories_outlined),
          ),
          IconButton(
            onPressed: _openSettings,
            tooltip: 'API 设置',
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            _RelationshipBar(state: _relationship),
            const Divider(height: 1),
            Expanded(
              child: _messages.isEmpty
                  ? const _EmptyChat()
                  : ListView.builder(
                      controller: _scroll,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      itemCount: _messages.length + (_sending ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == _messages.length) {
                          return Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                const SizedBox.square(
                                  dimension: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text('${widget.persona.name} 正在回复…'),
                              ],
                            ),
                          );
                        }
                        return _MessageBubble(
                          message: _messages[index],
                          personaName: widget.persona.name,
                        );
                      },
                    ),
            ),
            if (_notice != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Text(
                  _notice!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontSize: 12,
                  ),
                ),
              ),
            _Composer(controller: _input, sending: _sending, onSend: _send),
          ],
        ),
      ),
    );
  }
}

class _RelationshipBar extends StatelessWidget {
  const _RelationshipBar({required this.state});
  final RelationshipState state;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          _RelationItem('熟悉', state.familiarity),
          _RelationItem('信任', state.trust),
          _RelationItem('好感', state.affection),
          _RelationItem('芥蒂', state.grudge),
        ],
      ),
    );
  }
}

class _RelationItem extends StatelessWidget {
  const _RelationItem(this.label, this.value);
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$value', style: Theme.of(context).textTheme.titleMedium),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _EmptyChat extends StatelessWidget {
  const _EmptyChat();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.forum_outlined,
            size: 50,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 12),
          Text('开始一段对话', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text('消息和记忆会保存在这台设备上', style: Theme.of(context).textTheme.bodySmall),
        ],
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
    final scheme = Theme.of(context).colorScheme;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 520),
        margin: EdgeInsets.fromLTRB(isUser ? 56 : 12, 6, isUser ? 12 : 56, 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isUser
              ? scheme.primaryContainer
              : scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isUser ? '你' : personaName,
              style: Theme.of(context).textTheme.labelSmall,
            ),
            const SizedBox(height: 4),
            SelectableText(message.content),
          ],
        ),
      ),
    );
  }
}

class _Composer extends StatefulWidget {
  const _Composer({
    required this.controller,
    required this.sending,
    required this.onSend,
  });
  final TextEditingController controller;
  final bool sending;
  final VoidCallback onSend;

  @override
  State<_Composer> createState() => _ComposerState();
}

class _ComposerState extends State<_Composer> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_changed);
  }

  @override
  void didUpdateWidget(covariant _Composer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_changed);
      widget.controller.addListener(_changed);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_changed);
    super.dispose();
  }

  void _changed() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final enabled = !widget.sending && widget.controller.text.trim().isNotEmpty;
    return Material(
      elevation: 8,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: widget.controller,
                enabled: !widget.sending,
                minLines: 1,
                maxLines: 5,
                textInputAction: TextInputAction.newline,
                decoration: const InputDecoration(
                  hintText: '输入消息…',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: enabled ? widget.onSend : null,
              icon: const Icon(Icons.arrow_upward),
              tooltip: '发送',
            ),
          ],
        ),
      ),
    );
  }
}
