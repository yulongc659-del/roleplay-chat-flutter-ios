import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../services/settings_controller.dart';
import '../ui/app_theme.dart';
import '../ui/glass_components.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.settings});

  final SettingsController settings;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late ApiProvider _provider;
  late final TextEditingController _baseUrl;
  late final TextEditingController _model;
  late final TextEditingController _apiKey;
  String? _error;
  bool _saving = false;
  bool _showApiKey = false;

  @override
  void initState() {
    super.initState();
    _provider = widget.settings.provider;
    _baseUrl = TextEditingController(text: widget.settings.baseUrl);
    _model = TextEditingController(text: widget.settings.model);
    _apiKey = TextEditingController(text: widget.settings.apiKey);
  }

  @override
  void dispose() {
    _baseUrl.dispose();
    _model.dispose();
    _apiKey.dispose();
    super.dispose();
  }

  void _changeProvider(ApiProvider provider) {
    setState(() {
      _provider = provider;
      _baseUrl.text = provider.defaultBaseUrl;
      _model.text = provider.defaultModel;
    });
  }

  Future<void> _pickProvider() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final selected = await showModalBottomSheet<ApiProvider>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
          child: GlassCard(
            borderRadius: 28,
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
            blur: 28,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 5,
                    margin: const EdgeInsets.only(bottom: 18),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    '选择提供商',
                    style: Theme.of(sheetContext).textTheme.titleLarge,
                  ),
                ),
                const SizedBox(height: 12),
                for (final provider in ApiProvider.values) ...[
                  _ProviderOption(
                    provider: provider,
                    selected: provider == _provider,
                    onTap: () => Navigator.of(sheetContext).pop(provider),
                  ),
                  if (provider != ApiProvider.values.last)
                    const SizedBox(height: 8),
                ],
              ],
            ),
          ),
        ),
      ),
    );
    if (selected != null && mounted) _changeProvider(selected);
  }

  Future<void> _save() async {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.settings.save(
        newProvider: _provider,
        newBaseUrl: _baseUrl.text,
        newModel: _model.text,
        newApiKey: _apiKey.text,
      );
      if (mounted) Navigator.of(context).pop();
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppBackdrop(
        child: SafeArea(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: ListView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
                  children: [
                    Row(
                      children: [
                        GlassIconButton(
                          icon: CupertinoIcons.chevron_back,
                          tooltip: '返回',
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                        const Spacer(),
                        GlassActionButton(
                          label: '保存',
                          loading: _saving,
                          onPressed: _save,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'API 设置',
                      style: Theme.of(context).textTheme.displaySmall,
                    ),
                    const SizedBox(height: 9),
                    Text(
                      '配置 AI 服务接口，开始你的智能对话体验',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 28),
                    PressScale(
                      onTap: _saving ? null : _pickProvider,
                      semanticLabel: '选择提供商，当前为 ${_provider.label}',
                      child: GlassCard(
                        borderRadius: 24,
                        padding: const EdgeInsets.all(18),
                        child: Row(
                          children: [
                            const GlassIconBadge(
                              icon: CupertinoIcons.sparkles,
                              accent: true,
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '提供商',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.labelMedium,
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    _provider.label,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleMedium,
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              CupertinoIcons.chevron_down,
                              size: 18,
                              color: AppColors.textTertiary,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    _SettingsFieldCard(
                      icon: CupertinoIcons.link,
                      label: 'API 地址',
                      child: GlassInput(
                        controller: _baseUrl,
                        enabled: !_saving,
                        hintText: 'https://api.example.com/v1',
                        keyboardType: TextInputType.url,
                        textInputAction: TextInputAction.next,
                      ),
                    ),
                    const SizedBox(height: 15),
                    _SettingsFieldCard(
                      icon: CupertinoIcons.cube_box,
                      label: '模型',
                      child: GlassInput(
                        controller: _model,
                        enabled: !_saving,
                        hintText: '输入模型名称',
                        textInputAction: TextInputAction.next,
                      ),
                    ),
                    const SizedBox(height: 15),
                    _SettingsFieldCard(
                      icon: CupertinoIcons.lock,
                      label: 'API Key',
                      child: GlassInput(
                        controller: _apiKey,
                        enabled: !_saving,
                        obscureText: !_showApiKey,
                        hintText: '输入你的 API Key',
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _saving ? null : _save(),
                        trailing: _InputIconButton(
                          icon: _showApiKey
                              ? CupertinoIcons.eye_slash
                              : CupertinoIcons.eye,
                          tooltip: _showApiKey ? '隐藏 API Key' : '显示 API Key',
                          onPressed: () =>
                              setState(() => _showApiKey = !_showApiKey),
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    const _SecurityInfoCard(),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      child: _error == null
                          ? const SizedBox.shrink()
                          : Padding(
                              key: ValueKey(_error),
                              padding: const EdgeInsets.only(top: 15),
                              child: _ErrorCard(message: _error!),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SettingsFieldCard extends StatelessWidget {
  const _SettingsFieldCard({
    required this.icon,
    required this.label,
    required this.child,
  });

  final IconData icon;
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderRadius: 24,
      padding: const EdgeInsets.all(18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GlassIconBadge(icon: icon),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 2, top: 1),
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                ),
                const SizedBox(height: 9),
                child,
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProviderOption extends StatelessWidget {
  const _ProviderOption({
    required this.provider,
    required this.selected,
    required this.onTap,
  });

  final ApiProvider provider;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressScale(
      onTap: onTap,
      semanticLabel: provider.label,
      child: Container(
        constraints: const BoxConstraints(minHeight: 58),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.accent.withValues(alpha: 0.13)
              : Colors.white.withValues(alpha: 0.045),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected
                ? AppColors.accent.withValues(alpha: 0.2)
                : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                provider.label,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
            if (selected)
              const Icon(
                CupertinoIcons.check_mark,
                size: 18,
                color: AppColors.accent,
              ),
          ],
        ),
      ),
    );
  }
}

class _InputIconButton extends StatelessWidget {
  const _InputIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: PressScale(
        onTap: onPressed,
        semanticLabel: tooltip,
        child: SizedBox.square(
          dimension: 40,
          child: Icon(icon, size: 19, color: AppColors.textSecondary),
        ),
      ),
    );
  }
}

class _SecurityInfoCard extends StatelessWidget {
  const _SecurityInfoCard();

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderRadius: 22,
      tint: AppColors.accent,
      padding: const EdgeInsets.all(17),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const GlassIconBadge(icon: CupertinoIcons.info_circle, accent: true),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '关于密钥安全',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: const Color(0xFFD7CBFF),
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  'Key 仅保存在本机加密存储中。公开发布时，客户端内的第三方 API Key 仍可能被提取，正式产品建议使用自己的后端代理。',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFFBEB3D6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.16)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            CupertinoIcons.exclamationmark_circle,
            size: 19,
            color: AppColors.error,
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              message,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: const Color(0xFFD9A2A2)),
            ),
          ),
        ],
      ),
    );
  }
}
