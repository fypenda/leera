import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/ai/ai_settings.dart';
import '../../core/ai/backend_client.dart';
import '../../features/english/english_routes.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Where the person connects the app to their AI backend, or disconnects
/// it. Until this is done, nothing is sent anywhere.
class AiSettingsPage extends ConsumerStatefulWidget {
  const AiSettingsPage({super.key});

  @override
  ConsumerState<AiSettingsPage> createState() => _AiSettingsPageState();
}

class _AiSettingsPageState extends ConsumerState<AiSettingsPage> {
  final _baseUrl = TextEditingController();
  final _token = TextEditingController();
  var _loaded = false;
  var _busy = false;
  var _showToken = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    ref.read(aiSettingsStoreProvider).read().then((settings) {
      if (!mounted) return;
      setState(() {
        _baseUrl.text = settings?.baseUrl ?? '';
        _token.text = settings?.appToken ?? '';
        _loaded = true;
      });
    });
  }

  @override
  void dispose() {
    _baseUrl.dispose();
    _token.dispose();
    super.dispose();
  }

  void _say(String message) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));

  AiSettings? _entered() {
    try {
      final settings = AiSettings(
        baseUrl: _baseUrl.text,
        appToken: _token.text,
      );
      setState(() => _error = null);
      return settings;
    } on ArgumentError {
      setState(
        () => _error =
            'Enter an address starting with http:// or https://, and the '
            'app token.',
      );
      return null;
    }
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _test() => _run(() async {
    final settings = _entered();
    if (settings == null) return;
    try {
      await BackendClient(() async => settings).ping();
      _say('Connected ✅ The backend accepts the token.');
    } on BackendException catch (e) {
      _say(describeBackendFailure(e.failure));
    }
  });

  Future<void> _save() => _run(() async {
    final settings = _entered();
    if (settings == null) return;
    try {
      await ref.read(aiSettingsStoreProvider).write(settings);
      ref.invalidate(aiSettingsProvider);
      _say('Saved. Written presentations can now be corrected.');
    } on Object {
      _say('The settings could not be saved.');
    }
  });

  Future<void> _remove() => _run(() async {
    try {
      await ref.read(aiSettingsStoreProvider).clear();
      ref.invalidate(aiSettingsProvider);
      _baseUrl.clear();
      _token.clear();
      _say('Removed. Nothing will be sent for correction.');
    } on Object {
      _say('The settings could not be removed.');
    }
  });

  void _leave() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.goNamed(englishRouteName);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final field = InputDecoration(
      filled: true,
      fillColor: AppColors.background,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.md),
        borderSide: BorderSide.none,
      ),
    );

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      key: const ValueKey('settings-leave'),
                      onPressed: _leave,
                      child: const Text('← Back'),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text('AI correction ⚙️', style: textTheme.displaySmall),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Your written presentations are corrected by Claude, '
                    'through your own backend. Only the topic, the format and '
                    'what you wrote are sent: never your notes, never '
                    'anything else. Nothing is sent until you save these '
                    'settings, and removing them stops it.',
                    style: textTheme.bodyLarge,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text('Backend address', style: textTheme.titleMedium),
                          const SizedBox(height: AppSpacing.sm),
                          TextField(
                            key: const ValueKey('ai-base-url'),
                            controller: _baseUrl,
                            enabled: _loaded,
                            keyboardType: TextInputType.url,
                            autocorrect: false,
                            decoration: field.copyWith(
                              hintText: 'http://localhost:8080',
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          Text('App token', style: textTheme.titleMedium),
                          const SizedBox(height: AppSpacing.sm),
                          TextField(
                            key: const ValueKey('ai-token'),
                            controller: _token,
                            enabled: _loaded,
                            obscureText: !_showToken,
                            autocorrect: false,
                            enableSuggestions: false,
                            decoration: field.copyWith(
                              hintText: 'The APP_TOKEN of your backend',
                              suffixIcon: IconButton(
                                tooltip: _showToken
                                    ? 'Hide the token'
                                    : 'Show the token',
                                onPressed: () =>
                                    setState(() => _showToken = !_showToken),
                                icon: Icon(
                                  _showToken
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                ),
                              ),
                            ),
                          ),
                          if (_error case final error?) ...[
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              error,
                              key: const ValueKey('ai-settings-error'),
                              style: textTheme.bodyMedium?.copyWith(
                                color: AppColors.coralStrong,
                              ),
                            ),
                          ],
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            'The token is kept in the iPad\'s Keychain, not '
                            'in the app\'s database.',
                            style: textTheme.bodySmall,
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          Wrap(
                            spacing: AppSpacing.md,
                            runSpacing: AppSpacing.md,
                            children: [
                              FilledButton(
                                key: const ValueKey('ai-save'),
                                onPressed: _busy || !_loaded ? null : _save,
                                child: const Text('Save'),
                              ),
                              OutlinedButton(
                                key: const ValueKey('ai-test'),
                                onPressed: _busy || !_loaded ? null : _test,
                                child: const Text('Test connection'),
                              ),
                              TextButton(
                                key: const ValueKey('ai-remove'),
                                onPressed: _busy || !_loaded ? null : _remove,
                                child: const Text('Remove'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
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
