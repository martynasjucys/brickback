import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

import '../../core/display_name.dart';
import '../../l10n/l10n.dart';
import '../../theme/app_theme.dart';
import '../../widgets/primitives.dart';
import '../../widgets/readable_column.dart';
import '../auth/auth_repository.dart';
import 'party_repository.dart';

/// `/party/join` — resolve a short code to a party and enter it. A purple entry
/// screen: a big prompt and a styled code field. Joining mints a transparent
/// guest session if signed out.
class PartyJoinScreen extends ConsumerStatefulWidget {
  const PartyJoinScreen({super.key});

  @override
  ConsumerState<PartyJoinScreen> createState() => _PartyJoinScreenState();
}

class _PartyJoinScreenState extends ConsumerState<PartyJoinScreen> {
  final _controller = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _join() async {
    final code = _controller.text.trim();
    if (code.isEmpty || _loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref
          .read(authRepositoryProvider)
          .ensureGuestSession(displayName: ref.read(displayNameProvider));
      final party = await ref.read(partyRepositoryProvider).joinParty(code);
      if (mounted) context.pushReplacement('/party/${party.id}');
    } catch (e) {
      if (mounted) setState(() => _error = _messageFor(context, e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _messageFor(BuildContext context, Object e) {
    if (e is PostgrestException && e.code == 'P0001') return context.l10n.partyJoinError;
    if (_isOffline(e)) return context.l10n.partyJoinOffline;
    return context.l10n.partyJoinFailed;
  }

  bool _isOffline(Object e) {
    if (e is SocketException) return true;
    final s = e.toString().toLowerCase();
    return s.contains('socketexception') ||
        s.contains('failed host lookup') ||
        s.contains('network is unreachable') ||
        s.contains('connection refused') ||
        s.contains('connection closed') ||
        s.contains('clientexception');
  }

  @override
  Widget build(BuildContext context) {
    final c = BrickColors.of(context);
    final topPad = MediaQuery.paddingOf(context).top;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [c.partyDeep, c.party],
          ),
        ),
        child: ReadableColumn(
          child: ListView(
            padding: EdgeInsets.only(
                top: topPad + AppSpacing.s8, bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.s24),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: SquircleButton(
                    icon: Icons.arrow_back_rounded,
                    fill: c.party,
                    edge: c.partyEdge,
                    fg: Colors.white,
                    onTap: () => Navigator.of(context).maybePop(),
                    semanticLabel: MaterialLocalizations.of(context).backButtonTooltip,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.s40),
              const _JoinHero(),
              const SizedBox(height: AppSpacing.s32),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(context.l10n.partyJoinTitle,
                        style: AppText.display.copyWith(color: Colors.white, fontSize: 32),
                        textAlign: TextAlign.center),
                    const SizedBox(height: AppSpacing.s8),
                    Text(context.l10n.partyJoinSubtitle,
                        style: AppText.body.copyWith(color: Colors.white.withValues(alpha: 0.8)),
                        textAlign: TextAlign.center),
                    const SizedBox(height: AppSpacing.s32),
                    // The code field.
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.s20, vertical: AppSpacing.s16),
                      decoration: BoxDecoration(
                        color: c.partyDeep,
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 2),
                      ),
                      child: TextField(
                        controller: _controller,
                        autofocus: true,
                        textAlign: TextAlign.center,
                        textCapitalization: TextCapitalization.characters,
                        textInputAction: TextInputAction.go,
                        onSubmitted: (_) => _join(),
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 6),
                        cursorColor: Colors.white,
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          isDense: true,
                          hintText: 'A1B2C3D4',
                          hintStyle: TextStyle(
                              color: Colors.white.withValues(alpha: 0.35),
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 6),
                        ),
                      ),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: AppSpacing.s12),
                      Text(_error!,
                          style: AppText.caption.copyWith(color: Colors.white),
                          textAlign: TextAlign.center),
                    ],
                    const SizedBox(height: AppSpacing.s24),
                    AppButton(
                      context.l10n.partyJoinCta,
                      variant: AppButtonVariant.hero,
                      expand: true,
                      loading: _loading,
                      onPressed: _loading ? null : _join,
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

/// Two minifig discs — a light party-illustration placeholder.
class _JoinHero extends StatelessWidget {
  const _JoinHero();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Icon(Icons.groups_2_rounded, size: 96, color: Colors.white.withValues(alpha: 0.9)),
    );
  }
}
