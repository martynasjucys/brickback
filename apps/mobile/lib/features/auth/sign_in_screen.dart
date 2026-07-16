import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/l10n.dart';
import '../../theme/app_theme.dart';
import '../../widgets/primitives.dart';
import '../../widgets/readable_column.dart';
import 'auth_repository.dart';

/// `/sign-in` — the premium-sync entry point. Local-first, so this is only
/// reached deliberately (from the paywall or "turn on sync"), never forced.
///
/// Three providers per the product decision: Apple + Google + email OTP. Google
/// is fully wired; Apple + email need Supabase dashboard provider config to
/// complete the round-trip (the buttons + code paths are in place).
class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _email = TextEditingController();
  String? _busy; // which action is in flight: 'google' | 'apple' | 'email'
  String? _error;
  bool _emailSent = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _run(String tag, Future<void> Function() action) async {
    setState(() {
      _busy = tag;
      _error = null;
      _emailSent = false;
    });
    try {
      await action();
      if (tag == 'email' && mounted) setState(() => _emailSent = true);
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  void _sendEmailLink() {
    final email = _email.text.trim();
    if (!email.contains('@')) {
      setState(() => _error = context.l10n.emailInvalid);
      return;
    }
    _run('email', () => ref.read(authRepositoryProvider).signInWithEmail(email));
  }

  @override
  Widget build(BuildContext context) {
    final c = BrickColors.of(context);
    return ColoredBox(
      color: c.canvas,
      child: SafeArea(
        child: ReadableColumn(
          child: ListView(
          children: [
            ScreenHeader(context.l10n.signInTitle, onBack: () => Navigator.of(context).maybePop()),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(context.l10n.signInHeadline, style: AppText.display),
                  const SizedBox(height: AppSpacing.s8),
                  Text(
                    context.l10n.signInSubtitle,
                    style: AppText.caption,
                  ),
                  const SizedBox(height: AppSpacing.s24),
                  AppButton(
                    context.l10n.continueWithApple,
                    icon: Icons.apple,
                    variant: AppButtonVariant.secondary,
                    expand: true,
                    loading: _busy == 'apple',
                    onPressed: _busy != null
                        ? null
                        : () => _run('apple',
                            () => ref.read(authRepositoryProvider).signInWithApple()),
                  ),
                  const SizedBox(height: AppSpacing.s12),
                  AppButton(
                    context.l10n.continueWithGoogle,
                    icon: Icons.g_mobiledata,
                    expand: true,
                    loading: _busy == 'google',
                    onPressed: _busy != null
                        ? null
                        : () => _run('google',
                            () => ref.read(authRepositoryProvider).signInWithGoogle()),
                  ),
                  const SizedBox(height: AppSpacing.s24),
                  Row(
                    children: [
                      Expanded(child: Divider(color: c.line)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s12),
                        child: Text(context.l10n.orDivider, style: AppText.caption),
                      ),
                      Expanded(child: Divider(color: c.line)),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.s16),
                  SearchField(
                    controller: _email,
                    hint: context.l10n.emailHint,
                  ),
                  const SizedBox(height: AppSpacing.s12),
                  AppButton(
                    context.l10n.emailSignInLink,
                    icon: Icons.mail_outline,
                    variant: AppButtonVariant.secondary,
                    expand: true,
                    loading: _busy == 'email',
                    onPressed: _busy != null ? null : _sendEmailLink,
                  ),
                  if (_emailSent) ...[
                    const SizedBox(height: AppSpacing.s12),
                    Text(
                      context.l10n.emailSentConfirm,
                      style: AppText.caption.copyWith(color: c.success),
                    ),
                  ],
                  if (_error != null) ...[
                    const SizedBox(height: AppSpacing.s12),
                    Text('$_error',
                        style: AppText.caption.copyWith(color: c.danger)),
                  ],
                  const SizedBox(height: AppSpacing.s24),
                  Text(
                    context.l10n.signInFooter,
                    style: AppText.caption.copyWith(color: c.muted),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }
}
